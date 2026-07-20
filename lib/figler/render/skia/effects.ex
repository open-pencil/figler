defmodule Figler.Render.Skia.Effects.Resolved do
  @moduledoc false

  defstruct group_opts: [],
            shape_opts: [],
            background_blurs: [],
            inner_shadows: [],
            warnings: []

  @type t :: %__MODULE__{
          group_opts: keyword(),
          shape_opts: keyword(),
          background_blurs: [Figler.Render.Effect.t()],
          inner_shadows: [Figler.Render.Effect.t()],
          warnings: [term()]
        }
end

defmodule Figler.Render.Skia.Effects do
  @moduledoc false
  @compile {:no_warn_undefined, [Skia, Skia.ImageFilter]}

  alias Figler.Render.Node
  alias Figler.Render.Skia.Color
  alias Figler.Render.Skia.Effects.Resolved
  alias Figler.Render.Skia.Shape

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

  @spec resolve(Node.t() | map() | nil, number() | nil) :: Resolved.t()
  def resolve(nil, opacity), do: %Resolved{group_opts: opacity_opts(opacity)}

  def resolve(node, opacity) do
    {filter, background_blurs, inner_shadows, effect_warnings} =
      node.effects
      |> Kernel.||([])
      |> Enum.reject(&(Map.get(&1, :visible) == false))
      |> Enum.reduce({nil, [], [], []}, &resolve_effect(&1, node, &2))

    {blend_mode, blend_warnings} = blend_mode(node.blend_mode)

    group_opts =
      opacity
      |> opacity_opts()
      |> maybe_put(:blend_mode, blend_mode)

    %Resolved{
      group_opts: group_opts,
      shape_opts: maybe_put([], :image_filter, filter),
      background_blurs: Enum.reverse(background_blurs),
      inner_shadows: Enum.reverse(inner_shadows),
      warnings: Enum.reverse(effect_warnings, blend_warnings)
    }
  end

  @spec render_background_blurs(
          Skia.Document.t(),
          Node.t(),
          map(),
          Resolved.t()
        ) :: Skia.Document.t()
  def render_background_blurs(document, node, assets, resolved) do
    Enum.reduce(resolved.background_blurs, document, fn effect, rendered ->
      render_background_blur(rendered, node, assets, effect)
    end)
  end

  @spec render_inner_shadows(Skia.Document.t(), Node.t(), map(), Resolved.t()) ::
          Skia.Document.t()
  def render_inner_shadows(document, node, assets, resolved) do
    Enum.reduce(resolved.inner_shadows, document, fn effect, rendered ->
      render_inner_shadow(rendered, node, assets, effect)
    end)
  end

  defp resolve_effect(
         %{type: :drop_shadow} = effect,
         _node,
         {input, backgrounds, inner, warnings}
       ) do
    offset = Map.get(effect, :offset) || %{}
    radius = positive_number(Map.get(effect, :radius))
    spread = Map.get(effect, :spread) || 0.0

    filter =
      if spread == 0.0 do
        Skia.ImageFilter.drop_shadow(
          {Map.get(offset, :x) || 0.0, Map.get(offset, :y) || 0.0},
          radius / 2,
          effect_color(effect),
          input: input
        )
      else
        shadow_input = morphology_filter(spread, input)

        shadow =
          Skia.ImageFilter.drop_shadow(
            {Map.get(offset, :x) || 0.0, Map.get(offset, :y) || 0.0},
            radius / 2,
            effect_color(effect),
            input: shadow_input,
            shadow_only: true
          )

        Skia.ImageFilter.merge([input, shadow])
      end

    {filter, backgrounds, inner, effect_warnings(effect, :drop_shadow, warnings)}
  end

  defp resolve_effect(
         %{type: :foreground_blur} = effect,
         _node,
         {input, backgrounds, inner, warnings}
       ) do
    blur = Skia.ImageFilter.blur(positive_number(Map.get(effect, :radius)) / 2)
    filter = if input, do: Skia.ImageFilter.compose(blur, input), else: blur
    {filter, backgrounds, inner, effect_warnings(effect, :foreground_blur, warnings)}
  end

  defp resolve_effect(
         %{type: :background_blur} = effect,
         node,
         {input, backgrounds, inner, warnings}
       ) do
    warnings = effect_shape_warnings(effect, node, :background_blur, warnings)
    {input, [effect | backgrounds], inner, warnings}
  end

  defp resolve_effect(
         %{type: :inner_shadow} = effect,
         node,
         {input, backgrounds, inner, warnings}
       ) do
    warnings = effect_shape_warnings(effect, node, :inner_shadow, warnings)
    {input, backgrounds, [effect | inner], warnings}
  end

  defp resolve_effect(effect, _node, {input, backgrounds, inner, warnings}) do
    {input, backgrounds, inner, [{:effect_unsupported, Map.get(effect, :type)} | warnings]}
  end

  defp render_background_blur(document, node, assets, effect) do
    if Shape.effect_shape_supported?(node) do
      bounds = local_bounds(node)
      sigma = positive_number(Map.get(effect, :radius)) / 2

      Skia.layer(
        document,
        [bounds: bounds, backdrop_filter: Skia.ImageFilter.blur(sigma)],
        &mask_effect_shape(&1, node, assets, bounds)
      )
    else
      document
    end
  end

  defp render_inner_shadow(document, node, assets, effect) do
    if Shape.effect_shape_supported?(node) do
      bounds = inner_shadow_bounds(node, effect)
      offset = Map.get(effect, :offset) || %{}
      translate = {Map.get(offset, :x) || 0.0, Map.get(offset, :y) || 0.0}
      spread = inner_shadow_spread(node, effect)
      shadow_opts = inner_shadow_layer_opts(bounds, effect)

      Skia.layer(document, [bounds: bounds], fn isolated ->
        draw_inner_shadow_layer(
          isolated,
          node,
          assets,
          effect,
          bounds,
          translate,
          spread,
          shadow_opts
        )
      end)
    else
      document
    end
  end

  defp draw_inner_shadow_layer(
         isolated,
         node,
         assets,
         effect,
         bounds,
         translate,
         spread,
         shadow_opts
       ) do
    isolated =
      Skia.layer(isolated, shadow_opts, fn shadow_layer ->
        draw_inner_shadow_source(
          shadow_layer,
          node,
          assets,
          effect,
          bounds,
          translate,
          spread
        )
      end)

    mask_effect_shape(isolated, node, assets, bounds)
  end

  defp draw_inner_shadow_source(
         shadow_layer,
         node,
         assets,
         effect,
         {x, y, width, height} = bounds,
         translate,
         spread
       ) do
    shadow_layer
    |> Skia.rect(x: x, y: y, width: width, height: height, fill: effect_color(effect))
    |> Skia.group([translate: translate], fn shifted ->
      clear_inner_shadow_hole(shifted, node, assets, bounds, spread)
    end)
  end

  defp clear_inner_shadow_hole(document, node, assets, bounds, spread)
       when node.node_type in [:vector, :boolean_operation, :text] and spread != 0.0 do
    filter =
      if spread > 0,
        do: Skia.ImageFilter.erode(spread),
        else: Skia.ImageFilter.dilate(abs(spread))

    Skia.layer(
      document,
      [bounds: bounds, image_filter: filter, blend_mode: :dst_out],
      &Shape.draw_silhouette(&1, node, assets, fill: :black)
    )
  end

  defp clear_inner_shadow_hole(document, node, assets, _bounds, spread) do
    Shape.draw_silhouette(
      document,
      node,
      assets,
      [fill: :black, blend_mode: :clear],
      inset: spread
    )
  end

  defp mask_effect_shape(document, node, assets, bounds) do
    Skia.layer(document, [bounds: bounds, blend_mode: :dst_in], fn mask ->
      Shape.draw_silhouette(mask, node, assets, fill: :white)
    end)
  end

  defp inner_shadow_layer_opts(bounds, effect) do
    sigma = positive_number(Map.get(effect, :radius)) / 2

    if sigma > 0,
      do: [bounds: bounds, image_filter: Skia.ImageFilter.blur(sigma)],
      else: [bounds: bounds]
  end

  defp inner_shadow_bounds(%{size: %{x: width, y: height}}, effect) do
    offset = Map.get(effect, :offset) || %{}
    radius = positive_number(Map.get(effect, :radius))
    spread = abs(Map.get(effect, :spread) || 0.0)

    padding =
      radius * 2 + spread + max(abs(Map.get(offset, :x) || 0.0), abs(Map.get(offset, :y) || 0.0))

    {-padding, -padding, width + padding * 2, height + padding * 2}
  end

  defp local_bounds(%{size: %{x: width, y: height}}), do: {0.0, 0.0, width, height}

  defp inner_shadow_spread(_node, effect), do: Map.get(effect, :spread) || 0.0

  defp morphology_filter(spread, input) when spread > 0,
    do: Skia.ImageFilter.dilate(spread, input: input)

  defp morphology_filter(spread, input),
    do: Skia.ImageFilter.erode(abs(spread), input: input)

  defp effect_shape_warnings(effect, node, type, warnings) do
    warnings = effect_warnings(effect, type, warnings)

    if Shape.effect_shape_supported?(node),
      do: warnings,
      else: [{:effect_shape_unsupported, type, node.node_type} | warnings]
  end

  defp effect_warnings(effect, :drop_shadow, warnings) do
    warnings =
      if Map.get(effect, :show_shadow_behind_node) == false,
        do: [:drop_shadow_cutout_unsupported | warnings],
        else: warnings

    common_effect_warnings(effect, :drop_shadow, warnings)
  end

  defp effect_warnings(effect, type, warnings),
    do: common_effect_warnings(effect, type, warnings)

  defp common_effect_warnings(effect, type, warnings) do
    warnings =
      case Map.get(effect, :radius) do
        radius when is_number(radius) and radius < 0 ->
          [{:effect_radius_invalid, type, radius} | warnings]

        _radius ->
          warnings
      end

    case Map.get(effect, :blend_mode) do
      nil -> warnings
      :normal -> warnings
      mode -> [{:effect_blend_mode_unsupported, mode} | warnings]
    end
  end

  defp effect_color(effect),
    do: Color.rgba(Map.get(effect, :color), Map.get(effect, :opacity) || 1.0)

  defp positive_number(value) when is_number(value), do: max(value, 0.0)
  defp positive_number(_value), do: 0.0

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
