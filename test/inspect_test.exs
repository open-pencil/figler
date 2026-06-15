defmodule FigKiwi.InspectTest do
  use ExUnit.Case, async: true

  alias FigKiwi.Scene
  alias FigKiwi.Scene.Summary

  test "inspects compact schema structs" do
    guid = struct(FigKiwi.Schema.GUID, session_id: 12, local_id: 34)
    parent = struct(FigKiwi.Schema.ParentIndex, guid: guid, position: "!")
    vector = struct(FigKiwi.Schema.Vector, x: 100.0, y: 50.0)

    matrix =
      struct(FigKiwi.Schema.Matrix, m00: 1.0, m01: 0.0, m02: 10.0, m10: 0.0, m11: 1.0, m12: 20.0)

    assert inspect(guid) == "#FigKiwi.Schema.GUID<12:34>"

    assert inspect(parent) ==
             "#FigKiwi.Schema.ParentIndex<parent=#FigKiwi.Schema.GUID<12:34> pos=!>"

    assert inspect(vector) == "#FigKiwi.Schema.Vector<x=100.0 y=50.0>"
    assert inspect(matrix) == "#FigKiwi.Schema.Matrix<1.0,0.0,10.0,0.0,1.0,20.0>"
  end

  test "inspects node changes without dumping hundreds of nil fields" do
    node =
      struct(FigKiwi.Schema.NodeChange,
        guid: struct(FigKiwi.Schema.GUID, session_id: 12, local_id: 34),
        parent_index:
          struct(FigKiwi.Schema.ParentIndex,
            guid: struct(FigKiwi.Schema.GUID, session_id: 0, local_id: 1),
            position: "!"
          ),
        type: :rectangle,
        name: "Rect 1"
      )

    assert inspect(node) ==
             "#FigKiwi.Schema.NodeChange<rectangle \"Rect 1\" guid=12:34 parent=0:1 present=4/590>"
  end

  test "inspects projected scene structs" do
    node = %Scene.Node{
      guid: "0:1",
      node_type: "canvas",
      name: "Page 1",
      parent_guid: "0:0",
      position: "!",
      size: %{x: 100.0, y: 50.0},
      visible: true,
      locked: false,
      children: [%Scene.Node{guid: "0:2", node_type: "rectangle"}]
    }

    assert inspect(node) ==
             "#FigKiwi.Scene.Node<canvas \"Page 1\" 0:1 parent=0:0 pos=! size=100.0x50.0 visible=true locked=false children=1>"

    summary = %Summary{
      node_count: 10,
      parented_count: 9,
      root_count: 1,
      type_counts: [{"canvas", 1}]
    }

    assert inspect(summary) == "#FigKiwi.Scene.Summary<nodes=10 roots=1 parented=9 types=1>"
  end
end
