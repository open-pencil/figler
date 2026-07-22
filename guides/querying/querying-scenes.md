# Querying Scenes

`Figler.Scene` is the fastest way to inspect a `.fig` file. It accepts a complete archive, a standalone `fig-kiwi` container, or a raw Figma message.

## Build an index once

```elixir
alias Figler.Scene

fig = File.read!("design.fig")
index = Scene.index(fig)
```

Reuse the index for every query over that version of the file:

```elixir
Scene.pages(index)
Scene.components(index)
Scene.text_nodes(index)
Scene.with_fills(index)
Scene.with_strokes(index)
```

`Scene.summary/1` is useful when you only need document-level counts and metadata:

```elixir
summary = Scene.summary(fig)
IO.inspect(summary.node_count)
```

## Query with helpers

Find layers by type, exact name, partial name, or text:

```elixir
frames = Scene.by_type(index, :frame)
button = Scene.named(index, "Primary Button")
buttons = Scene.name_contains(index, "Button")
checkout_copy = Scene.text_contains(index, "Checkout")
```

Narrow the returned fields when a job only needs a few values:

```elixir
Scene.by_type(index, :text, fields: [:name, :text, :parent_guid])
```

`:guid` and `:node_type` are always present. Other omitted fields are `nil` in the returned `%Figler.Scene.Node{}`.

## Query with selectors

`Scene.query/3` accepts XPath-style selectors over the Figma hierarchy:

```elixir
Scene.query(index, "//canvas")
Scene.query(index, "//frame[contains(@name, 'Card')]")
Scene.query(index, "//text[@visible='true'][@text]")
Scene.query(index, "//*[@guid='12:34']")
```

Project fields in the same call:

```elixir
Scene.query(index, "//text[@text]", fields: [:name, :text])
```

Element names are Figma node types such as `canvas`, `frame`, `component`, `instance`, `text`, `vector`, and `rectangle`. Attributes correspond to documented fields on `Figler.Scene.Node`.

Invalid selectors raise `%Figler.Error{code: :invalid_query}`. A valid selector with no matches returns `[]`.

## Navigate the hierarchy

Look up a layer by GUID and move through its relationships:

```elixir
node = Scene.node(index, "12:34")
parent = Scene.parent(index, "12:34")
children = Scene.children(index, "12:34")
siblings = Scene.siblings(index, "12:34")
ancestors = Scene.ancestors(index, "12:34")
descendants = Scene.descendants(index, "12:34")
```

`Scene.roots/1` returns all root nodes in scene order. `Scene.tree/2` builds a nested tree when that shape is more convenient:

```elixir
tree = Scene.tree(index, root: "12:34", depth: 3)
```

A valid GUID that is absent returns `nil` from `node/2` and `parent/2`, or `[]` from collection lookups. A malformed GUID raises `%Figler.Error{code: :invalid_guid}`.

## Read attributes consistently

The helper functions work across projected nodes and effective graph nodes:

```elixir
Scene.attribute(node, :name)
Scene.text(node, :text)
Scene.find(nodes, "12:34")
```

This makes it easy to write analysis functions that accept either a fast source index or a resolved graph.

## Choose an index or graph

Use a scene index when you need the records stored in the file: names, text, types, hierarchy, geometry, styles, and references.

Use `Scene.graph/2` when you need the values produced after component instances, swaps, overrides, variables, and layout are applied. See [Effective Graphs](effective-graphs.md).
