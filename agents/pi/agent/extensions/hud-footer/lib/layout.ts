import type { Theme, ThemeColor } from '@earendil-works/pi-coding-agent'
import { type Color, foregroundAnsi, hyperlink, mixColors, truncateToWidth, visibleWidth } from '@earendil-works/pi-tui'
import type { Diff, PullRequest, PullRequestState } from './repo.ts'

// Ghostty maps these glyphs to JetBrainsMono Nerd Font (not Mono).
// Reserve a blank cell for their overhang and another for the icon/text gap.
// Avoid the full-height Powerline branch; dev ADR 0006 records the font assumption.
const ICON = {
  folder: '\u{f07b}',
  branch: '\u{f418}',
  pullRequest: '\u{f407}',
  worktrees: '\u{f0645}',
  model: '\u{ec20}',
  thinking: '\u{f06e8}',
  context: '\u{ee9c}',
  cache: '\u{f01bc}',
  warm: '\u{f0954}',
  cold: '\u{f0717}',
  work: '\u{f013}',
  status: '\u{f05a}',
} as const

const SPARK_LEVELS = '⡀⣀⣄⣤⣦⣶⣷⣿'
// Ghostty stretches block and vertical box glyphs over the whole cell, which
// adjust-cell-height makes taller than the text, so they touch adjacent rows.
// Horizontal lines and bullets stay centered on the text instead.
const BAR = { full: '━', half: '╸', empty: '─' } as const
const SEPARATOR = '•'
// Pi highlights the selected autocomplete item with `accent`; the path must not look selected.
const PATH_COLOR: ThemeColor = 'syntaxType'
// GitHub's state colors for grey draft, purple merged and red closed. Open is gold, not
// green, so it does not read as the continuation of the `success` branch beside it.
const PULL_REQUEST_COLOR: Record<PullRequestState, ThemeColor> = {
  open: 'warning',
  draft: 'muted',
  merged: 'syntaxKeyword',
  closed: 'error',
}
// `toolDiffAdded` matches the branch color, so the diff borrows the path's instead.
const DIFF_ADDED_COLOR: ThemeColor = PATH_COLOR
const BAR_WIDTHS = [16, 10, 6] as const
const GAP = '  '
const ICON_GAP = '  '
export const STATUS_ROWS = 2

export interface Place {
  readonly path: string
  readonly folder: string
  readonly repoUrl?: string
  readonly branch?: string
  readonly pullRequest?: PullRequest
  readonly diff?: Diff
  readonly worktrees: number
  readonly session?: string
  readonly model?: string
  readonly thinking?: string
}

export type CacheClock = { readonly remainingMs: number } | 'cold' | undefined

export interface Telemetry {
  readonly context?: { readonly percent: number | null }
  readonly cost: number
  readonly cacheHit?: number
  readonly clock: CacheClock
  readonly runs: readonly number[]
}

// Each level drops or shortens one more element; a row uses the first level that fits.
interface Detail {
  readonly labels: boolean
  readonly bar: number
  readonly session: boolean
  readonly spark: boolean
  readonly cost: boolean
  readonly diff: boolean
  readonly secondaryCounts: boolean
}
const DETAILS: readonly Detail[] = [
  { labels: true, bar: BAR_WIDTHS[0], session: true, spark: true, cost: true, diff: true, secondaryCounts: true },
  { labels: false, bar: BAR_WIDTHS[0], session: true, spark: true, cost: true, diff: true, secondaryCounts: true },
  { labels: false, bar: BAR_WIDTHS[1], session: true, spark: true, cost: true, diff: true, secondaryCounts: true },
  { labels: false, bar: BAR_WIDTHS[2], session: true, spark: true, cost: true, diff: true, secondaryCounts: true },
  { labels: false, bar: BAR_WIDTHS[2], session: false, spark: true, cost: true, diff: true, secondaryCounts: true },
  { labels: false, bar: BAR_WIDTHS[2], session: false, spark: false, cost: true, diff: true, secondaryCounts: true },
  { labels: false, bar: BAR_WIDTHS[2], session: false, spark: false, cost: false, diff: true, secondaryCounts: true },
  { labels: false, bar: BAR_WIDTHS[2], session: false, spark: false, cost: false, diff: false, secondaryCounts: true },
  { labels: false, bar: BAR_WIDTHS[2], session: false, spark: false, cost: false, diff: false, secondaryCounts: false },
]

export function formatClock(ms: number): string {
  const seconds = Math.ceil(ms / 1000)
  return `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, '0')}`
}

const paint = (theme: Theme, color: Color, text: string): string =>
  `${foregroundAnsi(color, theme.getColorMode())}${text}\x1b[39m`

const link = (text: string, url: string | undefined, linked: boolean): string =>
  url !== undefined && linked ? hyperlink(text, url) : text

function fit(width: number, build: (detail: Detail) => string): string {
  for (const detail of DETAILS) {
    const line = build(detail)
    if (visibleWidth(line) <= width) return line
  }
  return truncateToWidth(build(DETAILS[DETAILS.length - 1]!), width, '…')
}

function spread(left: string, right: string, width: number): string {
  if (right === '') return left
  return left + ' '.repeat(Math.max(2, width - visibleWidth(left) - visibleWidth(right))) + right
}

export function placeRow(theme: Theme, place: Place, width: number, linked: boolean): string {
  const right = [
    place.model === undefined ? '' : theme.fg('text', `${ICON.model}${ICON_GAP}${place.model}`),
    place.thinking === undefined ? '' : theme.fg('warning', `${ICON.thinking}${ICON_GAP}${place.thinking}`),
  ]
    .filter(Boolean)
    .join(GAP)
  return fit(width, detail => {
    const parts = [
      theme.bold(theme.fg(PATH_COLOR, link(`${ICON.folder}${ICON_GAP}${detail.labels ? place.path : place.folder}`, place.repoUrl, linked))),
    ]
    if (place.branch !== undefined) {
      const url = place.repoUrl === undefined ? undefined : `${place.repoUrl}/tree/${encodeURI(place.branch)}`
      parts.push(theme.fg('success', link(`${theme.bold(ICON.branch)}${ICON_GAP}${place.branch}`, url, linked)))
    }
    const pr = place.pullRequest
    if (detail.secondaryCounts && pr !== undefined)
      parts.push(
        theme.fg(
          PULL_REQUEST_COLOR[pr.state],
          link(`${theme.bold(ICON.pullRequest)}${ICON_GAP}#${pr.number}${detail.labels ? ` ${pr.state}` : ''}`, pr.url, linked),
        ),
      )
    const diff = place.diff
    if (detail.diff && diff !== undefined && (diff.added > 0 || diff.removed > 0))
      parts.push(theme.fg(DIFF_ADDED_COLOR, `+${diff.added}`) + ' ' + theme.fg('toolDiffRemoved', `-${diff.removed}`))
    if (detail.secondaryCounts && place.worktrees > 0)
      parts.push(
        theme.bold(theme.fg(PATH_COLOR, ICON.worktrees)) +
          theme.fg('muted', `${ICON_GAP}${place.worktrees}${detail.labels ? ' worktree' : ''}`),
      )
    let left = parts.join(GAP)
    if (detail.session && place.session !== undefined) left += theme.fg('dim', '  •  ') + theme.fg('mdCode', place.session)
    return spread(left, right, width)
  })
}

const gradientCache = new WeakMap<Theme, Map<number, readonly Color[]>>()

function gradient(theme: Theme, cells: number): readonly Color[] {
  let byWidth = gradientCache.get(theme)
  if (byWidth === undefined) gradientCache.set(theme, (byWidth = new Map()))
  let colors = byWidth.get(cells)
  if (colors === undefined) {
    const { success, warning, error } = theme.colors
    colors = Array.from({ length: cells }, (_, index) => {
      const t = cells === 1 ? 0 : index / (cells - 1)
      return t < 0.6 ? mixColors(success, warning, t / 0.6, 'oklch') : mixColors(warning, error, (t - 0.6) / 0.4, 'oklch')
    })
    byWidth.set(cells, colors)
  }
  return colors
}

export function contextBar(theme: Theme, percent: number, cells: number): string {
  const colors = gradient(theme, cells)
  const halves = Math.round((Math.min(100, Math.max(0, percent)) / 100) * cells * 2)
  let bar = ''
  for (let index = 0; index < cells; index++) {
    const fill = halves - index * 2
    if (fill >= 2) bar += paint(theme, colors[index]!, BAR.full)
    else if (fill === 1) bar += paint(theme, colors[index]!, BAR.half)
    else bar += theme.fg('border', BAR.empty)
  }
  return bar
}

export function sparkline(theme: Theme, runs: readonly number[]): string {
  const peak = Math.max(...runs)
  return runs
    .map((tokens, index) => {
      const level = peak === 0 ? 0 : Math.round((tokens / peak) * (SPARK_LEVELS.length - 1))
      const color = mixColors(theme.colors.dim, theme.colors.accent, runs.length === 1 ? 1 : index / (runs.length - 1), 'oklch')
      return paint(theme, color, SPARK_LEVELS[level]!)
    })
    .join('')
}

function percentColor(percent: number): ThemeColor {
  if (percent > 90) return 'error'
  if (percent > 70) return 'warning'
  return 'success'
}

export function telemetryRow(theme: Theme, telemetry: Telemetry, width: number): string {
  const separator = theme.fg('dim', ` ${SEPARATOR} `)
  return fit(width, detail => {
    const groups: string[] = []
    const { context } = telemetry
    if (context !== undefined) {
      const percent = context.percent
      let group = theme.fg('muted', `${ICON.context}${ICON_GAP}${detail.labels ? 'context ' : ''}`)
      group += contextBar(theme, percent ?? 0, detail.bar)
      group += percent === null ? theme.fg('dim', ' ?') : theme.bold(theme.fg(percentColor(percent), ` ${Math.round(percent)}%`))
      groups.push(group)
    }
    if (detail.cost && telemetry.cost > 0) groups.push(theme.fg('muted', `$${telemetry.cost.toFixed(2)}`))
    const cache: string[] = []
    // The final compact level drops secondary counts to keep the clock intact.
    if (detail.secondaryCounts && telemetry.cacheHit !== undefined)
      cache.push(theme.fg('muted', `${ICON.cache}${ICON_GAP}${detail.labels ? 'cache ' : ''}${telemetry.cacheHit.toFixed(1)}%`))
    if (telemetry.clock === 'cold') cache.push(theme.fg('dim', `${ICON.cold}${ICON_GAP}stale`))
    else if (telemetry.clock !== undefined) cache.push(theme.fg('success', `${ICON.warm}${ICON_GAP}${formatClock(telemetry.clock.remainingMs)}`))
    if (cache.length > 0) groups.push(cache.join(ICON_GAP))
    if (detail.spark && telemetry.runs.length > 0)
      groups.push(sparkline(theme, telemetry.runs) + (detail.labels ? theme.fg('dim', ' token/turn') : ''))
    return groups.join(separator)
  })
}

interface Segment {
  readonly text: string
  readonly separator?: string
  readonly lead: boolean
}

const sanitize = (text: string): string => text.replace(/[\r\n\t]/g, ' ').replace(/ +/g, ' ').trim()

function segments(statuses: ReadonlyMap<string, string>): Segment[] {
  const result: Segment[] = []
  for (const key of [...statuses.keys()].sort((a, b) => a.localeCompare(b))) {
    const text = sanitize(statuses.get(key) ?? '')
    if (text === '') continue
    const icon = key === 'dev/work' ? ICON.work : ICON.status
    const parts = text.split(/ ([·│|]) /)
    for (let index = 0; index < parts.length; index += 2) {
      const lead = index === 0
      result.push({
        text: lead ? `${icon}${ICON_GAP}${parts[index]}` : parts[index]!,
        lead,
        ...(index > 0 ? { separator: parts[index - 1] === '·' ? '·' : SEPARATOR } : result.length > 0 ? { separator: SEPARATOR } : {}),
      })
    }
  }
  return result
}

function paintSegment(theme: Theme, segment: Segment, first: boolean): string {
  const separator = first || segment.separator === undefined ? '' : theme.fg('dim', ` ${segment.separator} `)
  return separator + (segment.lead ? theme.bold(theme.fg('success', segment.text)) : theme.fg('muted', segment.text))
}

export function statusRows(theme: Theme, statuses: ReadonlyMap<string, string>, width: number): string[] {
  const queue = segments(statuses)
  const rows: string[] = []
  while (queue.length > 0 && rows.length < STATUS_ROWS) {
    const indent = rows.length === 0 ? '' : GAP
    let row = indent
    let placed = 0
    while (placed < queue.length) {
      const piece = paintSegment(theme, queue[placed]!, placed === 0)
      if (visibleWidth(row + piece) > width) break
      row += piece
      placed++
    }
    if (placed === 0) {
      row = truncateToWidth(indent + paintSegment(theme, queue[0]!, true), width, '…')
      placed = 1
    }
    const lastRow = rows.length === STATUS_ROWS - 1
    if (lastRow && placed < queue.length) {
      while (placed > 1 && visibleWidth(row + ` +${queue.length - placed}`) > width) {
        placed--
        row = indent + queue.slice(0, placed).map((segment, index) => paintSegment(theme, segment, index === 0)).join('')
      }
      const more = ` +${queue.length - placed}`
      if (visibleWidth(row + more) > width) row = truncateToWidth(row, width - more.length, '…')
      row += theme.fg('success', more)
    }
    rows.push(row)
    queue.splice(0, placed)
  }
  return rows
}
