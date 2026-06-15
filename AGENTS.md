# FigKiwi

Figma schema companion package for `kiwi_codec`.

## Development

```sh
mix deps.get
mix ci
```

GitHub CI uses the shared `elixir-vibe/actions/.github/workflows/elixir-rustler-ci.yml` workflow for Rustler setup and Cargo caching.

## Scope

- Keep the Figma `.kiwi` schema and Figma-specific container helpers here.
- Keep generic Kiwi parser, wire codec, DSL, and codegen in `../kiwi_codec`.
- Prefer generated `FigKiwi.Schema.*` modules for application code; runtime map helpers are for tooling.
- Preserve compatibility with `../open-pencil-app/packages/core/src/kiwi/fig/codec/schema/fig.kiwi`.

## Generated Code Policy

- Generate schema-shaped Rust with RustQ templates/splices when code depends on Kiwi field numbers, enum values, or generated schema structure.
- Prefer templates under `native/src/templates/` plus `RustQ.Rust` fragments over ad-hoc multiline Rust string interpolation.
- Keep Figma semantics in Elixir under `FigKiwi.Scene.Graph`: instance population, overrides, component props, swaps, stack/layout, variables/styles, provenance, and unresolved diagnostics.
- Do not add one-off native parsers for `.fig`, ZIP, or Kiwi containers in FigKiwi. Reusable parsing/container speedups belong upstream in `kiwi_codec` or another shared package.
