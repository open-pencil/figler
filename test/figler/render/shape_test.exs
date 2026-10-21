defmodule Figler.Render.ShapeTest do
  use ExUnit.Case, async: true

  alias Figler.Render.Shape
  alias Figler.Render.Shape.Arc
  alias Figler.Render.Shape.Polygon
  alias Figler.Render.Shape.Star

  test "uses Figma primitive defaults when fields are absent" do
    assert Shape.from_source(:regular_polygon, %{}) == %Polygon{point_count: 5}
    assert Shape.from_source(:star, %{}) == %Star{point_count: 5, inner_scale: 0.38}
    assert Shape.from_source(:ellipse, %{}) == nil
  end

  test "normalizes sparse arc values" do
    assert Shape.arc_from_sparse(%{
             starting_angle: 0.25,
             ending_angle: 2.5,
             inner_radius: 0.4
           }) == %Arc{start_angle: 0.25, end_angle: 2.5, inner_radius: 0.4}
  end

  test "keeps point counts and star ratios within Figma's ranges" do
    assert Shape.from_source(:regular_polygon, %{count: 2}) == %Polygon{point_count: 3}

    assert Shape.from_source(:star, %{count: 10_001, star_inner_scale: 1.5}) ==
             %Star{point_count: 60, inner_scale: 1.0}

    assert Shape.issues(%Polygon{point_count: nil}) == [
             %{code: :polygon_point_count_invalid, point_count: nil}
           ]
  end

  test "reports malformed arc radii" do
    assert Shape.issues(%Arc{start_angle: 0.0, end_angle: 1.0, inner_radius: 1.0}) == [
             %{code: :arc_inner_radius_invalid, inner_radius: 1.0}
           ]
  end
end
