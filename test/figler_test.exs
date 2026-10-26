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

  describe "OpenPencil compatibility" do
    alias Figler.Schema.{Color, GUID, Message, NodeChange, Paint, Vector}

    test "minimal Message bytes match OpenPencil TypeScript codec" do
      message = %Message{type: :node_changes, session_id: 12, node_changes: []}

      assert Figler.encode_message(message) == <<1, 1, 2, 12, 4, 0, 0>>
    end

    test "Vector bytes match OpenPencil TypeScript codec" do
      assert KiwiCodec.encode(%Vector{x: 1.5, y: -2.25}) == <<127, 0, 0, 128, 128, 1, 0, 32>>
    end

    test "GUID bytes match OpenPencil TypeScript codec" do
      assert KiwiCodec.encode(%GUID{session_id: 12, local_id: 34}) == <<12, 34>>
    end

    test "Paint bytes match OpenPencil TypeScript codec" do
      paint = %Paint{
        type: :solid,
        color: %Color{r: 1.0, g: 0.5, b: 0.25, a: 1.0},
        opacity: 0.75,
        visible: true
      }

      assert KiwiCodec.encode(paint) ==
               <<1, 0, 2, 127, 0, 0, 0, 126, 0, 0, 0, 125, 0, 0, 0, 127, 0, 0, 0, 3, 126, 0, 0,
                 128, 4, 1, 0>>
    end

    test "NodeChange bytes match OpenPencil TypeScript codec" do
      node_change = %NodeChange{
        guid: %GUID{session_id: 12, local_id: 34},
        type: :rectangle,
        name: "Rect 1",
        size: %Vector{x: 100.0, y: 50.0},
        fill_paints: [
          %Paint{type: :solid, color: %Color{r: 1.0, g: 0.0, b: 0.0, a: 1.0}, visible: true}
        ]
      }

      assert KiwiCodec.encode(node_change) ==
               <<1, 12, 34, 4, 10, 5, 82, 101, 99, 116, 32, 49, 0, 11, 133, 0, 0, 144, 132, 0, 0,
                 144, 38, 1, 1, 0, 2, 127, 0, 0, 0, 0, 0, 127, 0, 0, 0, 4, 1, 0, 0>>
    end

    test "Message with NodeChange bytes match OpenPencil TypeScript codec" do
      message = %Message{
        type: :node_changes,
        session_id: 12,
        node_changes: [
          %NodeChange{
            guid: %GUID{session_id: 12, local_id: 34},
            type: :rectangle,
            name: "Rect 1",
            size: %Vector{x: 100.0, y: 50.0}
          }
        ]
      }

      assert Figler.encode_message(message) ==
               <<1, 1, 2, 12, 4, 1, 1, 12, 34, 4, 10, 5, 82, 101, 99, 116, 32, 49, 0, 11, 133, 0,
                 0, 144, 132, 0, 0, 144, 0, 0>>
    end
  end

  test "decodes generated primitive structs through Elixir codec" do
    guid = struct(Figler.Schema.GUID, session_id: 12, local_id: 34)
    vector = struct(Figler.Schema.Vector, x: 100.0, y: 50.0)

    parent_index = struct(Figler.Schema.ParentIndex, guid: guid, position: "!")
    image = struct(Figler.Schema.Image, hash: <<1, 2, 3>>, name: "Preview", data_blob: 7)
    partial_image = struct(Figler.Schema.Image, name: "Preview")

    assert KiwiCodec.decode(KiwiCodec.encode(guid), Figler.Schema.GUID) == guid
    assert KiwiCodec.decode(KiwiCodec.encode(vector), Figler.Schema.Vector) == vector

    assert KiwiCodec.decode(KiwiCodec.encode(parent_index), Figler.Schema.ParentIndex) ==
             parent_index

    node_change =
      struct(Figler.Schema.NodeChange,
        guid: guid,
        phase: :created,
        parent_index: parent_index,
        type: :rectangle,
        name: "Rect 1",
        size: vector
      )

    message =
      struct(Figler.Schema.Message,
        type: :node_changes,
        session_id: 12,
        node_changes: [node_change]
      )

    partial_message = struct(Figler.Schema.Message, session_id: 12)
    unknown_enum_message = struct(Figler.Schema.Message, type: 999)

    assert KiwiCodec.decode(KiwiCodec.encode(image), Figler.Schema.Image) == image
    assert KiwiCodec.decode(KiwiCodec.encode(partial_image), Figler.Schema.Image) == partial_image

    assert KiwiCodec.decode(KiwiCodec.encode(node_change), Figler.Schema.NodeChange) ==
             node_change

    assert Figler.decode_message(KiwiCodec.encode(message)) == message
    assert Figler.decode_message(KiwiCodec.encode(partial_message)) == partial_message

    assert Figler.decode_message(KiwiCodec.encode(unknown_enum_message)) == unknown_enum_message
  end
end
