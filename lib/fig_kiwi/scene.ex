defmodule FigKiwi.Scene do
  @moduledoc """
  Projected native scene helpers.

  These functions accept any of the common Figma payload envelopes:

    * a raw Kiwi `Message` payload
    * a `fig-kiwi` `canvas.fig` container
    * a `.fig` ZIP containing `canvas.fig`

  The scene is scanned natively and projected into lightweight maps instead of
  materializing the full generated schema tree.
  """

  alias FigKiwi.Container
  alias FigKiwi.Native

  @type summary :: %{
          node_count: non_neg_integer(),
          parented_count: non_neg_integer(),
          root_count: non_neg_integer(),
          type_counts: [{String.t(), non_neg_integer()}]
        }

  @type scene_node :: %{
          guid: String.t(),
          node_type: String.t(),
          name: String.t() | nil,
          parent_guid: String.t() | nil,
          position: String.t() | nil
        }

  @doc """
  Returns a projected scene summary.
  """
  @spec summary(binary()) :: summary()
  def summary(binary) when is_binary(binary) do
    binary
    |> payload!()
    |> Native.decode_scene_summary()
  end

  @doc """
  Builds a reusable native scene index resource.

  Use this when running multiple XPath queries over the same scene.
  """
  @spec index(binary()) :: reference()
  def index(binary) when is_binary(binary) do
    binary
    |> payload!()
    |> Native.build_scene_index()
  end

  @doc """
  Queries a binary scene or reusable scene index with XPath.

  Scene nodes are exposed as elements named by their Figma node type, for
  example `//canvas` or `//text`. Supported projected attributes are:

    * `@guid`
    * `@type`
    * `@name`
    * `@parent_guid`
    * `@position`
  """
  @spec query(binary() | reference(), String.t()) :: [scene_node()]
  def query(binary, xpath) when is_binary(binary) and is_binary(xpath) do
    binary
    |> payload!()
    |> Native.query_scene_xpath(xpath)
  end

  def query(index, xpath) when is_binary(xpath) do
    Native.query_scene_index(index, xpath)
  end

  @doc """
  Extracts the raw Kiwi `Message` payload from a raw payload, `canvas.fig`
  container, or `.fig` ZIP.
  """
  @spec payload!(binary()) :: binary()
  def payload!(<<"PK", _rest::binary>> = zip_binary) do
    zip_binary
    |> unzip_canvas!()
    |> payload!()
  end

  def payload!(binary) when is_binary(binary) do
    %{data: data} = Container.decode(binary)
    data
  rescue
    KiwiCodec.DecodeError -> binary
    MatchError -> binary
  end

  defp unzip_canvas!(zip_binary) do
    case :zip.extract(zip_binary, [:memory]) do
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
