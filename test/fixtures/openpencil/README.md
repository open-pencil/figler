# OpenPencil fixtures

Files copied from [OpenPencil](https://github.com/open-pencil/open-pencil)
(MIT License, Copyright (c) 2026 Danila Poyarkov and OpenPencil contributors).

| File | Source | Commit |
| --- | --- | --- |
| `variable-override-precedence.fig` | `tests/fixtures/variable-override-precedence.fig` | 85b83cf05 |
| `instance-overrides/accordion-source-closure.json` | `packages/fig/tests/instance-overrides/fixtures/` | 68c2af560 |
| `instance-overrides/stale-chevron-override.json` | `packages/fig/tests/instance-overrides/fixtures/` | 68c2af560 |
| `instance-overrides/saved-swap-paths.json` | `packages/fig/tests/instance-overrides/fixtures/` | 68c2af560 |

`variable-override-precedence.fig` was saved by a current Figma release. Its
embedded schema defines about 200 message fields that `priv/schema/fig.kiwi`
does not, so it exercises decoding with the file's own schema.

The `instance-overrides` JSON files are decoded `NodeChange` records captured
from real Figma files (see OpenPencil's fixture README for their provenance).
`Figler.Test.NodeChangeJSON` converts them to Figler's sparse record shape.
