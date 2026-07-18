defmodule Figler.Render.Skia.Effects.Resolved do
  @moduledoc false

  defstruct group_opts: [], shape_opts: [], warnings: []

  @type t :: %__MODULE__{
          group_opts: keyword(),
          shape_opts: keyword(),
          warnings: [term()]
        }
end

defmodule Figler.Render.Skia.Effects do
  @moduledoc false
  @compile {:no_warn_undefined, [Skia.ImageFilter]}

  alias Figler.Render.Skia.Color
  alias Figler.Render.Skia.Effects.Resolved

  @blend_modes %{
    darken: :darken,
    multiply: :multiply,
    color_burn: :color_burn,
    lighten: :lighten,
    screen: :screen,
    linear_dodge: :plus,
    color_dodge: :color_dodge,
    overlay: :overlay,
    soft_light: :soft_light,
    hard_light: :hard_light,
    difference: :difference,
    exclusion: :exclusion,
    hue: :hue,
    saturation: :saturation,
    color: :color,
    luminosity: :luminosity
  }

  @spec resolve(Figler.Render.Node.t() | nil, number() | nil) :: Resolved.t()
  def resolve(nil, opacity), do: %Resolved{group_opts: opacity_opts(opacity)}

  def resolve(node, opacity) do
    {filter, effect_warnings} =
      node.effects
      |> Kernel.||([])
      |> Enum.reject(&(Map.get(&1, :visible) == false))
      |> Enum.reduce({nil, []}, &resolve_effect/2)

    {blend_mode, blend_warnings} = blend_mode(node.blend_mode)

    group_opts =
      opacity
      |> opacity_opts()
      |> maybe_put(:blend_mode, blend_mode)

    shape_opts = maybe_put([], :image_filter, filter)

    %Resolved{
      group_opts: group_opts,
      shape_opts: shape_opts,
      warnings: Enum.reverse(effect_warnings, blend_warnings)
    }
  end

  defp resolve_effect(%{type: :drop_shadow} = effect, {input, warnings}) do
    offset = Map.get(effect, :offset) || %{}
    radius = Map.get(effect, :radius) || 0.0

    filter =
      Skia.ImageFilter.drop_shadow(
        {Map.get(offset, :x) || 0.0, Map.get(offset, :y) || 0.0},
        radius / 2,
        Color.rgba(Map.get(effect, :color)),
        input: input
      )

    {filter, drop_shadow_warnings(effect, warnings)}
  end

  defp resolve_effect(%{type: :foreground_blur} = effect, {input, warnings}) do
    radius = Map.get(effect, :radius) || 0.0
    blur = Skia.ImageFilter.blur(radius / 2)
    filter = if input, do: Skia.ImageFilter.compose(blur, input), else: blur
    {filter, warnings}
  end

  defp resolve_effect(effect, {input, warnings}) do
    {input, [{:effect_unsupported, Map.get(effect, :type)} | warnings]}
  end

  defp drop_shadow_warnings(effect, warnings) do
    warnings =
      if (Map.get(effect, :spread) || 0.0) != 0.0,
        do: [:drop_shadow_spread_unsupported | warnings],
        else: warnings

    warnings =
      if Map.get(effect, :show_shadow_behind_node) == false,
        do: [:drop_shadow_cutout_unsupported | warnings],
        else: warnings

    case Map.get(effect, :blend_mode) do
      nil -> warnings
      :normal -> warnings
      mode -> [{:effect_blend_mode_unsupported, mode} | warnings]
    end
  end

  defp blend_mode(nil), do: {nil, []}
  defp blend_mode(:normal), do: {nil, []}
  defp blend_mode(:pass_through), do: {nil, []}
  defp blend_mode(:linear_burn), do: {nil, [{:blend_mode_unsupported, :linear_burn}]}

  defp blend_mode(mode) do
    case Map.fetch(@blend_modes, mode) do
      {:ok, skia_mode} -> {skia_mode, []}
      :error -> {nil, [{:blend_mode_unsupported, mode}]}
    end
  end

  defp opacity_opts(opacity) when is_number(opacity) and opacity < 1, do: [opacity: opacity]
  defp opacity_opts(_opacity), do: []

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)
end
