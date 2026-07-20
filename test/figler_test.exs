defmodule FiglerTest do
  use ExUnit.Case, async: true

  alias Figler.Error

  test "parses vendored Figma schema" do
    schema = Figler.schema()

    assert Enum.count(schema.definitions) == 607
    assert KiwiCodec.Schema.definition(schema, "Message")
    assert KiwiCodec.Schema.definition(schema, "NodeChange")
  end

  test "encodes and decodes a minimal static message" do
    message = %Figler.Schema.Message{type: :node_changes, session_id: 12, node_changes: []}

    assert message |> Figler.encode_message() |> Figler.decode_message() == message
  end

  test "encodes and decodes a minimal runtime message" do
    message = %{"type" => "NODE_CHANGES", "sessionID" => 12, "nodeChanges" => []}

    assert message |> Figler.encode_message_runtime() |> Figler.decode_message_runtime() ==
             message
  end

  test "normalizes malformed message decoding failures" do
    for {operation, fun} <- [
          decode_message: fn -> Figler.decode_message(<<1, 2, 3>>) end,
          decode_sparse_message: fn -> Figler.decode_sparse_message(<<1, 2, 3>>) end,
          decode_message_runtime: fn -> Figler.decode_message_runtime(<<1, 2, 3>>) end
        ] do
      error = assert_raise Error, fun
      assert error.code == :invalid_document
      assert error.operation == operation
      assert is_binary(error.context.reason)
    end
  end

  test "parses fig-kiwi containers" do
    binary =
      Figler.Container.build([
        Figler.Container.deflate("schema"),
        Figler.Container.deflate("data")
      ])

    parsed = Figler.Container.parse(binary)

    assert parsed.version == 101
    assert Enum.map(parsed.chunks, &Figler.Container.inflate/1) == ["schema", "data"]
  end
end
