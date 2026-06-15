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
  alias FigKiwi.Native.Scene, as: NativeScene
  alias FigKiwi.Scene.Graph
  alias FigKiwi.Scene.Graph.GUID
  alias FigKiwi.Scene.Index
  alias FigKiwi.Scene.Node
  alias FigKiwi.Scene.Summary

  @type summary :: Summary.t()
  @type scene_node :: Node.t()
  @type scene_index :: Index.t()
  @type scene_graph :: Graph.t()

  @doc """
  Returns a projected scene summary.
  """
  @spec summary(binary()) :: Summary.t()
  def summary(binary) when is_binary(binary) do
    binary
    |> payload!()
    |> NativeScene.decode_summary()
    |> Summary.from_map()
  end

  @doc """
  Builds a reusable native scene index resource.

  Use this when running multiple XPath queries over the same scene.
  """
  @spec index(binary()) :: Index.t()
  def index(binary) when is_binary(binary) do
    resource =
      binary
      |> payload!()
      |> NativeScene.build_index()

    %Index{resource: resource}
  end

  @doc """
  Builds an effective scene graph handle.

  `Scene.index/1` is the fast raw projection. `Scene.graph/2` is the separate
  surface for resolved Figma semantics such as populated instances, symbol
  overrides, component props, derived symbol data, and variable/style
  resolution. The first graph implementation is backed by the projected native
  index while resolver stages are added incrementally.
  """
  @spec graph(binary() | Index.t() | Graph.t() | reference(), keyword()) :: Graph.t()
  def graph(scene, opts \\ []) when is_list(opts), do: Graph.build(scene, opts)

  @doc """
  Queries a binary scene, reusable scene index, or effective graph with XPath.

  Options:

    * `:fields` - list of projected fields to keep in returned nodes. `:guid`
      and `:node_type` are always kept. Defaults to all fields.

  Scene nodes are exposed as elements named by their Figma node type, for
  example `//canvas` or `//text`. Supported projected attributes are:

    * `@guid`
    * `@type`
    * `@name`
    * `@parent_guid`
    * `@position`
    * `@x` / `@width`
    * `@y` / `@height`
    * `@transform`
    * `@visible`
    * `@locked`
    * `@text`
    * `@font_family`
    * `@font_style`
    * `@font_postscript`
    * `@text_style_guid`
  """
  @spec query(binary() | Index.t() | Graph.t() | reference(), String.t(), keyword()) :: [
          scene_node()
        ]
  def query(scene, xpath, opts \\ [])

  def query(binary, xpath, opts) when is_binary(binary) and is_binary(xpath) and is_list(opts) do
    fields = query_fields(opts)
    payload = payload!(binary)

    nodes =
      case fields do
        :all -> NativeScene.query_xpath(payload, xpath)
        fields -> NativeScene.query_xpath_fields(payload, xpath, fields)
      end

    nodes_from_maps(nodes)
  end

  def query(index, xpath, opts) when is_binary(xpath) and is_list(opts) do
    fields = query_fields(opts)
    resource = reusable_index(index)

    nodes =
      case fields do
        :all -> NativeScene.query_index(resource, xpath)
        fields -> NativeScene.query_index_fields(resource, xpath, fields)
      end

    nodes_from_maps(nodes)
  end

  @doc """
  Returns canvas/page nodes.
  """
  @spec pages(binary() | Index.t() | Graph.t() | reference()) :: [scene_node()]
  def pages(scene), do: query(scene, "//canvas")

  @doc """
  Looks up a projected scene node by GUID.
  """
  @spec node(binary() | Index.t() | Graph.t() | reference(), String.t()) :: scene_node() | nil
  def node(%Graph{} = graph, guid) when is_binary(guid),
    do: Map.get(graph.nodes, GUID.parse!(guid))

  def node(scene, guid) when is_binary(guid) do
    scene
    |> reusable_index()
    |> NativeScene.index_node(guid)
    |> maybe_node_from_map()
  end

  @doc """
  Returns root nodes in scene order.
  """
  @spec roots(binary() | Index.t() | Graph.t() | reference()) :: [scene_node()]
  def roots(%Graph{} = graph), do: nodes_by_guids(graph, graph.roots)

  def roots(scene) do
    scene
    |> reusable_index()
    |> NativeScene.index_roots()
    |> nodes_from_maps()
  end

  @doc """
  Returns the parent node for a node GUID.
  """
  @spec parent(binary() | Index.t() | Graph.t() | reference(), String.t()) :: scene_node() | nil
  def parent(%Graph{} = graph, guid) when is_binary(guid) do
    case node(graph, guid) do
      %Node{parent_guid: parent_guid} when is_binary(parent_guid) -> node(graph, parent_guid)
      _node -> nil
    end
  end

  def parent(scene, guid) when is_binary(guid) do
    scene
    |> reusable_index()
    |> NativeScene.index_parent(guid)
    |> maybe_node_from_map()
  end

  @doc """
  Returns direct children for a parent GUID in scene order.
  """
  @spec children(binary() | Index.t() | Graph.t() | reference(), String.t()) :: [scene_node()]
  def children(%Graph{} = graph, parent_guid) when is_binary(parent_guid) do
    nodes_by_guids(graph, Map.get(graph.children, GUID.parse!(parent_guid), []))
  end

  def children(scene, parent_guid) when is_binary(parent_guid) do
    scene
    |> reusable_index()
    |> NativeScene.index_children(parent_guid)
    |> nodes_from_maps()
  end

  @doc """
  Returns sibling nodes for a node GUID in scene order.
  """
  @spec siblings(binary() | Index.t() | Graph.t() | reference(), String.t()) :: [scene_node()]
  def siblings(%Graph{} = graph, guid) when is_binary(guid) do
    case node(graph, guid) do
      %Node{parent_guid: nil} ->
        []

      %Node{parent_guid: parent_guid} ->
        Enum.reject(children(graph, parent_guid), &(&1.guid == guid))

      nil ->
        []
    end
  end

  def siblings(scene, guid) when is_binary(guid) do
    scene
    |> reusable_index()
    |> NativeScene.index_siblings(guid)
    |> nodes_from_maps()
  end

  @doc """
  Returns ancestors for a node GUID, ordered from root to parent.
  """
  @spec ancestors(binary() | Index.t() | Graph.t() | reference(), String.t()) :: [scene_node()]
  def ancestors(%Graph{} = graph, guid) when is_binary(guid) do
    graph_ancestors(graph, guid, [])
  end

  def ancestors(scene, guid) when is_binary(guid) do
    scene
    |> reusable_index()
    |> NativeScene.index_ancestors(guid)
    |> nodes_from_maps()
  end

  @doc """
  Returns all descendants for a node GUID in scene order.
  """
  @spec descendants(binary() | Index.t() | Graph.t() | reference(), String.t()) :: [scene_node()]
  def descendants(%Graph{} = graph, guid) when is_binary(guid) do
    graph_descendants(graph, guid)
  end

  def descendants(scene, guid) when is_binary(guid) do
    scene
    |> reusable_index()
    |> NativeScene.index_descendants(guid)
    |> nodes_from_maps()
  end

  @doc """
  Returns nodes of a given projected node type without constructing XPath.
  """
  @spec by_type(
          binary() | Index.t() | Graph.t() | reference() | [scene_node()],
          atom() | String.t(),
          keyword()
        ) :: [scene_node()]
  def by_type(scene_or_nodes, type, opts \\ [])

  def by_type(nodes, type, _opts) when is_list(nodes) and (is_atom(type) or is_binary(type)) do
    node_type = type |> to_string() |> Macro.underscore()
    Enum.filter(nodes, &(&1.node_type == node_type))
  end

  def by_type(%Graph{} = graph, type, opts) when is_atom(type) or is_binary(type) do
    node_type = type |> to_string() |> Macro.underscore()

    graph
    |> nodes_by_guids(Map.get(graph.by_type, node_type, []))
    |> apply_field_filter(opts)
  end

  def by_type(scene, type, opts) when is_atom(type) or is_binary(type) do
    fields = query_fields(opts)
    index = reusable_index(scene)
    node_type = type |> to_string() |> Macro.underscore()

    case fields do
      :all -> NativeScene.index_by_type(index, node_type)
      fields -> NativeScene.index_by_type_fields(index, node_type, fields)
    end
    |> nodes_from_maps()
  end

  @doc """
  Returns nodes with an exact projected name without constructing XPath.
  """
  @spec named(binary() | Index.t() | Graph.t() | reference() | [scene_node()], String.t()) :: [
          scene_node()
        ]
  def named(nodes, name) when is_list(nodes) and is_binary(name) do
    Enum.filter(nodes, &(&1.name == name))
  end

  def named(%Graph{} = graph, name) when is_binary(name) do
    nodes_by_guids(graph, Map.get(graph.by_name, name, []))
  end

  def named(scene, name) when is_binary(name) do
    scene
    |> reusable_index()
    |> NativeScene.index_named(name)
    |> nodes_from_maps()
  end

  @doc """
  Returns nodes whose projected name contains `needle` without constructing XPath.
  """
  @spec name_contains(
          binary() | Index.t() | Graph.t() | reference() | [scene_node()],
          String.t(),
          keyword()
        ) ::
          [scene_node()]
  def name_contains(scene_or_nodes, needle, opts \\ [])

  def name_contains(nodes, needle, _opts) when is_list(nodes) and is_binary(needle) do
    Enum.filter(nodes, &(is_binary(&1.name) and String.contains?(&1.name, needle)))
  end

  def name_contains(%Graph{} = graph, needle, opts) when is_binary(needle) do
    graph.nodes
    |> Map.values()
    |> name_contains(needle)
    |> apply_field_filter(opts)
  end

  def name_contains(scene, needle, opts) when is_binary(needle) do
    fields = query_fields(opts)
    index = reusable_index(scene)

    case fields do
      :all -> NativeScene.index_name_contains(index, needle)
      fields -> NativeScene.index_name_contains_fields(index, needle, fields)
    end
    |> nodes_from_maps()
  end

  @doc """
  Returns text nodes.
  """
  @spec text_nodes(binary() | Index.t() | Graph.t() | reference() | [scene_node()]) :: [
          scene_node()
        ]
  def text_nodes(scene_or_nodes), do: by_type(scene_or_nodes, :text)

  @doc """
  Returns nodes with component keys.
  """
  @spec components(binary() | Index.t() | Graph.t() | reference() | [scene_node()]) :: [
          scene_node()
        ]
  def components(nodes) when is_list(nodes), do: Enum.filter(nodes, &present?(&1.component_key))

  def components(%Graph{} = graph), do: graph.nodes |> Map.values() |> components()

  def components(scene) do
    scene
    |> reusable_index()
    |> NativeScene.index_components()
    |> nodes_from_maps()
  end

  @doc """
  Returns nodes with one or more fill paints.
  """
  @spec with_fills(binary() | Index.t() | Graph.t() | reference() | [scene_node()]) :: [
          scene_node()
        ]
  def with_fills(nodes) when is_list(nodes), do: Enum.filter(nodes, &positive?(&1.fill_count))

  def with_fills(%Graph{} = graph), do: graph.nodes |> Map.values() |> with_fills()

  def with_fills(scene) do
    scene
    |> reusable_index()
    |> NativeScene.index_with_fills()
    |> nodes_from_maps()
  end

  @doc """
  Returns nodes with one or more stroke paints.
  """
  @spec with_strokes(binary() | Index.t() | Graph.t() | reference() | [scene_node()]) :: [
          scene_node()
        ]
  def with_strokes(nodes) when is_list(nodes), do: Enum.filter(nodes, &positive?(&1.stroke_count))

  def with_strokes(%Graph{} = graph), do: graph.nodes |> Map.values() |> with_strokes()

  def with_strokes(scene) do
    scene
    |> reusable_index()
    |> NativeScene.index_with_strokes()
    |> nodes_from_maps()
  end

  @doc """
  Returns text nodes whose projected text contains `needle` without constructing XPath.
  """
  @spec text_contains(
          binary() | Index.t() | Graph.t() | reference() | [scene_node()],
          String.t(),
          keyword()
        ) ::
          [scene_node()]
  def text_contains(scene_or_nodes, needle, opts \\ [])

  def text_contains(nodes, needle, _opts) when is_list(nodes) and is_binary(needle) do
    Enum.filter(nodes, &(is_binary(&1.text) and String.contains?(&1.text, needle)))
  end

  def text_contains(%Graph{} = graph, needle, opts) when is_binary(needle) do
    graph.nodes
    |> Map.values()
    |> text_contains(needle)
    |> apply_field_filter(opts)
  end

  def text_contains(scene, needle, opts) when is_binary(needle) do
    fields = query_fields(opts)
    index = reusable_index(scene)

    case fields do
      :all -> NativeScene.index_text_contains(index, needle)
      fields -> NativeScene.index_text_contains_fields(index, needle, fields)
    end
    |> nodes_from_maps()
  end

  @doc """
  Returns projected field values from nodes, similar to `Floki.attribute/2`.
  """
  @spec attribute([scene_node()], atom() | String.t()) :: [term()]
  def attribute(nodes, field) when is_list(nodes) and (is_atom(field) or is_binary(field)) do
    field = node_field(field)

    nodes
    |> Enum.map(&Map.get(&1, field))
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Returns projected text from nodes, similar to `Floki.text/2`.

  Options:

    * `:sep` - separator between text values. Defaults to `""`.
  """
  @spec text([scene_node()], keyword()) :: String.t()
  def text(nodes, opts \\ []) when is_list(nodes) and is_list(opts) do
    nodes
    |> attribute(:text)
    |> Enum.join(Keyword.get(opts, :sep, ""))
  end

  @doc """
  Finds nodes by common projected fields without interpolating XPath.

  Supported options:

    * `:type` - atom or string node type, for example `:text` or `"text"`
    * `:name` - exact node name
    * `:name_contains` - substring match on node name
    * `:text_contains` - substring match on projected text
  """
  @spec find(binary() | Index.t() | Graph.t() | reference(), keyword()) :: [scene_node()]
  def find(scene, opts) when is_list(opts) do
    scene
    |> reusable_index()
    |> find_candidates(opts)
    |> filter_find_results(opts)
  end

  @doc """
  Builds a lightweight nested scene tree.

  Options:

    * `:root` - GUID to use as the root. Defaults to all root nodes.
    * `:depth` - maximum child depth. Defaults to `3`.
  """
  @spec tree(binary() | Index.t() | Graph.t() | reference(), keyword()) ::
          [Node.t()] | Node.t() | nil
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

  defp reusable_index(scene) when is_binary(scene), do: scene |> index() |> reusable_index()
  defp reusable_index(%Graph{resource: resource}), do: resource
  defp reusable_index(%Index{resource: resource}), do: resource
  defp reusable_index(index), do: index

  defp tree_node(_index, %Node{} = node, 0), do: %Node{node | children: []}

  defp tree_node(index, %Node{} = node, depth) do
    children = Enum.map(children(index, node.guid), &tree_node(index, &1, depth - 1))
    %Node{node | children: children}
  end

  defp find_candidates(index, opts) do
    cond do
      type = opts[:type] -> by_type(index, type)
      name = opts[:name] -> named(index, name)
      name = opts[:name_contains] -> name_contains(index, name)
      text = opts[:text_contains] -> text_contains(index, text)
      true -> query(index, "//*")
    end
  end

  defp filter_find_results(nodes, opts) do
    Enum.filter(nodes, fn node ->
      Enum.all?(opts, fn
        {:type, type} -> node.node_type == type |> to_string() |> Macro.underscore()
        {:name, name} -> node.name == name
        {:name_contains, needle} -> is_binary(node.name) and String.contains?(node.name, needle)
        {:text_contains, needle} -> is_binary(node.text) and String.contains?(node.text, needle)
        {_key, _value} -> true
      end)
    end)
  end

  defp nodes_from_maps(nodes), do: Enum.map(nodes, &Node.from_map/1)

  defp nodes_by_guids(%Graph{} = graph, guids) do
    guids
    |> Enum.map(&Map.get(graph.nodes, &1))
    |> Enum.reject(&is_nil/1)
  end

  defp apply_field_filter(nodes, opts) do
    case query_fields(opts) do
      :all -> nodes
      fields -> Enum.map(nodes, &filter_node_fields(&1, fields))
    end
  end

  defp filter_node_fields(%Node{} = node, fields) do
    fields = Enum.uniq(["guid", "node_type" | fields])

    node
    |> Map.from_struct()
    |> Map.take(Enum.map(fields, &node_field/1))
    |> Node.from_map()
  end

  defp graph_ancestors(%Graph{} = graph, guid, acc) do
    case parent(graph, guid) do
      nil -> acc
      %Node{guid: parent_guid} = parent -> graph_ancestors(graph, parent_guid, [parent | acc])
    end
  end

  defp graph_descendants(%Graph{} = graph, guid) do
    graph
    |> children(guid)
    |> Enum.flat_map(fn child -> [child | graph_descendants(graph, child.guid)] end)
  end

  defp present?(value), do: is_binary(value) and value != ""
  defp positive?(value), do: is_integer(value) and value > 0

  defp maybe_node_from_map(nil), do: nil
  defp maybe_node_from_map(map), do: Node.from_map(map)

  defp query_fields(opts) do
    case Keyword.get(opts, :fields, :all) do
      :all -> :all
      fields when is_list(fields) -> fields |> Enum.map(&field_name/1) |> Enum.uniq()
    end
  end

  defp field_name(field) when is_atom(field), do: Atom.to_string(field)
  defp field_name(field) when is_binary(field), do: field

  defp node_field(:type), do: :node_type
  defp node_field("type"), do: :node_type
  defp node_field(field) when is_atom(field), do: field

  defp node_field(field) when is_binary(field) do
    String.to_existing_atom(field)
  rescue
    ArgumentError -> :__unknown_field__
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
