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
    rust_sources: [
      "deps/kiwi_codec/codegen/kiwi_codec/rustler_generator/templates/records_runtime.rs"
    ],
    callable_modules: [
      Figler.Codegen.Native.Graph.Occurrence,
      Figler.Codegen.Native.Graph.Claims,
      Figler.Codegen.Native.Graph.Variables
    ]

  alias Figler.Codegen.Native.Graph.Occurrence
  alias Figler.Codegen.Native.Graph.Variables
  alias RustQ.Type, as: R

  defrustmod NodeChange, as: [:kiwi_records, :node_change]
  defrustmod NodeType, as: [:kiwi_records, :node_type]
  defrustmod TextData, as: [:kiwi_records, :text_data]
  defrustmod Paint, as: [:kiwi_records, :paint]
  defrustmod ColorField, as: [:kiwi_records, :color]
  defrustmod Matrix, as: [:kiwi_records, :matrix]
  defrustmod Vector, as: [:kiwi_records, :vector]
  defrustmod NumberValue, as: [:kiwi_records, :number]
  defrustmod NumberUnits, as: [:kiwi_records, :number_units]
  defrustmod VariableData, as: [:kiwi_records, :variable_data]
  defrustmod VariableDataType, as: [:kiwi_records, :variable_data_type]
  defrustmod VariableAnyValue, as: [:kiwi_records, :variable_any_value]
  defrustmod VariableDataMapEntry, as: [:kiwi_records, :variable_data_map_entry]
  defrustmod VariableField, as: [:kiwi_records, :variable_field]
  defrustmod Expression, as: [:kiwi_records, :expression]
  defrustmod ExpressionFunction, as: [:kiwi_records, :expression_function]
  defrustmod Definitions, as: [:kiwi_record_definitions]

  # What a binding sets: a record field by its Kiwi variable field, or a paint's color.
  @typep bound_target ::
           R.hashable(
             R.enum(field: [R.u32()], fill_paint: [R.usize()], stroke_paint: [R.usize()])
           )

  @typep variable_binding :: %{
           required(:target) => bound_target(),
           required(:variable) => R.option(GuidKey.t()),
           required(:multiplier) => R.f64()
         }

  # A binding's exact form: a constant multiplier and the variable it names, if any.
  @typep linear :: %{
           required(:multiplier) => R.f64(),
           required(:reference) => R.option(KiwiRecord.t())
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
    field == VariableField.VISIBLE or field == VariableField.TEXT_DATA or
      numeric_target(field).is_some()
  end

  @spec field_target(R.u32()) :: bound_target()
  defrust(field_target(field), do: {:field, field})

  @spec paint_target(R.u32(), R.usize()) :: bound_target()
  defrust paint_target(field, index) do
    if field == NodeChange.FILL_PAINTS, do: {:fill_paint, index}, else: {:stroke_paint, index}
  end

  # The fields a record binds, each to the variable it names and a multiplier.
  @spec bound(R.ref(KiwiRecord.t()), R.ref(Variables.variables())) :: R.vec(variable_binding())
  defrust bound(record, vars) do
    bindings = Vec.new()

    for entry <- consumption_entries(record) do
      bind_entry(mut_ref(bindings), ref(entry), vars)
    end

    bind_paints(mut_ref(bindings), record, NodeChange.FILL_PAINTS, vars)
    bind_paints(mut_ref(bindings), record, NodeChange.STROKE_PAINTS, vars)
    bindings
  end

  @spec bind_entry(
          R.mut_ref(R.vec(variable_binding())),
          R.ref(KiwiRecord.t()),
          R.ref(Variables.variables())
        ) ::
          R.unit()
  defrust bind_entry(bindings, entry, vars) do
    case entry.enum_value(VariableDataMapEntry.VARIABLE_FIELD) do
      {:some, field} when bindable?(field) ->
        data = entry.record(VariableDataMapEntry.VARIABLE_DATA)

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
            data_type = data.and_then(fn data -> data.enum_value(VariableData.DATA_TYPE) end)

            if data_type != some(VariableDataType.ALIAS) and
                 data_type != some(VariableDataType.EXPRESSION) do
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
          R.option(GuidKey.t()),
          R.f64()
        ) ::
          R.unit()
  defrust put_binding(bindings, target, variable, multiplier) do
    binding =
      struct_literal(VariableBinding, target: target, variable: variable, multiplier: multiplier)

    case bindings.iter().position(fn existing -> existing.target == binding.target end) do
      {:some, index} -> assign!(bindings[index], binding)
      :none -> bindings.push(binding)
    end
  end

  # Only exact forms: an alias, a constant, a product of constants and one alias, or an alias
  # Figma converts to text or tests for visibility.
  @spec linear(R.ref(KiwiRecord.t()), R.u32()) :: R.option(linear())
  defrust linear(data, depth) do
    case data.record(VariableData.VALUE) do
      {:some, value} when depth <= 64 ->
        case {value.record(VariableAnyValue.ALIAS), value.float(VariableAnyValue.FLOAT_VALUE),
              value.record(VariableAnyValue.EXPRESSION_VALUE)} do
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

  @spec linear_expression(R.ref(KiwiRecord.t()), R.u32()) :: R.option(linear())
  defrust linear_expression(expression, depth) do
    arguments = expression.records(Expression.EXPRESSION_ARGUMENTS)

    case {expression.enum_value(Expression.EXPRESSION_FUNCTION), arguments.as_slice()} do
      {{:some, ExpressionFunction.STRINGIFY}, [argument]} ->
        argument_alias(argument)

      {{:some, ExpressionFunction.IS_TRUTHY}, [argument]} ->
        argument_alias(argument)

      {{:some, ExpressionFunction.MULTIPLY}, [_first | _rest]} ->
        linear_product(arguments.as_slice(), depth)

      _ ->
        nil
    end
  end

  @spec argument_alias(R.ref(KiwiRecord.t())) :: R.option(linear())
  defrust argument_alias(argument) do
    argument.record(VariableData.VALUE)
    |> and_then(fn value -> value.record(VariableAnyValue.ALIAS) end)
    |> map(fn reference ->
      struct_literal(Linear, multiplier: 1.0, reference: some(reference.clone()))
    end)
  end

  # A product of constants and at most one variable.
  @spec linear_product(R.slice(R.ref(KiwiRecord.t())), R.u32()) :: R.option(linear())
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
          R.ref(KiwiRecord.t()),
          R.u32(),
          R.ref(Variables.variables())
        ) ::
          R.unit()
  defrust bind_paints(bindings, record, field, vars) do
    for {index, paint} <- record.records(field).iter().enumerate() do
      reference =
        paint.record(Paint.COLOR_VAR)
        |> and_then(fn color -> color.record(VariableData.VALUE) end)
        |> and_then(fn value -> value.record(VariableAnyValue.ALIAS) end)
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
          KiwiRecord.t(),
          R.ref(Occurrence.occurrence()),
          R.ref(Variables.modes()),
          R.ref(Variables.variables())
        ) :: KiwiRecord.t()
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
          KiwiRecord.t(),
          R.ref(variable_binding()),
          R.ref(Variables.variable_value()),
          R.ref(Occurrence.occurrence())
        ) :: KiwiRecord.t()
  defrust apply_binding(record, binding, value, occurrence) do
    case {ref(binding.target), value} do
      {{:fill_paint, index}, {:color, color}} ->
        apply_paint(record, NodeChange.FILL_PAINTS, index, color)

      {{:stroke_paint, index}, {:color, color}} ->
        apply_paint(record, NodeChange.STROKE_PAINTS, index, color)

      {{:field, VariableField.TEXT_DATA}, _value} ->
        case text(value) do
          {:some, text} when record.enum_value(NodeChange.TYPE) == some(NodeType.TEXT) ->
            put_text(record, ref(text))

          _ ->
            record
        end

      {{:field, VariableField.VISIBLE}, _value} ->
        case truthy(value) do
          {:some, visible} when not occurrence.overridden.contains(ref(NodeChange.VISIBLE)) ->
            record.put_bool(NodeChange.VISIBLE, visible)

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
  @spec apply_paint(KiwiRecord.t(), R.u32(), R.usize(), R.ref(Variables.color())) ::
          KiwiRecord.t()
  defrust apply_paint(record, field, index, color) do
    paints = record.records(field) |> into_iter() |> cloned() |> collect()

    if index < paints.len() do
      paint =
        paints[index]
        |> put_record(Paint.COLOR, color_record(color))
        |> put_float(Paint.OPACITY, cast(color.a, R.f32()))

      assign!(paints[index], paint)
      record.put_records(field, paints)
    else
      record
    end
  end

  @spec color_record(R.ref(Variables.color())) :: KiwiRecord.t()
  defrust color_record(color) do
    KiwiRecord.new(Definitions.COLOR)
    |> put_float(ColorField.R, cast(color.r, R.f32()))
    |> put_float(ColorField.G, cast(color.g, R.f32()))
    |> put_float(ColorField.B, cast(color.b, R.f32()))
    |> put_float(ColorField.A, 1.0)
  end

  # Numbers apply in placed units, scaled with the instance; opacity is a percentage.
  @spec apply_number(KiwiRecord.t(), R.u32(), R.f64(), R.f64(), R.ref(Occurrence.occurrence())) ::
          KiwiRecord.t()
  defrust apply_number(record, field, value, multiplier, occurrence) do
    placed = value * multiplier * occurrence.layout_scale

    case {field, numeric_target(field)} do
      {VariableField.OPACITY, _target} ->
        record.put_float(NodeChange.OPACITY, cast((value * 0.01).clamp(0.0, 1.0), R.f32()))

      {VariableField.WIDTH, _target} ->
        put_length(record, Vector.X, placed, occurrence)

      {VariableField.HEIGHT, _target} ->
        put_length(record, Vector.Y, placed, occurrence)

      {VariableField.X_POSITION, _target} ->
        put_position(record, Matrix.M02, placed)

      {VariableField.Y_POSITION, _target} ->
        put_position(record, Matrix.M12, placed)

      {_field, {:some, target}}
      when target == NodeChange.LETTER_SPACING or target == NodeChange.LINE_HEIGHT ->
        record.put_record(
          target,
          KiwiRecord.new(Definitions.NUMBER)
          |> put_float(NumberValue.VALUE, cast(placed, R.f32()))
          |> put_enum(NumberValue.UNITS, NumberUnits.PIXELS, Definitions.NUMBER_UNITS)
        )

      {_field, {:some, target}} ->
        record.put_float(target, cast(placed, R.f32()))

      _ ->
        record
    end
  end

  @spec put_text(KiwiRecord.t(), R.str()) :: KiwiRecord.t()
  defrust put_text(record, text) do
    text_data =
      case record.record(NodeChange.TEXT_DATA) do
        {:some, text_data} -> text_data.clone()
        :none -> KiwiRecord.new(Definitions.TEXT_DATA)
      end

    if text_data.str(TextData.CHARACTERS) == some(text) do
      record
    else
      record
      |> put_record(NodeChange.TEXT_DATA, text_data.put_str(TextData.CHARACTERS, text))
      |> delete(NodeChange.DERIVED_TEXT_DATA)
    end
  end

  # A width or height the file saved for an instance layer, or that an override sets, is
  # kept.
  @spec put_length(KiwiRecord.t(), R.u32(), R.f64(), R.ref(Occurrence.occurrence())) ::
          KiwiRecord.t()
  defrust put_length(record, axis, value, occurrence) do
    case record.record(NodeChange.SIZE) do
      {:some, size}
      when occurrence.derived_size.is_none() and
             not occurrence.overridden.contains(ref(NodeChange.SIZE)) ->
        record.put_record(NodeChange.SIZE, size.put_float(axis, cast(value, R.f32())))

      _ ->
        record
    end
  end

  # Positions apply to unrotated layers, whose position is the matrix translation.
  @spec put_position(KiwiRecord.t(), R.u32(), R.f64()) :: KiwiRecord.t()
  defrust put_position(record, axis, value) do
    case record.record(NodeChange.TRANSFORM) do
      {:some, transform}
      when transform.float(Matrix.M01) == some(0.0) and transform.float(Matrix.M10) == some(0.0) ->
        record.put_record(NodeChange.TRANSFORM, transform.put_float(axis, cast(value, R.f32())))

      _ ->
        record
    end
  end

  # The record field a numeric variable field writes.
  @spec numeric_target(R.u32()) :: R.option(R.u32())
  defrust numeric_target(field) do
    case field do
      VariableField.CORNER_RADIUS ->
        some(NodeChange.CORNER_RADIUS)

      VariableField.RECTANGLE_TOP_LEFT_CORNER_RADIUS ->
        some(NodeChange.RECTANGLE_TOP_LEFT_CORNER_RADIUS)

      VariableField.RECTANGLE_TOP_RIGHT_CORNER_RADIUS ->
        some(NodeChange.RECTANGLE_TOP_RIGHT_CORNER_RADIUS)

      VariableField.RECTANGLE_BOTTOM_LEFT_CORNER_RADIUS ->
        some(NodeChange.RECTANGLE_BOTTOM_LEFT_CORNER_RADIUS)

      VariableField.RECTANGLE_BOTTOM_RIGHT_CORNER_RADIUS ->
        some(NodeChange.RECTANGLE_BOTTOM_RIGHT_CORNER_RADIUS)

      VariableField.STROKE_WEIGHT ->
        some(NodeChange.STROKE_WEIGHT)

      VariableField.BORDER_TOP_WEIGHT ->
        some(NodeChange.BORDER_TOP_WEIGHT)

      VariableField.BORDER_BOTTOM_WEIGHT ->
        some(NodeChange.BORDER_BOTTOM_WEIGHT)

      VariableField.BORDER_LEFT_WEIGHT ->
        some(NodeChange.BORDER_LEFT_WEIGHT)

      VariableField.BORDER_RIGHT_WEIGHT ->
        some(NodeChange.BORDER_RIGHT_WEIGHT)

      VariableField.STACK_SPACING ->
        some(NodeChange.STACK_SPACING)

      VariableField.STACK_PADDING_LEFT ->
        some(NodeChange.STACK_HORIZONTAL_PADDING)

      VariableField.STACK_PADDING_TOP ->
        some(NodeChange.STACK_VERTICAL_PADDING)

      VariableField.STACK_PADDING_RIGHT ->
        some(NodeChange.STACK_PADDING_RIGHT)

      VariableField.STACK_PADDING_BOTTOM ->
        some(NodeChange.STACK_PADDING_BOTTOM)

      VariableField.STACK_COUNTER_SPACING ->
        some(NodeChange.STACK_COUNTER_SPACING)

      VariableField.FONT_SIZE ->
        some(NodeChange.FONT_SIZE)

      VariableField.OPACITY ->
        some(NodeChange.OPACITY)

      VariableField.WIDTH ->
        some(NodeChange.SIZE)

      VariableField.HEIGHT ->
        some(NodeChange.SIZE)

      VariableField.X_POSITION ->
        some(NodeChange.TRANSFORM)

      VariableField.Y_POSITION ->
        some(NodeChange.TRANSFORM)

      VariableField.LETTER_SPACING ->
        some(NodeChange.LETTER_SPACING)

      VariableField.LINE_HEIGHT ->
        some(NodeChange.LINE_HEIGHT)

      _ ->
        nil
    end
  end
end
