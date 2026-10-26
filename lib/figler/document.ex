defmodule Figler.Document do
  @moduledoc """
  A complete decoded boundary for a Figma document.

  This representation preserves archive entries and rendering assets alongside
  the raw Kiwi payload and document metadata. `open/1` leaves `:message` as
  `nil` for analysis and rendering; `Figler.decode/1` additionally fills it
  with a complete generated message for ordinary Elixir transformations.
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
    :canvas_path,
    :payload,
    :message,
    schema: <<>>,
    entries: %{},
    images: %{},
    blobs: [],
    pages: []
  ]

  @type source :: :archive | :container | :payload

  @type t :: %__MODULE__{
          source: source(),
          canvas: binary() | nil,
          canvas_path: String.t() | nil,
          payload: binary(),
          schema: binary(),
          message: Figler.Schema.Message.t() | nil,
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
    {canvas_path, canvas} = canvas!(entries)
    build(:archive, canvas, Figler.Container.source(canvas), entries, canvas_path)
  end

  defp do_open!(<<"fig-kiwi", _rest::binary>> = canvas) do
    build(:container, canvas, Figler.Container.source(canvas), %{})
  end

  defp do_open!(payload), do: build(:payload, nil, {payload, <<>>}, %{})

  defp build(source, canvas, {payload, schema}, entries, canvas_path \\ nil) do
    {pages, blobs} =
      Error.protect(:open_document, fn ->
        CodecNifs.decode_document_metadata({payload, schema})
      end)

    %__MODULE__{
      source: source,
      canvas: canvas,
      canvas_path: canvas_path,
      payload: payload,
      schema: schema,
      message: nil,
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

  @doc false
  @spec encode_payload!(t(), binary()) :: binary()
  def encode_payload!(%__MODULE__{source: :payload}, payload) when is_binary(payload), do: payload

  def encode_payload!(%__MODULE__{source: :container, canvas: canvas}, payload)
      when is_binary(canvas) and is_binary(payload) do
    Figler.Container.replace_data(canvas, payload)
  end

  def encode_payload!(
        %__MODULE__{
          source: :archive,
          canvas: canvas,
          canvas_path: canvas_path,
          entries: entries
        },
        payload
      )
      when is_binary(canvas) and is_binary(canvas_path) and is_map(entries) and is_binary(payload) do
    canvas = Figler.Container.replace_data(canvas, payload)
    entries = Map.put(entries, canvas_path, canvas)

    zip_entries =
      entries
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map(fn {path, contents} -> {String.to_charlist(path), contents} end)

    case :zip.create(~c"document.fig", zip_entries, [:memory]) do
      {:ok, {_name, archive}} -> archive
      {:error, reason} -> raise Error.new(:invalid_document, :encode_document, %{reason: reason})
    end
  end

  def encode_payload!(%__MODULE__{}, _payload) do
    raise Error.new(:invalid_document, :encode_document, %{reason: :invalid_document_state})
  end

  defp canvas!(entries) do
    case Enum.find(["canvas.fig", "canvas"], &Map.has_key?(entries, &1)) do
      nil -> fallback_canvas!(entries)
      path -> {path, Map.fetch!(entries, path)}
    end
  end

  defp fallback_canvas!(entries) do
    case Enum.find(entries, fn {path, _contents} ->
           Path.basename(path) in ["canvas.fig", "canvas"]
         end) do
      nil -> raise Error.new(:missing_canvas, :open_document)
      canvas_entry -> canvas_entry
    end
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
