# Graph Resolver Pipeline

`FigKiwi.Scene.Graph` builds an effective scene from raw projected scene nodes.
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
graph = FigKiwi.Scene.graph(fig_binary, until: :component_props)
```

Use `skip:` for targeted experiments, not public performance flags:

```elixir
graph = FigKiwi.Scene.graph(fig_binary, skip: [:sync_overrides])
```

## Provenance and unresolved diagnostics

Resolver stages record provenance on effective nodes. Inspect it with:

```elixir
FigKiwi.Scene.Graph.explain(graph, "0:1")
FigKiwi.Scene.Graph.unresolved(graph)
```

Applied entries describe what changed; unresolved entries describe preserved or skipped semantic references.

## Performance profiling

Avoid strict timing assertions in CI. For local checks, use rough comparisons and record outputs in `/tmp`:

```sh
mise exec rust@1.96.0 -- mix fig_kiwi.profile.graph \
  --fixture /tmp/figma-current.fig \
  --root 3740:112537 \
  --until variables \
  --output /tmp/figkiwi-profile-current.json
```

For current live-export oracle validation:

```sh
FIG_KIWI_ORACLE_FIXTURE=/tmp/figma-current.fig \
  mise exec rust@1.96.0 -- mix run scripts/compare_figma_oracles.exs \
  /tmp/current_oracles_manifest.json
```
