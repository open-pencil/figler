defmodule Figler.Scene.GraphTest do
  use ExUnit.Case, async: true

  alias Figler.Scene
  alias Figler.Scene.Graph
  alias Figler.Scene.Node

  import Figler.Test.SceneFixture

  @instances "test/fixtures/openpencil/variable-override-precedence.fig"

  setup_all do
    # Instance expansion on its own: variable bindings would replace these texts.
    {:ok, instances: @instances |> File.read!() |> Scene.graph(resolve_variables: false)}
  end

  test "graph public APIs expose effective scene data" do
    graph = Scene.graph(message_payload())

    assert %Graph{mode: :interpreted} = graph
    assert Graph.unresolved(graph) == []
    assert Graph.stats(graph).node_count == 2

    assert Scene.query(graph, "//canvas") == [scene_canvas()]
    assert Scene.pages(graph) == [scene_canvas()]
    assert Scene.node(graph, "0:1") == scene_canvas()
    assert Scene.children(graph, "0:0") == [scene_canvas()]

    assert Scene.by_type(graph, :canvas, fields: [:name]) == [
             %Node{guid: "0:1", node_type: "canvas", name: "Page 1"}
           ]

    explanation = Graph.explain(graph, "0:1")

    assert Map.take(explanation, [:guid, :node, :source, :source_guid, :applied, :unresolved]) ==
             %{
               guid: "0:1",
               node: scene_canvas(),
               source: :projected_index,
               source_guid: "0:1",
               applied: [],
               unresolved: []
             }

    assert explanation.source_node == scene_canvas()
    assert explanation.parent_guid == "0:0"
    assert explanation.child_guids == []
    assert explanation.instance == nil

    assert [%Node{guid: "0:1", children: []}] = Graph.tree(graph, root: "0:0", depth: 1).children
    assert Scene.tree(graph, root: "0:0", depth: 1) == Graph.tree(graph, root: "0:0", depth: 1)
    assert Scene.find(graph, type: :canvas, name: "Page 1") == [scene_canvas()]
    assert Graph.diff(graph) == []

    assert Graph.diff_node(Scene.index(message_payload()), graph, "0:1") == %{
             guid: "0:1",
             changed: []
           }
  end

  test "rejects resolver stage options, which instance interpretation replaced" do
    for opts <- [[until: :component_props], [stages: [:variables]], [only: :variables]] do
      error = assert_raise Figler.Error, fn -> Scene.graph(message_payload(), opts) end
      assert error.code == :invalid_options
    end
  end

  test "builds a projected graph from an index, leaving instances unexpanded" do
    graph = Scene.graph(Scene.index(message_payload()))

    assert %Graph{mode: :projected} = graph
    assert Scene.node(graph, "0:1") == scene_canvas()
    assert Graph.root_guids(graph) == [{0, 0}]
  end

  test "profiles graph construction by phase" do
    assert %{graph: %Graph{} = graph, total_ms: total_ms, phases: phases} =
             Graph.profile(message_payload())

    assert Enum.map(phases, & &1.phase) == [:decode, :index, :interpret]
    assert Enum.all?(phases, &is_number(&1.ms))
    assert is_number(total_ms)
    assert Graph.stats(graph) == message_payload() |> Graph.build() |> Graph.stats()
  end

  test "expands every instance into its own occurrences", %{instances: graph} do
    texts =
      for guid <- ["clone:9:1469/9:1466/9:1462", "clone:9:1472/9:1466/9:1462"],
          do: Scene.node(graph, guid).text

    assert texts == ["Learn more", "Different"]

    # The component keeps its own name; instance names never leak into it.
    assert Scene.node(graph, "9:1468").name == "_alert"
    assert Scene.node(graph, "9:1472").name == "different-literal"
  end

  test "returns instance metadata and provenance for source instances", %{instances: graph} do
    assert %{
             guid: "9:1472",
             component_guid: "9:1468",
             component: %Node{name: "_alert"},
             provenance: %{source: :source, source_guid: {9, 1472}}
           } = Graph.instance(graph, "9:1472")
  end

  test "returns clone provenance for nested instance clones", %{instances: graph} do
    assert %{
             guid: "clone:9:1472/9:1466",
             component_guid: "9:1464",
             component: %Node{name: "_button-small"},
             provenance: %{
               source: :instance_clone,
               source_guid: {9, 1466},
               instance_guid: {9, 1472}
             }
           } = Graph.instance(graph, "clone:9:1472/9:1466")

    assert %{"9:1462" => _source} =
             Map.new([Graph.source_node(graph, "clone:9:1472/9:1466/9:1462")], &{&1.guid, &1})
  end

  test "keeps each node's effective record", %{instances: graph} do
    assert %{type: :text, text_data: %{characters: "Different"}} =
             Graph.record(graph, "clone:9:1472/9:1466/9:1462")
  end

  test "fetches nodes and records by GUID", %{instances: graph} do
    guid = "clone:9:1472/9:1466/9:1462"

    assert {:ok, %Node{guid: ^guid, text: "Different"}} = Graph.fetch(graph, guid)
    assert Graph.fetch(graph, "123:456") == :error
    assert %Node{guid: ^guid} = Graph.fetch!(graph, guid)
    assert_raise KeyError, fn -> Graph.fetch!(graph, "123:456") end

    assert %{type: :text, text_data: %{characters: "Different"}} =
             record = Graph.record(graph, guid, fields: [:type, :text_data])

    assert record |> Map.keys() |> Enum.sort() == [:__kiwi_module__, :text_data, :type]

    assert %Figler.Schema.NodeChange{text_data: %Figler.Schema.TextData{characters: "Different"}} =
             Graph.record(graph, guid, as: :struct)

    assert %{^guid => %{name: _name}} =
             Graph.records(graph, [guid, "123:456"], fields: [:name])

    assert map_size(Graph.records(graph, [guid, "123:456"])) == 1
  end

  test "materializes named parts and enumerates nodes", %{instances: graph} do
    assert %{roots: roots, children: children} = Graph.to_map(graph, only: [:roots, :children])
    assert roots == Graph.root_guids(graph)
    assert children[hd(roots)] == Graph.child_guids(graph, hd(roots))
    assert_raise ArgumentError, fn -> Graph.to_map(graph, only: [:everything]) end

    assert Enum.count(graph) == Graph.stats(graph).node_count
    assert "clone:9:1472/9:1466/9:1462" in Enum.map(graph, & &1.guid)
  end

  test "returns nil for non-instance nodes", %{instances: graph} do
    assert Graph.instance(graph, "9:1468") == nil
  end
end
