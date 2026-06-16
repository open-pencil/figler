defmodule FigKiwi.Scene.Graph.ComponentPropsTest do
  use ExUnit.Case, async: true

  alias FigKiwi.Scene
  alias FigKiwi.Scene.Graph
  alias FigKiwi.Scene.Graph.ComponentPropAssignment
  alias FigKiwi.Scene.Graph.ComponentPropRef
  alias FigKiwi.Scene.Graph.DerivedSymbolData
  alias FigKiwi.Scene.Graph.Patch
  alias FigKiwi.Scene.Graph.Resolver
  alias FigKiwi.Scene.Graph.SeedNode
  alias FigKiwi.Scene.Graph.SymbolOverride
  alias FigKiwi.Scene.Node

  test "applies basic component property assignments to cloned children" do
    graph =
      [
        %SeedNode{guid: {1, 1}, node_type: "component", name: "Button"},
        %SeedNode{
          guid: {1, 2},
          node_type: "text",
          parent_guid: {1, 1},
          text: "Default",
          visible: true,
          component_prop_refs: [
            %ComponentPropRef{def_id: {9, 1}, field: :text_data},
            %ComponentPropRef{def_id: {9, 2}, field: :visible}
          ]
        },
        %SeedNode{
          guid: {2, 1},
          node_type: "instance",
          symbol_id: {1, 1},
          component_prop_assignments: [
            %ComponentPropAssignment{def_id: {9, 1}, value: {:text, "Submit"}},
            %ComponentPropAssignment{def_id: {9, 2}, value: {:bool, false}}
          ]
        }
      ]
      |> Resolver.from_seed(
        resource: make_ref(),
        stages: [:populate_instances, :component_props]
      )
      |> Resolver.resolve()

    assert [%Node{guid: clone_guid, text: "Submit", visible: false}] =
             Scene.children(graph, "2:1")

    assert clone_guid == "clone:2:1/1:2"
    assert Scene.node(graph, "1:2").text == "Default"
    assert Scene.node(graph, "1:2").visible == true

    applied = Graph.explain(graph, clone_guid).applied
    assert {:component_prop, :text, "Default", "Submit"} in applied
    assert {:component_prop, :visible, true, false} in applied
  end

  test "materializes symbol override component swaps before field patches" do
    graph =
      [
        %SeedNode{guid: {1, 1}, node_type: "component", name: "Old"},
        %SeedNode{guid: {1, 2}, node_type: "text", parent_guid: {1, 1}, text: "Old label"},
        %SeedNode{guid: {3, 1}, node_type: "component", name: "New"},
        %SeedNode{guid: {3, 2}, node_type: "text", parent_guid: {3, 1}, text: "New label"},
        %SeedNode{
          guid: {2, 1},
          node_type: "instance",
          symbol_id: {1, 1},
          symbol_overrides: [
            %SymbolOverride{guid_path: [{2, 1}], overridden_symbol_id: {3, 1}},
            %SymbolOverride{guid_path: [{3, 1}, {3, 2}], fields: %{text: "Patched label"}}
          ]
        }
      ]
      |> Resolver.from_seed(
        resource: make_ref(),
        stages: [:populate_instances, :symbol_overrides]
      )
      |> Resolver.resolve()

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
        %SeedNode{guid: {1, 1}, node_type: "component", name: "Wrapper"},
        %SeedNode{guid: {1, 2}, node_type: "instance", parent_guid: {1, 1}, symbol_id: {2, 1}},
        %SeedNode{guid: {2, 1}, node_type: "component", name: "Old"},
        %SeedNode{guid: {3, 1}, node_type: "component", name: "New"},
        %SeedNode{
          guid: {3, 2},
          node_type: "frame",
          parent_guid: {3, 1},
          name: "Menu",
          visible: true,
          component_prop_refs: [%ComponentPropRef{def_id: {3, 99}, field: :visible}]
        },
        %SeedNode{guid: {3, 3}, node_type: "text", parent_guid: {3, 2}, text: "Hidden child"},
        %SeedNode{
          guid: {9, 1},
          node_type: "instance",
          symbol_id: {1, 1},
          symbol_overrides: [
            %SymbolOverride{
              guid_path: [{1, 2}],
              overridden_symbol_id: {3, 1},
              component_prop_assignments: [
                %ComponentPropAssignment{def_id: {3, 99}, value: {:bool, false}}
              ]
            }
          ]
        }
      ]
      |> Resolver.from_seed(
        resource: make_ref(),
        stages: [:populate_instances, :symbol_overrides]
      )
      |> Resolver.resolve()

    assert [%Node{guid: item_guid, name: "New"}] = Scene.children(graph, "9:1")
    assert [%Node{guid: menu_guid, visible: false}] = Scene.children(graph, item_guid)
    assert Scene.children(graph, menu_guid) == []

    assert {:component_prop, :visible, true, false} in Graph.explain(graph, menu_guid).applied
  end

  test "scales swapped component child offsets to the target instance size" do
    graph =
      [
        %SeedNode{guid: {1, 1}, node_type: "component", name: "Old", size: %{x: 20.0, y: 20.0}},
        %SeedNode{
          guid: {1, 2},
          node_type: "vector",
          parent_guid: {1, 1},
          transform: %{m00: 1.0, m01: 0.0, m02: 4.0, m10: 0.0, m11: 1.0, m12: 4.0}
        },
        %SeedNode{guid: {3, 1}, node_type: "component", name: "New", size: %{x: 24.0, y: 24.0}},
        %SeedNode{
          guid: {3, 2},
          node_type: "vector",
          parent_guid: {3, 1},
          transform: %{m00: 1.0, m01: 0.0, m02: 3.0, m10: 0.0, m11: 1.0, m12: 3.0}
        },
        %SeedNode{
          guid: {2, 1},
          node_type: "instance",
          symbol_id: {1, 1},
          size: %{x: 20.0, y: 20.0}
        }
      ]
      |> Resolver.from_seed(resource: make_ref(), stages: [:populate_instances])
      |> Resolver.resolve()
      |> Patch.apply_all(Patch.swap({2, 1}, {3, 1}, source: :test))

    assert [%Node{transform: %{m02: 2.5, m12: 2.5}}] = Scene.children(graph, "2:1")
  end

  test "materializes component prop component swaps" do
    graph =
      [
        %SeedNode{guid: {1, 1}, node_type: "component", name: "Old"},
        %SeedNode{
          guid: {1, 2},
          node_type: "instance",
          parent_guid: {1, 1},
          symbol_id: {4, 1},
          component_prop_refs: [%ComponentPropRef{def_id: {9, 1}, field: :overridden_symbol_id}]
        },
        %SeedNode{guid: {3, 1}, node_type: "component", name: "New"},
        %SeedNode{guid: {3, 2}, node_type: "text", parent_guid: {3, 1}, text: "New nested"},
        %SeedNode{
          guid: {2, 1},
          node_type: "instance",
          symbol_id: {1, 1},
          component_prop_assignments: [
            %ComponentPropAssignment{def_id: {9, 1}, value: {:guid, {3, 1}}}
          ]
        }
      ]
      |> Resolver.from_seed(resource: make_ref(), stages: [:populate_instances, :component_props])
      |> Resolver.resolve()

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
        %SeedNode{guid: {1, 1}, node_type: "component", name: "Old"},
        %SeedNode{
          guid: {1, 2},
          node_type: "instance",
          parent_guid: {1, 1},
          symbol_id: {3, 1},
          component_prop_refs: [%ComponentPropRef{def_id: {9, 1}, field: :overridden_symbol_id}]
        },
        %SeedNode{guid: {4, 1}, node_type: "component", name: "Swapped"},
        %SeedNode{guid: {4, 2}, node_type: "instance", parent_guid: {4, 1}, symbol_id: {5, 1}},
        %SeedNode{guid: {5, 1}, node_type: "component", name: "Icon"},
        %SeedNode{guid: {5, 2}, node_type: "vector", parent_guid: {5, 1}},
        %SeedNode{
          guid: {2, 1},
          node_type: "instance",
          symbol_id: {1, 1},
          component_prop_assignments: [
            %ComponentPropAssignment{def_id: {9, 1}, value: {:guid, {4, 1}}}
          ]
        }
      ]
      |> Resolver.from_seed(resource: make_ref(), stages: [:populate_instances, :component_props])
      |> Resolver.resolve()

    assert [%Node{guid: "clone:2:1/1:2/4:2"}] = Scene.children(graph, "clone:2:1/1:2")

    assert [%Node{guid: "clone:2:1/1:2/4:2/5:2"}] =
             Scene.children(graph, "clone:2:1/1:2/4:2")
  end

  test "component prop assignments apply to all matching refs" do
    graph =
      [
        %SeedNode{guid: {1, 1}, node_type: "component", name: "Menu"},
        %SeedNode{
          guid: {1, 2},
          node_type: "frame",
          parent_guid: {1, 1},
          visible: true,
          component_prop_refs: [%ComponentPropRef{def_id: {9, 1}, field: :visible}]
        },
        %SeedNode{
          guid: {1, 3},
          node_type: "vector",
          parent_guid: {1, 1},
          visible: true,
          component_prop_refs: [%ComponentPropRef{def_id: {9, 1}, field: :visible}]
        },
        %SeedNode{
          guid: {2, 1},
          node_type: "instance",
          symbol_id: {1, 1},
          component_prop_assignments: [
            %ComponentPropAssignment{def_id: {9, 1}, value: {:bool, false}}
          ]
        }
      ]
      |> Resolver.from_seed(resource: make_ref(), stages: [:populate_instances, :component_props])
      |> Resolver.resolve()

    assert [%Node{visible: false}, %Node{visible: false}] = Scene.children(graph, "2:1")
  end

  test "applies derived symbol layout data to cloned children" do
    transform = %{m00: 1.0, m01: 0.0, m02: 10.0, m10: 0.0, m11: 1.0, m12: 20.0}

    graph =
      [
        %SeedNode{guid: {1, 1}, node_type: "component", name: "Card"},
        %SeedNode{
          guid: {1, 2},
          node_type: "frame",
          parent_guid: {1, 1},
          size: %{x: 100.0, y: 40.0}
        },
        %SeedNode{
          guid: {2, 1},
          node_type: "instance",
          symbol_id: {1, 1},
          derived_symbol_data: [
            %DerivedSymbolData{
              guid_path: [{1, 1}, {1, 2}],
              size: %{x: 120.0, y: 50.0},
              transform: transform
            }
          ]
        }
      ]
      |> Resolver.from_seed(
        resource: make_ref(),
        stages: [:populate_instances, :derived_symbol_data]
      )
      |> Resolver.resolve()

    assert [%Node{guid: clone_guid, size: %{x: 120.0, y: 50.0}, transform: ^transform}] =
             Scene.children(graph, "2:1")

    assert clone_guid == "clone:2:1/1:2"

    applied = Graph.explain(graph, clone_guid).applied
    assert {:derived_symbol_data, :size, %{x: 100.0, y: 40.0}, %{x: 120.0, y: 50.0}} in applied
    assert {:derived_symbol_data, :transform, nil, transform} in applied
  end
end
