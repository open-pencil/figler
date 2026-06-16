defmodule FigKiwi.Test.SceneFixture do
  @moduledoc false

  alias FigKiwi.Scene.Node
  alias KiwiCodec.Schema.Binary, as: SchemaBinary

  def scene_document do
    %Node{guid: "0:0", node_type: "document", name: "Document", parent_guid: nil, position: nil}
  end

  def scene_canvas do
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

  def fig_zip do
    {:ok, {_name, zip}} =
      :zip.create(~c"fixture.fig", [{~c"canvas.fig", canvas_container()}], [:memory])

    zip
  end

  def canvas_container do
    FigKiwi.Container.build([
      FigKiwi.Container.deflate(FigKiwi.schema() |> SchemaBinary.encode()),
      FigKiwi.Container.deflate(message_payload())
    ])
  end

  def message_payload do
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
