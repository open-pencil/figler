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
