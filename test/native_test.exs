defmodule FigKiwi.NativeTest do
  use ExUnit.Case, async: true

  test "decodes generated primitive structs" do
    guid = struct(FigKiwi.Schema.GUID, session_id: 12, local_id: 34)
    vector = struct(FigKiwi.Schema.Vector, x: 100.0, y: 50.0)

    parent_index = struct(FigKiwi.Schema.ParentIndex, guid: guid, position: "!")
    image = struct(FigKiwi.Schema.Image, hash: <<1, 2, 3>>, name: "Preview", data_blob: 7)
    partial_image = struct(FigKiwi.Schema.Image, name: "Preview")

    assert FigKiwi.Native.decode_guid(KiwiCodec.encode(guid)) == guid
    assert FigKiwi.Native.decode_vector(KiwiCodec.encode(vector)) == vector
    assert FigKiwi.Native.decode_parent_index(KiwiCodec.encode(parent_index)) == parent_index

    node_change =
      struct(FigKiwi.Schema.NodeChange,
        guid: guid,
        phase: :created,
        parent_index: parent_index,
        type: :rectangle,
        name: "Rect 1",
        size: vector
      )

    message =
      struct(FigKiwi.Schema.Message,
        type: :node_changes,
        session_id: 12,
        node_changes: [node_change]
      )

    partial_message = struct(FigKiwi.Schema.Message, session_id: 12)
    unknown_enum_message = struct(FigKiwi.Schema.Message, type: 999)

    assert FigKiwi.Native.decode_image(KiwiCodec.encode(image)) == image
    assert FigKiwi.Native.decode_image(KiwiCodec.encode(partial_image)) == partial_image
    assert FigKiwi.Native.decode_node_change(KiwiCodec.encode(node_change)) == node_change
    assert FigKiwi.Native.decode_message(KiwiCodec.encode(message)) == message
    assert FigKiwi.Native.decode_message(KiwiCodec.encode(partial_message)) == partial_message

    assert FigKiwi.Native.decode_message(KiwiCodec.encode(unknown_enum_message)) ==
             unknown_enum_message
  end

  test "decodes sparse messages without absent fields" do
    guid = struct(FigKiwi.Schema.GUID, session_id: 12, local_id: 34)

    message =
      struct(FigKiwi.Schema.Message,
        type: :node_changes,
        session_id: 12,
        node_changes: [
          struct(FigKiwi.Schema.NodeChange,
            guid: guid,
            type: :rectangle,
            name: "Rect 1"
          )
        ]
      )

    assert FigKiwi.decode_sparse_message(KiwiCodec.encode(message)) == %{
             __kiwi_module__: FigKiwi.Schema.Message,
             type: :node_changes,
             session_id: 12,
             node_changes: [
               %{
                 __kiwi_module__: FigKiwi.Schema.NodeChange,
                 guid: guid,
                 type: :rectangle,
                 name: "Rect 1"
               }
             ]
           }
  end

  test "decodes scene summary without materializing schema structs" do
    message = scene_message()

    assert FigKiwi.Native.decode_scene_summary(KiwiCodec.encode(message)) == %{
             node_count: 2,
             parented_count: 1,
             root_count: 1,
             type_counts: [{"canvas", 1}, {"document", 1}]
           }
  end

  test "queries projected scene index with XPath" do
    assert FigKiwi.Native.query_scene_xpath(
             KiwiCodec.encode(scene_message()),
             "//canvas[@name='Page 1']"
           ) == [
             %{
               guid: "0:1",
               node_type: "canvas",
               name: "Page 1",
               parent_guid: "0:0",
               position: "!"
             }
           ]
  end

  defp scene_message do
    guid = struct(FigKiwi.Schema.GUID, session_id: 0, local_id: 0)

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
  end
end
