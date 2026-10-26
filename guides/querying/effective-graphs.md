# Effective Graphs

A scene index shows records as they are stored in the file. An effective graph applies the Figma semantics that determine what an instance actually contains and displays.

Use a graph when your analysis depends on component inheritance, populated instance children, swaps, property assignments, overrides, variables, or layout-derived values.

Figler resolves instances the way OpenPencil's reader does. Every use of a component is expanded into its own occurrences, so an override on one instance never reaches another use of the same component:

- swaps and component property assignments are routed to the instance they configure before it expands;
- symbol overrides are applied by the instance that declares them, inner instances before outer ones, and an override keeps a field unless a strictly outer instance assigned it;
- uniform instance scale, freeform resize constraints, and the sizes, transforms, and text layout Figma saved for each layer are applied last.

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

These helpers include generated instance clones and their effective values. Clone GUIDs look like `"clone:12:34/5:6"`: the outermost instance followed by the source layers on the path to the clone.

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
- its projected source node;
- source and source GUID information;
- the override claims applied to it and the component properties it binds;
- instance metadata;
- child GUIDs.

`Scene.Graph.record/2` returns a node's full effective record: the sparse `NodeChange` map with every override applied.

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

Review overrides that could not be resolved:

```elixir
unresolved = Scene.Graph.unresolved(graph)
first_ten = Scene.Graph.unresolved(graph, limit: 10)
```

Figma keeps override records after the layer they address is deleted, so real files often carry some. Each diagnostic names the instance that declared the override, its main component, and the layer path:

```elixir
{:unresolved_property, {7, 95}, {7, 94}, [{7, 93}], :missing_target}
```

Overrides that address layers of a component an outer swap replaced are stale and dropped without a diagnostic.

## Control variable and style resolution

```elixir
graph =
  Scene.graph(fig,
    root: "12:34",
    resolve_variables: :known,
    resolve_styles: :known
  )
```

With `:known`, the defaults, each layer's variable bindings resolve in the modes it and its ancestors set, falling back to each collection's default mode: bound numbers, paint colors, text, and visibility are written into the layer's values, and layers take the paints, effects, grids, and text fields of the shared styles they reference. `false` (or `:preserve` and `:refs`) keeps the values the file saved.

A text binding wins over an instance's literal text override, as Figma renders it. Visibility an instance overrides keeps its own value.

## Profile a graph build

```elixir
profile = Figler.Scene.Graph.profile(fig, root: "12:34")

profile.total_ms
profile.phases
profile.graph
```

`phases` times decoding, indexing, and interpretation. Reduce work with `root:` or `focus:`.
