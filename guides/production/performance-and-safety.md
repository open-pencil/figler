# Performance and Safety

Figler is designed for automated work on production-sized design files. The APIs let applications choose between fast analysis, complete transformation data, focused semantic resolution, and full-document resolution rather than paying the highest cost for every task.

## Parse once, query many times

Build one scene index per input version:

```elixir
index = Figler.Scene.index(fig)

pages = Figler.Scene.pages(index)
buttons = Figler.Scene.name_contains(index, "Button")
text = Figler.Scene.text_contains(index, "Checkout")
```

Do not pass the original binary to every helper in a loop; that rebuilds the index each time.

In the first-beta reference workload, a 104 MiB community file with roughly 79,000 source nodes built and queried the native index in about 11 ms warm p95 on an AMD Ryzen 9 9950X. Treat this as workload evidence, not a cross-machine guarantee.

## Decode completely only for transformations

`Figler.decode!/1` materializes the generated message structs because callers need exact values for round-trip editing. Use it when transforming a file, not as the default way to answer a name or hierarchy query.

A typical workflow can combine both APIs:

```elixir
index = Figler.Scene.index(fig)
targets = Figler.Scene.name_contains(index, "Deprecated")

document = Figler.decode!(fig)
# Apply exact changes to document.message using the discovered GUIDs.
updated = Figler.encode!(document)
```

## Focus effective graphs

A complete effective graph can be the most expensive operation because it resolves every component instance and generated clone.

Prefer a known root:

```elixir
graph = Figler.Scene.graph(fig, root: "12:34")
```

Or several relevant roots:

```elixir
graph = Figler.Scene.graph(fig, focus: ["12:34", "56:78"])
```

The representative 104 MiB workload intentionally resolves about 78,000 source nodes and 78,000 effective clones. Its full graph took roughly 5.1 seconds warm p95 and peaked near 0.82 GiB of additional BEAM process memory and 1.70 GiB of additional RSS on the reference host. Full graphs are available, but they should be a deliberate choice.

## Reuse documents and prepared scenes

Open once when rendering multiple roots:

```elixir
document = Figler.Document.open!(fig)

Figler.Render.render(document, root: "12:34")
Figler.Render.render(document, root: "56:78")
```

Prepare once when rendering the same effective selection with multiple output settings:

```elixir
{:ok, scene} = Figler.Render.prepare(document, root: "12:34")

Figler.Render.render(scene, scale: 1, format: :png)
Figler.Render.render(scene, scale: 2, format: :webp, quality: 90)
```

## Archive extraction limits

Figler checks ZIP metadata before extraction. The beta limits are:

| Limit | Value |
| --- | ---: |
| Archive entries | 4,096 |
| One uncompressed entry | 256 MiB |
| Total declared uncompressed content | 512 MiB |

Inputs exceeding a limit return or raise `%Figler.Error{code: :invalid_archive}` before extraction.

These limits protect services from malformed archives and decompression bombs. They are part of the beta contract rather than user-configurable tuning knobs.

## Render allocation limits

Output bounds are validated before image/font loading and canvas allocation:

| Limit | Value |
| --- | ---: |
| Width or height | 16,384 pixels |
| Total pixels | 67,108,864 |

Non-finite, negative, or oversized bounds return:

```elixir
{:error, {:invalid_render_bounds, context}}
```

The context includes the requested scale, source bounds, output dimensions, reason, and active limits.

## Benchmark your own workload

The repository includes `bench/beta_budgets.exs`, which measures:

- indexed querying;
- complete effective-graph construction;
- focused render projection;
- asset loading;
- compilation into one Skia document;
- rasterization.

Run it with external fixtures:

```bash
FIGLER_BUDGET_LARGE_FIXTURE='/path/to/large.fig' \
FIGLER_BUDGET_LARGE_ROOT='12:34' \
FIGLER_BUDGET_RENDER_FIXTURE='/path/to/render.fig' \
FIGLER_BUDGET_RENDER_ROOT='56:78' \
FIGLER_BUDGET_LIMITS=dev/budgets/first-beta.json \
FIGLER_BUDGET_OUTPUT=/tmp/figler-budget.json \
mix run bench/beta_budgets.exs
```

The checked-in limits are deliberately wider than the recorded reference measurements. Use representative files, roots, fonts, and output dimensions when establishing budgets for your application.
