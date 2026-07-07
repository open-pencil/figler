defmodule Figler.Scene do
  @moduledoc """
  Projected native scene helpers.

  These functions accept `.fig` files directly, as well as already-extracted
  Figma Kiwi binaries for lower-level tooling.

  The scene is scanned natively and projected into lightweight structs instead
  of materializing the full generated schema tree.
  """

  alias Figler.Native.SceneNifs, as: NativeScene
  alias Figler.Scene.Graph
  alias Figler.Scene.Graph.GUID
  alias Figler.Scene.Index
  alias Figler.Scene.Input
  alias Figler.Scene.Node
  alias Figler.Scene.Query
  alias Figler.Scene.Summary
  alias Figler.Scene.Tree

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
    resource = binary |> payload!() |> NativeScene.build_index()
    %Index{resource: resource}
  end

  @doc """
  Builds an effective scene graph handle.

  `Scene.index/1` is the fast raw projection. `Scene.graph/2` is the separate
  surface for resolved Figma semantics such as populated instances, symbol
  overrides, component props, derived symbol data, and variable/style
  resolution.
  """
  @spec graph(binary() | Index.t() | Graph.t() | reference(), keyword()) :: Graph.t()
  def graph(scene, opts \\ []) when is_list(opts), do: Graph.build(scene, opts)

  @doc """
  Queries a binary scene, reusable scene index, or effective graph with XPath.

  Options:

    * `:fields` - list of projected fields to keep in returned nodes. `:guid`
      and `:node_type` are always kept. Defaults to all fields.

  Scene nodes are exposed as elements named by their Figma node type, for
  example `//canvas` or `//text`.
  """
  @spec query(binary() | Index.t() | Graph.t() | reference(), String.t(), keyword()) :: [
          scene_node()
        ]
  def query(scene, xpath, opts \\ [])

  def query(binary, xpath, opts) when is_binary(binary) and is_binary(xpath) and is_list(opts) do
    fields = Query.query_fields(opts)
    payload = payload!(binary)

    case fields do
      :all -> NativeScene.query_xpath(payload, xpath)
      fields -> NativeScene.query_xpath_fields(payload, xpath, fields)
    end
    |> Query.nodes_from_maps()
  end

  def query(scene, xpath, opts) when is_binary(xpath) and is_list(opts) do
    fields = Query.query_fields(opts)
    resource = Input.resource(scene)

    case fields do
      :all -> NativeScene.query_index(resource, xpath)
      fields -> NativeScene.query_index_fields(resource, xpath, fields)
    end
    |> Query.nodes_from_maps()
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
    do: graph.nodes |> Map.get(GUID.parse!(guid)) |> Query.public_node()

  def node(scene, guid) when is_binary(guid) do
    scene
    |> Input.resource()
    |> NativeScene.index_node(guid)
    |> Query.maybe_node_from_map()
  end

  @doc """
  Returns root nodes in scene order.
  """
  @spec roots(binary() | Index.t() | Graph.t() | reference()) :: [scene_node()]
  def roots(%Graph{} = graph), do: Query.nodes_by_guids(graph, graph.roots)

  def roots(scene) do
    scene
    |> Input.resource()
    |> NativeScene.index_roots()
    |> Query.nodes_from_maps()
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
    |> Input.resource()
    |> NativeScene.index_parent(guid)
    |> Query.maybe_node_from_map()
  end

  @doc """
  Returns direct children for a parent GUID in scene order.
  """
  @spec children(binary() | Index.t() | Graph.t() | reference(), String.t()) :: [scene_node()]
  def children(%Graph{} = graph, parent_guid) when is_binary(parent_guid) do
    Query.nodes_by_guids(graph, Map.get(graph.children, GUID.parse!(parent_guid), []))
  end

  def children(scene, parent_guid) when is_binary(parent_guid) do
    scene
    |> Input.resource()
    |> NativeScene.index_children(parent_guid)
    |> Query.nodes_from_maps()
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
    |> Input.resource()
    |> NativeScene.index_siblings(guid)
    |> Query.nodes_from_maps()
  end

  @doc """
  Returns ancestors for a node GUID, ordered from root to parent.
  """
  @spec ancestors(binary() | Index.t() | Graph.t() | reference(), String.t()) :: [scene_node()]
  def ancestors(%Graph{} = graph, guid) when is_binary(guid),
    do: Tree.graph_ancestors(graph, guid)

  def ancestors(scene, guid) when is_binary(guid) do
    scene
    |> Input.resource()
    |> NativeScene.index_ancestors(guid)
    |> Query.nodes_from_maps()
  end

  @doc """
  Returns all descendants for a node GUID in scene order.
  """
  @spec descendants(binary() | Index.t() | Graph.t() | reference(), String.t()) :: [scene_node()]
  def descendants(%Graph{} = graph, guid) when is_binary(guid),
    do: Tree.graph_descendants(graph, guid)

  def descendants(scene, guid) when is_binary(guid) do
    scene
    |> Input.resource()
    |> NativeScene.index_descendants(guid)
    |> Query.nodes_from_maps()
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

  def by_type(nodes, type, _opts) when is_list(nodes), do: Query.by_type(nodes, type)

  def by_type(%Graph{} = graph, type, opts) when is_atom(type) or is_binary(type) do
    node_type = type |> to_string() |> Macro.underscore()

    graph
    |> Query.nodes_by_guids(Map.get(graph.by_type, node_type, []))
    |> Query.apply_field_filter(opts)
  end

  def by_type(scene, type, opts) when is_atom(type) or is_binary(type) do
    fields = Query.query_fields(opts)
    resource = Input.resource(scene)
    node_type = type |> to_string() |> Macro.underscore()

    case fields do
      :all -> NativeScene.index_by_type(resource, node_type)
      fields -> NativeScene.index_by_type_fields(resource, node_type, fields)
    end
    |> Query.nodes_from_maps()
  end

  @doc """
  Returns nodes with an exact projected name without constructing XPath.
  """
  @spec named(binary() | Index.t() | Graph.t() | reference() | [scene_node()], String.t()) :: [
          scene_node()
        ]
  def named(nodes, name) when is_list(nodes), do: Query.named(nodes, name)

  def named(%Graph{} = graph, name) when is_binary(name),
    do: Query.nodes_by_guids(graph, Map.get(graph.by_name, name, []))

  def named(scene, name) when is_binary(name) do
    scene
    |> Input.resource()
    |> NativeScene.index_named(name)
    |> Query.nodes_from_maps()
  end

  @doc """
  Returns nodes whose projected name contains `needle` without constructing XPath.
  """
  @spec name_contains(
          binary() | Index.t() | Graph.t() | reference() | [scene_node()],
          String.t(),
          keyword()
        ) :: [scene_node()]
  def name_contains(scene_or_nodes, needle, opts \\ [])

  def name_contains(nodes, needle, _opts) when is_list(nodes),
    do: Query.name_contains(nodes, needle)

  def name_contains(%Graph{} = graph, needle, opts) when is_binary(needle) do
    graph.nodes
    |> Map.values()
    |> Query.name_contains(needle)
    |> Query.apply_field_filter(opts)
  end

  def name_contains(scene, needle, opts) when is_binary(needle) do
    fields = Query.query_fields(opts)
    resource = Input.resource(scene)

    case fields do
      :all -> NativeScene.index_name_contains(resource, needle)
      fields -> NativeScene.index_name_contains_fields(resource, needle, fields)
    end
    |> Query.nodes_from_maps()
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
  def components(nodes) when is_list(nodes), do: Query.components(nodes)
  def components(%Graph{} = graph), do: graph.nodes |> Map.values() |> Query.components()

  def components(scene) do
    scene
    |> Input.resource()
    |> NativeScene.index_components()
    |> Query.nodes_from_maps()
  end

  @doc """
  Returns nodes with one or more fill paints.
  """
  @spec with_fills(binary() | Index.t() | Graph.t() | reference() | [scene_node()]) :: [
          scene_node()
        ]
  def with_fills(nodes) when is_list(nodes), do: Query.with_fills(nodes)
  def with_fills(%Graph{} = graph), do: graph.nodes |> Map.values() |> Query.with_fills()

  def with_fills(scene) do
    scene
    |> Input.resource()
    |> NativeScene.index_with_fills()
    |> Query.nodes_from_maps()
  end

  @doc """
  Returns nodes with one or more stroke paints.
  """
  @spec with_strokes(binary() | Index.t() | Graph.t() | reference() | [scene_node()]) :: [
          scene_node()
        ]
  def with_strokes(nodes) when is_list(nodes), do: Query.with_strokes(nodes)
  def with_strokes(%Graph{} = graph), do: graph.nodes |> Map.values() |> Query.with_strokes()

  def with_strokes(scene) do
    scene
    |> Input.resource()
    |> NativeScene.index_with_strokes()
    |> Query.nodes_from_maps()
  end

  @doc """
  Returns text nodes whose projected text contains `needle` without constructing XPath.
  """
  @spec text_contains(
          binary() | Index.t() | Graph.t() | reference() | [scene_node()],
          String.t(),
          keyword()
        ) :: [scene_node()]
  def text_contains(scene_or_nodes, needle, opts \\ [])

  def text_contains(nodes, needle, _opts) when is_list(nodes),
    do: Query.text_contains(nodes, needle)

  def text_contains(%Graph{} = graph, needle, opts) when is_binary(needle) do
    graph.nodes
    |> Map.values()
    |> Query.text_contains(needle)
    |> Query.apply_field_filter(opts)
  end

  def text_contains(scene, needle, opts) when is_binary(needle) do
    fields = Query.query_fields(opts)
    resource = Input.resource(scene)

    case fields do
      :all -> NativeScene.index_text_contains(resource, needle)
      fields -> NativeScene.index_text_contains_fields(resource, needle, fields)
    end
    |> Query.nodes_from_maps()
  end

  @doc """
  Returns projected field values from nodes, similar to `Floki.attribute/2`.
  """
  @spec attribute([scene_node()], atom() | String.t()) :: [term()]
  defdelegate attribute(nodes, field), to: Query

  @doc """
  Returns projected text from nodes, similar to `Floki.text/2`.
  """
  @spec text([scene_node()], keyword()) :: String.t()
  defdelegate text(nodes, opts \\ []), to: Query

  @doc """
  Finds nodes by common projected fields without interpolating XPath.
  """
  @spec find(binary() | Index.t() | Graph.t() | reference(), keyword()) :: [scene_node()]
  def find(scene, opts) when is_list(opts) do
    scene
    |> Input.resource()
    |> find_candidates(opts)
    |> Query.filter_find_results(opts)
  end

  @doc """
  Builds a lightweight nested scene tree.
  """
  @spec tree(binary() | Index.t() | Graph.t() | reference(), keyword()) ::
          [Node.t()] | Node.t() | nil
  def tree(scene, opts \\ []) when is_list(opts) do
    scene |> Input.resource() |> Tree.projected(opts)
  end

  @doc """
  Extracts the raw Figma Kiwi `Message` binary from any supported scene input.
  """
  @spec payload!(binary()) :: binary()
  defdelegate payload!(binary), to: Input

  defp find_candidates(index, opts) do
    cond do
      type = opts[:type] -> by_type(index, type)
      name = opts[:name] -> named(index, name)
      name = opts[:name_contains] -> name_contains(index, name)
      text = opts[:text_contains] -> text_contains(index, text)
      true -> query(index, "//*")
    end
  end
end
