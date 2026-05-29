defmodule FigKiwi.OpenPencilCompatibilityTest do
  use ExUnit.Case, async: true

  alias FigKiwi.Schema.{Color, GUID, Message, NodeChange, Paint, Vector}

  test "minimal Message bytes match OpenPencil TypeScript codec" do
    message = %Message{type: :node_changes, session_id: 12, node_changes: []}

    assert FigKiwi.encode_message(message) == <<1, 1, 2, 12, 4, 0, 0>>
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
             <<1, 0, 2, 127, 0, 0, 0, 126, 0, 0, 0, 125, 0, 0, 0, 127, 0, 0, 0, 3, 126, 0, 0, 128,
               4, 1, 0>>
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

    assert FigKiwi.encode_message(message) ==
             <<1, 1, 2, 12, 4, 1, 1, 12, 34, 4, 10, 5, 82, 101, 99, 116, 32, 49, 0, 11, 133, 0, 0,
               144, 132, 0, 0, 144, 0, 0>>
  end
end
