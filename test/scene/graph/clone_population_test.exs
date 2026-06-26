defmodule Figler.Scene.Graph.ClonePopulationTest do
  use ExUnit.Case, async: true

  alias Figler.Scene
  alias Figler.Scene.Graph
  alias Figler.Scene.Node

  import Figler.Test.GraphBuilder

  test "populates instance clones and applies overrides to cloned children" do
    graph =
      [
        component({1, 1}, name: "Button"),
        text({1, 2}, {1, 1}, "Default"),
        instance({2, 1}, {1, 1}, symbol_overrides: [symbol_override([{1, 2}], %{text: "Submit"})])
      ]
      |> resolve(stages: [:populate_instances, :symbol_overrides])

    assert [%Node{guid: clone_guid, text: "Submit"}] = Scene.children(graph, "2:1")
    assert clone_guid == "clone:2:1/1:2"
    assert Scene.node(graph, "1:2").text == "Default"

    explanation = Graph.explain(graph, clone_guid)

    assert Map.take(explanation, [
             :guid,
             :node,
             :source,
             :source_guid,
             :applied,
             :unresolved,
             :stages
           ]) == %{
             guid: clone_guid,
             node: Scene.node(graph, clone_guid),
             source: :instance_clone,
             source_guid: "1:2",
             applied: [{:symbol_override, :text, "Default", "Submit"}],
             unresolved: [],
             stages: [:populate_instances, :symbol_overrides]
           }

    assert [%{changed: [%{field: :text, source: "Default", resolved: "Submit"}]}] =
             Graph.diff(graph, root: clone_guid)
  end

  test "does not populate invisible instances" do
    graph =
      [
        component({1, 1}, name: "Button"),
        text({1, 2}, {1, 1}, "Default"),
        instance({2, 1}, {1, 1}, visible: false)
      ]
      |> resolve(stages: [:populate_instances])

    assert Scene.children(graph, "2:1") == []
    assert Graph.stats(graph).clone_count == 0
  end

  test "does not populate source instances inside symbol definitions" do
    graph =
      [
        node({1, 0}, :canvas, name: "Internal", visible: false),
        node({1, 1}, :symbol, parent_guid: {1, 0}, name: "Variant"),
        instance({1, 2}, {2, 1}, parent_guid: {1, 1}),
        component({2, 1}, name: "Button"),
        text({2, 2}, {2, 1}, "Default")
      ]
      |> resolve(stages: [:populate_instances])

    assert Scene.children(graph, "1:2") == []
    assert Graph.stats(graph).clone_count == 0
  end

  test "populates source instances inside focused symbol definitions" do
    graph =
      [
        node({1, 1}, :symbol, name: "Accordion"),
        instance({1, 2}, {2, 1}, parent_guid: {1, 1}),
        component({2, 1}, name: "Panel"),
        text({2, 2}, {2, 1}, "Item")
      ]
      |> resolve(stages: [:populate_instances], options: [focus: [{1, 1}]])

    assert [%Node{guid: "clone:1:2/2:2"}] = Scene.children(graph, "1:2")
    assert Graph.stats(graph).clone_count == 1
  end

  test "focuses resolver stages on selected source subtrees" do
    graph =
      [
        component({1, 1}, name: "Button"),
        text({1, 2}, {1, 1}, "Default"),
        instance({2, 1}, {1, 1}),
        instance({2, 2}, {1, 1})
      ]
      |> resolve(stages: [:populate_instances], options: [focus: [{2, 1}]])

    assert [%Node{guid: "clone:2:1/1:2"}] = Scene.children(graph, "2:1")
    assert Scene.children(graph, "2:2") == []
    assert Graph.stats(graph).clone_count == 1
  end
end
