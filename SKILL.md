---
name: figma-browser-oracle
description: Use agent-browser against the live Figma web editor as an oracle for Figler scene decoding.
---

# Figma browser oracle for Figler

Use this when comparing `figler` decoded data against Figma's live web editor internals.

## Preconditions

- `agent-browser` is installed and can launch Chromium.
- You have an authenticated Figma browser state or cookies for an account that can view the target file.
- The target is a Figma design URL.

Do **not** assume `window.figma` exists. In the normal editor page it is usually an accessor that returns `undefined`, even when signed in. The useful oracle is Figma's live internal scene graph.

## Start browser

Prefer an existing saved state if available:

```sh
agent-browser --session figma-oracle \
  --state "$FIGMA_BROWSER_STATE" \
  --args '--no-sandbox,--disable-blink-features=AutomationControlled' \
  open "$FIGMA_DESIGN_URL"
```

If using cookies instead, load them into a fresh session before opening the design. Save reusable auth afterward:

```sh
agent-browser --session figma-oracle state save "$FIGMA_BROWSER_STATE"
```

Use environment variables or task-provided paths. Do not hardcode local paths, file keys, node ids, or account details in tests or scripts.

## Wait for editor readiness

```sh
agent-browser --session figma-oracle wait --load networkidle || true
agent-browser --session figma-oracle wait --fn \
  "window._fullscreen_?.isReady?.() && window.store?.getState?.().isFullscreenDocumentLoaded"
```

## Get Figma's live scene graph

Figma exposes webpack's runtime require through `window.rspackChunk_figma_web_bundler`. Module `758973` currently exports `getActiveTSSceneGraph`.

```sh
cat <<'EOF' | agent-browser --session figma-oracle eval --stdin
(() => {
  let req
  window.rspackChunk_figma_web_bundler.push([
    [Math.floor(Math.random() * 1e9)],
    {},
    r => req = r
  ])

  const { getActiveTSSceneGraph } = req(758973)
  const sg = getActiveTSSceneGraph()
  const root = sg.getRoot()

  return {
    id: root.id,
    guid: root.guid,
    name: root.name,
    type: root.type,
    children: root.childrenNodes.map(node => node.guid)
  }
})()
EOF
```

## Serialize nodes for comparison

Use a bounded traversal. Avoid dumping huge files unless the test explicitly needs it.

```js
function serializeNode(node, depth = 2) {
  if (!node || depth < 0) return null

  return {
    id: node.id,
    guid: node.guid,
    type: node.type,
    name: node.name,
    visible: node.visible,
    locked: node.locked,
    x: node.x,
    y: node.y,
    width: node.width,
    height: node.height,
    characters: node.characters,
    parent: node.parentNode?.guid ?? null,
    children: (node.childrenNodes || [])
      .map(child => serializeNode(child, depth - 1))
      .filter(Boolean)
  }
}
```

Example oracle query:

```sh
cat <<'EOF' | agent-browser --session figma-oracle eval --stdin
(() => {
  let req
  window.rspackChunk_figma_web_bundler.push([[Math.floor(Math.random() * 1e9)], {}, r => req = r])
  const sg = req(758973).getActiveTSSceneGraph()

  function serializeNode(node, depth = 2) {
    if (!node || depth < 0) return null
    return {
      id: node.id,
      guid: node.guid,
      type: node.type,
      name: node.name,
      visible: node.visible,
      locked: node.locked,
      x: node.x,
      y: node.y,
      width: node.width,
      height: node.height,
      characters: node.characters,
      parent: node.parentNode?.guid ?? null,
      children: (node.childrenNodes || []).map(child => serializeNode(child, depth - 1))
    }
  }

  const nodeId = new URL(location.href).searchParams.get('node-id')?.replace('-', ':')
  const node = nodeId ? sg.get(nodeId) : sg.getRoot()
  return serializeNode(node, 2)
})()
EOF
```

## Useful entry points

```js
const root = sg.getRoot()       // DOCUMENT
const node = sg.get("0:1")      // arbitrary node id, if loaded
```

Other internal APIs worth probing when needed:

```js
const api = window._fullscreen_._getTsApisForWasm()
api.PluginCallbacks()
api.JsKiwiSerialization()
api.OpenFileBindings()
api.WebSelection()
api.FigmaApp()
```

## Export the current Figma file version

When using the browser oracle, prefer comparing against a `.fig` exported from the
same live browser session. A repository fixture can be stale relative to the file
currently open in Figma.

Manual/agent-browser flow:

```sh
# 1. Ensure the editor is loaded.
agent-browser --session figma-oracle wait --fn \
  "window._fullscreen_?.isReady?.() && window.store?.getState?.().isFullscreenDocumentLoaded"

# 2. Open Main menu -> File -> Save local copy…
agent-browser --session figma-oracle find role button click "Main menu"
agent-browser --session figma-oracle find role menuitem click "File"
agent-browser --session figma-oracle find role menuitem click "Save local copy…"

# 3. Wait for Figma's "Downloading images…" progress to disappear, then find
# the browser-created ZIP/.fig temp file. agent-browser/Chromium may save it
# under a random UUID-like name in /tmp rather than the requested filename.
find /tmp "$HOME/Downloads" -maxdepth 1 -type f \
  \( -name '*.fig' -o -name '*.crdownload' -o -regex '.*/[0-9a-f-]\{36\}' \) \
  -printf '%TY-%Tm-%Td %TH:%TM %p %s\\n' 2>/dev/null | sort | tail

# 4. Verify it is the expected .fig ZIP and copy to a stable temp path.
unzip -l /tmp/<downloaded-file> | head
cp /tmp/<downloaded-file> /tmp/figma-current.fig
```

Notes:

- If `agent-browser download @ref path` times out for Figma's menu item, use a
  normal click and locate the completed file in `/tmp` or `~/Downloads`.
- Figma may first show a toast/progress item such as `Downloading images… N / M`.
  Wait until it disappears before using the file.
- A valid exported `.fig` is a ZIP containing `canvas.fig`, `meta.json`,
  `thumbnail.png`, and possibly `images/`.
- Use the exported path as `FIGLER_ORACLE_FIXTURE=/tmp/figma-current.fig` for
  oracle comparisons so the Kiwi payload and browser scene graph are the same
  file version.

## Run multiple oracle comparisons

Use `scripts/compare_figma_oracles.exs` with a small JSON manifest when checking
several nodes from the same exported file.

Example manifest:

```json
[
  {
    "node": "3740:112537",
    "depth": 4,
    "json": "/tmp/figma_3740_112537_depth4.json"
  },
  {
    "node": "1706:44411",
    "depth": 3,
    "json": "/tmp/figma_1706_44411_d3.json"
  }
]
```

Run it against the current browser export:

```sh
FIGLER_ORACLE_FIXTURE=/tmp/figma-current.fig \
  mise exec rust@1.96.0 -- mix run scripts/compare_figma_oracles.exs /tmp/oracles.json
```

The script prints a per-node summary and exits non-zero with the collected diffs
if any comparison fails. Relative `json` paths are resolved from the manifest's
directory.

## Comparison fields for Figler

Good oracle fields for `figler` tests:

- `guid` / `id`
- `type`
- `name`
- `parentNode.guid`
- `childrenNodes[].guid`
- `x`, `y`, `width`, `height`
- `visible`, `locked`
- text `characters`

## Caveats

- The browser oracle only sees pages/nodes currently loaded by Figma. Navigate/select pages first if comparing non-current pages.
- Figma internals are private and can change. If module `758973` stops working, search loaded bundles for `getActiveTSSceneGraph` and update the module id.
- Keep oracle code in test helpers/scripts parameterized by environment variables; do not commit account credentials, cookies, local state paths, file keys, or node ids unless they are public fixtures intentionally used by the test.
