defmodule Figler.Render.WarningTest do
  use ExUnit.Case, async: true

  alias Figler.Render.Warning

  test "normalizes map diagnostics into stable warning fields" do
    warning =
      Warning.new("1:2", :font, %{
        code: :font_substituted,
        requested: %{family: "Inter"},
        resolved: %{family: "Arial"}
      })

    assert %Warning{
             code: :font_substituted,
             feature: :font,
             guid: "1:2",
             severity: :substitution,
             context: %{
               requested: %{family: "Inter"},
               resolved: %{family: "Arial"}
             }
           } = warning
  end

  test "normalizes tuple and atom diagnostics while preserving their values" do
    tuple = Warning.new("1:2", :shape, {:shape_unsupported, :star})
    atom = Warning.new("1:2", :mask, :outline_mask_approximated)

    assert tuple.code == :shape_unsupported
    assert tuple.severity == :unsupported
    assert tuple.context == %{details: [:star]}
    assert tuple.value == {:shape_unsupported, :star}

    assert atom.code == :outline_mask_approximated
    assert atom.severity == :approximation
    assert atom.context == %{}
    assert atom.value == :outline_mask_approximated
  end

  test "classifies invalid and missing diagnostics" do
    assert Warning.new("1:2", :stroke, {:dash_pattern_invalid, [0.0]}).severity == :invalid
    assert Warning.new("1:2", :fill, :geometry_missing).severity == :missing
    assert Warning.new("1:2", :fill, :diamond_shader_compile_failed).severity == :invalid
  end
end
