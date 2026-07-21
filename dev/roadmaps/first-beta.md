# Roadmap to the first Figler beta

The first beta targets a **headless renderer for a documented Figma subset**,
backed by stable query and effective-scene APIs. It does not claim complete
OpenPencil or Figma renderer parity.

The intended first public version is `0.1.0-beta.1`. The beta is ready when a
caller can inspect a real `.fig` archive, select a page or subtree, render every
feature in the documented support tier, and use `strict: true` to reject
unsupported semantics without silent fallback.

## Beta contract

The beta promises:

- complete `.fig` archive preservation, including `canvas.fig`, Kiwi blobs,
  archive entries, and `images/*`
- typed generated schema access, projected scene queries, and an effective scene
  graph for instances and overrides
- deterministic page/root selection and one batched Skia render document
- a published rendering support matrix
- structured warnings for every approximation, substitution, malformed value,
  and unsupported feature known during projection or compilation
- `strict: true` converting those warnings into a render error
- bounded native decoding and bounded offscreen compositing
- source-build installation with a documented Rust toolchain requirement

The beta does not promise:

- pixel identity with Figma, CanvasKit, or OpenPencil for arbitrary documents
- support for every Figma node, paint, effect, text, layout, or plugin feature
- editable round-tripping of every schema field
- bundled commercial or large fallback fonts
- precompiled Figler NIFs for every target

## Current baseline

The current implementation already provides:

- archive parsing, sparse/full decoding, projected indexes, XPath-style queries,
  and effective graph resolution
- components, instances, swaps, component properties, overrides, variables,
  and stack-layout projection
- rectangles, frames, sections, symbols, instances, ellipses, lines, text,
  imported/boolean paths, and editable vector networks
- rich text, paragraph typography, UTF-16 style ranges, and grapheme-level font
  fallback
- solid, linear, radial, angular, diamond, and transformed image paints
- styled and aligned strokes, alpha/luminance masks, drop/inner shadows, and
  layer/background blur
- one batched Skia document per render
- a 104 MiB, roughly 79,000-node resolver/performance fixture
- focused OpenPencil comparisons, including one real-file swatch

This baseline is substantial but is not yet evidence of whole-page parity on
representative production files.

## Milestone B0: integrate and describe the current baseline

**Exit condition:** the repository, README, changelog, and public docs describe
what the current code actually supports.

- [x] Integrate the completed stroke, effect, paint, and geometry-aware rendering
      tranches on the primary branch.
- [x] Use released Skia `0.3.7`; keep all local/path dependencies out of the
      release tree.
- [x] Update installation and rendering examples to the current Skia API.
- [x] Publish a feature support matrix with `supported`, `approximate`,
      `diagnostic-only`, and `deferred` tiers.
- [x] Remove stale claims that inner shadows, background blur, diamond gradients,
      or editable vectors are unsupported.
- [x] State explicitly that OpenPencil is the visual oracle, not a parity claim.

## Milestone B1: stabilize the public beta API

**Exit condition:** documented beta APIs and result shapes can evolve only under
normal semantic-versioning rules.

- [x] Audit public modules and hide codegen, projection internals, and backend
      implementation modules that are not part of the contract.
- [x] Stabilize the document/query/graph entrypoints and their error tuples.
- [x] Stabilize render selection options: page, root, scale, background, output
      format, fonts, and strict mode.
- [x] Define a documented warning taxonomy with stable codes and contextual
      fields.
- [x] Ensure every approximation exposed by the renderer is represented by a
      structured warning.
- [x] Verify optional-Skia behavior: query and graph APIs compile and run without
      Skia installed; rendering fails with a clear capability error.
- [x] Document the supported Elixir, OTP, Rust, and platform matrix.

## Milestone B2: close common rendering gaps

**Exit condition:** the documented beta subset covers common application and
design-system selections without rectangle fallbacks.

### Beta blockers

- [x] Add typed polygon, star, and arc/partial-ellipse rendering.
- [x] Support independent corner radii and document smooth-corner behavior.
- [x] Audit clipping for every supported container and transformed path type.
- [x] Audit live boolean geometry versus flattened/imported geometry and reject
      unresolved cases explicitly.
- [x] Verify stroke alignment, dashes, joins, and bounds on open, closed,
      compound, and transformed paths.
- [x] Verify effect order and bounds on nested frames, instances, masks, and text.

### Explicitly deferrable from beta.1

These may remain unsupported if they are listed in the support matrix and fail
under strict mode:

- decorative/arrow/ERD/washi stroke caps
- individual-side strokes
- pattern paints
- noise, grain, glass, repeat, symmetry, and custom effects
- plugin/custom paints and unrestricted image color-adjust pipelines
- outline-mask fidelity

## Milestone B3: prove behavior on real files

**Exit condition:** beta confidence comes from representative real selections,
not only synthetic feature fixtures.

- [x] Maintain at least five legally usable real `.fig` archives outside git,
      covering a design system, typography-heavy UI, image-heavy composition,
      vectors/illustration, and nested components/instances.
- [x] Record at least 30 representative page/root selections across those files.
- [x] Render each selection with identical root, scale, bounds, fonts, and
      background in Figler and OpenPencil.
- [x] Store fixture/reference hashes and case-specific pixel thresholds in
      external manifests.
- [x] Reject oracle cases where OpenPencil ignores the tested feature.
- [x] Run every supported case with `strict: true` and no unexpected warnings.
- [x] Add malformed archive, Kiwi, vector-network, text-range, image, and
      transform cases that must fail without panic or unbounded allocation.
- [x] Record cold/warm time and peak-memory budgets for query, graph, projection,
      asset loading, compilation, and rasterization.

Recommended beta minimums:

- no crash, NIF panic, hang, or scheduler-safety violation across the corpus
- all 30+ selected roots render or fail with an expected structured diagnostic
- all advertised-supported roots pass their OpenPencil thresholds
- no silent rectangle, font, paint, effect, or geometry substitution

## Milestone B4: make the package production-shaped

**Exit condition:** the unpacked Hex artifact behaves like a consumer dependency,
not like the development repository.

- [x] Remove the package-incompatible `override: true` RustQ dependency.
- [x] Separate transitive KiwiCodec/RustQ generator dependencies from runtime
      dependencies; packaged consumers neither resolve nor load them.
- [x] Exclude Figler development codegen and Mix task modules from the runtime
      package.
- [x] Ensure production consumers do not load RustQ, Reach, ExDNA, VibeKit, or
      generator modules.
- [x] Build and test an unpacked package consumer with Skia enabled.
- [x] Build and test an unpacked query-only consumer without Skia.
- [x] Compile the packaged native source with the documented stable Rust version.
- [x] Verify generated files and schemas are fresh before packaging.
- [x] Verify package contents, licenses, checksums, docs links, and source refs.
- [x] Keep precompiled Figler NIFs out of the beta.1 gate unless a supported
      target matrix and immutable artifact workflow are ready.

## Milestone B5: documentation and release readiness

**Exit condition:** a new consumer can evaluate, install, use, and troubleshoot
Figler from the published docs.

- [x] Add a short query tutorial and a short headless-render tutorial.
- [x] Publish the rendering support matrix and warning-code reference.
- [x] Document font resolution order, caller-supplied fonts, and strict
      substitution behavior.
- [x] Document performance guidance for full files versus focused roots.
- [x] Document native source-build requirements and common linker failures.
- [x] Add a beta compatibility policy: public APIs are usable but may change
      between beta releases with changelog notice.
- [x] Convert the unreleased changelog into concise `0.1.0-beta.1` notes.
- [ ] Run package, docs, Cargo, Credo, Dialyzer, ExDNA, Reach, and external-oracle
      gates from a clean synchronized commit.

## `0.1.0-beta.1` release gate

All of the following must be true:

- [ ] Milestones B0, B1, B3, B4, and B5 are complete.
- [ ] Every B2 beta blocker is complete or deliberately moved to the documented
      deferred tier before release.
- [ ] The repository is clean and contains no path/git diagnostic dependencies.
- [ ] Local and GitHub CI are green on the supported matrix.
- [ ] The external real-file oracle suite is green.
- [ ] The unpacked Hex package passes both rendering and query-only consumer
      tests.
- [ ] Hex package and HexDocs publication, version tag, and GitHub Release use
      the same immutable release commit.

## After beta.1

Feedback should drive beta.2 priorities. Likely follow-up work includes pattern
and noise paints, decorative strokes, smooth corners, broader text shaping,
advanced effects, optional precompiled Figler NIFs, and deeper OXC/Vize
boundary-schema migration.
