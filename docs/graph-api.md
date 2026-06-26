# Graph API Examples

`Figler.Scene.Graph` exposes an effective scene: projected nodes after resolver stages such as
instance population, symbol overrides, component props, variables, and stack layout.

```elixir
graph = Figler.Scene.graph(fig_binary, until: :component_props)
```

## Inspect a resolved node

```elixir
Figler.Scene.Graph.explain(graph, "0:1")
```

The explanation includes the effective node, original source node, applied operations,
unresolved diagnostics, parent/child GUIDs, and instance provenance when applicable.

## Tree

```elixir
Figler.Scene.Graph.tree(graph, root: "0:0", depth: 2)
```

Returns a nested `%Figler.Scene.Node{}` tree rooted at the requested GUID.

## Diff

```elixir
Figler.Scene.Graph.diff(graph)
Figler.Scene.Graph.diff(raw_index, graph)
```

Use this to inspect differences introduced by effective-scene resolver stages.

## Instance provenance

```elixir
Figler.Scene.Graph.instance(graph, "clone:2:1/1:2")
```

Returns the instance/source relationship for populated clone nodes when available.

## Profile

```elixir
Figler.Scene.Graph.profile(fig_binary, until: :variables)
```

Returns stage timings and graph stats. For CLI profiling use:

```sh
mix figler.profile.graph /path/to/file.fig --node 3740:112537
```
