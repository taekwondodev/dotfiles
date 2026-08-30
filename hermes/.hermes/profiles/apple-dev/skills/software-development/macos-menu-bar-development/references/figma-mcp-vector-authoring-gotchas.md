# Figma MCP vector authoring gotchas

Incremental pitfalls for authoring menu-bar icons (or any small vector art) via the
Figma MCP `use_figma` tool. Complements `figma-mcp-icon-workflow.md`, which covers
the full read → edit → export pipeline; this file records the hard-won gotchas that
bite when writing the Plugin API JS.

## vectorPaths accepts only absolute commands

`vectorPaths[*].data` is SVG path syntax restricted to **absolute** commands
(`M`, `L`, `Z`). Relative commands (`h4`, `v13`, `l`) throw:

```
Error: in set_vectorPaths: Failed to convert path. Invalid command at h4
```

Expand every relative run into absolute points before assigning. Example:

```js
// causes: 'M0 0 h4 v13 h10 v-13 h4 v30 Z'
// expand each h/v into explicit L:
' M0 0 L4 0 L4 13 L14 13 L14 0 L18 0 L18 30 L14 30 ... Z '
```

## Node-local path coordinates, then position the node

`vectorPaths` `data` uses the vector node's **local** coordinate system
(0..nodeWidth × 0..nodeHeight), not canvas coordinates. Recipe that works:

1. build the path in local coords ending at the node's intended size;
2. `node.resize(w, h)` FIRST (sets the local bounds);
3. `frame.appendChild(node)`;
4. set `node.x` / `node.y` to place it inside the frame.

Setting canvas-looking numbers in the path data (or skipping resize) makes the art
render compressed/shifted and can overflow the frame.

## Stroke bleed at frame edges

Stroke renders half in / half out of the path. It is clipped when the mark sits
flush to the frame edge. Check `node.x + node.width + strokeWidth/2 <= frame.width`
(and the analogous bottom/right checks). To widen the optical gap between two
sibling marks, move the node's `x` and re-verify the outer edge against the frame;
you may need a narrower child so the stroke still fits.

## White-on-transparent exports are invisible to vision models

A white-stroke vector on a transparent frame exports as white-on-transparent, which
auxiliary vision reads as "blank white image." To eyeball it: temporarily set the
frame fill to a dark solid (`f.fills = [{type:'SOLID', color:{r:0.024,g:0.157,b:0.153}}]`),
screenshot, then **clear the fill (`f.fills = []`) before the final export**. Also
remember a 60×36 screenshot stays ~60×36 — don't trust prose descriptions of it for
fine stroke/gap decisions; verify positions/sizes structurally from `get_metadata`.

## Editing tools can be plan/seat-gated

`use_figma` (writes) may be blocked by account plan even when read tools work:
- Starter plan per-window tool-call cap: `You've reached the Figma MCP tool call
  limit on the Starter plan`.
- Edit restriction: `To use MCP tools that make edits, you'll need a Full seat`.

Report the exact error and the `upgrade_request_type=figma&entry_mode=mcp_edit_restriction`
URL; these are account constraints the user resolves. Read-only tools keep working.
