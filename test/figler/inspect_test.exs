defmodule Figler.InspectTest do
  use ExUnit.Case, async: true

  alias Figler.Scene
  alias Figler.Scene.Graph
  alias Figler.Scene.Summary

  test "inspects compact schema structs" do
    guid = struct(Figler.Schema.GUID, session_id: 12, local_id: 34)
    parent = struct(Figler.Schema.ParentIndex, guid: guid, position: "!")
    vector = struct(Figler.Schema.Vector, x: 100.0, y: 50.0)

    matrix =
      struct(Figler.Schema.Matrix, m00: 1.0, m01: 0.0, m02: 10.0, m10: 0.0, m11: 1.0, m12: 20.0)

    assert inspect(guid) == "#Figler.Schema.GUID<12:34>"

    assert inspect(parent) ==
             "#Figler.Schema.ParentIndex<parent=#Figler.Schema.GUID<12:34> pos=!>"

    assert inspect(vector) == "#Figler.Schema.Vector<x=100.0 y=50.0>"
    assert inspect(matrix) == "#Figler.Schema.Matrix<1.0,0.0,10.0,0.0,1.0,20.0>"
  end

  test "inspects node changes without dumping hundreds of nil fields" do
    node =
      struct(Figler.Schema.NodeChange,
        guid: struct(Figler.Schema.GUID, session_id: 12, local_id: 34),
        parent_index:
          struct(Figler.Schema.ParentIndex,
            guid: struct(Figler.Schema.GUID, session_id: 0, local_id: 1),
            position: "!"
          ),
        type: :rectangle,
        name: "Rect 1"
      )

    assert inspect(node) ==
             "#Figler.Schema.NodeChange<rectangle \"Rect 1\" guid=12:34 parent=0:1 present=4/590>"
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
             "#Figler.Scene.Node<canvas \"Page 1\" 0:1 parent=0:0 pos=! size=100.0x50.0 visible=true locked=false children=1>"

    summary = %Summary{
      node_count: 10,
      parented_count: 9,
      root_count: 1,
      type_counts: [{"canvas", 1}]
    }

    assert inspect(summary) == "#Figler.Scene.Summary<nodes=10 roots=1 parented=9 types=1>"

    graph = %Graph{
      resource: make_ref(),
      mode: :projected,
      stages: [:populate_instances, :symbol_overrides],
      stats: %{resolver: :projected_index}
    }

    assert inspect(graph) ==
             "#Figler.Scene.Graph<mode=projected stages=2 resolver=projected_index>"
  end
end
