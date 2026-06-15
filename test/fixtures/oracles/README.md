# Figma oracle fixtures

Use this directory for stable, intentionally versioned oracle manifests and JSON
captures when a test fixture is committed to the repository.

Do not commit ad-hoc oracle captures from the live Figma editor or
`/tmp/figma-current.fig` unless the matching `.fig` fixture is also stable and
checked in. Current-export oracle runs should stay in `/tmp` and be regenerated
from the same browser session as the exported `.fig` file.

A manifest is a JSON array (or an object with `comparisons`) whose entries have:

```json
{
  "node": "3740:112537",
  "depth": 4,
  "json": "relative-or-absolute-oracle.json"
}
```

Run with:

```sh
FIG_KIWI_ORACLE_FIXTURE=/path/to/fixture.fig \
  mise exec rust@1.96.0 -- mix run scripts/compare_figma_oracles.exs manifest.json
```
