defmodule FigKiwi.SceneTest do
  use ExUnit.Case, async: true

  alias FigKiwi.Scene
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
    assert Node.source_fields() == [:guid, :type, :name, :parent_index]
    assert Node.parent_index_source_fields() == [:guid, :position]
  end

  test "queries raw message payloads" do
    assert Scene.query(message_payload(), "//canvas[@name='Page 1']") == [scene_canvas()]
  end

  test "reuses projected scene indexes across XPath queries" do
    index = Scene.index(message_payload())

    assert Scene.query(index, "//canvas") == [scene_canvas()]
    assert Scene.query(index, "//*[@parent_guid='0:0']") == [scene_canvas()]
  end

  test "navigates projected scene indexes" do
    index = Scene.index(message_payload())

    assert Scene.pages(index) == [scene_canvas()]
    assert Scene.node(index, "0:1") == scene_canvas()
    assert Scene.children(index, "0:0") == [scene_canvas()]
    assert Scene.find(index, type: :canvas, name_contains: "Page") == [scene_canvas()]

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
      position: "!"
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
            name: "Page 1"
          )
        ]
      )

    KiwiCodec.encode(message)
  end
end
