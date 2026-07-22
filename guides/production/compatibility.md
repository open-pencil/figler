# Compatibility

Figler `0.1.0-beta.1` establishes the first public beta contract for `.fig` analysis, complete-file transformation, effective graphs, and headless rendering.

## Beta versioning

During the `0.1.0-beta.*` series:

- documented public APIs are intended for real use;
- bug fixes and new supported Figma features may be added in beta releases;
- source-incompatible corrections may still occur before `0.1.0`;
- incompatible changes are called out in `CHANGELOG.md`;
- structured errors and warnings are more stable than exception message text;
- newly detected render problems may introduce additional warning codes.

Pin an exact beta version when visual output or encoded documents are part of a production pipeline. Review the changelog and representative fixtures before upgrading.

## Input compatibility

Figler accepts:

- complete exported `.fig` ZIP archives;
- standalone `fig-kiwi` containers;
- raw Figma Kiwi `Message` payloads.

Figma may evolve the private `.fig` format independently. Figler ships a specific vendored schema and preserves untouched archive data, but cannot guarantee compatibility with every future export.

Malformed, truncated, or unsupported input fails with structured `%Figler.Error{}` values rather than being interpreted as another format.

## Transformation compatibility

`Figler.decode!/1` and `Figler.encode!/1` preserve the input representation:

- archives remain archives and retain untouched entries;
- containers retain their schema chunk, version, compression family, and trailing chunks;
- raw messages remain raw messages.

The encoder guarantees valid Kiwi/container/archive encoding for supported values. It does not make arbitrary struct changes semantically valid. Callers remain responsible for relationships between GUIDs, parent indexes, components, style ranges, vectors, and assets.

Generated `Figler.Schema` structs follow the schema shipped with the installed package. Adding fields to generated structs is compatible for normal pattern matching, but callers should avoid exhaustive map equality against every field.

## Query compatibility

The stable scene surface includes indexes, helpers, selectors, field projections, hierarchy navigation, and effective graphs.

Valid queries with no match continue to return `[]` or `nil`. Malformed selectors, GUIDs, inputs, and options use `%Figler.Error{}`. Match on `code`, `operation`, and documented context fields rather than exception text.

## Rendering compatibility

The renderer promises the behavior listed in the [Rendering Support Matrix](../rendering/rendering-support.md), not arbitrary Figma/OpenPencil parity.

Supported features should render without warnings. Approximate, substituted, missing, malformed, or unsupported behavior produces `%Figler.Render.Warning{}` and is rejected by `strict: true`.

Pixel output can still change when:

- a rendering bug is fixed;
- Skia changes rasterization or text shaping;
- supplied fonts change;
- system font fallback differs between hosts;
- a previously approximate feature gains exact support.

Use explicit fonts, disable system fallback, enable strict mode, and compare representative images when output must be deterministic.

## Runtime baseline

The first beta supports Elixir 1.19 and later. The tested release matrix is documented in [Native Builds](native-builds.md).

## What is not promised

The first beta does not promise:

- pixel identity with Figma or OpenPencil for every document;
- support for every Figma node, paint, effect, or text behavior;
- semantic repair after arbitrary schema mutations;
- forward compatibility with unknown future `.fig` schema changes;
- stable internal resolver, rendering, generated-code, or native modules.

Use documented public modules and guides as the package contract.
