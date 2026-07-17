# Changelog

## Unreleased

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
