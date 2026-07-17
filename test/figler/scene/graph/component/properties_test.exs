defmodule Figler.Scene.Graph.Component.PropertiesTest do
  use ExUnit.Case, async: true

  alias Figler.Scene
  alias Figler.Scene.Graph
  alias Figler.Scene.Node

  import Figler.Test.GraphBuilder

  test "applies basic component property assignments to cloned children" do
    graph =
      [
        component({1, 1}, name: "Button"),
        text({1, 2}, {1, 1}, "Default",
          visible: true,
          component_prop_refs: [prop_ref({9, 1}, :text_data), prop_ref({9, 2}, :visible)]
        ),
        instance({2, 1}, {1, 1},
          component_prop_assignments: [
            prop_assignment({9, 1}, {:text, "Submit"}),
            prop_assignment({9, 2}, {:bool, false})
          ]
        )
      ]
      |> resolve(stages: [:populate_instances, :component_props])

    assert [%Node{guid: clone_guid, text: "Submit", visible: false}] =
             Scene.children(graph, "2:1")

    assert clone_guid == "clone:2:1/1:2"
    assert Scene.node(graph, "1:2").text == "Default"
    assert Scene.node(graph, "1:2").visible == true

    applied = Graph.explain(graph, clone_guid).applied
    assert {:component_prop, :text, "Default", "Submit"} in applied
    assert {:component_prop, :visible, true, false} in applied
  end

  test "repeated hidden assignments preserve provenance after children are cleared" do
    graph =
      [
        component({1, 1}, name: "Menu"),
        node({1, 2}, :frame,
          parent_guid: {1, 1},
          visible: true,
          component_prop_refs: [prop_ref({9, 1}, :visible)]
        ),
        text({1, 3}, {1, 2}, "Hidden child"),
        instance({2, 1}, {1, 1},
          component_prop_assignments: [
            prop_assignment({9, 1}, {:bool, false}),
            prop_assignment({9, 1}, {:bool, false})
          ]
        )
      ]
      |> resolve(stages: [:populate_instances, :component_props])

    assert [%Node{guid: clone_guid, visible: false}] = Scene.children(graph, "2:1")
    assert Scene.children(graph, clone_guid) == []

    assert Graph.explain(graph, clone_guid).applied == [
             {:component_prop, :visible, false, false},
             {:component_prop, :visible, true, false}
           ]
  end

  test "component prop assignments apply to all matching refs" do
    graph =
      [
        component({1, 1}, name: "Menu"),
        node({1, 2}, :frame,
          parent_guid: {1, 1},
          visible: true,
          component_prop_refs: [prop_ref({9, 1}, :visible)]
        ),
        node({1, 3}, :vector,
          parent_guid: {1, 1},
          visible: true,
          component_prop_refs: [prop_ref({9, 1}, :visible)]
        ),
        instance({2, 1}, {1, 1},
          component_prop_assignments: [prop_assignment({9, 1}, {:bool, false})]
        )
      ]
      |> resolve(stages: [:populate_instances, :component_props])

    assert [%Node{visible: false}, %Node{visible: false}] = Scene.children(graph, "2:1")
  end
end
