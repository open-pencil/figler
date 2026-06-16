defmodule FigKiwi.Scene.Graph.ResolverTest do
  use ExUnit.Case, async: true

  alias FigKiwi.Scene
  alias FigKiwi.Scene.Graph
  alias FigKiwi.Scene.Graph.GUID
  alias FigKiwi.Scene.Graph.Resolver
  alias FigKiwi.Scene.Graph.SeedNode
  alias FigKiwi.Scene.Graph.SymbolOverride
  alias FigKiwi.Scene.Graph.Target
  alias FigKiwi.Scene.Node

  import FigKiwi.Test.GraphBuilder

  test "extracts graph seed metadata from generated node changes" do
    target_guid = struct(FigKiwi.Schema.GUID, session_id: 1, local_id: 2)

    seed =
      struct(FigKiwi.Schema.NodeChange,
        guid: struct(FigKiwi.Schema.GUID, session_id: 2, local_id: 1),
        type: :instance,
        name: "Button instance",
        override_key: struct(FigKiwi.Schema.GUID, session_id: 2, local_id: 9),
        symbol_data:
          struct(FigKiwi.Schema.SymbolData,
            symbol_id: struct(FigKiwi.Schema.GUID, session_id: 1, local_id: 1),
            symbol_overrides: [
              struct(FigKiwi.Schema.NodeChange,
                guid_path: struct(FigKiwi.Schema.GUIDPath, guids: [target_guid]),
                text_data: struct(FigKiwi.Schema.TextData, characters: "Submit"),
                visible: false
              )
            ]
          )
      )
      |> SeedNode.from_node_change()

    assert %SeedNode{
             guid: {2, 1},
             node_type: "instance",
             name: "Button instance",
             symbol_id: {1, 1},
             component_guid: {1, 1},
             override_key: {2, 9},
             symbol_overrides: [
               %SymbolOverride{guid_path: [{1, 2}], fields: %{text: "Submit", visible: false}}
             ]
           } = seed
  end

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
        %SeedNode{guid: {1, 1}, node_type: "component", name: "Button"},
        %SeedNode{guid: {1, 2}, node_type: "text", parent_guid: {1, 1}, text: "Default"},
        %SeedNode{guid: {2, 1}, node_type: "instance", symbol_id: {1, 1}, visible: false}
      ]
      |> Resolver.from_seed(resource: make_ref(), stages: [:populate_instances])
      |> Resolver.resolve()

    assert Scene.children(graph, "2:1") == []
    assert Graph.stats(graph).clone_count == 0
  end

  test "does not populate source instances inside symbol definitions" do
    graph =
      [
        %SeedNode{guid: {1, 0}, node_type: "canvas", name: "Internal", visible: false},
        %SeedNode{guid: {1, 1}, node_type: "symbol", parent_guid: {1, 0}, name: "Variant"},
        %SeedNode{guid: {1, 2}, node_type: "instance", parent_guid: {1, 1}, symbol_id: {2, 1}},
        %SeedNode{guid: {2, 1}, node_type: "component", name: "Button"},
        %SeedNode{guid: {2, 2}, node_type: "text", parent_guid: {2, 1}, text: "Default"}
      ]
      |> Resolver.from_seed(resource: make_ref(), stages: [:populate_instances])
      |> Resolver.resolve()

    assert Scene.children(graph, "1:2") == []
    assert Graph.stats(graph).clone_count == 0
  end

  test "populates source instances inside focused symbol definitions" do
    graph =
      [
        %SeedNode{guid: {1, 1}, node_type: "symbol", name: "Accordion"},
        %SeedNode{guid: {1, 2}, node_type: "instance", parent_guid: {1, 1}, symbol_id: {2, 1}},
        %SeedNode{guid: {2, 1}, node_type: "component", name: "Panel"},
        %SeedNode{guid: {2, 2}, node_type: "text", parent_guid: {2, 1}, text: "Item"}
      ]
      |> Resolver.from_seed(
        resource: make_ref(),
        stages: [:populate_instances],
        options: [focus: [{1, 1}]]
      )
      |> Resolver.resolve()

    assert [%Node{guid: "clone:1:2/2:2"}] = Scene.children(graph, "1:2")
    assert Graph.stats(graph).clone_count == 1
  end

  test "focuses resolver stages on selected source subtrees" do
    graph =
      [
        %SeedNode{guid: {1, 1}, node_type: "component", name: "Button"},
        %SeedNode{guid: {1, 2}, node_type: "text", parent_guid: {1, 1}, text: "Default"},
        %SeedNode{guid: {2, 1}, node_type: "instance", symbol_id: {1, 1}},
        %SeedNode{guid: {2, 2}, node_type: "instance", symbol_id: {1, 1}}
      ]
      |> Resolver.from_seed(
        resource: make_ref(),
        stages: [:populate_instances],
        options: [focus: [{2, 1}]]
      )
      |> Resolver.resolve()

    assert [%Node{guid: "clone:2:1/1:2"}] = Scene.children(graph, "2:1")
    assert Scene.children(graph, "2:2") == []
    assert Graph.stats(graph).clone_count == 1
  end

  test "falls back to deepest source target for invalid nested override paths" do
    graph =
      [
        %SeedNode{guid: {1, 1}, node_type: "component", name: "Wrapper"},
        %SeedNode{guid: {1, 2}, node_type: "instance", parent_guid: {1, 1}, symbol_id: {3, 1}},
        %SeedNode{guid: {2, 1}, node_type: "instance", symbol_id: {1, 1}},
        %SeedNode{guid: {3, 1}, node_type: "component", name: "Leaf"},
        %SeedNode{guid: {3, 2}, node_type: "text", parent_guid: {3, 1}, text: "Default"}
      ]
      |> Resolver.from_seed(resource: make_ref(), stages: [:populate_instances])
      |> Resolver.resolve()

    assert {:ok, target} = Target.resolve(graph, {2, 1}, [{1, 2}, {3, 2}])
    assert GUID.format(target) == "clone:2:1/1:2/3:2"
  end

  test "validates nested source paths when resolving symbol overrides" do
    graph =
      [
        %SeedNode{guid: {1, 1}, node_type: "component", name: "Card"},
        %SeedNode{guid: {1, 2}, node_type: "frame", parent_guid: {1, 1}, name: "Body"},
        %SeedNode{guid: {1, 3}, node_type: "text", parent_guid: {1, 2}, text: "Default"},
        %SeedNode{
          guid: {2, 1},
          node_type: "instance",
          symbol_id: {1, 1},
          symbol_overrides: [
            %SymbolOverride{guid_path: [{1, 1}, {1, 2}, {1, 3}], fields: %{text: "Submit"}},
            %SymbolOverride{guid_path: [{1, 1}, {1, 3}], fields: %{visible: false}}
          ]
        }
      ]
      |> Resolver.from_seed(
        resource: make_ref(),
        stages: [:populate_instances, :symbol_overrides]
      )
      |> Resolver.resolve()

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
        %SeedNode{guid: {1, 1}, node_type: "component", name: "Wrapper"},
        %SeedNode{
          guid: {1, 2},
          node_type: "instance",
          parent_guid: {1, 1},
          symbol_id: {3, 1},
          name: "Nested instance",
          symbol_overrides: [%SymbolOverride{guid_path: [{1, 2}], fields: %{name: "Patched"}}]
        },
        %SeedNode{guid: {2, 1}, node_type: "instance", symbol_id: {1, 1}},
        %SeedNode{guid: {3, 1}, node_type: "component", name: "Leaf"}
      ]
      |> Resolver.from_seed(
        resource: make_ref(),
        stages: [:populate_instances, :symbol_overrides]
      )
      |> Resolver.resolve()

    assert Scene.node(graph, "1:2").name == "Patched"
    assert [%Node{guid: "clone:2:1/1:2", name: "Nested instance"}] = Scene.children(graph, "2:1")
    assert Graph.stats(graph).clone_instance_count == 1
    assert Graph.stats(graph).source_instance_count == 2
  end
end
