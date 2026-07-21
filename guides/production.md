# Production guidance

## Font resolution

Figler resolves text per grapheme cluster while preserving Figma's UTF-16 style
ranges. Resolution order is deterministic:

1. A caller-supplied typeface whose family matches the requested family and
   covers the cluster.
2. The installed requested family with the requested weight and slant.
3. A caller-supplied typeface matching a Figma fallback-family entry.
4. An installed Figma fallback family.
5. The first caller-supplied typeface that covers the cluster.
6. Character-aware system fallback, unless `system_font_fallback: false`.

Pass file paths with `fallback_font_paths: [...]` or already-loaded
`Skia.Typeface` values with `fallback_typefaces: [...]`. Lists retain caller
order. `font_languages: [...]` supplies BCP-47 hints to system character
matching.

A fallback replacing the requested family emits `font_substituted`. Missing
families, glyph coverage, or malformed caller font files also produce structured
font diagnostics. `strict: true` rejects substitutions and missing coverage.
Figler intentionally bundles no large fallback fonts, so deploy every font
needed for deterministic output with the application and ensure its license
permits that use.

## Large-file performance

Choose the narrowest representation that answers the question:

- Reuse `Figler.Document` to avoid repeatedly extracting the archive and decoding
  page/blob metadata.
- Reuse `Figler.Scene.index/1` for repeated raw-scene queries.
- Pass `fields: [...]` to project only needed query fields.
- Prefer scene helpers over full `Figler.decode_message/1` on hot paths.
- Build `Figler.Scene.graph/2` only for effective instance semantics. Use
  `root:` or `focus:` whenever the complete effective document is unnecessary.
- Reuse `Figler.Render.prepare/2` when rendering the same selection repeatedly.
- Keep roots focused: asset loading, diagnostics, command compilation, and
  rasterization walk the selected subtree.

A full effective graph can be much larger than the source because populated
instances create effective clones. Reference beta measurements use a 104 MiB,
roughly 79,000-source-node community file; full resolution creates about
157,000 effective nodes and has materially higher memory cost than indexed
queries or focused projection. Treat measurements as workload- and
machine-specific, and profile representative customer files before setting
service limits.

Figler rejects output larger than 16,384 pixels on either axis or 67,108,864
total pixels after scaling. Archive metadata is checked before extraction, with
limits documented in [Errors and options](errors-and-options.md). These limits
bound accidental or malicious allocation; select smaller roots or scales rather
than bypassing them.

## Native source builds

The beta baseline is Elixir 1.19/OTP 27 or Elixir 1.20/OTP 29 with stable Rust
1.97 on x86-64 Linux. A source build needs:

- Cargo and `rustc`
- a C/C++ compiler and linker
- CMake and Make
- normal system development headers used by native dependencies

Figler's own Rustler NIF is source-built. Skia is optional and normally uses its
published precompiled artifacts. `SKIA_EX_BUILD=1 mix compile` forces a local
Skia source build; on Debian/Ubuntu install `libfontconfig1-dev` and
`libfreetype6-dev` first.

Common failures:

- **Cargo or `rustc` missing** — install Rust 1.97 or a compatible stable
  toolchain and ensure both commands are on `PATH`.
- **C/C++ linker missing** — install the platform build-essential toolchain.
- **CMake/Make not found** — install both tools before compiling dependencies.
- **`-lfontconfig` or `-lfreetype` cannot be found during a forced Skia build** —
  install the development packages and ensure their library directory is on the
  linker's search path.
- **A Skia precompiled artifact is unavailable for the target** — either choose
  a target in Skia's published matrix or opt into a local source build and
  provide its native prerequisites.

## Beta compatibility policy

Documented public modules and result shapes are intended for application use.
During the beta series, source-incompatible changes may occur between beta
releases when needed to correct the contract. Such changes receive an explicit
changelog notice and a migration description.

Within a published beta release, existing error fields, warning fields, and
warning-code meanings are stable. New warning codes and additive metadata may
be introduced in later beta releases. Internal codegen, projection, and Skia
backend modules are not part of the public compatibility contract; use the
modules present in the generated API documentation.
