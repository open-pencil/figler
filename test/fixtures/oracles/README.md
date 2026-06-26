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
FIGLER_ORACLE_FIXTURE=/path/to/fixture.fig \
  mise exec rust@1.96.0 -- mix run scripts/compare_figma_oracles.exs manifest.json
```

The `basic/` fixture is a tiny generated `.fig` used by CI as a smoke test for
committed oracle manifests. Do not commit larger binary fixtures directly.

For local or CI environments that provide external real fixtures, set:

```sh
FIGLER_EXTERNAL_ORACLE_DIR=/path/to/oracle-fixtures \
  mise exec rust@1.96.0 -- mix test test/oracle_fixture_test.exs
```

or directly with:

```sh
mise exec rust@1.96.0 -- mix figler.oracles --dir /path/to/oracle-fixtures
```

Each external fixture directory should contain a `.fig`, a `manifest.json`, and
oracle JSON files referenced by that manifest. Use
`external-manifest.template.json` as a starting point for local real-file oracle
sets without committing the binary fixture itself.
