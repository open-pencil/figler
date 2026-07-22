# Figler 🎨

[![Hex.pm](https://img.shields.io/hexpm/v/figler.svg)](https://hex.pm/packages/figler) [![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/figler) [![CI](https://github.com/open-pencil/figler/actions/workflows/ci.yml/badge.svg)](https://github.com/open-pencil/figler/actions/workflows/ci.yml)

Fast `.fig` tooling for Elixir. Analyze production-sized Figma files, transform them with ordinary Elixir, and render pages or individual layers on the server.

Figler parses `.fig` files faster than Figma's JavaScript implementation while giving you structs, pattern matching, `Enum`, XPath-style queries, and headless Skia rendering inside the BEAM.

```elixir
fig = File.read!("design.fig")
index = Figler.Scene.index(fig)

buttons = Figler.Scene.name_contains(index, "Button")
copy = Figler.Scene.text_contains(index, "Checkout")

{:ok, png, %{warnings: []}} =
  Figler.Render.render(fig, root: "12:34", scale: 2, strict: true)

File.write!("button.png", png)
```

No Node.js process, browser session, REST export pipeline, or conversion to generic JSON.

## Why Figler

Figma's own file tooling is built around JavaScript. Analyzing a large design from Elixir normally means running another runtime, converting the file, or sending it to an external service.

Figler reads the original `.fig` file directly. Build an index once, then inspect pages, components, text, hierarchy, geometry, and styles with small, focused queries. Large files stay practical for background jobs, design-system checks, asset pipelines, migrations, and automated exports.

When you need to edit a file, decode it into generated Elixir structs and use the language you already know. Pattern matching and `Enum` are the transformation API. Encoding rebuilds the original representation and preserves untouched archive entries, metadata, images, and Kiwi container data.

Rendering is part of the same library. Figler resolves components, instances, overrides, variables, layout, vectors, paints, effects, masks, images, and rich text before compiling the selected root into one batched Skia document.

See [Why Figler](https://hexdocs.pm/figler/why-figler.html) for common use cases and the design behind the API.

## Installation

```elixir
def deps do
  [
    {:figler, "~> 0.1.0-beta.1"},
    {:skia, "~> 0.3.7"} # optional, only needed for rendering
  ]
end
```

Figler requires Elixir 1.19 or later and a stable Rust toolchain to build its native parser. Rendering uses Skia's published native artifacts when available.

See [Getting Started](https://hexdocs.pm/figler/getting-started.html).

## Analyze designs

Build an index once and run as many queries as you need:

```elixir
alias Figler.Scene

index = "design.fig" |> File.read!() |> Scene.index()

pages = Scene.pages(index)
components = Scene.components(index)
frames = Scene.by_type(index, :frame, fields: [:name, :size])
buttons = Scene.name_contains(index, "Button")
labels = Scene.text_contains(index, "Continue", fields: [:name, :text])
```

Use XPath-style selectors for structural questions:

```elixir
visible_text =
  Scene.query(index, "//text[@visible='true'][@text]",
    fields: [:name, :text, :parent_guid]
  )

cards = Scene.query(index, "//frame[contains(@name, 'Card')]")
```

Navigate through the document without rebuilding it:

```elixir
node = Scene.node(index, "12:34")
parent = Scene.parent(index, "12:34")
children = Scene.children(index, "12:34")
descendants = Scene.descendants(index, "12:34")
```

See [Querying Scenes](https://hexdocs.pm/figler/querying-scenes.html).

## Transform `.fig` files

Decode the complete file, change ordinary Elixir structs, and encode it again:

```elixir
alias Figler.Schema.NodeChange

fig = File.read!("design.fig")
document = Figler.decode!(fig)

document =
  update_in(document.message.node_changes, fn nodes ->
    Enum.map(nodes, fn
      %NodeChange{text_data: %{characters: "Buy now"} = text} = node ->
        %{node | text_data: %{text | characters: "Checkout"}}

      node ->
        node
    end)
  end)

File.write!("updated.fig", Figler.encode!(document))
```

The same API works for complete `.fig` archives, standalone `fig-kiwi` containers, and raw Figma messages. Output keeps the same representation as the input.

Because transformations are just data transformations, you can compose them with normal functions, pattern matching, `Enum.map/2`, `update_in/2`, and `put_in/2` instead of learning an editing DSL.

See [Transforming Files](https://hexdocs.pm/figler/transforming-files.html).

## Resolve what users see

Raw file records describe the source document. Effective graphs apply instance population, swaps, component properties, overrides, variables, and layout so you can inspect the resulting design:

```elixir
graph = Figler.Scene.graph(fig, root: "12:34")

resolved_copy = Figler.Scene.text_contains(graph, "Continue")
tree = Figler.Scene.Graph.tree(graph, root: "12:34", depth: 4)
instance = Figler.Scene.Graph.instance(graph, "12:34")
explanation = Figler.Scene.Graph.explain(graph, "12:34")
```

See [Effective Graphs](https://hexdocs.pm/figler/effective-graphs.html).

## Render headlessly

Render a page, frame, component, or individual layer without a browser:

```elixir
document = Figler.Document.open!(fig)

{:ok, png, metadata} =
  Figler.Render.render(document,
    root: "12:34",
    scale: 2,
    background: :transparent,
    format: :png,
    strict: true,
    fallback_font_paths: ["priv/fonts/Inter-Regular.ttf"]
  )

File.write!("selection.png", png)
metadata.bounds
```

Use `strict: true` for automated exports. Unsupported features, approximations, missing assets, and font substitutions become an error instead of silently changing the image. Non-strict mode returns the same information as structured warnings alongside the rendered output.

See [Headless Rendering](https://hexdocs.pm/figler/headless-rendering.html), the [Rendering Support Matrix](https://hexdocs.pm/figler/rendering-support.html), and [Rendering Warnings](https://hexdocs.pm/figler/rendering-warnings.html).

## Beta status

`0.1.0-beta.1` provides production-shaped analysis, transformation, and rendering APIs, but rendering intentionally supports a documented subset of Figma. It does not promise pixel identity with Figma or OpenPencil for arbitrary documents.

See [Compatibility](https://hexdocs.pm/figler/compatibility.html), [Performance and Safety](https://hexdocs.pm/figler/performance-and-safety.html), and the [Changelog](https://hexdocs.pm/figler/changelog.html).

## Documentation

Full guides and API documentation are available on [HexDocs](https://hexdocs.pm/figler).

## Development

```bash
mix deps.get
mix ci
```

## License

MIT © 2026 dannote
