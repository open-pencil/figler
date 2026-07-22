# Headless Rendering

Figler renders a Figma page, frame, component, instance, or layer without launching a browser. The selected scene is resolved and compiled into one batched Skia document before rasterization.

Add the optional Skia dependency to use rendering:

```elixir
def deps do
  [
    {:figler, "~> 0.1.0-beta.1"},
    {:skia, "~> 0.3.7"}
  ]
end
```

## Render a layer

```elixir
fig = File.read!("design.fig")

{:ok, png, metadata} =
  Figler.Render.render(fig,
    root: "12:34",
    scale: 2,
    background: :transparent,
    format: :png,
    strict: true
  )

File.write!("selection.png", png)
metadata.bounds
```

`root:` accepts a scene GUID. Use `page:` with a page GUID or zero-based page index when the desired selection is a page:

```elixir
Figler.Render.render(fig, page: 0, scale: 1)
Figler.Render.render(fig, page: "0:17", scale: 1)
```

Do not pass `root:` and `page:` together.

## Reuse an open document

Opening the archive once avoids repeated extraction when a job renders multiple selections:

```elixir
document = Figler.Document.open!(fig)

{:ok, card, _metadata} = Figler.Render.render(document, root: "12:34")
{:ok, icon, _metadata} = Figler.Render.render(document, root: "56:78")
```

A document returned by `Figler.decode!/1` is also accepted.

For more control, prepare a rendering-neutral scene separately:

```elixir
{:ok, scene} = Figler.Render.prepare(document, root: "12:34")
{:ok, png, metadata} = Figler.Render.render(scene, scale: 2, strict: true)
```

## Output options

```elixir
Figler.Render.render(document,
  root: "12:34",
  format: :webp,
  quality: 90,
  scale: 2,
  background: "#FFFFFFFF"
)
```

Supported formats are `:png`, `:jpeg`, `:webp`, and `:raw`. `quality:` accepts an integer from 0 to 100 for formats that use it.

Backgrounds can be named colors, `:transparent`, `"#RRGGBB"`, `"#RRGGBBAA"`, RGB tuples, or RGBA tuples.

## Strict rendering

Use strict mode for automated exports and tests:

```elixir
case Figler.Render.render(document, root: "12:34", strict: true) do
  {:ok, image, %{warnings: []} = metadata} ->
    {:ok, image, metadata}

  {:error, {:unsupported_render_features, warnings}} ->
    {:error, warnings}
end
```

Non-strict mode produces output when possible and returns structured `%Figler.Render.Warning{}` values in metadata:

```elixir
{:ok, image, %{warnings: warnings}} =
  Figler.Render.render(document, root: "12:34", strict: false)
```

See [Rendering Warnings](rendering-warnings.md) for warning fields and stable codes.

## Fonts

Provide the fonts required for deterministic text output:

```elixir
Figler.Render.render(document,
  root: "12:34",
  strict: true,
  fallback_font_paths: [
    "priv/fonts/Inter-Regular.ttf",
    "priv/fonts/NotoSansSC-Regular.ttf"
  ],
  font_languages: ["en", "zh-Hans"],
  system_font_fallback: false
)
```

Figler does not silently bundle a fallback font. See [Fonts](fonts.md).

## Graph options

Pass graph resolver options under `graph:`:

```elixir
Figler.Render.render(document,
  root: "12:34",
  graph: [resolve_variables: :known, resolve_styles: :known]
)
```

The selected render root already scopes graph construction. Most callers should keep the default resolver stages.

## Error results

Rendering returns stable error shapes:

```elixir
{:error, {:unsupported_render_features, warnings}}
{:error, {:invalid_render_options, errors}}
{:error, {:invalid_render_bounds, context}}
{:error, :skia_not_available}
```

Output dimensions are validated before a canvas is allocated. See [Errors and Options](../reference/errors-and-options.md) and [Performance and Safety](../production/performance-and-safety.md).
