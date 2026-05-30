defmodule FigKiwi.NativeTest do
  use ExUnit.Case, async: true

  test "decodes generated primitive structs" do
    guid = struct(FigKiwi.Schema.GUID, session_id: 12, local_id: 34)
    vector = struct(FigKiwi.Schema.Vector, x: 100.0, y: 50.0)

    parent_index = struct(FigKiwi.Schema.ParentIndex, guid: guid, position: "!")
    image = struct(FigKiwi.Schema.Image, hash: <<1, 2, 3>>, name: "Preview", data_blob: 7)

    assert FigKiwi.Native.decode_guid(KiwiCodec.encode(guid)) == guid
    assert FigKiwi.Native.decode_vector(KiwiCodec.encode(vector)) == vector
    assert FigKiwi.Native.decode_parent_index(KiwiCodec.encode(parent_index)) == parent_index
    assert FigKiwi.Native.decode_image(KiwiCodec.encode(image)) == image
  end
end
