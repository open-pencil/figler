# FigKiwi

FigKiwi is a companion package for [`kiwi_codec`](../kiwi_codec). It includes the Figma `.kiwi` schema, generated static schema modules, and helpers for Figma `Message` payloads.

Generic Kiwi wire primitives, schema parsing, runtime interpretation, DSL, and code generation stay in `kiwi_codec`.

## Usage

Prefer generated schema structs for normal use:

```elixir
message = %FigKiwi.Schema.Message{type: :node_changes, session_id: 12, node_changes: []}
binary = FigKiwi.encode_message(message)
message = FigKiwi.decode_message(binary)
```

Sparse native decode is available when you need recursive schema-backed maps without materializing hundreds of absent `nil` fields:

```elixir
sparse = FigKiwi.decode_sparse_message(binary)
FigKiwi.Sparse.module(sparse)
FigKiwi.Sparse.get(sparse, :node_changes)
```

Map-based runtime encode/decode is available for tooling:

```elixir
schema = FigKiwi.schema()
message = FigKiwi.decode_message_runtime(binary)
binary = FigKiwi.encode_message_runtime(%{"type" => "NODE_CHANGES"})
```

For `fig-kiwi` chunk containers:

```elixir
parsed = FigKiwi.Container.parse(binary)
chunks = Enum.map(parsed.chunks, &FigKiwi.Container.inflate/1)

decoded = FigKiwi.Container.decode(binary)
```

Projected native scene queries avoid materializing the full generated schema tree. They accept raw Kiwi `Message` payloads, `canvas.fig` containers, or `.fig` ZIPs containing `canvas.fig`:

```elixir
alias FigKiwi.Scene

summary = Scene.summary(fig_binary)
canvases = Scene.query(fig_binary, "//canvas")
text = Scene.query(fig_binary, "//text[@text]", fields: [:name, :text])

index = Scene.index(fig_binary) # %FigKiwi.Scene.Index{}
canvases = Scene.pages(index)
node = Scene.node(index, "0:123")
children = Scene.children(index, "0:123")
descendants = Scene.descendants(index, "0:123")
frames = Scene.find(index, type: :frame, name_contains: "Card")
components = Scene.components(index)
filled_nodes = Scene.with_fills(index)
tree = Scene.tree(index, depth: 3)

# A graph is the separate effective-scene surface for resolved Figma semantics:
# populated instances, overrides, component props, swaps, derived symbol data,
# and layout adjustments. Use `root:`/`focus:` for fast focused inspection.
graph = Scene.graph(fig_binary, root: "0:123") # %FigKiwi.Scene.Graph{}
text = Scene.text_contains(graph, "Submit")

# Graph-specific helpers expose resolved trees, provenance, diffs, and instance
# metadata for Figma debugging/tooling.
tree = Scene.Graph.tree(graph, root: "0:123", depth: 3)
explanation = Scene.Graph.explain(graph, "0:123")
changes = Scene.Graph.diff(graph, root: "0:123")
instance = Scene.Graph.instance(graph, "0:123")
```

For dynamic values, prefer native helpers instead of interpolating XPath strings:

```elixir
text_nodes = Scene.by_type(index, :text)
buttons = Scene.name_contains(index, "Button")
labels = Scene.text_contains(index, "Label")
named = Scene.named(index, "Primary action")

button_labels =
  index
  |> Scene.by_type(:text)
  |> Scene.name_contains("Button")
  |> Scene.attribute(:text)

# Helper APIs can push field filtering into native code when starting from an index.
label_text_nodes = Scene.text_contains(index, "Label", fields: [:text])

all_text =
  index
  |> Scene.text_nodes()
  |> Scene.text(sep: "\n")
```

Projected XPath nodes are returned as `%FigKiwi.Scene.Node{}` structs and expose `@guid`, `@type`, `@name`, `@parent_guid`, `@position`, geometry, visibility, text, font, and text-style attributes to XPath. Summaries are returned as `%FigKiwi.Scene.Summary{}` structs. Use `Scene.query/2` for raw XPath and build a reusable scene index when running multiple queries over the same file.

## Updating generated schema modules

```sh
rm -rf lib/generated
mix kiwi.gen priv/schema/fig.kiwi --module-prefix FigKiwi.Schema --out lib/generated
mix format
mix ci
```

## Benchmarks

```sh
elixir bench/message_bench.exs

FIG_KIWI_OPEN_PENCIL_FIXTURE_DIR=/path/to/open-pencil/tests/fixtures \
  mix fig_kiwi.bench.fixtures

# Skip expensive full materialization on large fixtures.
FIG_KIWI_OPEN_PENCIL_FIXTURE_DIR=/path/to/open-pencil/tests/fixtures \
FIG_KIWI_BENCH_FULL_DECODE=0 \
  mix fig_kiwi.bench.fixtures nuxtui.fig
```

OpenPencil oracle tests can use a Node-compatible OpenPencil CLI build:

```sh
FIG_KIWI_OPEN_PENCIL_FIXTURE_DIR=/path/to/open-pencil/tests/fixtures \
FIG_KIWI_OPEN_PENCIL_NODE_CLI=/path/to/openpencil-cli.js \
  mix test test/open_pencil_node_oracle_test.exs
```

## Development

```sh
mix deps.get
mix ci
```
