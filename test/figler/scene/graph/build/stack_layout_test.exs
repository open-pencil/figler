defmodule Figler.Scene.Graph.Build.StackLayoutTest do
  use ExUnit.Case, async: true

  alias Figler.Scene

  import Figler.Test.GraphBuilder

  test "positions visible horizontal stack children from left padding and spacing" do
    graph =
      [
        node({1, 1}, :frame,
          stack_mode: :horizontal,
          stack_horizontal_padding: 10.0,
          stack_spacing: 4.0,
          size: %{x: 100.0, y: 20.0}
        ),
        node({1, 2}, :rectangle,
          parent_guid: {1, 1},
          size: %{x: 8.0, y: 8.0},
          transform: %{m00: 1.0, m01: 0.0, m02: 0.0, m10: 0.0, m11: 1.0, m12: 0.0},
          visible: false
        ),
        node({1, 3}, :text,
          parent_guid: {1, 1},
          text: "Label",
          size: %{x: 20.0, y: 8.0},
          transform: %{m00: 1.0, m01: 0.0, m02: 0.0, m10: 0.0, m11: 1.0, m12: 0.0}
        ),
        node({1, 4}, :vector,
          parent_guid: {1, 1},
          size: %{x: 6.0, y: 8.0},
          transform: %{m00: 1.0, m01: 0.0, m02: 0.0, m10: 0.0, m11: 1.0, m12: 0.0}
        )
      ]
      |> resolve(stages: [:stack_layout])

    assert graph.stack_seed_guids == [{1, 1}]
    assert Scene.node(graph, "1:3").transform.m02 == 10.0
    assert Scene.node(graph, "1:4").transform.m02 == 34.0
  end
end
