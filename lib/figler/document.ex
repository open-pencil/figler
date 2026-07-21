defmodule Figler.Document do
  @moduledoc """
  A complete decoded boundary for a Figma document.

  Unlike the lightweight scene input normalizer, this representation preserves
  archive entries and rendering assets alongside the raw Kiwi payload and
  projected document metadata. Use it when later stages need more than scene records.
  """

  alias Figler.Document.Page
  alias Figler.Error
  alias Figler.Native.CodecNifs
  alias Figler.Scene.Graph.GUID

  @max_archive_entries 4_096
  @max_archive_entry_bytes 268_435_456
  @max_archive_uncompressed_bytes 536_870_912

  @enforce_keys [:source, :payload]
  defstruct [
    :source,
    :canvas,
    :payload,
    entries: %{},
    images: %{},
    blobs: [],
    pages: []
  ]

  @type source :: :archive | :container | :payload

  @type t :: %__MODULE__{
          source: source(),
          canvas: binary() | nil,
          payload: binary(),
          entries: %{optional(String.t()) => binary()},
          images: %{optional(String.t()) => binary()},
          blobs: [binary()],
          pages: [Page.t()]
        }

  @doc """
  Opens an exported `.fig` archive, `fig-kiwi` container, or raw Kiwi payload.

  Returns `{:error, %Figler.Error{}}` for malformed input.
  """
  @spec open(binary()) :: {:ok, t()} | {:error, Error.t()}
  def open(input) when is_binary(input) do
    {:ok, open!(input)}
  rescue
    error in Error -> {:error, error}
  end

  @doc "Like `open/1`, but raises `Figler.Error` when the input cannot be decoded."
  @spec open!(binary()) :: t()
  def open!(input) when is_binary(input),
    do: Error.protect(:open_document, fn -> do_open!(input) end)

  defp do_open!(<<"PK", _rest::binary>> = archive) do
    entries = unzip!(archive)
    canvas = canvas!(entries)
    build(:archive, canvas, Figler.Container.data(canvas), entries)
  end

  defp do_open!(<<"fig-kiwi", _rest::binary>> = canvas) do
    build(:container, canvas, Figler.Container.data(canvas), %{})
  end

  defp do_open!(payload), do: build(:payload, nil, payload, %{})

  defp build(source, canvas, payload, entries) do
    {pages, blobs} =
      Error.protect(:open_document, fn -> CodecNifs.decode_document_metadata(payload) end)

    %__MODULE__{
      source: source,
      canvas: canvas,
      payload: payload,
      entries: entries,
      images: archive_images(entries),
      blobs: Enum.map(blobs, &message_blob/1),
      pages: Enum.map(pages, &document_page/1)
    }
  end

  defp unzip!(archive) do
    with {:ok, table} <- :zip.table(archive),
         :ok <- validate_archive_table(table),
         {:ok, entries} <- :zip.extract(archive, [:memory]) do
      Map.new(entries, &archive_entry/1)
    else
      {:error, reason} -> raise Error.new(:invalid_archive, :open_document, %{reason: reason})
    end
  end

  defp validate_archive_table(table) do
    table
    |> Enum.reduce_while({0, 0}, &count_archive_entry/2)
    |> case do
      {:error, details} -> {:error, {:archive_limits_exceeded, details}}
      {_count, _total} -> :ok
    end
  end

  defp count_archive_entry({:zip_comment, _comment}, totals), do: {:cont, totals}

  defp count_archive_entry(
         {:zip_file, _path,
          {:file_info, size, _type, _access, _atime, _mtime, _ctime, _mode, _links, _major,
           _minor, _inode, _uid, _gid}, _comment, _offset, _compressed},
         {count, total}
       )
       when is_integer(size) and size >= 0 do
    next = %{entry_count: count + 1, entry_bytes: size, total_bytes: total + size}

    cond do
      next.entry_count > @max_archive_entries ->
        {:halt, {:error, Map.put(next, :limit, :entry_count)}}

      next.entry_bytes > @max_archive_entry_bytes ->
        {:halt, {:error, Map.put(next, :limit, :entry_bytes)}}

      next.total_bytes > @max_archive_uncompressed_bytes ->
        {:halt, {:error, Map.put(next, :limit, :total_bytes)}}

      true ->
        {:cont, {next.entry_count, next.total_bytes}}
    end
  end

  defp count_archive_entry(_entry, _totals),
    do: {:halt, {:error, %{limit: :invalid_archive_table}}}

  defp archive_entry({path, contents}) do
    {normalize_path(path), IO.iodata_to_binary(contents)}
  end

  defp normalize_path(path) do
    path
    |> to_string()
    |> String.replace("\\", "/")
    |> String.trim_leading("./")
  end

  defp canvas!(entries) do
    ["canvas.fig", "canvas"]
    |> Enum.find_value(&Map.get(entries, &1))
    |> case do
      nil -> fallback_canvas!(entries)
      canvas -> canvas
    end
  end

  defp fallback_canvas!(entries) do
    case Enum.find_value(entries, &canvas_entry/1) do
      nil -> raise Error.new(:missing_canvas, :open_document)
      canvas -> canvas
    end
  end

  defp canvas_entry({path, contents}) do
    if Path.basename(path) in ["canvas.fig", "canvas"], do: contents
  end

  defp archive_images(entries) do
    Enum.reduce(entries, %{}, fn {path, contents}, images ->
      case archive_image_path(path) do
        nil -> images
        image_path -> Map.put(images, image_path, contents)
      end
    end)
  end

  defp archive_image_path("images/"), do: nil
  defp archive_image_path("images/" <> image_path), do: image_path
  defp archive_image_path(_path), do: nil

  defp message_blob(blob), do: blob |> Map.get(:bytes, []) |> IO.iodata_to_binary()

  defp document_page({guid, name}), do: %Page{guid: GUID.format(guid), name: name}
end
