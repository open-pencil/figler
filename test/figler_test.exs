defmodule FiglerTest do
  use ExUnit.Case, async: true

  alias Figler.Error

  import Figler.Test.SceneFixture

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

  test "decodes, transforms, and encodes complete fig archives with ordinary Elixir" do
    archive =
      fig_zip([
        {~c"images/deadbeef", <<1, 2, 3>>},
        {~c"metadata.json", ~s({"name":"Fixture"})}
      ])

    document = Figler.decode!(archive)

    updated =
      update_in(document.message.node_changes, fn nodes ->
        Enum.map(nodes, fn
          %{name: "Page 1"} = node -> %{node | name: "Renamed page"}
          node -> node
        end)
      end)

    encoded = Figler.encode!(updated)
    reopened = Figler.decode!(encoded)

    assert Enum.any?(reopened.message.node_changes, &(&1.name == "Renamed page"))
    assert reopened.entries["metadata.json"] == ~s({"name":"Fixture"})
    assert reopened.images == %{"deadbeef" => <<1, 2, 3>>}
    assert reopened.canvas_path == "canvas.fig"
  end

  test "encodes complete documents back to their original representation" do
    for {input, source, prefix} <- [
          {message_payload(), :payload, <<1>>},
          {canvas_container(), :container, "fig-kiwi"},
          {fig_zip(), :archive, "PK"}
        ] do
      assert {:ok, document} = Figler.decode(input)
      assert document.source == source
      assert {:ok, encoded} = Figler.encode(document)
      assert String.starts_with?(encoded, prefix)
      assert Figler.decode!(encoded).message == document.message
    end
  end

  test "returns structured document encoding failures" do
    document = %{Figler.decode!(message_payload()) | message: %{invalid: true}}

    assert {:error,
            %Error{
              code: :invalid_document,
              operation: :encode_document,
              context: %{reason: :invalid_message}
            }} = Figler.encode(document)
  end
end
