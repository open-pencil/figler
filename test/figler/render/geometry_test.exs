defmodule Figler.Render.GeometryTest do
  use ExUnit.Case, async: true

  alias Figler.Render.Geometry

  test "decodes Figma move, line, quadratic, cubic, and close commands" do
    blob =
      <<1, f32(1.0)::binary, f32(2.0)::binary, 2, f32(3.0)::binary, f32(4.0)::binary, 3,
        f32(5.0)::binary, f32(6.0)::binary, f32(7.0)::binary, f32(8.0)::binary, 4,
        f32(9.0)::binary, f32(10.0)::binary, f32(11.0)::binary, f32(12.0)::binary,
        f32(13.0)::binary, f32(14.0)::binary, 0>>

    assert {:ok, path} = Geometry.decode(blob)

    assert Skia.Path.segments(path) == [
             {:move_to, 1.0, 2.0},
             {:line_to, 3.0, 4.0},
             {:quad_to, 5.0, 6.0, 7.0, 8.0},
             {:cubic_to, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0},
             :close
           ]
  end

  test "resolves blob references and winding rules" do
    references = [%{commands_blob: 0, winding_rule: :odd}]
    blob = <<1, f32(0.0)::binary, f32(0.0)::binary, 0>>

    assert {:ok, [%{path: path, fill_rule: :even_odd, closed?: true}]} =
             Geometry.paths(references, [blob])

    assert Skia.Path.segments(path) == [{:move_to, 0.0, 0.0}, :close]
  end

  test "classifies open and compound closed geometry structurally" do
    open = <<1, f32(0.0)::binary, f32(0.0)::binary, 2, f32(10.0)::binary, f32(10.0)::binary>>

    compound =
      <<1, f32(0.0)::binary, f32(0.0)::binary, 2, f32(10.0)::binary, f32(0.0)::binary, 0, 1,
        f32(20.0)::binary, f32(20.0)::binary, 2, f32(30.0)::binary, f32(20.0)::binary, 0>>

    references = [
      %{commands_blob: 0, winding_rule: :nonzero},
      %{commands_blob: 1, winding_rule: :odd}
    ]

    assert {:ok, [%{closed?: false}, %{closed?: true}]} =
             Geometry.paths(references, [open, compound])
  end

  test "rejects malformed and unsupported commands" do
    assert {:error, {:malformed_geometry_command, 1}} = Geometry.decode(<<1, 0>>)
    assert {:error, {:unsupported_geometry_command, 9}} = Geometry.decode(<<9>>)
    assert {:error, :missing_geometry_blob} = Geometry.paths([%{commands_blob: 2}], [])
  end

  defp f32(value), do: <<value::little-float-size(32)>>
end
