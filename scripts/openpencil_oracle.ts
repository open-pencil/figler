// Dumps OpenPencil's page trees for a .fig file as JSON.
//
// OpenPencil's reader is the reference for how Figler resolves instances. This
// script runs it from an OpenPencil checkout and prints a compact, stable
// projection that `Figler.Scene.Graph.OpenPencilOracle` compares against.
//
//   bun scripts/openpencil_oracle.ts --openpencil ../open-pencil-app file.fig [--page 0:1]
//
// By default it dumps the occurrence interpreter's trees. With `--scene` it
// materializes the document into OpenPencil's scene graph, which also resolves
// variables, modes, and styles, and dumps the resolved values.
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
    'max-depth': { type: 'string' },
    scene: { type: 'boolean', default: false }
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
  // The materialized width and height, which come from the record's size.
  if (p.size) out.size = [p.size.x, p.size.y]
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
// OpenPencil's placement matrix, loaded with the scene modules.
let localMatrix: (node: any) => number[] = () => []
const buffer = () => bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength)

if (values.scene) {
  const { materializeFigArchive } = await import(`${root}/packages/fig/src/document/materialize.ts`)
  const { getNodeLocalMatrix } = await import(`${root}/packages/scene-graph/src/coordinate.ts`)
  localMatrix = getNodeLocalMatrix
  const { reader } = createArchiveDocumentReader(buffer())
  const pageIds = new Set<string>(
    reader.pages
      .filter((page: { id: string; internalOnly: boolean }) =>
        values.page ? values.page.includes(page.id) : !page.internalOnly
      )
      .map((page: { id: string }) => page.id)
  )
  const { graph } = materializeFigArchive(buffer(), {
    ...options,
    pageIds,
    onUnsupportedVariableExpression: () => undefined,
    onUnresolvedBinding: () => undefined
  })
  const scenePages = graph
    .getNode(graph.rootId)
    .childIds.map((id: string) => graph.getNode(id))
    .filter((page: any) => pageIds.has(page.source?.id))
    .map((page: any) => ({ id: page.source.id, name: page.name, tree: projectScene(graph, page, 0) }))
  const json = JSON.stringify({ file: figPath, pages: scenePages, diagnostics })
  // Exiting before a piped write drains truncates it.
  await new Promise((done) => process.stdout.write(json, done))
  process.exit(0)
}

function hex(value: number): string {
  return Math.round(Math.min(1, Math.max(0, value)) * 255)
    .toString(16)
    .padStart(2, '0')
}

function paints(list: any[] | undefined): string[] {
  return (list ?? [])
    .filter((paint) => paint.visible !== false && paint.type === 'SOLID' && paint.color)
    .map(({ color, opacity }) => {
      const alpha = opacity === undefined || opacity === 1 ? '' : `@${Number(opacity.toFixed(3))}`
      return `#${hex(color.r)}${hex(color.g)}${hex(color.b)}${hex(color.a ?? 1)}${alpha}`
    })
}

function projectScene(graph: any, node: any, depth: number): Record<string, unknown> {
  const out: Record<string, unknown> = {
    source_id: node.source?.id ?? null,
    type: node.type === 'COMPONENT' ? 'SYMBOL' : node.type,
    name: node.name,
    visible: node.visible
  }
  if (node.type !== 'CANVAS') {
    out.size = [node.width, node.height]
    // The placement as Figma's matrix translates it, so rotated layers compare too.
    const matrix = localMatrix(node)
    out.position = [matrix[2], matrix[5]]
  }
  if (node.opacity !== 1) out.opacity = node.opacity
  if (node.type === 'TEXT') {
    out.characters = node.text
    out.font_size = node.fontSize
  }
  out.fills = paints(node.fills)
  out.strokes = paints(node.strokes)
  if (out.strokes.length) out.stroke_weight = node.strokeWeight
  if (node.cornerRadius) out.corner_radius = node.cornerRadius
  if (node.layoutMode && node.layoutMode !== 'NONE') {
    out.item_spacing = node.itemSpacing
    out.padding = [node.paddingTop, node.paddingRight, node.paddingBottom, node.paddingLeft]
  }
  const children = node.childIds.map((id: string) => graph.getNode(id)).filter(Boolean)
  if (depth < maxDepth) out.children = children.map((child: any) => projectScene(graph, child, depth + 1))
  else out.child_count = children.length
  return out
}

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
