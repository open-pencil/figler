# Scene Architecture

FigKiwi keeps two scene layers separate:

- `FigKiwi.Scene.Index` / native scene functions are the raw, fast projection of schema data.
- `FigKiwi.Scene.Graph` is the effective-scene resolver for Figma semantics.

## Projection specs

`FigKiwi.Scene.Projection` is the semantic source of truth for public projected node fields.
It defines field names and their schema sources.

`FigKiwi.Scene.Projection.Native` contains Rust/native rendering policy for those projected fields:
Rust field types, copy/clone behavior, and XPath attribute fanout.

## Seed specs and extraction

`FigKiwi.Scene.Graph.SeedProjection` contains resolver metadata field specs and defaults.

`FigKiwi.Scene.Graph.SeedExtraction` converts generated schema-shaped `NodeChange` values into
seed metadata. Conversion submodules keep concerns focused:

- `SeedExtraction.SymbolOverrides`
- `SeedExtraction.ComponentProps`
- `SeedExtraction.DerivedData`

## Tests

Tests should mirror module boundaries instead of accumulating in one integration file.
Keep top-level `test/scene_test.exs` for `FigKiwi.Scene` smoke/integration coverage.
Module-specific behavior belongs under matching paths, for example:

- `test/scene/projection_test.exs`
- `test/scene/navigation_test.exs`
- `test/scene/graph/resolver_test.exs`
- `test/scene/graph/component_props_test.exs`
- `test/scene/graph/variables_test.exs`

Native generator modules mirror generated Rust concerns:

- `FigKiwi.NativeSceneGenerator.Sparse` renders generic sparse schema decoders.
- `FigKiwi.NativeSceneGenerator.Skip` renders generic skip decoders and skip arms.
- `FigKiwi.NativeSceneGenerator.Focus` renders focused effective-graph seed traversal.
- `FigKiwi.NativeSceneGenerator.Scene` renders projected scene records, queries, XPath attrs, summaries, and navigation NIFs.
- `FigKiwi.NativeSceneGenerator` should stay a small facade/orchestrator.

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
- New graph seed metadata fields: update `Graph.SeedProjection`.
- NodeChange-to-seed conversion: update the focused `Graph.SeedExtraction.*` module.
- Figma effective-scene semantics: update the appropriate resolver stage module, not the raw scene index.
