# Graph Resolver Pipeline

`Figler.Scene.Graph` builds an effective scene from raw projected scene nodes.
Use the raw `Scene.Index` for fast schema-shaped navigation and `Scene.Graph` when Figma semantics matter.

Typical stage order:

1. `:populate_instances` — clone component/symbol source children under instances.
2. `:symbol_overrides` — apply symbol override patches to source nodes or populated clones.
3. `:sync_overrides` — compatibility synchronization stage.
4. `:component_props` — apply component prop assignments, including swaps.
5. `:sync_component_props` — compatibility synchronization stage.
6. `:derived_symbol_data` — apply derived symbol data and nested target behavior.
7. `:stack_layout` — conservative effective auto-layout adjustments.
8. `:variables` — apply known variable refs or preserve refs as unresolved diagnostics.

Use `until:` to stop at a stage while debugging:

```elixir
graph = Figler.Scene.graph(fig_binary, until: :component_props)
```

Use `skip:` for targeted experiments, not public performance flags:

```elixir
graph = Figler.Scene.graph(fig_binary, skip: [:sync_overrides])
```

The native seed decoder follows the selected stage plan. Builds using `only:`,
`until:`, or `stages:` do not materialize resolver metadata belonging solely to
later omitted stages. The fixed seed-record shape and clone-retention marker keep
projected builds behaviorally equivalent to full metadata decoding for the stages
that do run. To add a stage omitted from the original plan, rebuild from the
original input; an existing graph rejects stages whose seed metadata was not
materialized.

## Provenance and unresolved diagnostics

Resolver stages record provenance on effective nodes. Inspect it with:

```elixir
Figler.Scene.Graph.explain(graph, "0:1")
Figler.Scene.Graph.unresolved(graph)
```

Applied entries describe what changed; unresolved entries describe preserved or skipped semantic references.

## Performance profiling

Use a representative large `.fig` fixture from local storage; do not commit large
customer or oracle files. Record baseline and follow-up profile JSON in `/tmp`
using the same fixture, roots, runtime, and resolver stage cutoff:

```sh
export FIGLER_PROFILE_FIXTURE=/tmp/figma-current.fig
export FIGLER_PROFILE_ROOTS=3740:112537
export FIGLER_PROFILE_UNTIL=variables

mise exec rust@1.96.0 -- mix figler.profile.graph \
  --output /tmp/figkiwi-profile-before.json

# after an optimization
mise exec rust@1.96.0 -- mix figler.profile.graph \
  --output /tmp/figkiwi-profile-after.json
```

The JSON records payload extraction time, initial graph build time, per-stage
resolver timings, and final graph counts. Optimization commits should compare
before/after JSON from the same fixture and should be accepted by oracle tests,
not by intuition.

For per-function investigation on OTP 27+, wrap the same graph build command in
`:tprof` or `:eprof` locally and keep the profiler output in `/tmp` alongside the
stage JSON. Commit methodology and code changes, not the fixture or profiler
output.

For current live-export oracle validation:

```sh
FIGLER_ORACLE_FIXTURE=/tmp/figma-current.fig \
  mise exec rust@1.96.0 -- mix run scripts/compare_figma_oracles.exs \
  /tmp/current_oracles_manifest.json
```
