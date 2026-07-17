defmodule Figler.Scene.GraphTest do
  use ExUnit.Case, async: true

  alias Figler.Native.CodecNifs
  alias Figler.Scene
  alias Figler.Scene.Graph
  alias Figler.Scene.Graph.Build
  alias Figler.Scene.Graph.Seed.Node, as: SeedNode
  alias Figler.Scene.Node

  import Figler.Test.GraphBuilder
  import Figler.Test.SceneFixture

  test "graph public APIs expose projected effective scene data" do
    graph = Scene.graph(message_payload(), until: :component_props, skip: [:sync_overrides])

    assert %Graph{
             mode: :projected,
             stages: [:populate_instances, :symbol_overrides, :component_props],
             stats: %{
               node_count: 2,
               resolver: :elixir,
               resolved_stages: [:component_props, :symbol_overrides, :populate_instances]
             }
           } = graph

    assert [document_seed, canvas_seed] = Graph.seed_nodes(graph)

    assert %SeedNode{guid: {0, 0}, node_type: "document", name: "Document", source: nil} =
             document_seed

    assert %SeedNode{
             guid: {0, 1},
             node_type: "canvas",
             name: "Page 1",
             parent_guid: {0, 0},
             position: "!",
             size: %{x: 100.0, y: 50.0},
             visible: true,
             locked: false,
             text: "Hello world",
             font_family: "Inter",
             font_style: "Regular",
             font_postscript: "Inter-Regular",
             text_style_guid: "0:2",
             symbol_overrides: [],
             component_prop_assignments: []
           } = canvas_seed

    assert canvas_seed.transform == %{
             m00: 1.0,
             m01: 0.0,
             m02: 10.0,
             m10: 0.0,
             m11: 1.0,
             m12: 20.0
           }

    assert canvas_seed.source == nil

    assert Scene.query(graph, "//canvas") == [scene_canvas()]
    assert Scene.pages(graph) == [scene_canvas()]
    assert Scene.node(graph, "0:1") == scene_canvas()
    assert Scene.children(graph, "0:0") == [scene_canvas()]

    assert Scene.by_type(graph, :canvas, fields: [:name]) == [
             %Node{guid: "0:1", node_type: "canvas", name: "Page 1"}
           ]

    assert Graph.stats(graph).root_count == 1

    explanation = Graph.explain(graph, "0:1")

    assert Map.take(explanation, [
             :guid,
             :node,
             :source,
             :source_guid,
             :applied,
             :unresolved,
             :stages
           ]) == %{
             guid: "0:1",
             node: scene_canvas(),
             source: :projected_index,
             source_guid: "0:1",
             applied: [],
             unresolved: [],
             stages: [:populate_instances, :symbol_overrides, :component_props]
           }

    assert explanation.source_node == scene_canvas()
    assert explanation.parent_guid == "0:0"
    assert explanation.child_guids == []
    assert explanation.instance == nil

    assert [%Node{guid: "0:1", children: []}] = Graph.tree(graph, root: "0:0", depth: 1).children
    assert Graph.diff(graph) == []

    assert Graph.diff_node(Scene.index(message_payload()), graph, "0:1") == %{
             guid: "0:1",
             changed: []
           }
  end

  test "native graph seed records match sparse seed decoding" do
    payload = message_payload()

    sparse_seeds =
      payload
      |> CodecNifs.decode_sparse_message()
      |> SeedNode.from_message()

    native_records = CodecNifs.decode_graph_seed_records(payload)
    assert Enum.all?(native_records, &is_tuple/1)

    assert SeedNode.from_native_records(native_records) == sparse_seeds
  end

  test "native graph seed projection follows selected resolver stages" do
    payload = resolver_metadata_payload()

    [full] = payload |> CodecNifs.decode_graph_seed_records() |> SeedNode.from_native_records()

    [minimal] =
      payload
      |> CodecNifs.decode_graph_seed_records([:populate_instances])
      |> SeedNode.from_native_records()

    [overrides] =
      payload
      |> CodecNifs.decode_graph_seed_records([:symbol_overrides])
      |> SeedNode.from_native_records()

    [derived] =
      payload
      |> CodecNifs.decode_graph_seed_records([:derived_symbol_data])
      |> SeedNode.from_native_records()

    [stack] =
      payload
      |> CodecNifs.decode_graph_seed_records([:stack_layout])
      |> SeedNode.from_native_records()

    assert minimal.symbol_id == full.symbol_id
    assert minimal.symbol_overrides == []
    assert minimal.derived_symbol_data == []
    assert minimal.stack_mode == nil
    assert minimal.native_clone_seed

    assert overrides.symbol_overrides == full.symbol_overrides
    assert overrides.derived_symbol_data == []
    assert overrides.stack_mode == nil

    assert derived.symbol_overrides == []
    assert derived.derived_symbol_data == full.derived_symbol_data
    assert derived.stack_mode == nil

    assert stack.symbol_overrides == []
    assert stack.derived_symbol_data == []
    assert stack.stack_mode == :horizontal
    assert stack.stack_spacing == 8.0
  end

  test "builds identical initial indexes directly from native records" do
    records = CodecNifs.decode_graph_seed_records(message_payload())
    resource = make_ref()

    from_records = Build.from_native_records(records, resource: resource)
    from_seeds = Build.from_seed(SeedNode.from_native_records(records), resource: resource)

    assert from_records == from_seeds
  end

  test "profiles graph construction" do
    assert %{graph: %Graph{} = graph, initial_ms: initial_ms, total_ms: total_ms, stages: stages} =
             Graph.profile(message_payload(), until: :populate_instances)

    assert graph.stages == [:populate_instances]
    assert graph.projection_stages == [:populate_instances]

    assert_raise ArgumentError, ~r/not projected for stages \[:symbol_overrides\]/, fn ->
      Graph.build(graph, only: :symbol_overrides)
    end

    assert Graph.stats(graph) ==
             message_payload() |> Graph.build(until: :populate_instances) |> Graph.stats()

    assert is_number(initial_ms)
    assert is_number(total_ms)
    assert [%{stage: :populate_instances, graph: %{node_count: 2}}] = stages
  end

  test "returns instance metadata and provenance for source instances" do
    graph =
      [component({1, 1}, name: "Button"), instance({2, 1}, {1, 1})]
      |> resolve(stages: [:populate_instances])

    assert %{
             guid: "2:1",
             component_guid: "1:1",
             component: %Node{name: "Button"},
             provenance: %{source: :projected_index, source_guid: {2, 1}}
           } = Graph.instance(graph, "2:1")
  end

  test "returns clone provenance for nested instance clones" do
    graph =
      [
        component({1, 1}, name: "Wrapper"),
        instance({1, 2}, {3, 1}, parent_guid: {1, 1}),
        instance({2, 1}, {1, 1}),
        component({3, 1}, name: "Leaf")
      ]
      |> resolve(stages: [:populate_instances])

    assert %{
             guid: "clone:2:1/1:2",
             component_guid: "3:1",
             component: %Node{name: "Leaf"},
             provenance: %{source: :instance_clone, source_guid: {1, 2}, instance_guid: {2, 1}}
           } = Graph.instance(graph, "clone:2:1/1:2")
  end

  test "returns nil for non-instance nodes" do
    graph = [component({1, 1}, name: "Button")] |> resolve(stages: [])

    assert Graph.instance(graph, "1:1") == nil
  end

  defp resolver_metadata_payload do
    target_guid = struct(Figler.Schema.GUID, session_id: 1, local_id: 2)

    node =
      struct(Figler.Schema.NodeChange,
        guid: struct(Figler.Schema.GUID, session_id: 2, local_id: 1),
        type: :instance,
        stack_mode: :horizontal,
        stack_spacing: 8.0,
        symbol_data:
          struct(Figler.Schema.SymbolData,
            symbol_id: struct(Figler.Schema.GUID, session_id: 1, local_id: 1),
            symbol_overrides: [
              struct(Figler.Schema.NodeChange,
                guid_path: struct(Figler.Schema.GUIDPath, guids: [target_guid]),
                visible: false
              )
            ]
          ),
        derived_symbol_data: [
          struct(Figler.Schema.NodeChange,
            guid_path: struct(Figler.Schema.GUIDPath, guids: [target_guid]),
            size: struct(Figler.Schema.Vector, x: 10.0, y: 20.0)
          )
        ]
      )

    Figler.Schema.Message
    |> struct(type: :node_changes, session_id: 0, node_changes: [node])
    |> KiwiCodec.encode()
  end
end
