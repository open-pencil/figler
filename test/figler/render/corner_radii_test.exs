defmodule Figler.Render.CornerRadiiTest do
  use ExUnit.Case, async: true

  alias Figler.Render.CornerRadii

  test "uses the uniform radius unless independent corners are enabled" do
    assert %CornerRadii{
             top_left: 8.0,
             top_right: 8.0,
             bottom_right: 8.0,
             bottom_left: 8.0,
             independent?: false,
             smoothing: +0.0
           } =
             CornerRadii.from_source(%{
               corner_radius: 8.0,
               rectangle_top_left_corner_radius: 2.0
             })
  end

  test "normalizes enabled independent radii in Figma corner order" do
    assert %CornerRadii{
             top_left: 2.0,
             top_right: 4.0,
             bottom_right: 8.0,
             bottom_left: 6.0,
             independent?: true,
             smoothing: 0.25
           } =
             CornerRadii.from_source(%{
               corner_radius: 1.0,
               rectangle_top_left_corner_radius: 2.0,
               rectangle_top_right_corner_radius: 4.0,
               rectangle_bottom_left_corner_radius: 6.0,
               rectangle_bottom_right_corner_radius: 8.0,
               rectangle_corner_radii_independent: true,
               corner_smoothing: 0.25
             })
  end

  test "reports invalid radii and the documented smooth-corner approximation" do
    invalid = CornerRadii.from_source(%{corner_radius: -1.0})

    assert [%{code: :corner_radius_invalid, corner: :uniform, radius: -1.0}] =
             CornerRadii.warnings(invalid)

    smoothed = CornerRadii.from_source(%{corner_radius: 8.0, corner_smoothing: 0.5})

    assert CornerRadii.warnings(smoothed) == [
             %{code: :corner_smoothing_approximated, smoothing: 0.5}
           ]
  end
end
