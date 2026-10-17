import type { ExtensionAPI } from '@earendil-works/pi-coding-agent'

type SoundKind = 'done' | 'request'

const COMPLETION_RENDER_GRACE_MS = 150

const defaultSounds: Partial<Record<NodeJS.Platform, Record<SoundKind, string>>> = {
  darwin: {
    done: '/System/Library/Sounds/Glass.aiff',
    request: '/System/Library/Sounds/Ping.aiff',
  },
}

function soundPath(kind: SoundKind): string | undefined {
  const configured = process.env[kind === 'done' ? 'PI_AGENT_SOUND_DONE' : 'PI_AGENT_SOUND_REQUEST']
  if (configured !== undefined) return configured || undefined
  return defaultSounds[process.platform]?.[kind]
}

function playSound(pi: ExtensionAPI, kind: SoundKind): void {
  const path = soundPath(kind)
  if (path === undefined) return

  void pi.exec('afplay', [path], { timeout: 5_000 }).catch(() => undefined)
}

export default function (pi: ExtensionAPI): void {
  let waitingForInput = false
  let hasFinalReply = false
  let completionTimer: ReturnType<typeof setTimeout> | undefined

  const cancelCompletion = (): void => {
    clearTimeout(completionTimer)
    completionTimer = undefined
  }
  const reset = (): void => {
    cancelCompletion()
    hasFinalReply = false
    waitingForInput = false
  }

  pi.on('session_start', reset)
  pi.on('session_shutdown', reset)
  pi.on('agent_start', () => {
    cancelCompletion()
    hasFinalReply = false
  })
  pi.on('message_start', () => {
    cancelCompletion()
    hasFinalReply = false
  })
  pi.on('message_end', ({ message }) => {
    hasFinalReply = message.role === 'assistant' &&
      message.stopReason === 'stop' &&
      !message.content.some(block => block.type === 'toolCall') &&
      message.content.some(block => block.type === 'text' && block.text.trim().length > 0)
  })

  pi.on('ui_prompt_start', (_event, ctx) => {
    waitingForInput = true
    cancelCompletion()
    if (ctx.mode === 'tui') playSound(pi, 'request')
  })

  pi.on('ui_prompt_end', () => {
    waitingForInput = false
  })

  pi.on('agent_settled', (event, ctx) => {
    if (event.aborted) {
      reset()
      return
    }
    if (!hasFinalReply) return
    hasFinalReply = false
    if (ctx.mode !== 'tui' || !ctx.isIdle() || ctx.hasPendingMessages() || waitingForInput) return

    completionTimer = setTimeout(() => {
      completionTimer = undefined
      if (ctx.isIdle() && !ctx.hasPendingMessages() && !waitingForInput) playSound(pi, 'done')
    }, COMPLETION_RENDER_GRACE_MS)
    completionTimer.unref()
  })
}
