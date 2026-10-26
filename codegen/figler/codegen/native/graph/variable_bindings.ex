defmodule Figler.Codegen.Native.Graph.VariableBindings do
  @moduledoc """
  Applies a layer's variable bindings to its effective record, for the native interpreter.

  Following OpenPencil's document binding passes, a record binds a field through a variable
  consumption entry that names a variable (an alias, a constant times an alias, or an alias
  wrapped in `STRINGIFY` or `IS_TRUTHY`); a later entry for the field without a variable clears
  the binding. A paint binds its color through `colorVar`. Resolved values are written back into
  the record's own fields.
  """

  use RustQ.Meta,
    callable_modules: [
      Figler.Codegen.Native.Graph.Occurrence,
      Figler.Codegen.Native.Graph.Claims,
      Figler.Codegen.Native.Graph.Variables
    ]

  alias Figler.Codegen.Native.Graph.Occurrence
  alias Figler.Codegen.Native.Graph.Variables
  alias Figler.Codegen.Native.Graph.Records
  alias KiwiCodec.RustlerGenerator.Records, as: Kiwi
  alias RustQ.Type, as: R

  # What a binding sets: a record field by its Kiwi variable field, or a paint's color.
  @typep bound_target ::
           R.hashable(
             R.enum(field: [R.u32()], fill_paint: [R.usize()], stroke_paint: [R.usize()])
           )

  @typep variable_binding :: %{
           required(:target) => bound_target(),
           required(:variable) => R.option(Records.guid_key()),
           required(:multiplier) => R.f64()
         }

  # A binding's exact form: a constant multiplier and the variable it names, if any.
  @typep linear :: %{
           required(:multiplier) => R.f64(),
           required(:reference) => R.option(Kiwi.kiwi_record())
         }

  @doc false
  @spec items() :: [term()]
  def items do
    __rustq_type_items__() ++
      RustQ.Meta.AST.functions!(__MODULE__, [
        :bindable?,
        :field_target,
        :paint_target,
        :argument_alias,
        :bound,
        :bind_entry,
        :put_binding,
        :linear,
        :linear_expression,
        :linear_product,
        :bind_paints,
        :apply_bindings,
        :apply_binding,
        :apply_paint,
        :apply_number,
        :put_text,
        :put_length,
        :put_position,
        :numeric_target,
        :color_record
      ])
  end

  @spec bindable?(R.u32()) :: R.bool()
  defrust bindable?(field) do
    field == Kiwi.VariableField.VISIBLE or field == Kiwi.VariableField.TEXT_DATA or
      numeric_target(field).is_some()
  end

  @spec field_target(R.u32()) :: bound_target()
  defrust(field_target(field), do: {:field, field})

  @spec paint_target(R.u32(), R.usize()) :: bound_target()
  defrust paint_target(field, index) do
    if field == Kiwi.NodeChange.FILL_PAINTS,
      do: {:fill_paint, index},
      else: {:stroke_paint, index}
  end

  # The fields a record binds, each to the variable it names and a multiplier.
  @spec bound(R.ref(Kiwi.kiwi_record()), R.ref(Variables.variables())) ::
          R.vec(variable_binding())
  defrust bound(record, vars) do
    bindings = Vec.new()

    for entry <- consumption_entries(record) do
      bind_entry(mut_ref(bindings), ref(entry), vars)
    end

    bind_paints(mut_ref(bindings), record, Kiwi.NodeChange.FILL_PAINTS, vars)
    bind_paints(mut_ref(bindings), record, Kiwi.NodeChange.STROKE_PAINTS, vars)
    bindings
  end

  @spec bind_entry(
          R.mut_ref(R.vec(variable_binding())),
          R.ref(Kiwi.kiwi_record()),
          R.ref(Variables.variables())
        ) ::
          R.unit()
  defrust bind_entry(bindings, entry, vars) do
    case entry.enum_value(Kiwi.VariableDataMapEntry.VARIABLE_FIELD) do
      {:some, field} when bindable?(field) ->
        data = entry.record(Kiwi.VariableDataMapEntry.VARIABLE_DATA)

        case data.and_then(fn data -> linear(data, 0) end) do
          {:some, %{multiplier: multiplier, reference: {:some, variable}}} ->
            # A variable the document lacks still binds the field, to nothing.
            put_binding(
              bindings,
              field_target(field),
              reference(vars, ref(variable)),
              multiplier
            )

          _ ->
            data_type = data.and_then(fn data -> data.enum_value(Kiwi.VariableData.DATA_TYPE) end)

            if data_type != some(Kiwi.VariableDataType.ALIAS) and
                 data_type != some(Kiwi.VariableDataType.EXPRESSION) do
              bindings.retain(fn binding -> binding.target != field_target(field) end)
            end
        end

      _ ->
        :ok
    end
  end

  @spec put_binding(
          R.mut_ref(R.vec(variable_binding())),
          bound_target(),
          R.option(Records.guid_key()),
          R.f64()
        ) ::
          R.unit()
  defrust put_binding(bindings, target, variable, multiplier) do
    binding =
      struct_literal(VariableBinding, target: target, variable: variable, multiplier: multiplier)

    case Enum.find_index(bindings, fn existing -> existing.target == binding.target end) do
      {:some, index} -> assign!(bindings[index], binding)
      :none -> bindings.push(binding)
    end
  end

  # Only exact forms: an alias, a constant, a product of constants and one alias, or an alias
  # Figma converts to text or tests for visibility.
  @spec linear(R.ref(Kiwi.kiwi_record()), R.u32()) :: R.option(linear())
  defrust linear(data, depth) do
    case data.record(Kiwi.VariableData.VALUE) do
      {:some, value} when depth <= 64 ->
        case {value.record(Kiwi.VariableAnyValue.ALIAS),
              value.float(Kiwi.VariableAnyValue.FLOAT_VALUE),
              value.record(Kiwi.VariableAnyValue.EXPRESSION_VALUE)} do
          {{:some, reference}, _number, _expression} ->
            some(struct_literal(Linear, multiplier: 1.0, reference: some(reference.clone())))

          {:none, {:some, number}, _expression} ->
            some(struct_literal(Linear, multiplier: cast(number, R.f64()), reference: nil))

          {:none, :none, {:some, expression}} ->
            linear_expression(expression, depth)

          _ ->
            nil
        end

      _ ->
        nil
    end
  end

  @spec linear_expression(R.ref(Kiwi.kiwi_record()), R.u32()) :: R.option(linear())
  defrust linear_expression(expression, depth) do
    arguments = expression.records(Kiwi.Expression.EXPRESSION_ARGUMENTS)

    case {expression.enum_value(Kiwi.Expression.EXPRESSION_FUNCTION), arguments.as_slice()} do
      {{:some, Kiwi.ExpressionFunction.STRINGIFY}, [argument]} ->
        argument_alias(argument)

      {{:some, Kiwi.ExpressionFunction.IS_TRUTHY}, [argument]} ->
        argument_alias(argument)

      {{:some, Kiwi.ExpressionFunction.MULTIPLY}, [_first | _rest]} ->
        linear_product(arguments.as_slice(), depth)

      _ ->
        nil
    end
  end

  @spec argument_alias(R.ref(Kiwi.kiwi_record())) :: R.option(linear())
  defrust argument_alias(argument) do
    argument.record(Kiwi.VariableData.VALUE)
    |> and_then(fn value -> value.record(Kiwi.VariableAnyValue.ALIAS) end)
    |> map(fn reference ->
      struct_literal(Linear, multiplier: 1.0, reference: some(reference.clone()))
    end)
  end

  # A product of constants and at most one variable.
  @spec linear_product(R.slice(R.ref(Kiwi.kiwi_record())), R.u32()) :: R.option(linear())
  defrust linear_product(factors, depth) do
    factors
    |> iter()
    |> try_fold(struct_literal(Linear, multiplier: 1.0, reference: nil), fn product, factor ->
      case linear(factor, depth + 1) do
        {:some, %{multiplier: term, reference: :none}} ->
          some(
            struct_literal(Linear,
              multiplier: product.multiplier * term,
              reference: product.reference.clone()
            )
          )

        {:some, %{multiplier: term, reference: {:some, reference}}}
        when product.reference.is_none() ->
          some(
            struct_literal(Linear,
              multiplier: product.multiplier * term,
              reference: some(reference)
            )
          )

        _ ->
          nil
      end
    end)
  end

  @spec bind_paints(
          R.mut_ref(R.vec(variable_binding())),
          R.ref(Kiwi.kiwi_record()),
          R.u32(),
          R.ref(Variables.variables())
        ) ::
          R.unit()
  defrust bind_paints(bindings, record, field, vars) do
    for {paint, index} <- Enum.with_index(record.records(field)) do
      reference =
        paint.record(Kiwi.Paint.COLOR_VAR)
        |> and_then(fn color -> color.record(Kiwi.VariableData.VALUE) end)
        |> and_then(fn value -> value.record(Kiwi.VariableAnyValue.ALIAS) end)
        |> and_then(fn variable -> reference(vars, variable) end)

      case reference do
        {:some, id} ->
          put_binding(bindings, paint_target(field, index), some(id), 1.0)

        :none ->
          :ok
      end
    end
  end

  # Writes the values a record's bindings resolve to in `modes` into the record.
  @spec apply_bindings(
          Kiwi.kiwi_record(),
          R.ref(Occurrence.occurrence()),
          R.ref(Variables.modes()),
          R.ref(Variables.variables())
        ) :: Kiwi.kiwi_record()
  defrust apply_bindings(record, occurrence, modes, vars) do
    bound(ref(record), vars)
    |> iter()
    |> fold(record, fn record, binding ->
      case binding.variable.and_then(fn id -> resolve_variable(vars, id, modes) end) do
        {:some, value} -> apply_binding(record, binding, ref(value), occurrence)
        :none -> record
      end
    end)
  end

  @spec apply_binding(
          Kiwi.kiwi_record(),
          R.ref(variable_binding()),
          R.ref(Variables.variable_value()),
          R.ref(Occurrence.occurrence())
        ) :: Kiwi.kiwi_record()
  defrust apply_binding(record, binding, value, occurrence) do
    case {ref(binding.target), value} do
      {{:fill_paint, index}, {:color, color}} ->
        apply_paint(record, Kiwi.NodeChange.FILL_PAINTS, index, color)

      {{:stroke_paint, index}, {:color, color}} ->
        apply_paint(record, Kiwi.NodeChange.STROKE_PAINTS, index, color)

      {{:field, Kiwi.VariableField.TEXT_DATA}, _value} ->
        case text(value) do
          {:some, text}
          when record.enum_value(Kiwi.NodeChange.TYPE) == some(Kiwi.NodeType.TEXT) ->
            put_text(record, ref(text))

          _ ->
            record
        end

      {{:field, Kiwi.VariableField.VISIBLE}, _value} ->
        case truthy(value) do
          {:some, visible}
          when not occurrence.overridden.contains(ref(Kiwi.NodeChange.VISIBLE)) ->
            record.put_bool(Kiwi.NodeChange.VISIBLE, visible)

          _ ->
            record
        end

      {{:field, field}, {:float, number}} ->
        apply_number(record, field, deref(number), binding.multiplier, occurrence)

      _ ->
        record
    end
  end

  # A bound paint takes its whole color from the variable: RGB at full alpha, and the
  # variable's alpha as the paint's opacity.
  @spec apply_paint(Kiwi.kiwi_record(), R.u32(), R.usize(), R.ref(Variables.color())) ::
          Kiwi.kiwi_record()
  defrust apply_paint(record, field, index, color) do
    paints = record.records(field) |> into_iter() |> cloned() |> collect()

    if index < paints.len() do
      paint =
        paints[index]
        |> put_record(Kiwi.Paint.COLOR, color_record(color))
        |> put_float(Kiwi.Paint.OPACITY, cast(color.a, R.f32()))

      assign!(paints[index], paint)
      record.put_records(field, paints)
    else
      record
    end
  end

  @spec color_record(R.ref(Variables.color())) :: Kiwi.kiwi_record()
  defrust color_record(color) do
    KiwiRecord.new(Kiwi.Definitions.COLOR)
    |> put_float(Kiwi.Color.R, cast(color.r, R.f32()))
    |> put_float(Kiwi.Color.G, cast(color.g, R.f32()))
    |> put_float(Kiwi.Color.B, cast(color.b, R.f32()))
    |> put_float(Kiwi.Color.A, 1.0)
  end

  # Numbers apply in placed units, scaled with the instance; opacity is a percentage.
  @spec apply_number(
          Kiwi.kiwi_record(),
          R.u32(),
          R.f64(),
          R.f64(),
          R.ref(Occurrence.occurrence())
        ) ::
          Kiwi.kiwi_record()
  defrust apply_number(record, field, value, multiplier, occurrence) do
    placed = value * multiplier * occurrence.layout_scale

    case {field, numeric_target(field)} do
      {Kiwi.VariableField.OPACITY, _target} ->
        record.put_float(Kiwi.NodeChange.OPACITY, cast((value * 0.01).clamp(0.0, 1.0), R.f32()))

      {Kiwi.VariableField.WIDTH, _target} ->
        put_length(record, Kiwi.Vector.X, placed, occurrence)

      {Kiwi.VariableField.HEIGHT, _target} ->
        put_length(record, Kiwi.Vector.Y, placed, occurrence)

      {Kiwi.VariableField.X_POSITION, _target} ->
        put_position(record, Kiwi.Matrix.M02, placed)

      {Kiwi.VariableField.Y_POSITION, _target} ->
        put_position(record, Kiwi.Matrix.M12, placed)

      {_field, {:some, target}}
      when target == Kiwi.NodeChange.LETTER_SPACING or target == Kiwi.NodeChange.LINE_HEIGHT ->
        record.put_record(
          target,
          KiwiRecord.new(Kiwi.Definitions.NUMBER)
          |> put_float(Kiwi.Number.VALUE, cast(placed, R.f32()))
          |> put_enum(Kiwi.Number.UNITS, Kiwi.NumberUnits.PIXELS, Kiwi.Definitions.NUMBER_UNITS)
        )

      {_field, {:some, target}} ->
        record.put_float(target, cast(placed, R.f32()))

      _ ->
        record
    end
  end

  @spec put_text(Kiwi.kiwi_record(), R.str()) :: Kiwi.kiwi_record()
  defrust put_text(record, text) do
    text_data =
      case record.record(Kiwi.NodeChange.TEXT_DATA) do
        {:some, text_data} -> text_data.clone()
        :none -> KiwiRecord.new(Kiwi.Definitions.TEXT_DATA)
      end

    if text_data.str(Kiwi.TextData.CHARACTERS) == some(text) do
      record
    else
      record
      |> put_record(Kiwi.NodeChange.TEXT_DATA, text_data.put_str(Kiwi.TextData.CHARACTERS, text))
      |> delete(Kiwi.NodeChange.DERIVED_TEXT_DATA)
    end
  end

  # A width or height the file saved for an instance layer, or that an override sets, is
  # kept.
  @spec put_length(Kiwi.kiwi_record(), R.u32(), R.f64(), R.ref(Occurrence.occurrence())) ::
          Kiwi.kiwi_record()
  defrust put_length(record, axis, value, occurrence) do
    case record.record(Kiwi.NodeChange.SIZE) do
      {:some, size}
      when occurrence.derived_size.is_none() and
             not occurrence.overridden.contains(ref(Kiwi.NodeChange.SIZE)) ->
        record.put_record(Kiwi.NodeChange.SIZE, size.put_float(axis, cast(value, R.f32())))

      _ ->
        record
    end
  end

  # Positions apply to unrotated layers, whose position is the matrix translation.
  @spec put_position(Kiwi.kiwi_record(), R.u32(), R.f64()) :: Kiwi.kiwi_record()
  defrust put_position(record, axis, value) do
    case record.record(Kiwi.NodeChange.TRANSFORM) do
      {:some, transform}
      when transform.float(Kiwi.Matrix.M01) == some(0.0) and
             transform.float(Kiwi.Matrix.M10) == some(0.0) ->
        record.put_record(
          Kiwi.NodeChange.TRANSFORM,
          transform.put_float(axis, cast(value, R.f32()))
        )

      _ ->
        record
    end
  end

  # The record field a numeric variable field writes.
  @spec numeric_target(R.u32()) :: R.option(R.u32())
  defrust numeric_target(field) do
    case field do
      Kiwi.VariableField.CORNER_RADIUS ->
        some(Kiwi.NodeChange.CORNER_RADIUS)

      Kiwi.VariableField.RECTANGLE_TOP_LEFT_CORNER_RADIUS ->
        some(Kiwi.NodeChange.RECTANGLE_TOP_LEFT_CORNER_RADIUS)

      Kiwi.VariableField.RECTANGLE_TOP_RIGHT_CORNER_RADIUS ->
        some(Kiwi.NodeChange.RECTANGLE_TOP_RIGHT_CORNER_RADIUS)

      Kiwi.VariableField.RECTANGLE_BOTTOM_LEFT_CORNER_RADIUS ->
        some(Kiwi.NodeChange.RECTANGLE_BOTTOM_LEFT_CORNER_RADIUS)

      Kiwi.VariableField.RECTANGLE_BOTTOM_RIGHT_CORNER_RADIUS ->
        some(Kiwi.NodeChange.RECTANGLE_BOTTOM_RIGHT_CORNER_RADIUS)

      Kiwi.VariableField.STROKE_WEIGHT ->
        some(Kiwi.NodeChange.STROKE_WEIGHT)

      Kiwi.VariableField.BORDER_TOP_WEIGHT ->
        some(Kiwi.NodeChange.BORDER_TOP_WEIGHT)

      Kiwi.VariableField.BORDER_BOTTOM_WEIGHT ->
        some(Kiwi.NodeChange.BORDER_BOTTOM_WEIGHT)

      Kiwi.VariableField.BORDER_LEFT_WEIGHT ->
        some(Kiwi.NodeChange.BORDER_LEFT_WEIGHT)

      Kiwi.VariableField.BORDER_RIGHT_WEIGHT ->
        some(Kiwi.NodeChange.BORDER_RIGHT_WEIGHT)

      Kiwi.VariableField.STACK_SPACING ->
        some(Kiwi.NodeChange.STACK_SPACING)

      Kiwi.VariableField.STACK_PADDING_LEFT ->
        some(Kiwi.NodeChange.STACK_HORIZONTAL_PADDING)

      Kiwi.VariableField.STACK_PADDING_TOP ->
        some(Kiwi.NodeChange.STACK_VERTICAL_PADDING)

      Kiwi.VariableField.STACK_PADDING_RIGHT ->
        some(Kiwi.NodeChange.STACK_PADDING_RIGHT)

      Kiwi.VariableField.STACK_PADDING_BOTTOM ->
        some(Kiwi.NodeChange.STACK_PADDING_BOTTOM)

      Kiwi.VariableField.STACK_COUNTER_SPACING ->
        some(Kiwi.NodeChange.STACK_COUNTER_SPACING)

      Kiwi.VariableField.FONT_SIZE ->
        some(Kiwi.NodeChange.FONT_SIZE)

      Kiwi.VariableField.OPACITY ->
        some(Kiwi.NodeChange.OPACITY)

      Kiwi.VariableField.WIDTH ->
        some(Kiwi.NodeChange.SIZE)

      Kiwi.VariableField.HEIGHT ->
        some(Kiwi.NodeChange.SIZE)

      Kiwi.VariableField.X_POSITION ->
        some(Kiwi.NodeChange.TRANSFORM)

      Kiwi.VariableField.Y_POSITION ->
        some(Kiwi.NodeChange.TRANSFORM)

      Kiwi.VariableField.LETTER_SPACING ->
        some(Kiwi.NodeChange.LETTER_SPACING)

      Kiwi.VariableField.LINE_HEIGHT ->
        some(Kiwi.NodeChange.LINE_HEIGHT)

      _ ->
        nil
    end
  end
end
