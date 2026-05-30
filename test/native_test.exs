defmodule FigKiwi.NativeTest do
  use ExUnit.Case, async: true

  test "decodes generated primitive structs" do
    guid = struct(FigKiwi.Schema.GUID, session_id: 12, local_id: 34)
    vector = struct(FigKiwi.Schema.Vector, x: 100.0, y: 50.0)

    assert FigKiwi.Native.decode_guid(KiwiCodec.encode(guid)) == guid
    assert FigKiwi.Native.decode_vector(KiwiCodec.encode(vector)) == vector
  end
end
