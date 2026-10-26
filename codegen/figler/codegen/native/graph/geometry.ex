defmodule Figler.Codegen.Native.Graph.Geometry do
  @moduledoc """
  Placed geometry of an instance expansion, for the native interpreter: uniform scale, freeform
  resize constraints, and the saved derived cache Figma keeps per layer path.

  Arithmetic runs in `f64` and is stored back as the schema's `f32`.
  """

  use RustQ.Meta,
    callable_modules: [Figler.Codegen.Native.Graph.Occurrence]

  alias Figler.Codegen.Native.Graph.Occurrence
  alias KiwiCodec.RustlerGenerator.Records, as: Kiwi
  alias RustQ.Type, as: R

  @doc "The Rust types and functions this module defines."
  @spec items() :: [term()]
  def items, do: __rustq_items__()

  @spec visual_lengths() :: R.slice(R.u32(), R.lifetime(:static))
  defrust visual_lengths() do
    [
      Kiwi.NodeChange.STROKE_WEIGHT,
      Kiwi.NodeChange.CORNER_RADIUS,
      Kiwi.NodeChange.RECTANGLE_TOP_LEFT_CORNER_RADIUS,
      Kiwi.NodeChange.RECTANGLE_TOP_RIGHT_CORNER_RADIUS,
      Kiwi.NodeChange.RECTANGLE_BOTTOM_LEFT_CORNER_RADIUS,
      Kiwi.NodeChange.RECTANGLE_BOTTOM_RIGHT_CORNER_RADIUS
    ]
  end

  # Stack padding and spacing, which uniform scale treats as lengths.
  @spec layout_distances() :: R.slice(R.u32(), R.lifetime(:static))
  defrust layout_distances() do
    [
      Kiwi.NodeChange.STACK_PADDING,
      Kiwi.NodeChange.STACK_SPACING,
      Kiwi.NodeChange.STACK_COUNTER_SPACING,
      Kiwi.NodeChange.STACK_HORIZONTAL_PADDING,
      Kiwi.NodeChange.STACK_VERTICAL_PADDING,
      Kiwi.NodeChange.STACK_PADDING_RIGHT,
      Kiwi.NodeChange.STACK_PADDING_BOTTOM
    ]
  end

  # Every field scaling touches. An instance record declares these in placed space, so after
  # its expansion is scaled the record's own values are restored.
  @spec scaled_fields() :: R.slice(R.u32(), R.lifetime(:static))
  defrust scaled_fields() do
    [
      Kiwi.NodeChange.STACK_PADDING,
      Kiwi.NodeChange.STACK_SPACING,
      Kiwi.NodeChange.STACK_COUNTER_SPACING,
      Kiwi.NodeChange.STACK_HORIZONTAL_PADDING,
      Kiwi.NodeChange.STACK_VERTICAL_PADDING,
      Kiwi.NodeChange.STACK_PADDING_RIGHT,
      Kiwi.NodeChange.STACK_PADDING_BOTTOM,
      Kiwi.NodeChange.STROKE_WEIGHT,
      Kiwi.NodeChange.CORNER_RADIUS,
      Kiwi.NodeChange.RECTANGLE_TOP_LEFT_CORNER_RADIUS,
      Kiwi.NodeChange.RECTANGLE_TOP_RIGHT_CORNER_RADIUS,
      Kiwi.NodeChange.RECTANGLE_BOTTOM_LEFT_CORNER_RADIUS,
      Kiwi.NodeChange.RECTANGLE_BOTTOM_RIGHT_CORNER_RADIUS,
      Kiwi.NodeChange.FONT_SIZE,
      Kiwi.NodeChange.LINE_HEIGHT,
      Kiwi.NodeChange.LETTER_SPACING,
      Kiwi.NodeChange.TEXT_DATA,
      Kiwi.NodeChange.DERIVED_TEXT_DATA,
      Kiwi.NodeChange.DASH_PATTERN,
      Kiwi.NodeChange.EFFECTS,
      Kiwi.NodeChange.SIZE,
      Kiwi.NodeChange.TRANSFORM
    ]
  end

  # The fields a saved derived entry may carry.
  @spec derived_fields() :: R.slice(R.u32(), R.lifetime(:static))
  defrust derived_fields() do
    [
      Kiwi.NodeChange.DERIVED_TEXT_DATA,
      Kiwi.NodeChange.FONT_SIZE,
      Kiwi.NodeChange.LINE_HEIGHT,
      Kiwi.NodeChange.LETTER_SPACING,
      Kiwi.NodeChange.SIZE,
      Kiwi.NodeChange.TRANSFORM,
      Kiwi.NodeChange.FILL_GEOMETRY,
      Kiwi.NodeChange.STROKE_GEOMETRY,
      Kiwi.NodeChange.VECTOR_DATA
    ]
  end

  @spec uniform_scale(R.ref(Kiwi.kiwi_record())) :: R.f64()
  defrust uniform_scale(record) do
    case record.record(Kiwi.NodeChange.SYMBOL_DATA).and_then(fn data ->
           data.float(Kiwi.SymbolData.UNIFORM_SCALE_FACTOR)
         end) do
      {:some, factor} -> cast(factor, R.f64())
      :none -> 1.0
    end
  end

  # Scales an expansion from component space into the instance's placed space, then restores
  # the distances the instance record itself declares.
  @spec apply_layout_scale(Occurrence.occurrence(), R.ref(Kiwi.kiwi_record())) ::
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
    properties = scale_properties(occurrence.properties, factor)
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

  @spec scale_properties(R.ref(Kiwi.kiwi_record()), R.f64()) :: Kiwi.kiwi_record()
  defrust scale_properties(properties, factor) do
    scale_text_layout(properties, factor)
    |> scale_numbers(visual_lengths(), factor)
    |> scale_numbers(layout_distances(), factor)
    |> scale_floats(Kiwi.NodeChange.DASH_PATTERN, factor)
    |> map_records(Kiwi.NodeChange.EFFECTS, fn effect -> scale_effect(effect, factor) end)
    |> map_record(Kiwi.NodeChange.SIZE, fn size -> scale_vector(size, factor) end)
    |> map_record(Kiwi.NodeChange.TRANSFORM, fn transform ->
      scale_numbers(transform, [Kiwi.Matrix.M02, Kiwi.Matrix.M12], factor)
    end)
  end

  @spec scale_effect(R.ref(Kiwi.kiwi_record()), R.f64()) :: Kiwi.kiwi_record()
  defrust scale_effect(effect, factor) do
    effect
    |> map_record(Kiwi.Effect.OFFSET, fn offset -> scale_vector(offset, factor) end)
    |> scale_numbers([Kiwi.Effect.RADIUS, Kiwi.Effect.SPREAD], factor)
  end

  # Scales positional text data, not font identity or normalized glyph outlines.
  @spec scale_text_layout(R.ref(Kiwi.kiwi_record()), R.f64()) :: Kiwi.kiwi_record()
  defrust scale_text_layout(properties, factor) do
    properties
    |> scale_numbers([Kiwi.NodeChange.FONT_SIZE], factor)
    |> scale_pixel_value(Kiwi.NodeChange.LINE_HEIGHT, factor)
    |> scale_pixel_value(Kiwi.NodeChange.LETTER_SPACING, factor)
    |> map_record(Kiwi.NodeChange.TEXT_DATA, fn text ->
      text.map_records(Kiwi.TextData.STYLE_OVERRIDE_TABLE, fn style ->
        scale_text_layout(style, factor)
      end)
    end)
    |> map_record(Kiwi.NodeChange.DERIVED_TEXT_DATA, fn derived ->
      scale_derived_text(derived, factor)
    end)
  end

  @spec scale_derived_text(R.ref(Kiwi.kiwi_record()), R.f64()) :: Kiwi.kiwi_record()
  defrust scale_derived_text(derived, factor) do
    derived
    |> map_record(Kiwi.DerivedTextData.LAYOUT_SIZE, fn size -> scale_vector(size, factor) end)
    |> scale_numbers([Kiwi.DerivedTextData.TRUNCATED_HEIGHT], factor)
    |> map_records(Kiwi.DerivedTextData.GLYPHS, fn glyph -> scale_glyph(glyph, factor) end)
    |> map_records(Kiwi.DerivedTextData.BASELINES, fn baseline ->
      scale_baseline(baseline, factor)
    end)
  end

  @spec scale_glyph(R.ref(Kiwi.kiwi_record()), R.f64()) :: Kiwi.kiwi_record()
  defrust scale_glyph(glyph, factor) do
    glyph
    |> map_record(Kiwi.Glyph.POSITION, fn position -> scale_vector(position, factor) end)
    |> scale_numbers([Kiwi.Glyph.FONT_SIZE], factor)
  end

  @spec scale_baseline(R.ref(Kiwi.kiwi_record()), R.f64()) :: Kiwi.kiwi_record()
  defrust scale_baseline(baseline, factor) do
    baseline
    |> map_record(Kiwi.Baseline.POSITION, fn position -> scale_vector(position, factor) end)
    |> scale_numbers(
      [
        Kiwi.Baseline.WIDTH,
        Kiwi.Baseline.LINE_HEIGHT,
        Kiwi.Baseline.LINE_ASCENT,
        Kiwi.Baseline.LINE_Y
      ],
      factor
    )
  end

  # A metric given in pixels scales; one given in percent or raw units does not.
  @spec scale_pixel_value(Kiwi.kiwi_record(), R.u32(), R.f64()) :: Kiwi.kiwi_record()
  defrust scale_pixel_value(properties, field, factor) do
    properties.map_record(field, fn metric ->
      if metric.enum_value(Kiwi.Number.UNITS) == some(Kiwi.NumberUnits.PIXELS),
        do: scale_numbers(metric, [Kiwi.Number.VALUE], factor),
        else: metric.clone()
    end)
  end

  @spec scale_numbers(R.ref(Kiwi.kiwi_record()), R.slice(R.u32()), R.f64()) :: Kiwi.kiwi_record()
  defrust scale_numbers(record, fields, factor) do
    Enum.reduce(fields, record.clone(), fn field, scaled ->
      case scaled.float(field) do
        {:some, value} ->
          scaled.put_float(field, cast(cast(value, R.f64()) * factor, R.f32()))

        :none ->
          scaled
      end
    end)
  end

  @spec scale_vector(R.ref(Kiwi.kiwi_record()), R.f64()) :: Kiwi.kiwi_record()
  defrust(scale_vector(vector, factor),
    do: scale_numbers(vector, [Kiwi.Vector.X, Kiwi.Vector.Y], factor)
  )

  @spec scale_floats(Kiwi.kiwi_record(), R.u32(), R.f64()) :: Kiwi.kiwi_record()
  defrust scale_floats(record, field, factor) do
    if record.has(field) do
      values =
        Enum.map(record.floats(field), fn value ->
          cast(cast(value, R.f64()) * factor, R.f32())
        end)

      record.put_floats(field, values)
    else
      record
    end
  end

  @spec vector_size(R.ref(Kiwi.kiwi_record())) :: {R.f64(), R.f64()}
  defrust vector_size(vector) do
    {cast(vector.float(Kiwi.Vector.X).unwrap_or(0.0), R.f64()),
     cast(vector.float(Kiwi.Vector.Y).unwrap_or(0.0), R.f64())}
  end

  # Resizes an instance's freeform children from the component's scaled size to its own.
  @spec apply_placed_constraints(
          Occurrence.occurrence(),
          R.option(R.ref(Occurrence.occurrence())),
          R.ref(Kiwi.kiwi_record())
        ) :: Occurrence.occurrence()
  defrust apply_placed_constraints(root, base, source) do
    with {:some, base} <- base,
         {:some, base_size} <- base.properties.record(Kiwi.NodeChange.SIZE),
         {:some, size} <- source.record(Kiwi.NodeChange.SIZE) do
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
        case root.properties.enum_value(Kiwi.NodeChange.STACK_MODE) do
          {:some, Kiwi.StackMode.NONE} -> false
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
      child.properties.enum_value(Kiwi.NodeChange.STACK_POSITIONING) ==
        some(Kiwi.StackPositioning.ABSOLUTE)

    if (auto_layout and not absolute) or not child.properties.has(Kiwi.NodeChange.SIZE),
      do: child,
      else: resized_child(child, before_size, after_size)
  end

  @spec resized_child(Occurrence.occurrence(), {R.f64(), R.f64()}, {R.f64(), R.f64()}) ::
          Occurrence.occurrence()
  defrust resized_child(child, before_size, after_size) do
    transform =
      case child.properties.record(Kiwi.NodeChange.TRANSFORM) do
        {:some, transform} -> transform.clone()
        :none -> identity_matrix()
      end

    size =
      case child.properties.record(Kiwi.NodeChange.SIZE) do
        {:some, size} -> size.clone()
        :none -> KiwiRecord.new(Kiwi.Definitions.VECTOR)
      end

    {width, height} = vector_size(size)
    {before_width, before_height} = before_size
    {after_width, after_height} = after_size

    {x, new_width} =
      constrained_axis(
        cast(transform.float(Kiwi.Matrix.M02).unwrap_or(0.0), R.f64()),
        width,
        before_width,
        after_width,
        child.properties.enum_value(Kiwi.NodeChange.HORIZONTAL_CONSTRAINT)
      )

    {y, new_height} =
      constrained_axis(
        cast(transform.float(Kiwi.Matrix.M12).unwrap_or(0.0), R.f64()),
        height,
        before_height,
        after_height,
        child.properties.enum_value(Kiwi.NodeChange.VERTICAL_CONSTRAINT)
      )

    child = resize(child, {width, height}, {new_width, new_height})

    new_size =
      size
      |> put_float(Kiwi.Vector.X, cast(new_width, R.f32()))
      |> put_float(Kiwi.Vector.Y, cast(new_height, R.f32()))

    placed =
      transform
      |> put_float(Kiwi.Matrix.M02, cast(x, R.f32()))
      |> put_float(Kiwi.Matrix.M12, cast(y, R.f32()))

    properties =
      child.properties
      |> put_record(Kiwi.NodeChange.SIZE, new_size)
      |> put_record(Kiwi.NodeChange.TRANSFORM, placed)

    %{child | properties: properties}
  end

  @spec constrained_axis(R.f64(), R.f64(), R.f64(), R.f64(), R.option(R.u32())) ::
          {R.f64(), R.f64()}
  defrust constrained_axis(position, size, before_size, after_size, constraint) do
    delta = after_size - before_size

    case constraint do
      {:some, Kiwi.ConstraintType.SCALE} when before_size > 0.0 ->
        {position * (after_size / before_size), size * (after_size / before_size)}

      {:some, Kiwi.ConstraintType.MAX} ->
        {position + delta, size}

      {:some, Kiwi.ConstraintType.CENTER} ->
        {position + delta / 2.0, size}

      {:some, Kiwi.ConstraintType.STRETCH} ->
        {position, (size + delta).max(0.0)}

      _ ->
        {position, size}
    end
  end

  @spec identity_matrix() :: Kiwi.kiwi_record()
  defrust identity_matrix() do
    KiwiRecord.new(Kiwi.Definitions.MATRIX)
    |> put_float(Kiwi.Matrix.M00, 1.0)
    |> put_float(Kiwi.Matrix.M01, 0.0)
    |> put_float(Kiwi.Matrix.M02, 0.0)
    |> put_float(Kiwi.Matrix.M10, 0.0)
    |> put_float(Kiwi.Matrix.M11, 1.0)
    |> put_float(Kiwi.Matrix.M12, 0.0)
  end

  # Copies one saved derived entry onto its target; a cache, not a claim.
  @spec apply_derived_entry(R.mut_ref(Occurrence.occurrence()), R.ref(Kiwi.kiwi_record())) ::
          R.unit()
  defrust apply_derived_entry(target, entry) do
    derived = entry.take(derived_fields())

    case derived.record(Kiwi.NodeChange.SIZE) do
      {:some, size} -> assign!(target.derived_size, some(size.clone()))
      :none -> :ok
    end

    assign!(target.properties, target.properties.merge(ref(derived)))
  end
end
