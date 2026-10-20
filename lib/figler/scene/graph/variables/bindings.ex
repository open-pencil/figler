defmodule Figler.Scene.Graph.Variables.Bindings do
  @moduledoc """
  Applies a layer's variable bindings to its effective record, following
  OpenPencil's document binding passes (`document/bindings/*.ts`).

  A record binds a field through a variable consumption entry that names a
  variable (an alias, a constant times an alias, or an alias wrapped in
  `STRINGIFY` or `IS_TRUTHY`); a later entry for the field without a variable
  clears the binding. A paint binds its color through `colorVar`.

  Resolved values are written back into the record's own fields:

    * numbers in placed units, multiplied by the binding's constant and the
      instance's uniform scale; opacity is a percentage. A width or height the
      file saved for an instance layer, or that an override sets, is kept;
    * paint colors, the variable's alpha becoming the paint's opacity;
    * text, which a binding sets even over an instance's literal override;
    * visibility, unless an instance override sets it.
  """

  alias Figler.Scene.Graph.Occurrence
  alias Figler.Scene.Graph.Occurrence.Claims
  alias Figler.Scene.Graph.Variables
  alias Figler.Scene.Graph.Variables.Formula

  # Kiwi's variable field for each bound record field.
  @numeric_fields %{
    corner_radius: :corner_radius,
    rectangle_top_left_corner_radius: :rectangle_top_left_corner_radius,
    rectangle_top_right_corner_radius: :rectangle_top_right_corner_radius,
    rectangle_bottom_left_corner_radius: :rectangle_bottom_left_corner_radius,
    rectangle_bottom_right_corner_radius: :rectangle_bottom_right_corner_radius,
    stroke_weight: :stroke_weight,
    border_top_weight: :border_top_weight,
    border_bottom_weight: :border_bottom_weight,
    border_left_weight: :border_left_weight,
    border_right_weight: :border_right_weight,
    stack_spacing: :stack_spacing,
    stack_padding_left: :stack_horizontal_padding,
    stack_padding_top: :stack_vertical_padding,
    stack_padding_right: :stack_padding_right,
    stack_padding_bottom: :stack_padding_bottom,
    stack_counter_spacing: :stack_counter_spacing,
    font_size: :font_size,
    opacity: :opacity,
    width: :width,
    height: :height,
    x_position: :x,
    y_position: :y,
    letter_spacing: :letter_spacing,
    line_height: :line_height
  }

  @value_fields [:visible, :text_data]
  @bindable Map.keys(@numeric_fields) ++ @value_fields

  @doc """
  The fields a record binds, by Kiwi variable field, each to
  `{variable, multiplier}`; paint colors as `{:fill_paints | :stroke_paints, index}`.
  """
  @spec bound(map(), Variables.t()) :: %{optional(term()) => {Variables.id(), number()}}
  def bound(record, vars) do
    fields =
      record
      |> Claims.consumption_entries()
      |> Enum.reduce(%{}, fn entry, bound -> bind_entry(entry, bound, vars) end)

    fields
    |> bind_paints(record, :fill_paints, vars)
    |> bind_paints(record, :stroke_paints, vars)
  end

  defp bind_entry(%{variable_field: field} = entry, bound, vars) when field in @bindable do
    data = Map.get(entry, :variable_data)

    case linear(data, 0) do
      {:ok, multiplier, reference} when reference != nil ->
        # A variable the document lacks still binds the field, to nothing.
        Map.put(bound, field, {Variables.reference(vars, reference), multiplier})

      _unbound ->
        if Map.get(data || %{}, :data_type) in [:alias, :expression],
          do: bound,
          else: Map.delete(bound, field)
    end
  end

  defp bind_entry(_entry, bound, _vars), do: bound

  # Only exact forms: an alias, a constant, a product of constants and one
  # alias, or an alias Figma converts to text or tests for visibility.
  defp linear(_data, depth) when depth > 64, do: :error

  defp linear(nil, _depth), do: :error

  defp linear(data, depth) do
    value = Map.get(data, :value) || %{}

    cond do
      alias_ref = Map.get(value, :alias) -> {:ok, 1, alias_ref}
      is_number(Map.get(value, :float_value)) -> {:ok, value.float_value, nil}
      expression = Map.get(value, :expression_value) -> linear_expression(expression, depth)
      true -> :error
    end
  end

  defp linear_expression(
         %{expression_function: function, expression_arguments: [argument]},
         _depth
       )
       when function in [:stringify, :is_truthy] do
    case get_in(argument, [:value, :alias]) do
      nil -> :error
      reference -> {:ok, 1, reference}
    end
  end

  defp linear_expression(
         %{expression_function: :multiply, expression_arguments: [_ | _] = factors},
         depth
       ) do
    Enum.reduce_while(factors, {:ok, 1, nil}, fn factor, {:ok, multiplier, reference} ->
      case linear(factor, depth + 1) do
        {:ok, term, nil} -> {:cont, {:ok, multiplier * term, reference}}
        {:ok, term, ref} when is_nil(reference) -> {:cont, {:ok, multiplier * term, ref}}
        _other -> {:halt, :error}
      end
    end)
  end

  defp linear_expression(_expression, _depth), do: :error

  defp bind_paints(bound, record, field, vars) do
    record
    |> Map.get(field)
    |> List.wrap()
    |> Stream.with_index()
    |> Enum.reduce(bound, fn {paint, index}, bound ->
      case Variables.reference(vars, get_in(paint, [:color_var, :value, :alias])) do
        nil -> bound
        id -> Map.put(bound, {field, index}, {id, 1})
      end
    end)
  end

  @doc """
  Writes the values a record's bindings resolve to in `modes` into the record.
  """
  @spec apply(map(), Occurrence.t(), Variables.modes(), Variables.t()) :: map()
  def apply(record, %Occurrence{} = occurrence, modes, vars) do
    record
    |> bound(vars)
    |> Enum.reduce(record, fn {field, {id, multiplier}}, record ->
      case id && Variables.resolve(vars, id, modes) do
        nil -> record
        value -> apply_value(record, field, value, multiplier, occurrence)
      end
    end)
  end

  defp apply_value(record, {paints, index}, %{r: _} = color, _multiplier, _occurrence) do
    case Enum.at(Map.get(record, paints), index) do
      nil ->
        record

      paint ->
        Map.put(record, paints, List.replace_at(record[paints], index, bound_color(paint, color)))
    end
  end

  defp apply_value(record, :text_data, value, _multiplier, _occurrence) do
    case {Map.get(record, :type), Formula.text(value)} do
      {:text, text} when is_binary(text) -> put_text(record, text)
      _other -> record
    end
  end

  defp apply_value(record, :visible, value, _multiplier, occurrence) do
    case Formula.truthy(value) do
      visible when is_boolean(visible) ->
        if MapSet.member?(occurrence.overridden, :visible),
          do: record,
          else: Map.put(record, :visible, visible)

      nil ->
        record
    end
  end

  defp apply_value(record, field, value, multiplier, occurrence) when is_number(value) do
    case Map.fetch(@numeric_fields, field) do
      {:ok, :opacity} ->
        Map.put(record, :opacity, value |> Kernel.*(0.01) |> max(0.0) |> min(1.0))

      {:ok, target} ->
        put_number(record, target, value * multiplier * occurrence.layout_scale, occurrence)

      :error ->
        record
    end
  end

  defp apply_value(record, _field, _value, _multiplier, _occurrence), do: record

  # A bound paint takes its whole color from the variable: RGB at full alpha,
  # and the variable's alpha as the paint's opacity.
  defp bound_color(paint, color) do
    paint
    |> Map.put(:color, %{color | a: 1.0})
    |> Map.put(:opacity, color.a)
  end

  defp put_text(record, text) do
    text_data = Map.get(record, :text_data) || %{}

    if Map.get(text_data, :characters) == text do
      record
    else
      record
      |> Map.put(:text_data, Map.put(text_data, :characters, text))
      |> Map.delete(:derived_text_data)
    end
  end

  defp put_number(record, axis, value, occurrence) when axis in [:width, :height] do
    claimed? = MapSet.member?(occurrence.overridden, :size)

    case Map.get(record, :size) do
      %{x: _, y: _} = size when occurrence.derived_size == nil and not claimed? ->
        key = if axis == :width, do: :x, else: :y
        Map.put(record, :size, Map.put(size, key, value))

      _saved ->
        record
    end
  end

  # Positions apply to unrotated layers, whose position is the matrix translation.
  defp put_number(record, axis, value, _occurrence) when axis in [:x, :y] do
    case Map.get(record, :transform) do
      %{m01: m01, m10: m10} = transform when m01 in [0, +0.0, -0.0] and m10 in [0, +0.0, -0.0] ->
        key = if axis == :x, do: :m02, else: :m12
        Map.put(record, :transform, Map.put(transform, key, value))

      _rotated ->
        record
    end
  end

  defp put_number(record, metric, value, _occurrence)
       when metric in [:letter_spacing, :line_height],
       do: Map.put(record, metric, %{value: value, units: :pixels})

  defp put_number(record, field, value, _occurrence), do: Map.put(record, field, value)
end
