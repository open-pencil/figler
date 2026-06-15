defmodule FigKiwi.SceneTest do
  use ExUnit.Case, async: true

  alias FigKiwi.Scene
  alias FigKiwi.Scene.Graph
  alias FigKiwi.Scene.Graph.ComponentPropAssignment
  alias FigKiwi.Scene.Graph.ComponentPropRef
  alias FigKiwi.Scene.Graph.Resolver
  alias FigKiwi.Scene.Graph.SeedNode
  alias FigKiwi.Scene.Graph.SymbolOverride
  alias FigKiwi.Scene.Node
  alias FigKiwi.Scene.Summary
  alias KiwiCodec.Schema.Binary, as: SchemaBinary

  test "summarizes raw message payloads" do
    assert Scene.summary(message_payload()) == %Summary{
             node_count: 2,
             parented_count: 1,
             root_count: 1,
             type_counts: [{"canvas", 1}, {"document", 1}]
           }
  end

  test "scene node projection is backed by generated Kiwi schema metadata" do
    assert Node.source_module() == FigKiwi.Schema.NodeChange

    assert Node.source_fields() == [
             :guid,
             :type,
             :name,
             :parent_index,
             :size,
             :transform,
             :visible,
             :locked,
             :text_data,
             :font_name,
             :style_id_for_text,
             :component_key,
             :origin_component_key,
             :style_id_for_fill,
             :style_id_for_stroke_fill,
             :style_id_for_effect,
             :style_id_for_grid,
             :fill_paints,
             :stroke_paints
           ]

    assert Node.parent_index_source_fields() == [:guid, :position]
  end

  test "queries raw message payloads" do
    assert Scene.query(message_payload(), "//canvas[@name='Page 1']") == [scene_canvas()]

    assert Scene.query(message_payload(), "//canvas[@width='100' and @visible='true']") == [
             scene_canvas()
           ]

    assert Scene.query(message_payload(), "//canvas[contains(@text, 'Hello')]") == [
             scene_canvas()
           ]

    assert Scene.query(message_payload(), "//canvas", fields: [:name]) == [
             %Node{guid: "0:1", node_type: "canvas", name: "Page 1"}
           ]
  end

  test "reuses projected scene indexes across XPath queries" do
    index = Scene.index(message_payload())

    assert Scene.query(index, "//canvas") == [scene_canvas()]
    assert Scene.query(index, "//*[@parent_guid='0:0']") == [scene_canvas()]
  end

  test "builds effective graph handles over projected indexes" do
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

    assert Graph.explain(graph, "0:1") == %{
             guid: "0:1",
             node: scene_canvas(),
             source: :projected_index,
             source_guid: "0:1",
             applied: [],
             unresolved: [],
             stages: [:populate_instances, :symbol_overrides, :component_props]
           }

    assert Graph.diff_node(Scene.index(message_payload()), graph, "0:1") == %{
             guid: "0:1",
             changed: []
           }
  end

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
        %SeedNode{guid: {1, 1}, node_type: "component", name: "Button"},
        %SeedNode{guid: {1, 2}, node_type: "text", parent_guid: {1, 1}, text: "Default"},
        %SeedNode{
          guid: {2, 1},
          node_type: "instance",
          symbol_id: {1, 1},
          symbol_overrides: [
            %SymbolOverride{guid_path: [{1, 2}], fields: %{text: "Submit", visible: false}}
          ]
        }
      ]
      |> Resolver.from_seed(resource: make_ref(), stages: [:symbol_overrides])
      |> Resolver.resolve()

    assert Scene.node(graph, "1:2").text == "Submit"
    assert Scene.node(graph, "1:2").visible == false

    assert {:symbol_override, :text, "Default", "Submit"} in Graph.explain(graph, "1:2").applied
    assert {:symbol_override, :visible, nil, false} in Graph.explain(graph, "1:2").applied
  end

  test "populates instance clones and applies overrides to cloned children" do
    graph =
      [
        %SeedNode{guid: {1, 1}, node_type: "component", name: "Button"},
        %SeedNode{guid: {1, 2}, node_type: "text", parent_guid: {1, 1}, text: "Default"},
        %SeedNode{
          guid: {2, 1},
          node_type: "instance",
          symbol_id: {1, 1},
          symbol_overrides: [%SymbolOverride{guid_path: [{1, 2}], fields: %{text: "Submit"}}]
        }
      ]
      |> Resolver.from_seed(
        resource: make_ref(),
        stages: [:populate_instances, :symbol_overrides]
      )
      |> Resolver.resolve()

    assert [%Node{guid: clone_guid, text: "Submit"}] = Scene.children(graph, "2:1")
    assert clone_guid == "clone:2:1/1:2"
    assert Scene.node(graph, "1:2").text == "Default"

    assert Graph.explain(graph, clone_guid) == %{
             guid: clone_guid,
             node: Scene.node(graph, clone_guid),
             source: :instance_clone,
             source_guid: "1:2",
             applied: [{:symbol_override, :text, "Default", "Submit"}],
             unresolved: [],
             stages: [:populate_instances, :symbol_overrides]
           }
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
    assert [%Node{guid: "clone:2:1/1:3", text: "Submit"}] = Scene.children(graph, "clone:2:1/1:2")

    assert Graph.explain(graph, "clone:2:1/1:3").applied == [
             {:symbol_override, :text, "Default", "Submit"}
           ]

    assert Graph.unresolved(graph) == [
             {:symbol_override_target, {2, 1}, [{1, 1}, {1, 3}], :invalid_path}
           ]
  end

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

  test "navigates projected scene indexes" do
    index = Scene.index(message_payload())

    assert Scene.pages(index) == [scene_canvas()]
    assert Scene.roots(index) == [scene_document()]
    assert Scene.node(index, "0:1") == scene_canvas()
    assert Scene.parent(index, "0:1") == scene_document()
    assert Scene.children(index, "0:0") == [scene_canvas()]
    assert Scene.siblings(index, "0:1") == []
    assert Scene.ancestors(index, "0:1") == [scene_document()]
    assert Scene.descendants(index, "0:0") == [scene_canvas()]
    assert %FigKiwi.Scene.Index{} = index
    assert Scene.by_type(index, :canvas) == [scene_canvas()]
    assert Scene.named(index, "Page 1") == [scene_canvas()]
    assert Scene.name_contains(index, "Page") == [scene_canvas()]
    assert Scene.text_nodes(index) == []
    assert Scene.text_contains(index, "Hello") == [scene_canvas()]

    assert Scene.by_type(index, :canvas, fields: [:name]) == [
             %Node{guid: "0:1", node_type: "canvas", name: "Page 1"}
           ]

    assert Scene.name_contains(index, "Page", fields: [:name]) == [
             %Node{guid: "0:1", node_type: "canvas", name: "Page 1"}
           ]

    assert Scene.text_contains(index, "Hello", fields: [:text]) == [
             %Node{guid: "0:1", node_type: "canvas", text: "Hello world"}
           ]

    assert index
           |> Scene.by_type(:canvas)
           |> Scene.name_contains("Page")
           |> Scene.text_contains("Hello") == [scene_canvas()]

    assert index
           |> Scene.by_type(:canvas)
           |> Scene.attribute(:name) == ["Page 1"]

    assert index
           |> Scene.by_type(:canvas)
           |> Scene.text(sep: "\n") == "Hello world"

    assert Scene.components(index) == []
    assert Scene.with_fills(index) == []
    assert Scene.with_strokes(index) == []

    assert Scene.find(index, type: :canvas, name_contains: "Page", text_contains: "Hello") == [
             scene_canvas()
           ]

    assert Scene.tree(index, depth: 1) == [
             %Node{scene_document() | children: [%Node{scene_canvas() | children: []}]}
           ]
  end

  test "accepts canvas.fig containers" do
    assert Scene.summary(canvas_container()) == Scene.summary(message_payload())
  end

  test "accepts .fig ZIPs containing canvas.fig" do
    assert Scene.query(fig_zip(), "//*[@parent_guid='0:0']") == [scene_canvas()]
  end

  defp scene_document do
    %Node{
      guid: "0:0",
      node_type: "document",
      name: "Document",
      parent_guid: nil,
      position: nil
    }
  end

  defp scene_canvas do
    %Node{
      guid: "0:1",
      node_type: "canvas",
      name: "Page 1",
      parent_guid: "0:0",
      position: "!",
      size: %{x: 100.0, y: 50.0},
      transform: %{m00: 1.0, m01: 0.0, m02: 10.0, m10: 0.0, m11: 1.0, m12: 20.0},
      visible: true,
      locked: false,
      text: "Hello world",
      font_family: "Inter",
      font_style: "Regular",
      font_postscript: "Inter-Regular",
      text_style_guid: "0:2"
    }
  end

  defp fig_zip do
    {:ok, {_name, zip}} =
      :zip.create(~c"fixture.fig", [{~c"canvas.fig", canvas_container()}], [:memory])

    zip
  end

  defp canvas_container do
    FigKiwi.Container.build([
      FigKiwi.Container.deflate(FigKiwi.schema() |> SchemaBinary.encode()),
      FigKiwi.Container.deflate(message_payload())
    ])
  end

  defp message_payload do
    guid = struct(FigKiwi.Schema.GUID, session_id: 0, local_id: 0)

    message =
      struct(FigKiwi.Schema.Message,
        type: :node_changes,
        session_id: 0,
        node_changes: [
          struct(FigKiwi.Schema.NodeChange,
            guid: guid,
            type: :document,
            name: "Document"
          ),
          struct(FigKiwi.Schema.NodeChange,
            guid: struct(FigKiwi.Schema.GUID, session_id: 0, local_id: 1),
            parent_index: struct(FigKiwi.Schema.ParentIndex, guid: guid, position: "!"),
            type: :canvas,
            name: "Page 1",
            size: struct(FigKiwi.Schema.Vector, x: 100.0, y: 50.0),
            transform:
              struct(FigKiwi.Schema.Matrix,
                m00: 1.0,
                m01: 0.0,
                m02: 10.0,
                m10: 0.0,
                m11: 1.0,
                m12: 20.0
              ),
            visible: true,
            locked: false,
            text_data: struct(FigKiwi.Schema.TextData, characters: "Hello world"),
            font_name:
              struct(FigKiwi.Schema.FontName,
                family: "Inter",
                style: "Regular",
                postscript: "Inter-Regular"
              ),
            style_id_for_text:
              struct(FigKiwi.Schema.StyleId,
                guid: struct(FigKiwi.Schema.GUID, session_id: 0, local_id: 2)
              )
          )
        ]
      )

    KiwiCodec.encode(message)
  end
end
