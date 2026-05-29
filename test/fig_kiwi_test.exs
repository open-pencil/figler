defmodule FigKiwiTest do
  use ExUnit.Case, async: true

  test "parses vendored Figma schema" do
    schema = FigKiwi.schema()

    assert Enum.count(schema.definitions) == 605
    assert KiwiCodec.Schema.definition(schema, "Message")
    assert KiwiCodec.Schema.definition(schema, "NodeChange")
  end

  test "encodes and decodes a minimal static message" do
    message = %FigKiwi.Schema.Message{type: :node_changes, session_id: 12, node_changes: []}

    assert message |> FigKiwi.encode_message() |> FigKiwi.decode_message() == message
  end

  test "encodes and decodes a minimal runtime message" do
    message = %{"type" => "NODE_CHANGES", "sessionID" => 12, "nodeChanges" => []}

    assert message |> FigKiwi.encode_message_runtime() |> FigKiwi.decode_message_runtime() ==
             message
  end

  test "parses fig-kiwi containers" do
    binary =
      FigKiwi.Container.build([
        FigKiwi.Container.deflate("schema"),
        FigKiwi.Container.deflate("data")
      ])

    parsed = FigKiwi.Container.parse(binary)

    assert parsed.version == 101
    assert Enum.map(parsed.chunks, &FigKiwi.Container.inflate/1) == ["schema", "data"]
  end
end
