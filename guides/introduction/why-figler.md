# Why Figler

Figler brings Figma files into ordinary Elixir workflows. It reads the original `.fig` format directly, exposes pleasant APIs for analysis and transformation, and renders selected parts of a design without running Figma, Node.js, or a browser.

## Analyze large files quickly

Production design files can contain tens of thousands of layers and exceed 100 MiB. Figma's JavaScript tooling turns that data into a large JavaScript object graph before an application can use it.

Figler's native parser is faster than Figma's JavaScript implementation and lets callers ask for the information they need:

```elixir
index = Figler.Scene.index(fig)

Figler.Scene.pages(index)
Figler.Scene.components(index)
Figler.Scene.name_contains(index, "Button")
Figler.Scene.text_contains(index, "Checkout")
```

The index is reusable, so one background job can answer many questions without reading the file again. This works well for:

- design-system audits;
- copy extraction and localization checks;
- component inventories;
- accessibility and naming rules;
- asset and screenshot pipelines;
- migration tooling;
- design change analysis.

See [Querying Scenes](../querying/querying-scenes.md).

## Transform with ordinary Elixir

A `.fig` file can be decoded into generated Elixir structs, changed with normal language features, and encoded again:

```elixir
alias Figler.Schema.NodeChange

document = Figler.decode!(fig)

document =
  update_in(document.message.node_changes, fn nodes ->
    Enum.map(nodes, fn
      %NodeChange{name: "Old name"} = node -> %{node | name: "New name"}
      node -> node
    end)
  end)

updated_fig = Figler.encode!(document)
```

There is no separate editing language. Use pattern matching, functions, `Enum`, `Map`, `update_in`, and `put_in`.

Complete archives retain their metadata, images, and other entries. Standalone containers retain their schema, version, compression family, and extra chunks. Raw messages remain raw messages.

See [Transforming Files](../querying/transforming-files.md).

## Understand components and instances

The records stored in a Figma file are not always the final values shown on the canvas. Instances inherit component layers and can apply swaps, property values, text and vector overrides, variables, and layout changes.

Figler can build an effective graph for the whole design or one focused subtree:

```elixir
graph = Figler.Scene.graph(fig, root: "12:34")

Figler.Scene.text_contains(graph, "Continue")
Figler.Scene.Graph.tree(graph, root: "12:34", depth: 4)
Figler.Scene.Graph.explain(graph, "12:34")
```

The graph keeps enough provenance to explain where resolved values came from.

See [Effective Graphs](../querying/effective-graphs.md).

## Render on the server

Figler can turn a page, frame, component, or layer into PNG or WebP without browser automation:

```elixir
{:ok, png, metadata} =
  Figler.Render.render(fig,
    root: "12:34",
    scale: 2,
    strict: true
  )
```

The renderer handles the documented Figma subset through Skia. Strict mode rejects unsupported or approximate behavior, missing assets, and substitutions, which makes automated exports predictable.

See [Headless Rendering](../rendering/headless-rendering.md).

## Stay inside the BEAM

Analysis, transformation, semantic resolution, and rendering are available from the same Elixir application. There is no external conversion service to maintain and no JavaScript worker to supervise.

Query-only applications do not need Skia. Rendering applications can open a document once and reuse its scene data and archive assets. Lower-level schema APIs remain available when a tool needs exact Figma fields.
