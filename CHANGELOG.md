# Changelog

## Unreleased

- Normalize projected paints, effects, image references, geometry references,
  colors, vectors, and matrices into a typed rendering IR. Generate native
  projection record order from the same structural schema and apply rich symbol
  overrides to effective render nodes instead of reusing unmodified source
  paints and effects for instance clones.
- Add an optional Skia rendering pipeline backed by a complete `Figler.Document`
  archive boundary and a native, page/root-focused source projection. Rendering
  retains `canvas.fig`, `images/*`, message blobs, entries, and page metadata
  without densely decoding every `NodeChange`, then joins projected paint/shape
  data with the effective graph and emits one batched Skia document. On a
  generated 5,002-node sparse document, focused source projection measured
  3.7ms and about 1.0MB process-memory growth versus 15.2ms and 7.6MB for dense
  decoding. The renderer supports affine transforms, opacity, clipping, solid
  and positioned linear/radial/angular gradients, archive and message-blob
  image fills across Figma scale modes, imported vector fill/stroke paths,
  flattened boolean geometry, blend layers, basic drop shadows and foreground
  blur, alpha/luminance sibling masks, basic strokes/shapes/text,
  PNG/JPEG/WEBP, explicit approximation warnings, and strict mode. Editable
  geometry without imported path blobs, inner shadows, and backdrop blur are
  rejected explicitly. Add thresholded RGBA and reference-PNG oracle helpers.
- Index actionable horizontal stack seeds during graph construction and rebuild
  that candidate list with graph indexes, avoiding a full seed-map scan during
  stack layout. Exact-output fixture A/B runs reduced median stack-layout time
  from about 574ms to 402ms.
- Project native graph-seed metadata from the selected resolver stage plan while
  preserving fixed records, clone retention, resolver output, and profiling
  semantics. On the 79,261-node fixture, initial/population-only seed decoding
  fell from about 1.37s and 562 MB to 0.30s and 157 MB; through component props
  fell to about 0.67s and 325 MB.
- Traverse component-property instances in stable graph order so full and
  stage-projected seed records produce identical resolver output.
- Ignore component-property assignments from instance nodes removed by earlier
  graph mutations instead of letting stale clone seeds fall back to and mutate
  source definitions. The 79,261-node fixture skipped 2,001 stale instances and
  reduced median component-props time from 1.09s to 1.00s.
- Avoid redundant component-property removal work by fast-pathing already-empty
  child clears and collecting removal subtrees in one pass. On the 79,261-node
  fixture, exact-output A/B runs reduced median component-props time by about 7%.
- Profile each resolver stage with its remaining stage plan intact, so deferred
  index work and the returned graph match normal full-pipeline execution.
- Represent extended clone GUID paths with structurally shared tails instead of
  copying the full source path on every append; the 200,140-append external
  profile reduced GUID append time by about 30% while preserving public IDs.
- Defer clone type/name index maintenance when a later component-props stage will
  rebuild those indexes; a 79,261-node full-stage A/B improved median resolver
  time from 8.46s to 7.95s with identical node/provenance output hashes.
- Materialize initial graph indexes directly from native seed records instead of
  allocating a second complete seed list; a 79,261-node external fixture dropped
  from 8.27s to 5.98s in same-process A/B construction while preserving graph
  nodes, children, provenance, and unresolved output exactly.
- Use released KiwiCodec 0.3.0 instead of a sibling path dependency so clean
  checkouts and GitHub CI can generate and validate native code.
- Scan seed metadata directly during stack layout and skip variable/style stage
  work for seeds with no relevant metadata, avoiding broad node-key allocation
  and unnecessary per-node resolver calls.
- Build the native exact-name index lazily so scene indexes that only navigate,
  query by type, or evaluate XPath do not duplicate every node name.
- Resolve XPath `id()` lookups through the native GUID hash index instead of
  reparsing the requested ID while scanning every scene node.
- Return fixed graph-seed records as tuples instead of cons-cell lists, reducing
  the record-container footprint by roughly 42% on a 2,000-node synthetic scene.
- Cache the versioned parsed Figma schema and its prepared interpreter indexes,
  accelerating repeated runtime-schema encode/decode calls across processes.
- Recognize raw Kiwi payloads and `fig-kiwi` containers structurally instead of
  raising and rescuing decode errors during every raw-payload operation.
- Repair the message benchmark after dense native decoder removal and run it
  with Benchee across static, interpreted, sparse, seed, index, and graph paths.
- Report fixture benchmark p50/p95 timings from configurable warmups and samples,
  label process-memory deltas as BEAM-only, and preserve sub-millisecond graph
  profile precision.
- Drop generated dense native schema decoders; public dense decode remains
  available through `KiwiCodec.decode/2`.
- Use descriptor-backed sparse message decoders and RustQ-authored sparse
  runtime helpers for primitive values, field dispatch, and sparse message
  scanning.
- Regenerate sparse descriptor declarations and descriptor macros from RustQ
  `@type` / `defrustmacro` support.
- Share sparse and skip message descriptor field inventories, use RustQ-authored
  sparse enum, sparse struct, and descriptor skip scanning, and generate skip
  descriptor function/enum/field declarations from RustQ type metadata in native
  Rust.
- Author scene skip-field dispatch with RustQ `defrust` / `defrustmacro`
  helpers instead of a raw Rust template macro.
- Reduce checked-in generated native source to about 555 KB / 13,481 lines while
  preserving public sparse decode and graph seed performance paths.

## 0.1.0 - 2026-06-26

- Initial Figma Kiwi schema package with generated schema modules and message helpers.
- Add native scene indexing, XPath-style querying, sparse decoding, and graph helpers for Figma files.
- Generate native decoder code with `rustq` and `kiwi_codec` 0.2.0.
