# Effective Graphs

A scene index shows records as they are stored in the file. An effective graph applies the Figma semantics that determine what an instance actually contains and displays.

Use a graph when your analysis depends on component inheritance, populated instance children, swaps, property assignments, overrides, variables, or layout-derived values.

## Build a focused graph

Resolve one subtree whenever you know the root:

```elixir
alias Figler.Scene

fig = File.read!("design.fig")
graph = Scene.graph(fig, root: "12:34")
```

`root:` keeps the result focused while including the component and reference data needed to resolve that subtree. `focus:` accepts one GUID or multiple source GUIDs for broader jobs:

```elixir
graph = Scene.graph(fig, focus: ["12:34", "56:78"])
```

Building an unrestricted graph resolves the whole file and is intentionally more expensive:

```elixir
graph = Scene.graph(fig)
```

## Use the normal scene APIs

Most `Figler.Scene` helpers work with an effective graph:

```elixir
Scene.node(graph, "12:34")
Scene.children(graph, "12:34")
Scene.by_type(graph, :instance)
Scene.name_contains(graph, "Button")
Scene.text_contains(graph, "Continue")
```

These helpers include generated instance clones and their effective values.

XPath queries on a graph still run against its reusable source index. Use helper functions, `Scene.node/2`, and `Scene.children/2` when generated clones must be included.

## Inspect a resolved tree

```elixir
tree = Scene.Graph.tree(graph, root: "12:34", depth: 4)
```

Without `root:`, `tree/2` returns every graph root up to the selected depth.

## Explain where a value came from

```elixir
explanation = Scene.Graph.explain(graph, "12:34")
```

The result includes:

- the effective node;
- its projected source node when available;
- source and source GUID information;
- applied resolver operations;
- unresolved diagnostics;
- instance metadata;
- child GUIDs and active resolver stages.

Inspect instance-specific information directly:

```elixir
instance = Scene.Graph.instance(graph, "12:34")
```

This includes the source component, component property assignments, symbol overrides, derived symbol data, and provenance.

## Diff source and effective values

```elixir
changes = Scene.Graph.diff(graph)
subtree_changes = Scene.Graph.diff(graph, root: "12:34")
```

Only nodes whose effective values differ from their projected source are returned.

Review anything the resolver could not apply:

```elixir
unresolved = Scene.Graph.unresolved(graph)
first_ten = Scene.Graph.unresolved(graph, limit: 10)
```

## Control variable and style resolution

```elixir
graph =
  Scene.graph(fig,
    root: "12:34",
    resolve_variables: :known,
    resolve_styles: :known
  )
```

Variable modes are `false`, `:known`, and `:preserve`. Style modes are `false`, `:refs`, and `:known`. Defaults favor known variable values while leaving style resolution disabled.

## Profile a graph build

```elixir
profile = Figler.Scene.Graph.profile(fig, root: "12:34")

profile.total_ms
profile.initial_ms
profile.stages
profile.graph
```

Use profiling before changing stage selection. Most applications should keep the standard resolver pipeline and reduce work with `root:` or `focus:` rather than manually skipping semantic stages.
