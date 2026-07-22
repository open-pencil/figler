# Schema and Codecs

Most applications should start with `Figler.Scene` for analysis, `Figler.decode!/1` for complete-file transformations, and `Figler.Render` for images.

Figler also exposes the underlying Figma Kiwi schema and message codecs for importers, exporters, protocol research, and tools that already manage their own container boundary.

## Generated structs

Decode a raw Figma message into generated schema structs:

```elixir
message = Figler.decode_message(payload)

%Figler.Schema.Message{
  type: :node_changes,
  node_changes: node_changes
} = message
```

Every schema record and enum has a generated Elixir module below `Figler.Schema`.

Encode a message after changing it:

```elixir
payload = Figler.encode_message(message)
```

These functions operate on the raw Kiwi message only. Use `Figler.decode!/1` and `Figler.encode!/1` when you need Figler to preserve and rebuild a complete `.fig` archive or `fig-kiwi` container.

## Sparse messages

Sparse decoding returns schema-backed maps containing only fields present on the wire:

```elixir
message = Figler.decode_sparse_message(payload)
node_changes = Figler.Sparse.get(message, :node_changes)
```

Sparse values carry `:__kiwi_module__` metadata so callers can inspect their generated schema type while avoiding default fields that were absent from the payload.

This is useful for protocol inspection. Prefer scene indexes for repeated high-level queries and generated structs for round-trip transformations.

## Runtime map codecs

Decode with the vendored schema at runtime:

```elixir
message = Figler.decode_message_runtime(payload)
```

Encode the map again:

```elixir
payload = Figler.encode_message_runtime(message)
```

Runtime codecs use the source names and enum names from the Figma schema. They are convenient for dynamic tooling that cannot depend on generated structs.

## Vendored schema

Read the original schema text:

```elixir
Figler.schema_text()
```

Or use its parsed `%KiwiCodec.Schema{}` representation:

```elixir
schema = Figler.schema()
message_definition = KiwiCodec.Schema.definition(schema, "Message")
```

The schema shipped with the installed Figler version is the source of truth for generated modules and runtime codecs.

## Container helpers

`Figler.Container` handles standalone `fig-kiwi` binaries:

```elixir
%{version: version, schema: schema, data: payload} =
  Figler.Container.decode(container)
```

Replace only the message while preserving container metadata:

```elixir
updated_container = Figler.Container.replace_data(container, updated_payload)
```

Complete-file transformations normally do not need these helpers; `Figler.encode!/1` performs the same work as part of rebuilding the document.
