# Changelog

## Unreleased

### Added

- Optional headless raster rendering through Skia, with PNG, JPEG, WEBP, and
  raw RGBA output.
- Rendering support for the documented beta subset, including rectangles,
  ellipses, partial ellipse rings, regular polygons, stars, editable vectors,
  fills, transformed gradients, image paints, strokes,
  rich text, effects, clipping, and sibling masks.
- `%Figler.Render.Warning{}` diagnostics with stable codes and structured
  context. Non-strict renders return warnings in metadata; `strict: true`
  rejects renders that would require unsupported, approximate, substituted,
  malformed, or missing behavior.
- Caller-controlled font fallback, grapheme-safe fallback selection, and
  UTF-16-compatible rich-text style ranges.
- Visual-oracle helpers for comparing Figler output with reference PNGs and
  running repeatable manifest-based render checks.
- Preservation of complete `.fig` archives, including Kiwi payloads, archive
  entries, message blobs, and `images/*` assets.

### Changed

- Render options now have a documented validation contract. Unknown,
  conflicting, or malformed options return structured
  `{:invalid_render_options, errors}` results.
- Malformed documents, scene selectors, GUIDs, and graph options now use a
  consistent `%Figler.Error{}` contract with machine-readable codes and context.
- Effective scene graphs now apply instance overrides, component-property
  assignments, swaps, variables, and layout metadata before rendering.
- Large-file scene indexing and effective-graph construction use less memory
  and complete substantially faster.
- The Hex package no longer brings development-time code generators or quality
  tools into production dependency resolution.
- The published API reference now focuses on supported document, scene, graph,
  rendering, and oracle modules.

### Fixed

- Shape effects no longer accidentally include child content.
- Effect, mask, and aligned-stroke layers use geometry-aware bounds instead of
  unbounded compositing surfaces.
- Text styling and fallback no longer split Unicode scalars or grapheme
  clusters.
- Invalid vector networks, geometry, paint transforms, image settings, text
  ranges, and stroke values now produce explicit diagnostics instead of silent
  fallback output.
- Instance clones retain effective paint, effect, vector, text, and layout
  overrides during rendering.

## 0.1.0 - 2026-06-26

- Initial Figma Kiwi schema package with generated schema modules and message helpers.
- Add native scene indexing, XPath-style querying, sparse decoding, and graph helpers for Figma files.
- Generate native decoder code with `rustq` and `kiwi_codec` 0.2.0.
