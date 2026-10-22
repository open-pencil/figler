defmodule Figler.Codegen.Native.Graph.Geometry do
  @moduledoc """
  Placed geometry of an instance expansion, for the native interpreter: uniform scale, freeform
  resize constraints, and the saved derived cache Figma keeps per layer path.

  Arithmetic runs in `f64` and is stored back as the schema's `f32`.
  """

  use RustQ.Meta,
    rust_sources: [
      "deps/kiwi_codec/codegen/kiwi_codec/rustler_generator/templates/records_runtime.rs"
    ],
    callable_modules: [Figler.Codegen.Native.Graph.Occurrence]

  alias Figler.Codegen.Native.Graph.Occurrence
  alias RustQ.Type, as: R

  defrustmod NodeChange, as: [:kiwi_records, :node_change]
  defrustmod SymbolData, as: [:kiwi_records, :symbol_data]
  defrustmod TextData, as: [:kiwi_records, :text_data]
  defrustmod DerivedTextData, as: [:kiwi_records, :derived_text_data]
  defrustmod Glyph, as: [:kiwi_records, :glyph]
  defrustmod Baseline, as: [:kiwi_records, :baseline]
  defrustmod Effect, as: [:kiwi_records, :effect]
  defrustmod Vector, as: [:kiwi_records, :vector]
  defrustmod Matrix, as: [:kiwi_records, :matrix]
  defrustmod NumberValue, as: [:kiwi_records, :number]
  defrustmod NumberUnits, as: [:kiwi_records, :number_units]
  defrustmod ConstraintType, as: [:kiwi_records, :constraint_type]
  defrustmod StackMode, as: [:kiwi_records, :stack_mode]
  defrustmod StackPositioning, as: [:kiwi_records, :stack_positioning]
  defrustmod Definitions, as: [:kiwi_record_definitions]

  @doc false
  @spec items() :: [term()]
  def items do
    RustQ.Meta.AST.functions!(__MODULE__, [
      :visual_lengths,
      :layout_distances,
      :scaled_fields,
      :derived_fields,
      :uniform_scale,
      :apply_layout_scale,
      :scale_occurrence,
      :scale_properties,
      :scale_effect,
      :scale_text_layout,
      :scale_derived_text,
      :scale_glyph,
      :scale_baseline,
      :scale_pixel_value,
      :scale_numbers,
      :scale_vector,
      :scale_floats,
      :vector_size,
      :apply_placed_constraints,
      :resize,
      :resize_child,
      :resized_child,
      :constrained_axis,
      :identity_matrix,
      :apply_derived_entry
    ])
  end

  @spec visual_lengths() :: R.slice(R.u32(), R.lifetime(:static))
  defrust visual_lengths() do
    ref([
      NodeChange.STROKE_WEIGHT,
      NodeChange.CORNER_RADIUS,
      NodeChange.RECTANGLE_TOP_LEFT_CORNER_RADIUS,
      NodeChange.RECTANGLE_TOP_RIGHT_CORNER_RADIUS,
      NodeChange.RECTANGLE_BOTTOM_LEFT_CORNER_RADIUS,
      NodeChange.RECTANGLE_BOTTOM_RIGHT_CORNER_RADIUS
    ])
  end

  # Stack padding and spacing, which uniform scale treats as lengths.
  @spec layout_distances() :: R.slice(R.u32(), R.lifetime(:static))
  defrust layout_distances() do
    ref([
      NodeChange.STACK_PADDING,
      NodeChange.STACK_SPACING,
      NodeChange.STACK_COUNTER_SPACING,
      NodeChange.STACK_HORIZONTAL_PADDING,
      NodeChange.STACK_VERTICAL_PADDING,
      NodeChange.STACK_PADDING_RIGHT,
      NodeChange.STACK_PADDING_BOTTOM
    ])
  end

  # Every field scaling touches. An instance record declares these in placed space, so after
  # its expansion is scaled the record's own values are restored.
  @spec scaled_fields() :: R.slice(R.u32(), R.lifetime(:static))
  defrust scaled_fields() do
    ref([
      NodeChange.STACK_PADDING,
      NodeChange.STACK_SPACING,
      NodeChange.STACK_COUNTER_SPACING,
      NodeChange.STACK_HORIZONTAL_PADDING,
      NodeChange.STACK_VERTICAL_PADDING,
      NodeChange.STACK_PADDING_RIGHT,
      NodeChange.STACK_PADDING_BOTTOM,
      NodeChange.STROKE_WEIGHT,
      NodeChange.CORNER_RADIUS,
      NodeChange.RECTANGLE_TOP_LEFT_CORNER_RADIUS,
      NodeChange.RECTANGLE_TOP_RIGHT_CORNER_RADIUS,
      NodeChange.RECTANGLE_BOTTOM_LEFT_CORNER_RADIUS,
      NodeChange.RECTANGLE_BOTTOM_RIGHT_CORNER_RADIUS,
      NodeChange.FONT_SIZE,
      NodeChange.LINE_HEIGHT,
      NodeChange.LETTER_SPACING,
      NodeChange.TEXT_DATA,
      NodeChange.DERIVED_TEXT_DATA,
      NodeChange.DASH_PATTERN,
      NodeChange.EFFECTS,
      NodeChange.SIZE,
      NodeChange.TRANSFORM
    ])
  end

  # The fields a saved derived entry may carry.
  @spec derived_fields() :: R.slice(R.u32(), R.lifetime(:static))
  defrust derived_fields() do
    ref([
      NodeChange.DERIVED_TEXT_DATA,
      NodeChange.FONT_SIZE,
      NodeChange.LINE_HEIGHT,
      NodeChange.LETTER_SPACING,
      NodeChange.SIZE,
      NodeChange.TRANSFORM,
      NodeChange.FILL_GEOMETRY,
      NodeChange.STROKE_GEOMETRY,
      NodeChange.VECTOR_DATA
    ])
  end

  @spec uniform_scale(R.ref(KiwiRecord.t())) :: R.f64()
  defrust uniform_scale(record) do
    case record.record(NodeChange.SYMBOL_DATA).and_then(fn data ->
           data.float(SymbolData.UNIFORM_SCALE_FACTOR)
         end) do
      {:some, factor} -> cast(factor, R.f64())
      :none -> 1.0
    end
  end

  # Scales an expansion from component space into the instance's placed space, then restores
  # the distances the instance record itself declares.
  @spec apply_layout_scale(Occurrence.occurrence(), R.ref(KiwiRecord.t())) ::
          R.nif_result(Occurrence.occurrence())
  defrust apply_layout_scale(root, source) do
    factor = uniform_scale(source)

    cond do
      factor == 1.0 ->
        ok(root)

      factor > 0.0 ->
        scaled = scale_occurrence(root, factor)
        properties = scaled.properties.merge(ref(source.take(scaled_fields())))
        ok(%{scaled | properties: properties})

      true ->
        err(badarg())
    end
  end

  @spec scale_occurrence(Occurrence.occurrence(), R.f64()) :: Occurrence.occurrence()
  defrust scale_occurrence(occurrence, factor) do
    properties = scale_properties(ref(occurrence.properties), factor)
    derived_size = occurrence.derived_size.as_ref().map(fn size -> scale_vector(size, factor) end)
    layout_scale = occurrence.layout_scale * factor

    children =
      occurrence.children
      |> into_iter()
      |> map(fn child -> scale_occurrence(child, factor) end)
      |> collect()

    %{
      occurrence
      | properties: properties,
        derived_size: derived_size,
        layout_scale: layout_scale,
        children: children
    }
  end

  @spec scale_properties(R.ref(KiwiRecord.t()), R.f64()) :: KiwiRecord.t()
  defrust scale_properties(properties, factor) do
    scale_text_layout(properties, factor)
    |> scale_numbers(visual_lengths(), factor)
    |> scale_numbers(layout_distances(), factor)
    |> scale_floats(NodeChange.DASH_PATTERN, factor)
    |> map_records(NodeChange.EFFECTS, fn effect -> scale_effect(effect, factor) end)
    |> map_record(NodeChange.SIZE, fn size -> scale_vector(size, factor) end)
    |> map_record(NodeChange.TRANSFORM, fn transform ->
      scale_numbers(transform, ref([Matrix.M02, Matrix.M12]), factor)
    end)
  end

  @spec scale_effect(R.ref(KiwiRecord.t()), R.f64()) :: KiwiRecord.t()
  defrust scale_effect(effect, factor) do
    effect
    |> map_record(Effect.OFFSET, fn offset -> scale_vector(offset, factor) end)
    |> scale_numbers(ref([Effect.RADIUS, Effect.SPREAD]), factor)
  end

  # Scales positional text data, not font identity or normalized glyph outlines.
  @spec scale_text_layout(R.ref(KiwiRecord.t()), R.f64()) :: KiwiRecord.t()
  defrust scale_text_layout(properties, factor) do
    properties
    |> scale_numbers(ref([NodeChange.FONT_SIZE]), factor)
    |> scale_pixel_value(NodeChange.LINE_HEIGHT, factor)
    |> scale_pixel_value(NodeChange.LETTER_SPACING, factor)
    |> map_record(NodeChange.TEXT_DATA, fn text ->
      text.map_records(TextData.STYLE_OVERRIDE_TABLE, fn style ->
        scale_text_layout(style, factor)
      end)
    end)
    |> map_record(NodeChange.DERIVED_TEXT_DATA, fn derived ->
      scale_derived_text(derived, factor)
    end)
  end

  @spec scale_derived_text(R.ref(KiwiRecord.t()), R.f64()) :: KiwiRecord.t()
  defrust scale_derived_text(derived, factor) do
    derived
    |> map_record(DerivedTextData.LAYOUT_SIZE, fn size -> scale_vector(size, factor) end)
    |> scale_numbers(ref([DerivedTextData.TRUNCATED_HEIGHT]), factor)
    |> map_records(DerivedTextData.GLYPHS, fn glyph -> scale_glyph(glyph, factor) end)
    |> map_records(DerivedTextData.BASELINES, fn baseline -> scale_baseline(baseline, factor) end)
  end

  @spec scale_glyph(R.ref(KiwiRecord.t()), R.f64()) :: KiwiRecord.t()
  defrust scale_glyph(glyph, factor) do
    glyph
    |> map_record(Glyph.POSITION, fn position -> scale_vector(position, factor) end)
    |> scale_numbers(ref([Glyph.FONT_SIZE]), factor)
  end

  @spec scale_baseline(R.ref(KiwiRecord.t()), R.f64()) :: KiwiRecord.t()
  defrust scale_baseline(baseline, factor) do
    baseline
    |> map_record(Baseline.POSITION, fn position -> scale_vector(position, factor) end)
    |> scale_numbers(
      ref([Baseline.WIDTH, Baseline.LINE_HEIGHT, Baseline.LINE_ASCENT, Baseline.LINE_Y]),
      factor
    )
  end

  # A metric given in pixels scales; one given in percent or raw units does not.
  @spec scale_pixel_value(KiwiRecord.t(), R.u32(), R.f64()) :: KiwiRecord.t()
  defrust scale_pixel_value(properties, field, factor) do
    properties.map_record(field, fn metric ->
      if metric.enum_value(NumberValue.UNITS) == some(NumberUnits.PIXELS),
        do: scale_numbers(metric, ref([NumberValue.VALUE]), factor),
        else: metric.clone()
    end)
  end

  @spec scale_numbers(R.ref(KiwiRecord.t()), R.slice(R.u32()), R.f64()) :: KiwiRecord.t()
  defrust scale_numbers(record, fields, factor) do
    fields
    |> iter()
    |> fold(record.clone(), fn scaled, field ->
      case scaled.float(deref(field)) do
        {:some, value} ->
          scaled.put_float(deref(field), cast(cast(value, R.f64()) * factor, R.f32()))

        :none ->
          scaled
      end
    end)
  end

  @spec scale_vector(R.ref(KiwiRecord.t()), R.f64()) :: KiwiRecord.t()
  defrust(scale_vector(vector, factor),
    do: scale_numbers(vector, ref([Vector.X, Vector.Y]), factor)
  )

  @spec scale_floats(KiwiRecord.t(), R.u32(), R.f64()) :: KiwiRecord.t()
  defrust scale_floats(record, field, factor) do
    if record.has(field) do
      values =
        record.floats(field)
        |> into_iter()
        |> map(fn value -> cast(cast(value, R.f64()) * factor, R.f32()) end)
        |> collect()

      record.put_floats(field, values)
    else
      record
    end
  end

  @spec vector_size(R.ref(KiwiRecord.t())) :: {R.f64(), R.f64()}
  defrust vector_size(vector) do
    {cast(vector.float(Vector.X).unwrap_or(0.0), R.f64()),
     cast(vector.float(Vector.Y).unwrap_or(0.0), R.f64())}
  end

  # Resizes an instance's freeform children from the component's scaled size to its own.
  @spec apply_placed_constraints(
          Occurrence.occurrence(),
          R.option(R.ref(Occurrence.occurrence())),
          R.ref(KiwiRecord.t())
        ) :: Occurrence.occurrence()
  defrust apply_placed_constraints(root, base, source) do
    with {:some, base} <- base,
         {:some, base_size} <- base.properties.record(NodeChange.SIZE),
         {:some, size} <- source.record(NodeChange.SIZE) do
      {width, height} = vector_size(base_size)
      factor = uniform_scale(source)
      resize(root, {width * factor, height * factor}, vector_size(size))
    else
      _ -> root
    end
  end

  @spec resize(Occurrence.occurrence(), {R.f64(), R.f64()}, {R.f64(), R.f64()}) ::
          Occurrence.occurrence()
  defrust resize(root, before_size, after_size) do
    if before_size == after_size do
      root
    else
      auto_layout =
        case root.properties.enum_value(NodeChange.STACK_MODE) do
          {:some, StackMode.NONE} -> false
          {:some, _mode} -> true
          :none -> false
        end

      children =
        root.children
        |> into_iter()
        |> map(fn child -> resize_child(child, before_size, after_size, auto_layout) end)
        |> collect()

      %{root | children: children}
    end
  end

  @spec resize_child(Occurrence.occurrence(), {R.f64(), R.f64()}, {R.f64(), R.f64()}, R.bool()) ::
          Occurrence.occurrence()
  defrust resize_child(child, before_size, after_size, auto_layout) do
    absolute =
      child.properties.enum_value(NodeChange.STACK_POSITIONING) ==
        some(StackPositioning.ABSOLUTE)

    if (auto_layout and not absolute) or not child.properties.has(NodeChange.SIZE),
      do: child,
      else: resized_child(child, before_size, after_size)
  end

  @spec resized_child(Occurrence.occurrence(), {R.f64(), R.f64()}, {R.f64(), R.f64()}) ::
          Occurrence.occurrence()
  defrust resized_child(child, before_size, after_size) do
    transform =
      case child.properties.record(NodeChange.TRANSFORM) do
        {:some, transform} -> transform.clone()
        :none -> identity_matrix()
      end

    size =
      case child.properties.record(NodeChange.SIZE) do
        {:some, size} -> size.clone()
        :none -> KiwiRecord.new(Definitions.VECTOR)
      end

    {width, height} = vector_size(ref(size))
    {before_width, before_height} = before_size
    {after_width, after_height} = after_size

    {x, new_width} =
      constrained_axis(
        cast(transform.float(Matrix.M02).unwrap_or(0.0), R.f64()),
        width,
        before_width,
        after_width,
        child.properties.enum_value(NodeChange.HORIZONTAL_CONSTRAINT)
      )

    {y, new_height} =
      constrained_axis(
        cast(transform.float(Matrix.M12).unwrap_or(0.0), R.f64()),
        height,
        before_height,
        after_height,
        child.properties.enum_value(NodeChange.VERTICAL_CONSTRAINT)
      )

    child = resize(child, {width, height}, {new_width, new_height})

    new_size =
      size
      |> put_float(Vector.X, cast(new_width, R.f32()))
      |> put_float(Vector.Y, cast(new_height, R.f32()))

    placed =
      transform
      |> put_float(Matrix.M02, cast(x, R.f32()))
      |> put_float(Matrix.M12, cast(y, R.f32()))

    properties =
      child.properties
      |> put_record(NodeChange.SIZE, new_size)
      |> put_record(NodeChange.TRANSFORM, placed)

    %{child | properties: properties}
  end

  @spec constrained_axis(R.f64(), R.f64(), R.f64(), R.f64(), R.option(R.u32())) ::
          {R.f64(), R.f64()}
  defrust constrained_axis(position, size, before_size, after_size, constraint) do
    delta = after_size - before_size

    case constraint do
      {:some, ConstraintType.SCALE} when before_size > 0.0 ->
        {position * (after_size / before_size), size * (after_size / before_size)}

      {:some, ConstraintType.MAX} ->
        {position + delta, size}

      {:some, ConstraintType.CENTER} ->
        {position + delta / 2.0, size}

      {:some, ConstraintType.STRETCH} ->
        {position, (size + delta).max(0.0)}

      _ ->
        {position, size}
    end
  end

  @spec identity_matrix() :: KiwiRecord.t()
  defrust identity_matrix() do
    KiwiRecord.new(Definitions.MATRIX)
    |> put_float(Matrix.M00, 1.0)
    |> put_float(Matrix.M01, 0.0)
    |> put_float(Matrix.M02, 0.0)
    |> put_float(Matrix.M10, 0.0)
    |> put_float(Matrix.M11, 1.0)
    |> put_float(Matrix.M12, 0.0)
  end

  # Copies one saved derived entry onto its target; a cache, not a claim.
  @spec apply_derived_entry(R.mut_ref(Occurrence.occurrence()), R.ref(KiwiRecord.t())) :: R.unit()
  defrust apply_derived_entry(target, entry) do
    derived = entry.take(derived_fields())

    case derived.record(NodeChange.SIZE) do
      {:some, size} -> assign!(target.derived_size, some(size.clone()))
      :none -> :ok
    end

    assign!(target.properties, target.properties.merge(ref(derived)))
  end
end
