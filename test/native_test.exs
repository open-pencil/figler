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
end
