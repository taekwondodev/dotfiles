import { AssistantMessageComponent, type ExtensionAPI, type Theme } from '@earendil-works/pi-coding-agent'
import { backgroundAnsi, colorToOkhsl, okhslColor, visibleWidth } from '@earendil-works/pi-tui'

// Pi has no hook for the background of assistant messages, so this wraps the
// render of its component. A final reply is a completed message without tool calls.
type AssistantInternals = {
  lastMessage?: { stopReason?: string }
  hasToolCalls: boolean
  isStreaming: boolean
}

const ORIGINAL_RENDER = Symbol.for('dev.final-reply-bg.original-render')
// A near-neutral grey just above the user message background.
const SATURATION = 0.08
const LIGHTNESS_LIFT = 0.03

type Prototype = typeof AssistantMessageComponent.prototype & { [ORIGINAL_RENDER]?: (width: number) => string[] }

function finalReplyBg(theme: Theme): string {
  const { h, l } = colorToOkhsl(theme.colors.userMessageBg)
  const lift = theme.appearance === 'dark' ? LIGHTNESS_LIFT : -LIGHTNESS_LIFT
  return backgroundAnsi(okhslColor(h, SATURATION, l + lift), theme.getColorMode())
}

function withBackground(line: string, width: number, bg: string): string {
  const padded = line + ' '.repeat(Math.max(0, width - visibleWidth(line)))
  return bg + padded.replace(/\x1b\[(?:0|49)?m/g, match => match + bg) + '\x1b[49m'
}

export default function (pi: ExtensionAPI): void {
  let currentTheme: (() => Theme) | undefined

  pi.on('session_start', (_event, ctx) => {
    if (ctx.mode === 'tui') currentTheme = () => ctx.ui.theme
  })
  // Pi invalidates ctx right after shutdown, but the TUI can still render before
  // the next session_start; reading ctx.ui from a stale ctx throws.
  pi.on('session_shutdown', () => {
    currentTheme = undefined
  })

  const prototype = AssistantMessageComponent.prototype as Prototype
  const original = prototype[ORIGINAL_RENDER] ?? prototype.render
  prototype[ORIGINAL_RENDER] = original
  prototype.render = function (this: AssistantMessageComponent, width: number): string[] {
    const lines = original.call(this, width)
    const state = this as unknown as AssistantInternals
    const isFinal = !state.isStreaming && !state.hasToolCalls && state.lastMessage?.stopReason === 'stop'
    if (!isFinal || lines.length === 0 || currentTheme === undefined) return lines

    const bg = finalReplyBg(currentTheme())
    return lines.map(line => withBackground(line, width, bg))
  }
}
