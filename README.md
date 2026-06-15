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
named_text = Scene.query(fig_binary, "//text[contains(@name, 'Hello')]")

index = Scene.index(fig_binary)
canvases = Scene.pages(index)
node = Scene.node(index, "0:123")
children = Scene.children(index, "0:123")
frames = Scene.find(index, type: :frame, name_contains: "Card")
tree = Scene.tree(index, depth: 3)
```

Projected XPath nodes are returned as `%FigKiwi.Scene.Node{}` structs and expose `@guid`, `@type`, `@name`, `@parent_guid`, and `@position` to XPath. Summaries are returned as `%FigKiwi.Scene.Summary{}` structs. Use `Scene.query/2` for raw XPath and build a reusable scene index when running multiple queries over the same file.

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
```

## Development

```sh
mix deps.get
mix ci
```
