defmodule Figler.Scene.Graph.Symbol.OverrideApplicationTest do
  use ExUnit.Case, async: true

  alias Figler.Scene
  alias Figler.Scene.Graph
  alias Figler.Scene.Node

  import Figler.Test.GraphBuilder

  test "applies basic symbol override patches in Elixir graph resolver" do
    graph =
      [
        component({1, 1}, name: "Button"),
        text({1, 2}, {1, 1}, "Default"),
        instance({2, 1}, {1, 1},
          symbol_overrides: [symbol_override([{1, 2}], %{text: "Submit", visible: false})]
        )
      ]
      |> resolve(stages: [:symbol_overrides])

    assert Scene.node(graph, "1:2").text == "Submit"
    assert Scene.node(graph, "1:2").visible == false

    assert {:symbol_override, :text, "Default", "Submit"} in Graph.explain(graph, "1:2").applied
    assert {:symbol_override, :visible, nil, false} in Graph.explain(graph, "1:2").applied
  end

  test "validates nested source paths when resolving symbol overrides" do
    graph =
      [
        component({1, 1}, name: "Card"),
        node({1, 2}, :frame, parent_guid: {1, 1}, name: "Body"),
        text({1, 3}, {1, 2}, "Default"),
        instance({2, 1}, {1, 1},
          symbol_overrides: [
            symbol_override([{1, 1}, {1, 2}, {1, 3}], %{text: "Submit"}),
            symbol_override([{1, 1}, {1, 3}], %{visible: false})
          ]
        )
      ]
      |> resolve(stages: [:populate_instances, :symbol_overrides])

    assert [%Node{guid: "clone:2:1/1:2"}] = Scene.children(graph, "2:1")

    assert [%Node{guid: "clone:2:1/1:2/1:3", text: "Submit"}] =
             Scene.children(graph, "clone:2:1/1:2")

    assert Graph.explain(graph, "clone:2:1/1:2/1:3").applied == [
             {:symbol_override, :visible, nil, false},
             {:symbol_override, :text, "Default", "Submit"}
           ]

    assert Graph.unresolved(graph) == []
  end

  test "does not run resolver stages from cloned seeds" do
    graph =
      [
        component({1, 1}, name: "Wrapper"),
        instance({1, 2}, {3, 1},
          parent_guid: {1, 1},
          name: "Nested instance",
          symbol_overrides: [symbol_override([{1, 2}], %{name: "Patched"})]
        ),
        instance({2, 1}, {1, 1}),
        component({3, 1}, name: "Leaf")
      ]
      |> resolve(stages: [:populate_instances, :symbol_overrides])

    assert Scene.node(graph, "1:2").name == "Patched"
    assert [%Node{guid: "clone:2:1/1:2", name: "Nested instance"}] = Scene.children(graph, "2:1")
    assert Graph.stats(graph).clone_instance_count == 1
    assert Graph.stats(graph).source_instance_count == 2
  end
end
