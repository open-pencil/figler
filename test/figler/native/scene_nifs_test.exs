defmodule Figler.Native.SceneNifsTest do
  use ExUnit.Case, async: true

  alias Figler.Native.SceneNifs, as: Scene

  test "decodes scene summary without materializing schema structs" do
    message = scene_message()

    assert Scene.decode_summary(KiwiCodec.encode(message)) == %{
             node_count: 2,
             parented_count: 1,
             root_count: 1,
             type_counts: [{"canvas", 1}, {"document", 1}]
           }
  end

  test "queries projected scene index with XPath" do
    assert Scene.query_xpath(
             KiwiCodec.encode(scene_message()),
             "//canvas[@name='Page 1']"
           ) == [
             %{
               guid: "0:1",
               node_type: "canvas",
               name: "Page 1",
               parent_guid: "0:0",
               position: "!",
               size: nil,
               transform: nil,
               visible: nil,
               locked: nil,
               opacity: nil,
               text: nil,
               font_family: nil,
               font_style: nil,
               font_postscript: nil,
               font_size: nil,
               text_style_guid: nil,
               component_key: nil,
               origin_component_key: nil,
               fill_style_guid: nil,
               stroke_style_guid: nil,
               effect_style_guid: nil,
               grid_style_guid: nil,
               fill_count: nil,
               stroke_count: nil
             }
           ]
  end

  defp scene_message do
    guid = struct(Figler.Schema.GUID, session_id: 0, local_id: 0)

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
          name: "Page 1"
        )
      ]
    )
  end
end
