# Custom menu-bar icon via the Figma MCP

Use this when the user has Figma as the source for the menu-bar mark (or any small
vector icon) and the `mcp__figma__*` tools are available. This complements
`custom-icon-picker-and-source.md` (sizing/source rules) and
`custom-menu-bar-icon-sizing.md` (NSImage sizing) for when the art is authored in
Figma rather than generated in Swift.

## Getting the file key

Every Figma tool that targets a specific file requires `fileKey` (the 22+ char ID
in the file URL, e.g. `https://figma.com/design/leTDr..UY/Untitled?node-id=9-12`).
Do not guess it: ask the user to paste the file link, or read `node-id` / file key
from the URL if they already provided one. Some tools also support a `nodeId`
(`page:id`, or `page-id` with a dash). If only the file is needed, call
`get_metadata` with just `fileKey` and no `nodeId` — it lists top-level pages.

## Reading state first

- `get_metadata(fileKey)` (no nodeId) — lists top-level pages.
- `get_metadata(fileKey, nodeId)` — XML dump: node ids, types, names, x/y/w/h.
- `get_screenshot(fileKey, nodeId)` — returns a short-lived URL or inline base64
  PNG of that node. Set `enableBase64Response: true` and download via curl when you
  will inspect it.

### Pitfall: get_screenshot on a tiny node

For a 60×36 icon frame the screenshot stays ~60×36 px. Auxiliary vision models
misread it (invent overlapping shapes, "touching" elements, colors that do not
exist). Verify geometry structurally from `get_metadata` / `use_figma` positions and
sizes, not from prose describing the tiny render. To actually eyeball strokes,
either export at scale (below) or temporarily set a solid dark fill on the frame so
white strokes are visible (remove the fill before exporting the final asset).

## use_figma — writing via the Figure Plugin API

`use_figma(fileKey, code, description)` runs JavaScript in the file. Rules that
matter for icon work:

- Colors are 0–1, not 0–255.
- Return data with `return {...}`; do not use `figma.notify()` or wrap in an IIFE.
- Switch pages with `await figma.setCurrentPageAsync(page)` (sync setter throws).
- After creating/changing nodes, `return` their IDs for the next call.

### Pitfall: node-local vs canvas-absolute vector coordinates

`vectorPaths` `data` is in the node's LOCAL coordinate system (0..nodeWidth,
0..nodeHeight), NOT canvas coordinates. When you create a vector, append it to a
frame, then set vector paths with canvas-absolute-looking numbers, the node keeps
its default size and the art renders compressed/shifted and can overflow the frame.

Correct recipe:

```js
const sparkle = figma.createVector();
sparkle.vectorPaths = [{ windingRule: 'NONZERO',
  data: 'M15 0 L19 10.5 L30 15 L19 19.5 L15 30 L11 19.5 L0 15 L11 10.5 Z' }]; // 0..30 local
sparkle.strokes = [{ type: 'SOLID', color: { r: 1, g: 1, b: 1 } }];
sparkle.strokeWeight = 2.5;
sparkle.strokeCap = 'ROUND';
sparkle.strokeJoin = 'ROUND';
sparkle.fills = [];
sparkle.resize(30, 30);      // set local size FIRST
frame.appendChild(sparkle);
sparkle.x = 2; sparkle.y = 3; // then place inside the frame
```

- Fills/strokes are read-only arrays: clone-and-reassign, never mutate in place.
- Multipoint paths (e.g. an H) can be a single `data` with several `M.. L..`
  sub-paths and `windingRule: 'NONZERO'`.
- Keep stroke weight uniform and check the outer stroke does not bleed past the
  frame edge: `node.x + node.width + strokeWidth/2 <= frame.width` and likewise for
  the bottom edge. A stroke placed flush at the frame edge renders clipped.

## Exporting a retina PNG into the project

Export needs to happen from the Plugin API with a scale factor:

```js
const f = await figma.getNodeByIdAsync('11:2');
f.fills = []; // ensure transparent final
const bytes = await f.exportAsync({ format: 'PNG', constraint: { type: 'SCALE', value: 4 } });
let binary = '';
for (let i = 0; i < bytes.length; i += 0x8000)
  binary += String.fromCharCode.apply(null, bytes.subarray(i, i + 0x8000));
return { b64: btoa(binary), w: 240, h: 144, byteLength: bytes.length };
```

Chunk the `Uint8Array` before `String.fromCharCode.apply` to avoid argument-length
limits. Then decode the returned `b64` with a local script and write it over
`Sources/.../Resources/HermesMenuBarIcon.png` (see `custom-menu-bar-icon-sizing.md`
for the runtime sizing that consumes it).

## Validation

- Confirm the exported PNG dimensions match the logical frame × scale (e.g. 60×36
  → 240×144 at 4×) and that it has alpha.
- Close/reopen the installed menu-bar app (a live process may serve a stale render).
- Unit tests and `Assets.car` content cannot prove visual menu-bar geometry; the
  live bar is the real check.
