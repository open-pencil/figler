defmodule Figler.Scene.Input do
  @moduledoc """
  Normalizes Figma scene inputs for native scene APIs.

  Public scene APIs accept exported `.fig` archives, lower-level Figma Kiwi
  container binaries, and already-extracted raw Kiwi `Message` binaries. This
  module owns that boundary so `Figler.Scene` can stay focused on the query and
  navigation API.
  """

  alias Figler.Container
  alias Figler.Scene.Graph
  alias Figler.Scene.Index

  @doc """
  Extracts the raw Figma Kiwi `Message` binary from any supported scene input.
  """
  @spec payload!(binary()) :: binary()
  def payload!(<<"PK", _rest::binary>> = zip_binary) do
    zip_binary
    |> unzip_canvas!()
    |> payload!()
  end

  def payload!(<<"fig-kiwi", _rest::binary>> = binary), do: Container.data(binary)
  def payload!(binary) when is_binary(binary), do: binary

  @doc """
  Returns a native scene index resource for a binary, graph, index, or resource.
  """
  @spec resource(binary() | Graph.t() | Index.t() | reference()) :: reference()
  def resource(binary) when is_binary(binary), do: binary |> Figler.Scene.index() |> resource()
  def resource(%Graph{resource: nil, source: source}) when is_binary(source), do: resource(source)
  def resource(%Graph{resource: resource}), do: resource
  def resource(%Index{resource: resource}), do: resource
  def resource(resource) when is_reference(resource), do: resource

  defp unzip_canvas!(zip_binary) do
    case :zip.extract(zip_binary, [:memory, {:file_list, [~c"canvas.fig"]}]) do
      {:ok, entries} -> canvas_entry!(entries)
      {:error, reason} -> raise ArgumentError, "cannot read FIG ZIP: #{inspect(reason)}"
    end
  end

  defp canvas_entry!(entries) do
    case Enum.find_value(entries, &canvas_entry/1) do
      nil -> raise ArgumentError, "ZIP does not contain canvas.fig"
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
