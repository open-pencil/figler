defmodule Figler.Render.Skia.ShapeTest do
  use ExUnit.Case, async: true

  alias Figler.Render.CornerRadii
  alias Figler.Render.Node
  alias Figler.Render.Shape.Star
  alias Figler.Render.Skia.Shape

  test "uses primitive paths for effect and aligned-stroke silhouettes" do
    node = %Node{
      guid: {1, 1},
      source_guid: {1, 1},
      node_type: :star,
      size: %{x: 100.0, y: 80.0},
      shape: %Star{point_count: 5, inner_scale: 0.4}
    }

    document = Skia.canvas(100, 80)
    rendered = Shape.draw_silhouette(document, node, %{}, fill: :white)

    assert [%{op: :path, args: [%{__struct__: Skia.Path}]}] = Skia.commands(rendered)
    assert Shape.stroke_alignment_supported?(node)
    assert Shape.effect_shape_supported?(node)
  end

  test "uses one path for independent rectangular corners and their effect silhouette" do
    node = %Node{
      guid: {1, 2},
      source_guid: {1, 2},
      node_type: :rectangle,
      size: %{x: 100.0, y: 80.0},
      corners: %CornerRadii{
        top_left: 4.0,
        top_right: 8.0,
        bottom_right: 12.0,
        bottom_left: 16.0,
        independent?: true,
        smoothing: +0.0
      }
    }

    rendered = Shape.draw_silhouette(Skia.canvas(100, 80), node, %{}, fill: :white)
    assert [%{op: :path, args: [path]}] = Skia.commands(rendered)

    assert [
             {:move_to, 4.0, +0.0},
             {:line_to, 92.0, +0.0},
             {:r_arc_to, 8.0, 8.0, +0.0, {false, :cw, 8.0, 8.0}},
             {:line_to, 100.0, 68.0},
             {:r_arc_to, 12.0, 12.0, +0.0, {false, :cw, -12.0, 12.0}},
             {:line_to, 16.0, 80.0},
             {:r_arc_to, 16.0, 16.0, +0.0, {false, :cw, -16.0, -16.0}},
             {:line_to, +0.0, 4.0},
             {:r_arc_to, 4.0, 4.0, +0.0, {false, :cw, 4.0, -4.0}},
             :close
           ] = Skia.Path.segments(path)
  end

  test "recognizes every supported clipping container type" do
    for type <- [:frame, :instance, :symbol] do
      node = %Node{
        guid: {1, 4},
        source_guid: {1, 4},
        node_type: type,
        frame_mask_disabled: false
      }

      assert Node.clips_children?(node)
    end

    refute Node.clips_children?(%Node{
             guid: {1, 5},
             source_guid: {1, 5},
             node_type: :section,
             frame_mask_disabled: false
           })
  end

  test "rejects malformed rectangular corners instead of drawing them" do
    node = %Node{
      guid: {1, 3},
      source_guid: {1, 3},
      node_type: :rectangle,
      size: %{x: 100.0, y: 80.0},
      corners: CornerRadii.from_source(%{corner_radius: -1.0})
    }

    assert Shape.issues(node) == [
             %{code: :corner_radius_invalid, corner: :uniform, radius: -1.0}
           ]

    rendered = Shape.draw_silhouette(Skia.canvas(100, 80), node, %{}, fill: :white)
    assert Skia.commands(rendered) == []
  end
end
