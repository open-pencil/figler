defmodule FigKiwi.Scene.Graph.ApiTest do
  use ExUnit.Case, async: true

  alias FigKiwi.Scene
  alias FigKiwi.Scene.Graph
  alias FigKiwi.Scene.Graph.SeedNode
  alias FigKiwi.Scene.Node

  import FigKiwi.Test.SceneFixture

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
    assert %SeedNode{guid: {0, 0}, node_type: "document", name: "Document"} = document_seed
    assert %Node{} = document_seed.source

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

    assert %Node{} = canvas_seed.source

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

  test "profiles graph construction" do
    assert %{graph: %Graph{}, initial_ms: initial_ms, total_ms: total_ms, stages: stages} =
             Graph.profile(message_payload(), until: :populate_instances)

    assert is_integer(initial_ms)
    assert is_integer(total_ms)
    assert [%{stage: :populate_instances, graph: %{node_count: 2}}] = stages
  end
end
