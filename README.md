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
```

## Development

```sh
mix deps.get
mix ci
```
