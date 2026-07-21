# Querying and headless rendering

Figler has two complementary scene views: a projected index for fast raw-file
queries and an effective graph for resolved instances and overrides. Rendering
uses the effective view and keeps archive assets through `Figler.Document`.

## Query a file

Read the archive and build one reusable index when issuing more than one query:

```elixir
alias Figler.Scene

fig = File.read!("design.fig")
index = Scene.index(fig)

pages = Scene.pages(index)
frames = Scene.by_type(index, :frame, fields: [:name, :size])
buttons = Scene.name_contains(index, "Button", fields: [:name, :parent_guid])
labels = Scene.text_contains(index, "Submit", fields: [:name, :text])
```

A valid lookup with no match returns `nil` or `[]`. Malformed inputs, selectors,
GUIDs, and options raise `Figler.Error`; see [Errors and
options](errors-and-options.md).

Use `Scene.query/3` for structural selectors and helpers for dynamic values:

```elixir
visible_text = Scene.query(index, "//text[@visible='true'][@text]", fields: [:name, :text])
card_frames = Scene.name_contains(index, "Card", fields: [:name, :size])
```

Build a focused effective graph only when resolved instance semantics are
needed:

```elixir
[%{guid: root_guid} | _] = card_frames
graph = Scene.graph(fig, root: root_guid)

tree = Scene.Graph.tree(graph, root: root_guid, depth: 3)
resolved_labels = Scene.text_contains(graph, "Submit")
explanation = Scene.Graph.explain(graph, root_guid)
```

## Render a selected root

Add the optional `:skia` dependency, open the document once, and select an
explicit page or root:

```elixir
fig = File.read!("design.fig")
document = Figler.Document.open!(fig)

case Figler.Render.render(document,
       root: "12:34",
       scale: 2,
       background: :transparent,
       format: :png,
       strict: true,
       fallback_font_paths: ["priv/fonts/Inter-Regular.ttf"]
     ) do
  {:ok, png, %{warnings: []} = metadata} ->
    File.write!("selection.png", png)
    metadata.bounds

  {:error, {:unsupported_render_features, warnings}} ->
    {:unsupported, Enum.map(warnings, &{&1.code, &1.guid})}

  {:error, reason} ->
    {:render_failed, reason}
end
```

`strict: true` is recommended for automated exports. It rejects the same
structured warnings that a non-strict render would return, including
approximations, font substitutions, missing assets, malformed geometry, and
unsupported features.

For repeated output of the same selection, prepare once and vary only output
encoding options:

```elixir
{:ok, scene} = Figler.Render.prepare(document, root: "12:34")
{:ok, png, _metadata} = Figler.Render.render(scene, format: :png)
{:ok, webp, _metadata} = Figler.Render.render(scene, format: :webp, quality: 90)
```

Changing `:root` or `:page` on a prepared scene prepares that selection again.
See [Rendering support](rendering-support.md) for the supported subset and
[Rendering warnings](render-warnings.md) for diagnostic codes.
