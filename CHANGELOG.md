# Changelog

## Unreleased

### Fixed

- Read files saved by current Figma releases. Their embedded schema adds message
  fields Figler's vendored schema lacks, and every decoder used to reject them
  as an invalid document. Native and Elixir decoders now skip such fields using
  the schema embedded in the file.

### Added

- `Figler.Scene.source!/1` returns a payload together with its embedded schema;
  native entrypoints, `Figler.Scene.graph/2`, and `Figler.decode_message/1`
  accept it.
- `mix figler.openpencil` and `Figler.Scene.Graph.OpenPencilOracle` diff
  effective graphs against OpenPencil's occurrence interpreter, run from an
  OpenPencil checkout through `scripts/openpencil_oracle.ts`.

## 0.1.0-beta.1 - 2026-07-22

### Added

- Native scene indexing, XPath-style queries, sparse/full schema decoding, and
  effective graphs for resolved Figma instances and overrides.
- Optional headless raster rendering through Skia, with PNG, JPEG, WEBP, and
  raw RGBA output.
- Rendering support for the documented beta subset, including rectangles with
  independent corner radii, ellipses, partial ellipse rings, regular polygons,
  stars, editable vectors,
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
- Complete-document `Figler.decode/1` and `Figler.encode/1` APIs for transforming
  `.fig` archives with ordinary Elixir structs, pattern matching, `Enum`, and
  `Access`, while preserving archive entries, images, container metadata, and
  the original input representation.
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
- Clipped containers now use independent corner paths, preserve transformed
  descendant clipping, and exclude clipped overflow from output bounds.
- Closed compound path strokes retain alignment, dash, join, cap, miter, and
  transformed-bound semantics; open-path alignment reports its centered
  approximation explicitly.
- Opacity and blend isolation layers are bounded to nested subtree content, and
  mask nodes retain supported effects and opacity during compositing.
- Text styling and fallback no longer split Unicode scalars or grapheme
  clusters.
- Invalid vector networks, geometry, paint transforms, image settings, text
  ranges, and stroke values now produce explicit diagnostics instead of silent
  fallback output.
- Live boolean operations without flattened or imported geometry are rejected
  explicitly instead of disappearing silently.
- Full-circle `arcData` ellipses and rings are emitted as renderable half-arc
  path segments instead of disappearing on a 360-degree backend arc.
- Cyclic parent graphs, oversized or non-finite render bounds, excessive archive
  expansion, and malformed background colors now fail before recursive traversal,
  canvas allocation, archive extraction, or backend command construction.
- Instance clones retain effective paint, effect, vector, text, and layout
  overrides during rendering.
