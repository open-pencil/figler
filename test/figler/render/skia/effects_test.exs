defmodule Figler.Render.Skia.EffectsTest do
  use ExUnit.Case, async: true

  alias Figler.Render.Skia.Effects

  test "builds blend, opacity, drop-shadow, and foreground-blur layers" do
    source = %{
      blend_mode: :screen,
      effects: [
        %{
          type: :drop_shadow,
          visible: true,
          radius: 8.0,
          offset: %{x: 3.0, y: 4.0},
          color: %{r: 0.0, g: 0.0, b: 0.0, a: 0.5},
          blend_mode: :normal
        },
        %{type: :foreground_blur, visible: true, radius: 6.0}
      ]
    }

    resolved = Effects.resolve(source, 0.75)
    assert resolved.group_opts == [blend_mode: :screen, opacity: 0.75]

    assert %Skia.ImageFilter.Compose{
             outer: %Skia.ImageFilter.Blur{sigma_x: 3.0, sigma_y: 3.0},
             inner: %Skia.ImageFilter.DropShadow{dx: 3.0, dy: 4.0, sigma_x: 4.0}
           } = resolved.shape_opts[:image_filter]

    assert resolved.warnings == []
  end

  test "separates front and backdrop effects and reports lossy policy" do
    inner_shadow = %{type: :inner_shadow, visible: true}
    background_blur = %{type: :background_blur, visible: true}

    source = %{
      node_type: :rectangle,
      blend_mode: :linear_burn,
      effects: [
        inner_shadow,
        background_blur,
        %{
          type: :drop_shadow,
          visible: true,
          spread: 4.0,
          show_shadow_behind_node: false,
          blend_mode: :overlay
        }
      ]
    }

    resolved = Effects.resolve(source, 1.0)
    assert resolved.inner_shadows == [inner_shadow]
    assert resolved.background_blurs == [background_blur]
    assert {:blend_mode_unsupported, :linear_burn} in resolved.warnings
    assert :drop_shadow_cutout_unsupported in resolved.warnings
    assert {:effect_blend_mode_unsupported, :overlay} in resolved.warnings
    refute :drop_shadow_spread_unsupported in resolved.warnings
  end

  test "models drop-shadow spread with morphology without altering the source" do
    source = %{
      node_type: :rectangle,
      blend_mode: :normal,
      effects: [
        %{
          type: :drop_shadow,
          visible: true,
          radius: 4.0,
          spread: 3.0,
          offset: %{x: 1.0, y: 2.0},
          color: %{r: 0.0, g: 0.0, b: 0.0, a: 0.5}
        }
      ]
    }

    resolved = Effects.resolve(source, 1.0)

    assert %Skia.ImageFilter.Merge{
             filters: [
               nil,
               %Skia.ImageFilter.DropShadow{
                 shadow_only: true,
                 input: %Skia.ImageFilter.Morphology{op: :dilate, radius_x: 3.0}
               }
             ]
           } = resolved.shape_opts[:image_filter]

    assert resolved.warnings == []
  end

  test "supports vector inner-shadow spread while diagnosing invalid radii" do
    source = %{
      node_type: :vector,
      blend_mode: :normal,
      effects: [
        %{type: :inner_shadow, visible: true, radius: -1.0, spread: 2.0}
      ]
    }

    warnings = Effects.resolve(source, 1.0).warnings
    assert {:effect_radius_invalid, :inner_shadow, -1.0} in warnings
    refute {:inner_shadow_spread_unsupported, 2.0} in warnings
    assert [%{spread: 2.0}] = Effects.resolve(source, 1.0).inner_shadows
  end

  test "rejects effects that require an unsupported shape mask" do
    source = %{
      node_type: :line,
      blend_mode: :normal,
      effects: [
        %{type: :inner_shadow, visible: true},
        %{type: :background_blur, visible: true}
      ]
    }

    warnings = Effects.resolve(source, 1.0).warnings
    assert {:effect_shape_unsupported, :inner_shadow, :line} in warnings
    assert {:effect_shape_unsupported, :background_blur, :line} in warnings
  end
end
