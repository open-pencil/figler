# Rendering warnings

Figler reports every unsupported, approximate, substituted, malformed, or
missing rendering feature as a `%Figler.Render.Warning{}`:

```elixir
%Figler.Render.Warning{
  code: :font_substituted,
  feature: :font,
  guid: "12:34",
  severity: :substitution,
  context: %{requested: %{family: "Inter"}, resolved: %{family: "Arial"}},
  value: %{code: :font_substituted, requested: %{family: "Inter"}, ...}
}
```

The stable fields are:

- `:code` — machine-readable atom identifying the diagnostic.
- `:feature` — affected rendering area, such as `:fill`, `:stroke`, `:font`,
  `:text`, `:effect`, `:mask`, or `:shape`.
- `:guid` — effective scene-node GUID as a string.
- `:severity` — `:approximation`, `:unsupported`, `:substitution`, `:invalid`,
  or `:missing`.
- `:context` — structured code-specific details.
- `:value` — original backend-neutral diagnostic value retained for debugging
  and compatibility. Prefer `:code` and `:context` in application logic.

Non-strict rendering returns warnings in metadata. Strict rendering rejects the
same list:

```elixir
{:error, {:unsupported_render_features, warnings}} =
  Figler.Render.render(document, root: "12:34", strict: true)
```

## Stable warning codes

### Shapes, geometry, and masks

| Code | Meaning |
| --- | --- |
| `shape_unsupported` | Visible node geometry is outside the supported subset. |
| `geometry_missing` | A visible vector/boolean paint has no usable geometry. |
| `invalid_geometry` | Imported path data failed validation or decoding. |
| `invalid_vector_network` | Editable vector-network data failed validation. |
| `outline_mask_approximated` | Outline masks use the documented approximation. |
| `mask_type_unsupported` | The requested mask type is unsupported. |

### Paints and images

| Code | Meaning |
| --- | --- |
| `unsupported_paint` | The visible paint type is unsupported. |
| `blend_mode_unsupported` | The requested paint or node blend mode is unsupported. |
| `non_solid_stroke_unsupported` | A primitive shape requested a non-solid stroke. |
| `image_filters_unsupported` | Image color-adjust/filter semantics are unsupported. |
| `missing_image_hash` | An image paint has no asset reference. |
| `missing_image_asset` | The referenced archive/message image is unavailable. |
| `invalid_image_geometry` | Image-paint destination geometry is malformed. |
| `invalid_image_scale` | Image scale or tile scale is invalid. |
| `invalid_image_rotation` | Image rotation is malformed. |
| `missing_geometry` | A gradient lacks the geometry required by its type. |
| `missing_gradient_stops` | A gradient has no usable stops. |
| `missing_gradient_transform` | A transformed gradient lacks its transform. |
| `singular_paint_transform` | A paint transform cannot be inverted. |
| `diamond_shader_compile_failed` | The diamond-gradient SkSL shader failed to compile. |
| `paint_invalid` | A paint failed with an otherwise unclassified malformed value. |

### Strokes

| Code | Meaning |
| --- | --- |
| `stroke_align_approximated` | Requested alignment is rendered as centered. |
| `stroke_cap_unsupported` | Decorative or unknown cap semantics are unsupported. |
| `stroke_cap_size_unsupported` | Explicit cap sizing is unsupported. |
| `dash_pattern_invalid` | Dash values are invalid. |
| `stroke_miter_invalid` | The miter limit is invalid. |

### Effects

| Code | Meaning |
| --- | --- |
| `effect_unsupported` | The effect type is unsupported. |
| `effect_shape_unsupported` | The effect requires a silhouette unavailable for this shape. |
| `effect_blend_mode_unsupported` | Effect-local blend mode is unsupported. |
| `effect_radius_invalid` | Blur/shadow radius is invalid. |
| `drop_shadow_cutout_unsupported` | Hiding shadow beneath translucent content is unsupported. |

### Text and fonts

| Code | Meaning |
| --- | --- |
| `font_substituted` | A deterministic fallback replaced the requested font. |
| `font_unavailable` | The requested font cannot be resolved. |
| `font_family_missing` | The source contains no usable requested family. |
| `font_inspection_failed` | Typeface inspection failed. |
| `fallback_font_load_failed` | A caller-provided fallback could not be loaded. |
| `glyphs_missing` | The resolved typeface lacks required characters. |
| `text_style_length_mismatch` | UTF-16 style metadata length differs from text length. |
| `text_style_splits_surrogate` | A style boundary splits a Unicode scalar. |
| `text_style_override_missing` | A style ID has no matching override. |
| `text_case_unsupported` | Requested case conversion is unsupported. |
| `text_run_paint_unsupported` | A rich-text run uses a non-solid fill. |
| `text_decoration_paint_unsupported` | Decoration paint is unsupported. |
| `text_decoration_thickness_unsupported` | Explicit decoration thickness is unsupported. |
| `text_underline_offset_unsupported` | Explicit underline offset is unsupported. |

New codes may be added during the beta series. Existing code meanings and
field shapes change only with a changelog notice under the beta compatibility
policy.
