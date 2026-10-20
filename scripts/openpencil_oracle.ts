// Dumps OpenPencil's interpreted page trees for a .fig file as JSON.
//
// OpenPencil's occurrence interpreter is the reference for how Figler resolves
// instances. This script runs it from an OpenPencil checkout and prints a compact,
// stable projection that `Figler.Scene.Graph.OpenPencilOracle` compares against.
//
//   bun scripts/openpencil_oracle.ts --openpencil ../open-pencil-app file.fig [--page 0:1]
//
// The checkout must have its dependencies installed (`bun install`).

import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { parseArgs } from 'node:util'

const { values, positionals } = parseArgs({
  allowPositionals: true,
  options: {
    openpencil: { type: 'string', default: process.env.FIGLER_OPENPENCIL_DIR ?? '../open-pencil-app' },
    page: { type: 'string', multiple: true },
    'max-depth': { type: 'string' }
  }
})

const [figPath] = positionals
if (!figPath) {
  console.error('usage: bun scripts/openpencil_oracle.ts --openpencil DIR FILE.fig [--page ID]')
  process.exit(2)
}

const root = resolve(values.openpencil!)
const { createArchiveDocumentReader } = await import(`${root}/packages/fig/src/document/read.ts`)
const maxDepth = values['max-depth'] ? Number(values['max-depth']) : Infinity

type GUID = { sessionID: number; localID: number }
type Occurrence = {
  sourceId: string
  mainComponentId: string | null
  properties: Record<string, any>
  children: Occurrence[]
  derivedSize?: { x: number; y: number }
}

const guid = (value: GUID | undefined) => (value ? `${value.sessionID}:${value.localID}` : null)

function project(node: Occurrence, depth: number): Record<string, unknown> {
  const p = node.properties
  const out: Record<string, unknown> = {
    source_id: node.sourceId,
    type: p.type ?? null,
    name: p.name ?? null,
    visible: p.visible ?? true
  }
  if (p.type === 'INSTANCE') out.main_component_id = node.mainComponentId
  const size = node.derivedSize ?? p.size
  if (size) out.size = [size.x, size.y]
  if (p.transform) out.position = [p.transform.m02, p.transform.m12]
  if (p.opacity !== undefined && p.opacity !== 1) out.opacity = p.opacity
  if (p.type === 'TEXT') out.characters = p.textData?.characters ?? ''
  if (depth < maxDepth) out.children = node.children.map((child) => project(child, depth + 1))
  else out.child_count = node.children.length
  return out
}

const diagnostics: Record<string, unknown>[] = []
const options = {
  derivedBounds: true,
  onUnresolvedProperty: (d: any) => diagnostics.push({ kind: 'property', ...pathDiagnostic(d) }),
  onUnresolvedAssignment: (d: any) => diagnostics.push({ kind: 'assignment', ...pathDiagnostic(d) }),
  onMissingComponent: (d: any) =>
    diagnostics.push({ kind: 'component', owner_id: d.ownerId, component_id: d.componentId }),
  onMissingSlotContent: (d: any) =>
    diagnostics.push({ kind: 'slot_content', slot_id: d.slotId, slot_content_id: d.slotContentId })
}

function pathDiagnostic(d: any) {
  return {
    owner_id: d.ownerId,
    main_component_id: d.mainComponentId ?? null,
    path: d.path.map(guid),
    reason: d.reason.replace('-', '_')
  }
}

const bytes = readFileSync(figPath)
const { reader } = createArchiveDocumentReader(
  bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength)
)
const wanted = values.page ? new Set(values.page) : null
const pages = reader.pages
  .filter((page: { id: string; internalOnly: boolean }) =>
    wanted ? wanted.has(page.id) : !page.internalOnly
  )
  .map((page: { id: string; name: string }) => ({
    id: page.id,
    name: page.name,
    tree: project(reader.readPage(page.id, options), 0)
  }))

for (const d of reader.bindingDiagnostics)
  diagnostics.push({ kind: 'binding', source_id: d.sourceId, field: d.field, key: d.key })

process.stdout.write(JSON.stringify({ file: figPath, pages, diagnostics }))
