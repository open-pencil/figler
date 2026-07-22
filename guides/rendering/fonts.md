# Fonts

Deterministic text rendering requires the same font data on every machine. Figler does not silently bundle a fallback font or hide substitutions.

## Provide fallback files

```elixir
Figler.Render.render(document,
  root: "12:34",
  fallback_font_paths: [
    "priv/fonts/Inter-Regular.ttf",
    "priv/fonts/Inter-Bold.ttf",
    "priv/fonts/NotoSansSC-Regular.ttf"
  ],
  system_font_fallback: false,
  strict: true
)
```

The order is significant. Figler resolves each grapheme cluster against the requested Figma font and then the caller-provided fallback stack.

A font file is registered with Skia under its embedded family and style metadata. The filename itself does not determine the family.

## Reuse loaded typefaces

Applications that already manage Skia typefaces can pass them directly:

```elixir
Figler.Render.render(document,
  root: "12:34",
  fallback_typefaces: typefaces,
  strict: true
)
```

Use either paths, typefaces, or both. Paths are convenient for jobs and CLI tools; preloaded typefaces avoid repeated file loading in long-running systems.

## Language preferences

Pass BCP 47 language tags to help backend fallback choose the intended script-specific face:

```elixir
Figler.Render.render(document,
  root: "12:34",
  font_languages: ["ja", "en"]
)
```

Language preferences do not replace font files. The selected font still needs glyph coverage for the text.

## System fallback

System font fallback can be enabled explicitly:

```elixir
Figler.Render.render(document,
  root: "12:34",
  system_font_fallback: true
)
```

This is useful for exploratory rendering but makes output depend on the host image. Keep it disabled and provide an explicit font stack when pixels must be reproducible across development, CI, and production.

## Font diagnostics

Font problems are reported as structured render warnings, including:

- unavailable requested fonts;
- fallback substitutions;
- missing glyph coverage;
- malformed font files;
- text runs that cannot be represented exactly.

With `strict: true`, those warnings reject the render:

```elixir
{:error, {:unsupported_render_features, warnings}} =
  Figler.Render.render(document,
    root: "12:34",
    fallback_font_paths: fonts,
    strict: true
  )
```

See [Rendering Warnings](rendering-warnings.md) for the warning contract.

## Deployment checklist

For deterministic output:

1. License and ship the exact font files your documents require.
2. Keep paths stable inside the release or container image.
3. Disable system fallback.
4. Pass language preferences for CJK and other script-specific fallback.
5. Run strict render tests against representative documents.
6. Treat a font file change as a visual output change.

Do not commit third-party fonts to Figler itself. Font licensing and selection belong to the consuming application.
