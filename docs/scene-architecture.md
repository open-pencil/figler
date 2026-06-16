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
