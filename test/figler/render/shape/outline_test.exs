defmodule Figler.Render.Shape.OutlineTest do
  use ExUnit.Case, async: true

  alias Figler.Render.Shape.Outline

  @square [{0.0, 0.0}, {10.0, 0.0}, {10.0, 10.0}, {0.0, 10.0}]

  test "keeps sharp corners without a radius" do
    assert Outline.polygon(@square, 0.0, 0.0) == [
             {:move_to, 0.0, 0.0},
             {:line_to, 10.0, 0.0},
             {:line_to, 10.0, 10.0},
             {:line_to, 0.0, 10.0},
             :close
           ]
  end

  test "rounds each corner with a quarter arc tangent to both edges" do
    [{:move_to, x, y}, {:cubic_to, _, _, _, _, ex, ey} | _] = Outline.polygon(@square, 2.0, 0.0)

    assert_in_delta x, 0.0, 1.0e-9
    assert_in_delta y, 2.0, 1.0e-9
    assert_in_delta ex, 2.0, 1.0e-9
    assert_in_delta ey, 0.0, 1.0e-9
  end

  test "caps the radius so neighbouring corners fit along each edge" do
    commands = Outline.polygon(@square, 100.0, 0.0)

    # Every corner meets its neighbours mid-edge, leaving no straight lines.
    refute Enum.any?(commands, &match?({:line_to, _, _}, &1))
    assert Enum.count(commands, &match?({:cubic_to, _, _, _, _, _, _}, &1)) == 4
  end

  test "eases smoothed corners into their edges" do
    plain = Outline.polygon(@square, 2.0, 0.0)
    smoothed = Outline.polygon(@square, 2.0, 0.6)

    assert Enum.count(smoothed, &match?({:cubic_to, _, _, _, _, _, _}, &1)) >
             Enum.count(plain, &match?({:cubic_to, _, _, _, _, _, _}, &1))
  end
end
