defmodule Figler.Scene.Input do
  @moduledoc """
  Normalizes Figma scene inputs for native scene APIs.

  Public scene APIs accept exported `.fig` archives, lower-level Figma Kiwi
  container binaries, and already-extracted raw Kiwi `Message` binaries. This
  module owns that boundary so `Figler.Scene` can stay focused on the query and
  navigation API.
  """

  alias Figler.Container
  alias Figler.Error
  alias Figler.Native.SceneNifs
  alias Figler.Scene.Graph
  alias Figler.Scene.Index

  @typedoc """
  A raw `Message` binary with the binary Kiwi schema it was written with.

  The schema is empty when the input carried none, as for a raw `Message`.
  Native decoders use it to skip fields Figler's compiled schema does not know.
  """
  @type source :: Figler.Scene.source()

  @doc """
  Extracts the raw Figma Kiwi `Message` binary from any supported scene input.
  """
  @spec payload!(binary()) :: binary()
  def payload!(binary) when is_binary(binary), do: binary |> source!() |> elem(0)

  @doc """
  Extracts the raw `Message` binary and its embedded schema from any supported
  scene input.
  """
  @spec source!(binary()) :: source()
  def source!(binary) when is_binary(binary),
    do: Error.protect(:extract_payload, fn -> do_source!(binary) end)

  @doc """
  Normalizes a payload binary or source into a source.
  """
  @spec to_source(binary() | source()) :: source()
  def to_source({payload, schema} = source) when is_binary(payload) and is_binary(schema),
    do: source

  def to_source(payload) when is_binary(payload), do: {payload, <<>>}

  defp do_source!(<<"PK", _rest::binary>> = zip_binary) do
    zip_binary
    |> unzip_canvas!()
    |> do_source!()
  end

  defp do_source!(<<"fig-kiwi", _rest::binary>> = binary), do: Container.source(binary)
  defp do_source!(binary), do: {binary, <<>>}

  @doc """
  Returns a native scene index resource for a binary, graph, index, or resource.
  """
  @spec resource(binary() | Graph.t() | Index.t() | reference()) :: reference()
  def resource(binary) when is_binary(binary), do: binary |> Figler.Scene.index() |> resource()

  def resource(%Graph{resource: nil, source: {payload, _schema} = source})
      when is_binary(payload),
      do: SceneNifs.build_index(source)

  def resource(%Graph{resource: nil, source: source}) when is_binary(source), do: resource(source)
  def resource(%Graph{resource: resource}), do: resource
  def resource(%Index{resource: resource}), do: resource
  def resource(resource) when is_reference(resource), do: resource

  defp unzip_canvas!(zip_binary) do
    case :zip.extract(zip_binary, [:memory, {:file_list, [~c"canvas.fig"]}]) do
      {:ok, entries} -> canvas_entry!(entries)
      {:error, reason} -> raise Error.new(:invalid_archive, :extract_payload, %{reason: reason})
    end
  end

  defp canvas_entry!(entries) do
    case Enum.find_value(entries, &canvas_entry/1) do
      nil -> raise Error.new(:missing_canvas, :extract_payload)
      canvas -> canvas
    end
  end

  defp canvas_entry({~c"canvas.fig", canvas}), do: IO.iodata_to_binary(canvas)

  defp canvas_entry({path, canvas}) do
    if Path.basename(to_string(path)) == "canvas.fig" do
      IO.iodata_to_binary(canvas)
    end
  end
end
