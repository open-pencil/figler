defmodule Figler.Render.Skia.ShapeTest do
  use ExUnit.Case, async: true

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
end
