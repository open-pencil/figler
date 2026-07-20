# Figler

Read and query Figma files from Elixir.

Figler lets Elixir applications inspect Figma `.fig` files without shelling
out to Node or materializing the entire Figma document into huge nested structs.
It is designed for tooling that needs to answer questions like:

- What pages, frames, components, and text nodes are in this file?
- Which nodes match a type, name, text snippet, or XPath-style selector?
- What does a scene look like after Figma instance overrides and component
  properties are applied?
- Can I decode a full Figma message when I need exact schema data?
- Can I scan large files quickly when I only need a handful of fields?

Figler includes the Figma Kiwi schema, generated Elixir schema modules, native
sparse decoders, a fast projected scene index, and an effective scene graph for
resolved Figma semantics.

## Why Figler?

Figma files are large, deeply nested, and encoded with Figma's Kiwi schema.
Naively decoding every field into every generated struct can be expensive and
hard to work with. Figler gives you multiple levels of access:

- **Fast scene queries** for common inspection tasks, backed by native decoding.
- **Reusable indexes** when running many queries over the same file.
- **Sparse decoding** when you need schema-shaped data but only fields present
  on the wire.
- **Full generated structs** when you need exact typed access to the complete
  Figma message schema.
- **Effective scene graphs** when raw nodes are not enough and you need Figma
  semantics such as populated instances, symbol overrides, component props,
  swaps, derived symbol data, and layout metadata.

## Installation

```elixir
{:figler, "~> 0.1"}
```

For optional native raster rendering, also add Skia:

```elixir
{:skia, "~> 0.3.7"}
```

Figler uses a Rustler native extension for high-performance decoding and scene
queries. Building from source requires a Rust toolchain.

## Quick start: query a Figma file

Most scene APIs accept a Figma `.fig` file directly. Lower-level APIs can also
work with already-extracted Figma Kiwi binaries when you have them.

```elixir
alias Figler.Scene

fig = File.read!("design.fig")

summary = Scene.summary(fig)
pages = Scene.pages(fig)
text_nodes = Scene.query(fig, "//text[@text]", fields: [:name, :text])
```

For repeated queries, build an index once:

```elixir
index = Scene.index(fig)

frames = Scene.by_type(index, :frame)
buttons = Scene.name_contains(index, "Button")
labels = Scene.text_contains(index, "Label", fields: [:name, :text])
components = Scene.components(index)
filled_nodes = Scene.with_fills(index)
```

Navigate the scene without writing selectors:

```elixir
roots = Scene.roots(index)
node = Scene.node(index, "0:123")
parent = Scene.parent(index, "0:123")
children = Scene.children(index, "0:123")
descendants = Scene.descendants(index, "0:123")
```

Helpers also compose on returned node lists:

```elixir
button_labels =
  index
  |> Scene.by_type(:text)
  |> Scene.name_contains("Button")
  |> Scene.attribute(:text)

all_text =
  index
  |> Scene.text_nodes()
  |> Scene.text(sep: "\n")
```

Scene queries return `%Figler.Scene.Node{}` structs. Projected fields include
GUID, type, name, parent GUID, position, size, transform, visibility, lock
state, text, font metadata, style GUIDs, component keys, and paint counts.

## XPath-style selectors

Use `Scene.query/3` when a selector is clearer than helper calls:

```elixir
canvases = Scene.query(index, "//canvas")
visible_text = Scene.query(index, "//text[@visible='true'][@text]")
card_frames = Scene.query(index, "//frame[contains(@name, 'Card')]")
```

Use the `:fields` option to keep returned nodes small and push field filtering
into native code:

```elixir
Scene.query(index, "//text[@text]", fields: [:name, :text])
```

For dynamic values, prefer helpers such as `Scene.name_contains/3` and
`Scene.text_contains/3` instead of interpolating selector strings.

## Effective scene graphs

The projected index is the fast raw view. A graph is the semantic view.

Use `Scene.graph/2` when you need resolved Figma behavior rather than only raw
node records:

```elixir
graph = Scene.graph(fig, root: "0:123")

resolved_text = Scene.text_contains(graph, "Submit")
tree = Scene.Graph.tree(graph, root: "0:123", depth: 3)
explanation = Scene.Graph.explain(graph, "0:123")
changes = Scene.Graph.diff(graph, root: "0:123")
instance = Scene.Graph.instance(graph, "0:123")
stats = Scene.Graph.stats(graph)
```

Graphs are useful for debugging design systems, comparing fixtures, inspecting
instances, and building tools that need effective scene structure. Use `root:`
or `focus:` to limit work to a subtree and its semantic dependencies.

## Render with Skia

Open a complete document when rendering needs archive assets as well as scene
data. The document retains `canvas.fig`, `images/*`, message blobs, archive
entries, and page metadata without densely decoding every `NodeChange`:

```elixir
document = Figler.Document.open!(fig)
image = document.images["deadbeef..."]

{:ok, png, metadata} =
  document
  |> Figler.Render.render(page: 0, scale: 2, format: :png)

File.write!("page.png", png)
```

Rendering projects only the selected root's paint and shape metadata,
normalizes it into typed rendering values (including text and font requests),
applies effective instance overrides, and compiles one batched Skia document
for a single native rendering boundary.

The rendering surface supports affine transforms, opacity, rectangular
clipping, solid and positioned linear/radial/angular gradient paints, archive
and message-blob image fills (`FILL`, `FIT`, transformed `STRETCH`, and `TILE`),
basic strokes, rectangles, ellipses, lines, UTF-16-indexed rich-text style
runs with per-run fonts and solid fills, imported vector paths, flattened
boolean geometry, node blend layers, drop shadows, foreground blur,
and alpha/luminance sibling masks. Diamond gradients and outline masks are
explicit approximations. Editable vector networks, unflattened booleans, inner
shadows, and backdrop blur are reported rather than silently approximated.

Unsupported or approximate features are listed in `metadata.warnings`; this
includes unavailable requested font families, missing glyph coverage, malformed
style ranges, and font substitutions. Figler resolves each grapheme cluster
against its style run's requested font and Figma fallback-font metadata, then
asks Skia for installed character-aware fallbacks. Callers can provide deterministic
fallbacks with `fallback_font_paths: [...]` or already-loaded
`fallback_typefaces: [...]`, and can pass BCP-47 hints with
`font_languages: [...]`. Pass `strict: true` to reject substitutions instead of
silently accepting fallback glyphs or a partial rendering. Visual tests can
compare decoded OpenPencil reference PNGs with Figler RGBA output through
`Figler.Render.Oracle.compare_png/3`. For repeatable same-scene comparisons,
create a `render-manifest.json` that records the `.fig` fixture, reference PNG,
root or page, scale, background, thresholds, optional fallback font paths and
language tags, and optional `expected_warning_codes`, then run:

```bash
mix figler.render.oracles --manifest /path/to/render-manifest.json
# or discover manifests recursively without checking large fixtures into git
FIGLER_RENDER_ORACLE_DIR=/path/to/oracles mix figler.render.oracles
```

## Decode Figma messages

When you need exact schema data, decode into generated Elixir structs:

```elixir
message = Figler.decode_message(payload)

%Figler.Schema.Message{
  type: :node_changes,
  node_changes: node_changes
} = message
```

You can also encode generated structs back to Kiwi binary:

```elixir
binary = Figler.encode_message(message)
```

The vendored schema is available for tooling:

```elixir
schema_text = Figler.schema_text()
schema = Figler.schema()
```

## Sparse decoding for large messages

Sparse decoding keeps the schema shape but avoids allocating every absent field.
It returns maps containing only values present in the encoded payload.

```elixir
sparse = Figler.decode_sparse_message(payload)

Figler.Sparse.module(sparse)
Figler.Sparse.fields(sparse)
Figler.Sparse.present?(sparse, :node_changes)
Figler.Sparse.get(sparse, :node_changes)
```

Sparse maps include `:__kiwi_module__`, so tooling can still identify the
corresponding `Figler.Schema.*` module.

## Low-level Figma Kiwi binaries

Most users should start with `Figler.Scene` and pass a `.fig` file directly.
If you are building import/export tooling and already have Figma's internal
Kiwi container binary, `Figler.Container` can parse it directly:

```elixir
parsed = Figler.Container.parse(container_binary)
chunks = Enum.map(parsed.chunks, &Figler.Container.inflate/1)

decoded = Figler.Container.decode(container_binary)
payload = Figler.Container.data(container_binary)
```

To normalize any supported input into the raw Figma Kiwi `Message` binary:

```elixir
payload = Figler.Scene.payload!(binary)
```

## Runtime map encoding/decoding

For dynamic tools that do not want generated structs, use the runtime schema
interpreter:

```elixir
message = Figler.decode_message_runtime(payload)
binary = Figler.encode_message_runtime(%{"type" => "NODE_CHANGES"})
```

Figler caches the versioned parsed schema and reuses prepared interpreter indexes
for these calls. Prefer generated structs or native projections for the hottest
large-file paths.

## Generated code

Figler checks in generated Elixir schema modules and generated Rust source so
consumers do not need to run code generation during normal use.

Regenerate Elixir schema modules from `priv/schema/fig.kiwi`:

```sh
rm -rf lib/generated
mix kiwi.gen priv/schema/fig.kiwi --module-prefix Figler.Schema --out lib/generated
mix format
```

Regenerate native Rust source from `rustq.exs`:

```sh
mix rustq.gen native
```

Check generated files are fresh:

```sh
mix rustq.gen --check native
```

## Benchmarks and oracle fixtures

Message benchmark:

```sh
elixir bench/message_bench.exs
```

This Benchee suite covers static and interpreted codecs plus native sparse,
graph-seed, scene-index, and graph-materialization paths.

OpenPencil fixture benchmark:

```sh
FIGLER_OPEN_PENCIL_FIXTURE_DIR=/path/to/open-pencil/tests/fixtures \
  mix figler.bench.fixtures
```

Skip expensive full materialization on large fixtures:

```sh
FIGLER_OPEN_PENCIL_FIXTURE_DIR=/path/to/open-pencil/tests/fixtures \
FIGLER_BENCH_FULL_DECODE=0 \
  mix figler.bench.fixtures nuxtui.fig
```

Fixture timings report p50/p95 after two warmups and seven measured samples.
Use `FIGLER_BENCH_WARMUP` and `FIGLER_BENCH_SAMPLES` to tune those counts. Memory
columns are BEAM process deltas and exclude native resource allocations.

Oracle comparisons can use a Node-compatible OpenPencil CLI build:

```sh
FIGLER_OPEN_PENCIL_FIXTURE_DIR=/path/to/open-pencil/tests/fixtures \
FIGLER_OPEN_PENCIL_NODE_CLI=/path/to/openpencil-cli.js \
  mix test test/open_pencil_node_oracle_test.exs
```

## Development

```sh
mix deps.get
mix ci
```

`mix ci` checks Elixir compilation, generated native freshness, formatting,
Rust formatting/checks/clippy, tests, Credo, Dialyzer, clone detection, and
architecture/smell checks.
