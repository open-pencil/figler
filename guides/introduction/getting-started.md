# Getting Started

Figler reads exported Figma `.fig` archives, internal `fig-kiwi` containers, and raw Kiwi message payloads. Most applications should pass the complete `.fig` binary to `Figler.Scene`, or open it once with `Figler.Document` when rendering needs archive assets.

## Installation

Add Figler to `mix.exs`:

```elixir
def deps do
  [
    {:figler, "~> 0.1.0-beta.1"},
    {:skia, "~> 0.3.7"} # optional
  ]
end
```

Skia is only required for raster rendering. Query-only applications do not compile or load it through Figler.

Fetch dependencies:

```bash
mix deps.get
```

Figler's decoder is a Rustler NIF built from source. The supported beta baseline is Elixir 1.19/OTP 27 or Elixir 1.20/OTP 29 with stable Rust 1.97 on x86-64 Linux. See [Native Builds](../production/native-builds.md) for prerequisites and troubleshooting.

## Inspect a file

```elixir
alias Figler.Scene

fig = File.read!("design.fig")
summary = Scene.summary(fig)
index = Scene.index(fig)

IO.inspect(summary.node_count)
IO.inspect(Scene.pages(index))
IO.inspect(Scene.components(index))
```

Reuse the index for repeated queries:

```elixir
frames = Scene.by_type(index, :frame, fields: [:name, :size])
buttons = Scene.name_contains(index, "Button", fields: [:name, :parent_guid])
labels = Scene.text_contains(index, "Continue", fields: [:name, :text])
```

A valid lookup with no match returns `nil` or `[]`. Invalid archives, payloads, selectors, GUIDs, and options raise `Figler.Error` on direct-returning scene APIs.

See [Querying Scenes](../querying/querying-scenes.md).

## Resolve an effective subtree

Build an effective graph when source nodes are not enough and instance semantics matter:

```elixir
graph = Scene.graph(fig, root: "12:34")

tree = Scene.Graph.tree(graph, root: "12:34", depth: 3)
resolved_text = Scene.text_contains(graph, "Continue")
explanation = Scene.Graph.explain(graph, "12:34")
```

Focused graphs retain the selected subtree and semantic dependencies without forcing every populated instance in the document.

See [Effective Graphs](../querying/effective-graphs.md).

## Render a root

Open a document to preserve `images/*`, message blobs, and page metadata:

```elixir
document = fig |> Figler.Document.open!()

case Figler.Render.render(document,
       root: "12:34",
       scale: 2,
       format: :png,
       strict: true
     ) do
  {:ok, png, %{warnings: []}} ->
    File.write!("selection.png", png)

  {:error, {:unsupported_render_features, warnings}} ->
    IO.inspect(warnings, label: "unsupported render features")

  {:error, reason} ->
    IO.inspect(reason, label: "render failed")
end
```

Use `strict: true` for automated exports. Non-strict mode returns the same diagnostics in render metadata and may produce partial or approximate output.

See [Headless Rendering](../rendering/headless-rendering.md) and the [Rendering Support Matrix](../rendering/rendering-support.md).

## Choose the right API

| Need | Start with |
| --- | --- |
| Page, node, name, text, or type lookup | `Figler.Scene.index/1` and scene helpers |
| Structural selector | `Figler.Scene.query/3` |
| Resolved instances and overrides | `Figler.Scene.graph/2` |
| Raster output | `Figler.Document` and `Figler.Render` |
| Exact generated Figma fields | `Figler.decode_message/1` |
| Dynamic map-shaped tooling | Runtime codecs or sparse decoding |

The next guides explain each layer without requiring applications to adopt the others.
