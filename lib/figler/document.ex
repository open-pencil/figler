defmodule Figler.Document do
  @moduledoc """
  A complete decoded boundary for a Figma document.

  Unlike the lightweight scene input normalizer, this representation preserves
  archive entries and rendering assets alongside the raw Kiwi payload and
  projected document metadata. Use it when later stages need more than scene records.
  """

  alias Figler.Document.Page
  alias Figler.Native.CodecNifs
  alias Figler.Scene.Graph.GUID

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

  @doc "Opens an exported `.fig` archive, `fig-kiwi` container, or raw Kiwi payload."
  @spec open(binary()) :: {:ok, t()} | {:error, term()}
  def open(input) when is_binary(input) do
    {:ok, open!(input)}
  rescue
    error in [ArgumentError, KiwiCodec.DecodeError, ErlangError] -> {:error, error}
  end

  @doc "Like `open/1`, but raises when the input cannot be decoded."
  @spec open!(binary()) :: t()
  def open!(<<"PK", _rest::binary>> = archive) do
    entries = unzip!(archive)
    canvas = canvas!(entries)
    build(:archive, canvas, Figler.Container.data(canvas), entries)
  end

  def open!(<<"fig-kiwi", _rest::binary>> = canvas) do
    build(:container, canvas, Figler.Container.data(canvas), %{})
  end

  def open!(payload) when is_binary(payload), do: build(:payload, nil, payload, %{})

  defp build(source, canvas, payload, entries) do
    {pages, blobs} = CodecNifs.decode_document_metadata(payload)

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
    case :zip.extract(archive, [:memory]) do
      {:ok, entries} -> Map.new(entries, &archive_entry/1)
      {:error, reason} -> raise ArgumentError, "cannot read FIG ZIP: #{inspect(reason)}"
    end
  end

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
      nil -> raise ArgumentError, "ZIP does not contain canvas.fig or canvas"
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
