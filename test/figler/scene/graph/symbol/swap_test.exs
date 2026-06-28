defmodule Figler.Scene.Graph.Symbol.SwapTest do
  use ExUnit.Case, async: true

  alias Figler.Scene
  alias Figler.Scene.Graph
  alias Figler.Scene.Graph.Patch
  alias Figler.Scene.Node

  import Figler.Test.GraphBuilder

  test "materializes symbol override component swaps before field patches" do
    graph =
      [
        component({1, 1}, name: "Old"),
        text({1, 2}, {1, 1}, "Old label"),
        component({3, 1}, name: "New"),
        text({3, 2}, {3, 1}, "New label"),
        instance({2, 1}, {1, 1},
          symbol_overrides: [
            symbol_swap([{2, 1}], {3, 1}),
            symbol_override([{3, 1}, {3, 2}], %{text: "Patched label"})
          ]
        )
      ]
      |> resolve(stages: [:populate_instances, :symbol_overrides])

    assert graph.seed_nodes[{2, 1}].symbol_id == {3, 1}
    assert Scene.node(graph, "clone:2:1/1:2") == nil
    assert [%Node{guid: "clone:2:1/3:2", text: "Patched label"}] = Scene.children(graph, "2:1")

    assert Graph.explain(graph, "2:1").applied == [
             {:component_swap, :name, nil, "New"},
             {:symbol_override, :component_guid, {1, 1}, {3, 1}}
           ]

    assert Graph.explain(graph, "clone:2:1/3:2").applied == [
             {:symbol_override, :text, "New label", "Patched label"}
           ]
  end

  test "applies component prop assignments carried by symbol override swaps" do
    graph =
      [
        component({1, 1}, name: "Wrapper"),
        instance({1, 2}, {2, 1}, parent_guid: {1, 1}),
        component({2, 1}, name: "Old"),
        component({3, 1}, name: "New"),
        node({3, 2}, :frame,
          parent_guid: {3, 1},
          name: "Menu",
          visible: true,
          component_prop_refs: [prop_ref({3, 99}, :visible)]
        ),
        text({3, 3}, {3, 2}, "Hidden child"),
        instance({9, 1}, {1, 1},
          symbol_overrides: [
            symbol_swap([{1, 2}], {3, 1},
              component_prop_assignments: [prop_assignment({3, 99}, {:bool, false})]
            )
          ]
        )
      ]
      |> resolve(stages: [:populate_instances, :symbol_overrides])

    assert [%Node{guid: item_guid, name: "New"}] = Scene.children(graph, "9:1")
    assert [%Node{guid: menu_guid, visible: false}] = Scene.children(graph, item_guid)
    assert Scene.children(graph, menu_guid) == []

    assert {:component_prop, :visible, true, false} in Graph.explain(graph, menu_guid).applied
  end

  test "scales swapped component child offsets to the target instance size" do
    graph =
      [
        component({1, 1}, name: "Old", size: %{x: 20.0, y: 20.0}),
        node({1, 2}, :vector,
          parent_guid: {1, 1},
          transform: %{m00: 1.0, m01: 0.0, m02: 4.0, m10: 0.0, m11: 1.0, m12: 4.0}
        ),
        component({3, 1}, name: "New", size: %{x: 24.0, y: 24.0}),
        node({3, 2}, :vector,
          parent_guid: {3, 1},
          transform: %{m00: 1.0, m01: 0.0, m02: 3.0, m10: 0.0, m11: 1.0, m12: 3.0}
        ),
        instance({2, 1}, {1, 1}, size: %{x: 20.0, y: 20.0})
      ]
      |> resolve(stages: [:populate_instances])
      |> Patch.apply_all(Patch.swap({2, 1}, {3, 1}, source: :test))

    assert [%Node{transform: %{m02: 2.5, m12: 2.5}}] = Scene.children(graph, "2:1")
  end

  test "materializes component prop component swaps" do
    graph =
      [
        component({1, 1}, name: "Old"),
        instance({1, 2}, {4, 1},
          parent_guid: {1, 1},
          component_prop_refs: [prop_ref({9, 1}, :overridden_symbol_id)]
        ),
        component({3, 1}, name: "New"),
        text({3, 2}, {3, 1}, "New nested"),
        instance({2, 1}, {1, 1},
          component_prop_assignments: [prop_assignment({9, 1}, {:guid, {3, 1}})]
        )
      ]
      |> resolve(stages: [:populate_instances, :component_props])

    clone_guid = {:clone, {2, 1}, [{1, 2}]}
    assert graph.seed_nodes[clone_guid].symbol_id == {3, 1}

    assert [%Node{guid: "clone:2:1/1:2/3:2", text: "New nested"}] =
             Scene.children(graph, "clone:2:1/1:2")

    assert {:component_prop, :component_guid, {4, 1}, {3, 1}} in Graph.explain(
             graph,
             "clone:2:1/1:2"
           ).applied

    assert %{
             guid: "clone:2:1/1:2",
             component_guid: "3:1",
             component: %Node{name: "New"},
             provenance: %{source: :instance_clone}
           } = Graph.instance(graph, "clone:2:1/1:2")
  end

  test "component swaps populate nested source instances" do
    graph =
      [
        component({1, 1}, name: "Old"),
        instance({1, 2}, {3, 1},
          parent_guid: {1, 1},
          component_prop_refs: [prop_ref({9, 1}, :overridden_symbol_id)]
        ),
        component({4, 1}, name: "Swapped"),
        instance({4, 2}, {5, 1}, parent_guid: {4, 1}),
        component({5, 1}, name: "Icon"),
        node({5, 2}, :vector, parent_guid: {5, 1}),
        instance({2, 1}, {1, 1},
          component_prop_assignments: [prop_assignment({9, 1}, {:guid, {4, 1}})]
        )
      ]
      |> resolve(stages: [:populate_instances, :component_props])

    assert [%Node{guid: "clone:2:1/1:2/4:2"}] = Scene.children(graph, "clone:2:1/1:2")

    assert [%Node{guid: "clone:2:1/1:2/4:2/5:2"}] =
             Scene.children(graph, "clone:2:1/1:2/4:2")
  end
end
