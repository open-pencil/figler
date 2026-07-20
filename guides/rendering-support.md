# Rendering support

Figler is a headless renderer for a documented Figma subset. It does not claim
complete Figma or OpenPencil parity.

Use `strict: true` when partial or approximate output is unacceptable:

```elixir
Figler.Render.render(fig,
  root: "0:123",
  scale: 2,
  strict: true,
  fallback_font_paths: ["fonts/Inter-Regular.ttf"]
)
```

A non-strict render returns structured warnings in `metadata.warnings`. Strict
mode returns `{:error, {:unsupported_render_features, warnings}}` instead.

## Status meanings

- **Supported** — implemented and covered by behavioral tests.
- **Oracle-covered** — compared with OpenPencil using the same root, bounds,
  scale, background, and fonts.
- **Approximate** — rendered with an explicit warning.
- **Diagnostic-only** — not rendered; strict mode rejects it.

## Documents and scene semantics

| Feature | Status |
| --- | --- |
| Complete `.fig` ZIP/archive input | Supported |
| Raw Kiwi message input | Supported |
| Page and root selection | Supported |
| Archive `images/*` and message blobs | Supported |
| Components, instances, swaps, and overrides | Supported |
| Component properties and effective values | Supported |
| Focused native source projection | Supported |
| Affine transforms, visibility, and opacity | Supported |
| Frame/container clipping | Supported |
| Common node blend modes | Supported |
| Linear burn | Diagnostic-only |

## Shapes and geometry

| Feature | Status |
| --- | --- |
| Frames, sections, symbols, and instances | Supported |
| Rectangles and rounded rectangles | Supported |
| Ellipses | Supported |
| Lines | Supported |
| Text | Supported |
| Imported vector paths | Supported |
| Flattened boolean geometry | Supported |
| Editable vector networks and compound regions | Supported, oracle-covered |
| Even-odd and winding fill rules | Supported |
| Polygon and star nodes | Diagnostic-only |
| Arc/partial-ellipse geometry | Diagnostic-only |
| Unresolved live boolean geometry | Diagnostic-only |
| Figma smooth-corner fidelity | Deferred |

Figler does not fall back to drawing an unsupported shape as a rectangle.

## Paints and images

| Feature | Status |
| --- | --- |
| Solid fills | Supported, oracle-covered |
| Linear gradients | Supported, oracle-covered |
| Radial gradients | Supported, oracle-covered |
| Angular/sweep gradients | Supported, oracle-covered |
| Diamond gradients | Supported with a native SkSL shader |
| Gradient transforms | Supported, oracle-covered |
| Gradient fills on editable vectors | Supported, oracle-covered |
| Image `FILL` and `FIT` | Supported |
| Transformed `STRETCH`/crop | Supported |
| Transformed and scaled `TILE` | Supported, oracle-covered |
| Image rotation | Supported |
| Image color-adjust/filter pipelines | Diagnostic-only |
| Pattern paints | Diagnostic-only |
| Noise and custom paints | Diagnostic-only |

OpenPencil currently approximates diamond gradients as radial gradients, so
Figler uses native behavioral coverage rather than a misleading visual oracle
for that feature.

## Strokes

| Feature | Status |
| --- | --- |
| Width, miter limit, joins, and butt/round/square caps | Supported |
| Dash patterns | Supported, oracle-covered |
| Center alignment | Supported |
| Inside/outside alignment on closed supported shapes | Supported, oracle-covered |
| Open-line inside/outside alignment | Approximate as centered |
| Gradient/image strokes on vectors and boolean paths | Supported |
| Non-solid strokes on ordinary primitive shapes | Diagnostic-only |
| Decorative arrow, ERD, highlight, and washi caps | Diagnostic-only |
| Stroke cap sizing | Diagnostic-only |
| Individual-side stroke weights | Deferred |

## Text and fonts

| Feature | Status |
| --- | --- |
| UTF-16-indexed rich-text style runs | Supported |
| Unicode scalar and grapheme-safe segmentation | Supported |
| Per-run font, size, fills, and fallback | Supported, oracle-covered |
| Caller-supplied font files | Supported |
| Character-aware system fallback | Supported |
| Line height and letter spacing | Supported |
| Horizontal and vertical paragraph alignment | Supported |
| Underline, line-through, and decoration styles | Supported |
| Wrapping, max lines, ellipsis, and bounded clipping | Supported, oracle-covered |
| Upper/lower/title case | Supported |
| Small caps | Diagnostic-only |
| Decoration thickness/offset and non-solid decoration paints | Diagnostic-only |
| Exact CanvasKit/Figma shaping for every script | Not guaranteed |

Font substitution is always reported and is rejected by strict mode. Figler
does not bundle a large fallback font; applications provide any required font
files or directories.

## Effects, compositing, and masks

| Feature | Status |
| --- | --- |
| Drop shadow, including spread | Supported, oracle-covered |
| Inner shadow on supported shapes, vectors, and text | Supported, oracle-covered |
| Foreground/layer blur | Supported, oracle-covered |
| Shape-masked background blur | Supported, oracle-covered |
| Bounded offscreen layers | Supported |
| Effect ordering around shapes and children | Supported |
| Alpha sibling masks | Supported, oracle-covered |
| Luminance sibling masks preserving source alpha | Supported, oracle-covered |
| Outline masks | Approximate |
| Effect-specific non-normal blend modes | Diagnostic-only |
| Drop-shadow cutout under translucent content | Diagnostic-only |
| Grain, glass, repeat, symmetry, noise, and custom effects | Diagnostic-only |

## Visual validation

OpenPencil is Figler's primary visual oracle. Oracle manifests record the exact
source and Figler roots because OpenPencil may remap GUIDs while importing a
`.fig` file. Each case also records fixture/reference hashes, scale, background,
fonts, expected warnings, and case-specific pixel thresholds.

An oracle case is omitted when OpenPencil ignores the feature being tested.
Passing the oracle suite demonstrates the listed selections, not arbitrary
whole-file parity.
