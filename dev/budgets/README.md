# First-beta performance budgets

`first-beta.json` records the reference measurements and deliberately wider
regression ceilings for the beta workload. It is development evidence, not a
cross-machine performance guarantee.

Run the budget directly from the repository with external fixtures:

```sh
FIGLER_BUDGET_LARGE_FIXTURE='/path/to/Preline UI Figma (Community).fig' \
FIGLER_BUDGET_LARGE_ROOT='292075:63881' \
FIGLER_BUDGET_RENDER_FIXTURE='/path/to/features.fig' \
FIGLER_BUDGET_RENDER_ROOT='170:1' \
FIGLER_BUDGET_LIMITS=dev/budgets/first-beta.json \
FIGLER_BUDGET_OUTPUT=/tmp/figler-beta-budget.json \
mix run bench/beta_budgets.exs
```

The large fixture measures indexed query, full effective-graph construction,
and focused native projection. The render fixture's image-paint root measures
asset loading, compilation into one Skia document, and PNG rasterization.

The runner records one first-use sample, warms each operation once, and records
five warm samples by default. `FIGLER_BUDGET_WARMUP` and
`FIGLER_BUDGET_SAMPLES` can override those counts. Warm timing reports p50 and
p95. Peak BEAM memory is polled on an isolated worker process; peak RSS is the
whole BEAM OS-process delta and therefore includes native work but can contain
runtime noise. The runner exits unsuccessfully when a configured ceiling is
exceeded.

The 104 MiB Preline graph intentionally exercises the expensive complete
resolver, including roughly 78,000 source nodes and 78,000 effective clones. A
focused application should prefer root-focused graph options when it does not
need the complete effective document.
