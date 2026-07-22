# Transforming Files

Figler transforms `.fig` files through ordinary Elixir data. Decode a complete document, update generated structs with pattern matching and `Enum`, then encode it again.

## Decode a complete document

```elixir
document = "design.fig" |> File.read!() |> Figler.decode!()
```

The result is a `%Figler.Document{}` containing:

- `message` — the decoded `%Figler.Schema.Message{}`;
- `entries` — every file in the original ZIP archive;
- `images` — archive image assets keyed by their path below `images/`;
- `canvas` and `payload` — the original container and message data;
- `pages` and `blobs` — convenient document metadata.

`Figler.decode/1` returns `{:ok, document}` or `{:error, %Figler.Error{}}` when tuple-based control flow is preferred.

## Change layer names

Generated schema values are ordinary structs:

```elixir
alias Figler.Schema.NodeChange

document =
  update_in(document.message.node_changes, fn nodes ->
    Enum.map(nodes, fn
      %NodeChange{name: "Primary button"} = node ->
        %{node | name: "Checkout button"}

      node ->
        node
    end)
  end)
```

## Replace visible text

Text content lives in `%Figler.Schema.TextData{}`:

```elixir
document =
  update_in(document.message.node_changes, fn nodes ->
    Enum.map(nodes, fn
      %NodeChange{text_data: %{characters: "Buy now"} = text} = node ->
        %{node | text_data: %{text | characters: "Checkout"}}

      node ->
        node
    end)
  end)
```

Pattern matching keeps bulk transformations explicit. More elaborate changes can be ordinary functions:

```elixir
defp localize(%NodeChange{text_data: %{characters: text} = data} = node, translations) do
  case translations do
    %{^text => translated} -> %{node | text_data: %{data | characters: translated}}
    _ -> node
  end
end

document =
  update_in(document.message.node_changes, fn nodes ->
    Enum.map(nodes, &localize(&1, translations))
  end)
```

## Target nodes found by analysis

Use the fast scene API to discover GUIDs, then apply exact changes to the decoded message:

```elixir
index = Figler.Scene.index(fig)

targets =
  index
  |> Figler.Scene.name_contains("Deprecated")
  |> MapSet.new(& &1.guid)

document = Figler.decode!(fig)

document =
  update_in(document.message.node_changes, fn nodes ->
    Enum.map(nodes, fn node ->
      guid = "#{node.guid.session_id}:#{node.guid.local_id}"

      if MapSet.member?(targets, guid) do
        %{node | visible: false}
      else
        node
      end
    end)
  end)
```

This separates fast discovery from exact file mutation without introducing a transformation DSL.

## Update archive files

For complete `.fig` archives, `entries` is the source used when rebuilding the ZIP. Update metadata or assets with the standard `Access` functions:

```elixir
document =
  put_in(document.entries["metadata.json"], Jason.encode!(%{name: "Updated design"}))

document =
  put_in(document.entries["images/deadbeef"], File.read!("replacement.png"))
```

When replacing an image entry directly, update `document.images` too if the same in-memory document will be rendered before encoding:

```elixir
image = File.read!("replacement.png")

document =
  document
  |> put_in([Access.key(:entries), "images/deadbeef"], image)
  |> put_in([Access.key(:images), "deadbeef"], image)
```

## Encode the result

```elixir
updated_fig = Figler.encode!(document)
File.write!("updated.fig", updated_fig)
```

`Figler.encode/1` returns `{:ok, binary}` or `{:error, %Figler.Error{}}`.

The output representation matches the input:

| Input | Output |
| --- | --- |
| Complete `.fig` ZIP archive | Complete `.fig` ZIP archive |
| `fig-kiwi` container | `fig-kiwi` container |
| Raw Figma `Message` | Raw Figma `Message` |

For archives, Figler replaces the canvas container and keeps all other entries. For standalone containers, it retains the schema chunk, version, compression family, and trailing chunks.

## Preserve file semantics

Figler validates the binary encoding, but it cannot infer the intent of arbitrary struct changes. GUIDs, parent relationships, component references, text style ranges, vector data, and image hashes may refer to one another.

Prefer narrow changes to fields you understand, preserve unknown values, and reopen or query the encoded result as a validation step:

```elixir
updated_fig = Figler.encode!(document)
updated = Figler.Scene.index(updated_fig)

if Figler.Scene.text_contains(updated, "Checkout") == [] do
  raise "transformation did not produce the expected scene"
end
```

Use `Figler.decode_message/1` and `Figler.encode_message/1` directly only when working with an already-extracted raw Kiwi message.
