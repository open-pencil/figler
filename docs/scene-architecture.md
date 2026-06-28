# Scene Architecture

Figler keeps two scene layers separate:

- `Figler.Scene.Index` / native scene functions are the raw, fast projection of schema data.
- `Figler.Scene.Graph` is the effective-scene resolver for Figma semantics.

## Projection specs

`Figler.Scene.Projection` is the semantic source of truth for public projected node fields.
It defines field names and their schema sources.

`Figler.Scene.Projection.Native` contains Rust/native rendering policy for those projected fields:
Rust field types, copy/clone behavior, and XPath attribute fanout.

## Seed specs and extraction

`Figler.Scene.Graph.Seed.Projection` contains resolver metadata field specs and defaults.

`Figler.Scene.Graph.Seed.Extraction` converts generated schema-shaped `NodeChange` values into
seed metadata. Conversion submodules keep concerns focused:

- `Seed.Extraction.SymbolOverrides`
- `Seed.Extraction.ComponentProps`
- `Seed.Extraction.DerivedData`

## Tests

Tests should mirror module boundaries instead of accumulating in one integration file.
Keep top-level integration-style tests only for scenarios that span modules.
Module-specific behavior belongs under matching paths, for example:

- `test/figler/scene_test.exs`
- `test/figler/scene/graph_test.exs`
- `test/figler/scene/graph/seed/projection_test.exs`
- `test/figler/scene/graph/component/properties_test.exs`
- `test/figler/scene/graph/build/variables_test.exs`

Native generator modules mirror generated Rust concerns:

- `KiwiCodec.RustlerGenerator.Sparse` renders generic sparse schema decoders.
- `KiwiCodec.RustlerGenerator.Skip` renders generic skip decoders and reusable skip arms.
- `Figler.Codegen.Native.Focus` renders focused effective-graph seed traversal.
- `Figler.Codegen.Native.Scene` renders projected scene records, queries, XPath attrs, summaries, and navigation NIFs.
- `Figler.Codegen.Native` should stay a small facade/orchestrator.

Reusable tiny scene fixtures live in `test/support/scene_fixture_test.exs`.
Graph resolver builders live in `test/support/graph_builder_test.exs`.

## Resolver semantics

Resolver stages stay in Elixir while behavior is evolving:

- clone population
- symbol overrides
- component props and swaps
- derived symbol data
- variables/styles
- stack layout

Schema-shaped Rust should still be generated from projection/spec modules and RustQ templates.
Avoid adding hand-maintained field-number or schema-name lists outside those specs.

## Where to add behavior

- New public projected fields: update `Scene.Projection`; native projection should follow via generator splices.
- Native Rust field rendering policy: update `Scene.Projection.Native`.
- New graph seed metadata fields: update `Graph.Seed.Projection`.
- NodeChange-to-seed conversion: update the focused `Graph.Seed.Extraction.*` module.
- Figma effective-scene semantics: update the appropriate `Graph.Build.*`, `Graph.Component.*`, or `Graph.Symbol.*` module, not the raw scene index.
