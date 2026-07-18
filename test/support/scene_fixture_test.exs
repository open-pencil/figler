defmodule Figler.Test.SceneFixture do
  @moduledoc """
  Test fixture builders for small Figler scene payloads.

  The fixture binary contains a minimal document and canvas so container,
  sparse decode, and native scene tests can exercise real Kiwi payloads without
  large external files.
  """

  alias Figler.Scene.Node
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

  def fig_zip(extra_entries \\ []) do
    entries = [{~c"canvas.fig", canvas_container()} | extra_entries]
    {:ok, {_name, zip}} = :zip.create(~c"fixture.fig", entries, [:memory])
    zip
  end

  def canvas_container do
    Figler.Container.build([
      Figler.Container.deflate(Figler.schema() |> SchemaBinary.encode()),
      Figler.Container.deflate(message_payload())
    ])
  end

  def message_payload do
    guid = struct(Figler.Schema.GUID, session_id: 0, local_id: 0)

    message =
      struct(Figler.Schema.Message,
        type: :node_changes,
        session_id: 0,
        node_changes: [
          struct(Figler.Schema.NodeChange,
            guid: guid,
            type: :document,
            name: "Document"
          ),
          struct(Figler.Schema.NodeChange,
            guid: struct(Figler.Schema.GUID, session_id: 0, local_id: 1),
            parent_index: struct(Figler.Schema.ParentIndex, guid: guid, position: "!"),
            type: :canvas,
            name: "Page 1",
            size: struct(Figler.Schema.Vector, x: 100.0, y: 50.0),
            transform:
              struct(Figler.Schema.Matrix,
                m00: 1.0,
                m01: 0.0,
                m02: 10.0,
                m10: 0.0,
                m11: 1.0,
                m12: 20.0
              ),
            visible: true,
            locked: false,
            text_data: struct(Figler.Schema.TextData, characters: "Hello world"),
            font_name:
              struct(Figler.Schema.FontName,
                family: "Inter",
                style: "Regular",
                postscript: "Inter-Regular"
              ),
            style_id_for_text:
              struct(Figler.Schema.StyleId,
                guid: struct(Figler.Schema.GUID, session_id: 0, local_id: 2)
              )
          )
        ]
      )

    KiwiCodec.encode(message)
  end
end
