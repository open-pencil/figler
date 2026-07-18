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

  test "reports effects that cannot be represented faithfully" do
    source = %{
      blend_mode: :linear_burn,
      effects: [
        %{type: :inner_shadow, visible: true},
        %{type: :background_blur, visible: true},
        %{
          type: :drop_shadow,
          visible: true,
          spread: 4.0,
          show_shadow_behind_node: false,
          blend_mode: :overlay
        }
      ]
    }

    warnings = Effects.resolve(source, 1.0).warnings
    assert {:blend_mode_unsupported, :linear_burn} in warnings
    assert {:effect_unsupported, :inner_shadow} in warnings
    assert {:effect_unsupported, :background_blur} in warnings
    assert :drop_shadow_spread_unsupported in warnings
    assert :drop_shadow_cutout_unsupported in warnings
    assert {:effect_blend_mode_unsupported, :overlay} in warnings
  end
end
