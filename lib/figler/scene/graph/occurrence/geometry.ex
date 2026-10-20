defmodule Figler.Scene.Graph.Occurrence.Geometry do
  @moduledoc false

  # Placed geometry of an instance expansion: uniform scale, freeform resize
  # constraints, and the saved derived cache Figma keeps per layer path.

  alias Figler.Scene.Graph.Occurrence
  alias Figler.Scene.Graph.Occurrence.Fields

  @visual_lengths [
    :stroke_weight,
    :corner_radius,
    :rectangle_top_left_corner_radius,
    :rectangle_top_right_corner_radius,
    :rectangle_bottom_left_corner_radius,
    :rectangle_bottom_right_corner_radius
  ]

  @layout_distances [:stack_padding | Fields.layout_distances()]
  @text_lengths [:font_size, :line_height, :letter_spacing, :text_data, :derived_text_data]

  # Every field scaling touches. An instance record declares these in placed
  # space, so after its expansion is scaled the record's own values are restored.
  @scaled_fields @layout_distances ++
                   @visual_lengths ++
                   @text_lengths ++ [:dash_pattern, :effects, :size, :transform]

  @identity %{m00: 1.0, m01: 0.0, m02: 0.0, m10: 0.0, m11: 1.0, m12: 0.0}

  @spec uniform_scale(map()) :: number()
  def uniform_scale(record), do: get_in(record, [:symbol_data, :uniform_scale_factor]) || 1

  @doc """
  Scales an expansion from component space into the instance's placed space,
  then restores the distances the instance record itself declares.
  """
  @spec apply_layout_scale(Occurrence.t(), map()) :: Occurrence.t()
  def apply_layout_scale(root, source), do: scale_root(root, source, uniform_scale(source))

  defp scale_root(root, _source, 1), do: root
  defp scale_root(root, _source, 1.0), do: root

  defp scale_root(root, source, factor) when is_number(factor) and factor > 0 do
    root
    |> Occurrence.map_subtree(&scale_occurrence(&1, factor))
    |> restore_placed_fields(source)
  end

  defp scale_root(_root, _source, factor),
    do: raise(ArgumentError, "invalid instance uniform scale #{inspect(factor)}")

  defp restore_placed_fields(root, source) do
    restored = Map.take(source, @scaled_fields)
    %{root | properties: Map.merge(root.properties, restored)}
  end

  defp scale_occurrence(occurrence, factor) do
    properties =
      occurrence.properties
      |> scale_text_layout(factor)
      |> scale_numbers(@visual_lengths ++ @layout_distances, factor)
      |> update_present(:dash_pattern, fn dashes -> Enum.map(dashes, &(&1 * factor)) end)
      |> update_present(:effects, fn effects -> Enum.map(effects, &scale_effect(&1, factor)) end)
      |> update_present(:size, &scale_vector(&1, factor))
      |> update_present(:transform, fn transform ->
        %{transform | m02: transform.m02 * factor, m12: transform.m12 * factor}
      end)

    %{
      occurrence
      | properties: properties,
        layout_scale: occurrence.layout_scale * factor,
        derived_size: occurrence.derived_size && scale_vector(occurrence.derived_size, factor)
    }
  end

  defp scale_effect(effect, factor) do
    effect
    |> update_present(:offset, &scale_vector(&1, factor))
    |> scale_numbers([:radius, :spread], factor)
  end

  # Scales positional text data, not font identity or normalized glyph outlines.
  defp scale_text_layout(properties, factor) do
    properties
    |> scale_numbers([:font_size], factor)
    |> scale_pixel_value(:line_height, factor)
    |> scale_pixel_value(:letter_spacing, factor)
    |> update_present(:text_data, &scale_style_overrides(&1, factor))
    |> update_present(:derived_text_data, &scale_derived_text(&1, factor))
  end

  defp scale_style_overrides(text_data, factor) do
    update_present(text_data, :style_override_table, fn styles ->
      Enum.map(styles, &scale_text_layout(&1, factor))
    end)
  end

  defp scale_derived_text(derived, factor) do
    derived
    |> update_present(:layout_size, &scale_vector(&1, factor))
    |> scale_numbers([:truncated_height], factor)
    |> update_present(:glyphs, fn glyphs ->
      Enum.map(glyphs, fn glyph ->
        glyph
        |> update_present(:position, &scale_vector(&1, factor))
        |> scale_numbers([:font_size], factor)
      end)
    end)
    |> update_present(:baselines, fn baselines ->
      Enum.map(baselines, fn baseline ->
        baseline
        |> update_present(:position, &scale_vector(&1, factor))
        |> scale_numbers([:width, :line_height, :line_ascent, :line_y], factor)
      end)
    end)
  end

  defp scale_pixel_value(properties, field, factor) do
    case Map.get(properties, field) do
      %{units: :pixels, value: value} = metric ->
        Map.put(properties, field, %{metric | value: value * factor})

      _other ->
        properties
    end
  end

  @doc "Resizes an instance's freeform children from the component's scaled size to its own."
  @spec apply_placed_constraints(Occurrence.t(), Occurrence.t() | nil, map()) :: Occurrence.t()
  def apply_placed_constraints(root, base, source) do
    with %Occurrence{properties: %{size: base_size}} <- base,
         %{size: size} <- source do
      resize(root, scale_vector(base_size, uniform_scale(source)), size)
    else
      _no_size -> root
    end
  end

  defp resize(root, %{x: x, y: y}, %{x: x, y: y}), do: root

  defp resize(root, before_size, after_size) do
    auto_layout? = Map.get(root.properties, :stack_mode, :none) not in [nil, :none]

    %{
      root
      | children:
          Enum.map(root.children, &resize_child(&1, before_size, after_size, auto_layout?))
    }
  end

  defp resize_child(child, before_size, after_size, auto_layout?) do
    properties = child.properties

    cond do
      auto_layout? and Map.get(properties, :stack_positioning) != :absolute ->
        child

      not Map.has_key?(properties, :size) ->
        child

      true ->
        transform = Map.get(properties, :transform) || @identity
        size = properties.size

        {x, width} =
          constrained_axis(
            transform.m02,
            size.x,
            before_size.x,
            after_size.x,
            Map.get(properties, :horizontal_constraint)
          )

        {y, height} =
          constrained_axis(
            transform.m12,
            size.y,
            before_size.y,
            after_size.y,
            Map.get(properties, :vertical_constraint)
          )

        new_size = %{size | x: width, y: height}
        child = resize(child, size, new_size)

        properties =
          child.properties
          |> Map.put(:size, new_size)
          |> Map.put(:transform, %{transform | m02: x, m12: y})

        %{child | properties: properties}
    end
  end

  defp constrained_axis(position, size, before_size, after_size, constraint) do
    delta = after_size - before_size

    case constraint do
      :scale when before_size > 0 ->
        {position * (after_size / before_size), size * (after_size / before_size)}

      :max ->
        {position + delta, size}

      :center ->
        {position + delta / 2, size}

      :stretch ->
        {position, max(0, size + delta)}

      _fixed ->
        {position, size}
    end
  end

  @derived_fields [
    :derived_text_data,
    :font_size,
    :line_height,
    :letter_spacing,
    :size,
    :transform,
    :fill_geometry,
    :stroke_geometry,
    :vector_data
  ]

  @doc "Copies one saved derived entry onto its target; a cache, not a claim."
  @spec apply_derived_entry(Occurrence.t(), map()) :: Occurrence.t()
  def apply_derived_entry(target, entry) do
    derived =
      entry |> Map.take(@derived_fields) |> Map.reject(fn {_field, value} -> is_nil(value) end)

    %{
      target
      | properties: Map.merge(target.properties, derived),
        derived_size: Map.get(derived, :size, target.derived_size)
    }
  end

  defp scale_numbers(map, fields, factor) do
    Enum.reduce(fields, map, fn field, map ->
      case Map.get(map, field) do
        value when is_number(value) -> Map.put(map, field, value * factor)
        _other -> map
      end
    end)
  end

  defp scale_vector(%{x: x, y: y} = vector, factor), do: %{vector | x: x * factor, y: y * factor}

  defp update_present(map, field, fun) do
    case Map.get(map, field) do
      nil -> map
      value -> Map.put(map, field, fun.(value))
    end
  end
end
