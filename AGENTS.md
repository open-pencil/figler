# Figler

Elixir toolkit for reading, querying, and inspecting Figma files.

## Development

```sh
mix deps.get
mix ci
```

GitHub CI uses the shared `elixir-vibe/actions/.github/workflows/elixir-rustler-ci.yml` workflow for Rustler setup and Cargo caching.

## Scope

- Keep the Figma `.kiwi` schema and Figma-specific container helpers here.
- Keep generic Kiwi parser, wire codec, DSL, and codegen in `../kiwi_codec`.
- Prefer generated `Figler.Schema.*` modules when exact Figma schema structs are needed; runtime map helpers are for tooling.
- Preserve compatibility with `../open-pencil-app/packages/core/src/kiwi/fig/codec/schema/fig.kiwi`.

## Generated Code Policy

- Generate schema-shaped Rust with RustQ templates/splices when code depends on Kiwi field numbers, enum values, or generated schema structure.
- Prefer `defrust` helpers for repeated generated Rust behavior when it can be expressed as valid Elixir.
- Keep Rusty-Elixir functional: use recursion, pattern matching, and accumulator-style helper APIs for repeated/counting behavior instead of introducing imperative loop/break/continue generator snippets.
- Treat loop/break/continue as RustQ-internal IR or last-resort Rust implementation details, not the normal Figler generator style.
- Prefer templates under `native/src/templates/` plus `RustQ.Rust` fragments over ad-hoc multiline Rust string interpolation.
- Keep Figma semantics in Elixir under `Figler.Scene.Graph`: instance population, overrides, component props, swaps, stack/layout, variables/styles, provenance, and unresolved diagnostics.
- Do not add one-off native parsers for `.fig`, ZIP, or Kiwi containers in Figler. Reusable parsing/container speedups belong upstream in `kiwi_codec` or another shared package.
- Keep large real `.fig` oracle fixtures outside git. Use `mix figler.oracles --dir /path/to/oracle-fixtures` or `FIGLER_EXTERNAL_ORACLE_DIR` for external oracle runs.
