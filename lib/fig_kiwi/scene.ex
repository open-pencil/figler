defmodule FigKiwi.Scene do
  @moduledoc """
  Projected native scene helpers.

  These functions accept any of the common Figma payload envelopes:

    * a raw Kiwi `Message` payload
    * a `fig-kiwi` `canvas.fig` container
    * a `.fig` ZIP containing `canvas.fig`

  The scene is scanned natively and projected into lightweight structs instead
  of materializing the full generated schema tree.
  """

  alias FigKiwi.Container
  alias FigKiwi.Native
  alias FigKiwi.Scene.Node
  alias FigKiwi.Scene.Summary

  @type summary :: Summary.t()
  @type scene_node :: Node.t()

  @doc """
  Returns a projected scene summary.
  """
  @spec summary(binary()) :: Summary.t()
  def summary(binary) when is_binary(binary) do
    binary
    |> payload!()
    |> Native.decode_scene_summary()
    |> Summary.from_map()
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
    |> nodes_from_maps()
  end

  def query(index, xpath) when is_binary(xpath) do
    index
    |> Native.query_scene_index(xpath)
    |> nodes_from_maps()
  end

  @doc """
  Returns canvas/page nodes.
  """
  @spec pages(binary() | reference()) :: [scene_node()]
  def pages(scene), do: query(scene, "//canvas")

  @doc """
  Looks up a projected scene node by GUID.
  """
  @spec node(binary() | reference(), String.t()) :: scene_node() | nil
  def node(scene, guid) when is_binary(guid) do
    scene
    |> query("//*[@guid=#{xpath_literal(guid)}]")
    |> List.first()
  end

  @doc """
  Returns direct children for a parent GUID in scene order.
  """
  @spec children(binary() | reference(), String.t()) :: [scene_node()]
  def children(scene, parent_guid) when is_binary(parent_guid) do
    query(scene, "//*[@parent_guid=#{xpath_literal(parent_guid)}]")
  end

  @doc """
  Finds nodes by common projected fields.

  Supported options:

    * `:type` - atom or string node type, for example `:text` or `"text"`
    * `:name` - exact node name
    * `:name_contains` - substring match on node name
  """
  @spec find(binary() | reference(), keyword()) :: [scene_node()]
  def find(scene, opts) when is_list(opts) do
    type = opts[:type]
    element = if type, do: type |> to_string() |> Macro.underscore(), else: "*"

    predicates =
      [
        if(name = opts[:name], do: "@name=#{xpath_literal(name)}"),
        if(contains = opts[:name_contains], do: "contains(@name, #{xpath_literal(contains)})")
      ]
      |> Enum.reject(&is_nil/1)

    predicate =
      case predicates do
        [] -> ""
        predicates -> "[#{Enum.join(predicates, " and ")}]"
      end

    query(scene, "//#{element}#{predicate}")
  end

  @doc """
  Builds a lightweight nested scene tree.

  Options:

    * `:root` - GUID to use as the root. Defaults to all root nodes.
    * `:depth` - maximum child depth. Defaults to `3`.
  """
  @spec tree(binary() | reference(), keyword()) :: [Node.t()] | Node.t() | nil
  def tree(scene, opts \\ []) when is_list(opts) do
    index = reusable_index(scene)
    depth = Keyword.get(opts, :depth, 3)

    case Keyword.fetch(opts, :root) do
      {:ok, guid} ->
        if root = node(index, guid) do
          tree_node(index, root, depth)
        end

      :error ->
        index
        |> query("//*[not(@parent_guid)]")
        |> Enum.map(&tree_node(index, &1, depth))
    end
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

  defp reusable_index(scene) when is_binary(scene), do: index(scene)
  defp reusable_index(index), do: index

  defp tree_node(_index, %Node{} = node, 0), do: %Node{node | children: []}

  defp tree_node(index, %Node{} = node, depth) do
    children = Enum.map(children(index, node.guid), &tree_node(index, &1, depth - 1))
    %Node{node | children: children}
  end

  defp nodes_from_maps(nodes), do: Enum.map(nodes, &Node.from_map/1)

  defp xpath_literal(value) when is_atom(value), do: value |> Atom.to_string() |> xpath_literal()

  defp xpath_literal(value) when is_binary(value) do
    cond do
      not String.contains?(value, "'") ->
        "'#{value}'"

      not String.contains?(value, "\"") ->
        "\"#{value}\""

      true ->
        parts = value |> String.split("'") |> Enum.map(&"'#{&1}'")
        "concat(#{Enum.join(parts, ~s[, "'", ])})"
    end
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
