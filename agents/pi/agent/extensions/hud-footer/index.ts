// HUD footer: replaces Pi's footer with a two-row layout (where you are, then
// context, cost, prompt cache and run sizes) plus up to two rows of extension
// statuses. EXPECTED-BEHAVIOR.md states the contract; check.mjs verifies it.
//
// Pi renders the footer on every frame, so render() does no I/O and recomputes
// session statistics only when the session, leaf or model changes; every session
// append, cache-warm usage included, moves the leaf (check.mjs verifies it). Repository
// facts, diff included, are read asynchronously after each turn, one read at a time;
// gh is asked for the branch's pull request at most once a minute. Nothing runs while
// idle, and the cache clock schedules one render per second only while it runs.
import { basename } from 'node:path'
import type { ExtensionAPI, ExtensionContext } from '@earendil-works/pi-coding-agent'
import { getCapabilities, type TUI } from '@earendil-works/pi-tui'
import { type CacheClock, placeRow, statusRows, telemetryRow } from './lib/layout.ts'
import { type PullRequest, readPullRequest, readRepoFacts, type RepoFacts } from './lib/repo.ts'
import { cacheRemaining, type SessionStats, sessionStats } from './lib/stats.ts'

const homePath = (path: string): string => {
  const home = process.env.HOME
  return home !== undefined && (path === home || path.startsWith(`${home}/`)) ? `~${path.slice(home.length)}` : path
}

const PULL_REQUEST_TTL_MS = 60_000

const sameFacts = (a: RepoFacts, b: RepoFacts): boolean =>
  a.url === b.url &&
  a.defaultBranch === b.defaultBranch &&
  a.worktrees === b.worktrees &&
  a.diff?.added === b.diff?.added &&
  a.diff?.removed === b.diff?.removed

interface PullRequestLookup {
  readonly cwd: string
  readonly branch: string
  readonly checkedAt: number
  readonly value?: PullRequest
}

export default function (pi: ExtensionAPI): void {
  let enabled = true
  let active: ExtensionContext | undefined
  let respondedAt: number | undefined
  let repo: RepoFacts = { worktrees: 0 }
  let reading = false
  let stale = false
  let pullRequest: PullRequestLookup | undefined
  let lookingUp = false
  let currentBranch: () => string | null = () => null
  let requestRender: (() => void) | undefined
  let statsKey = ''
  let stats: SessionStats = { cost: 0, runs: [] }
  let contextUsage: ReturnType<ExtensionContext['getContextUsage']>

  // The default branch and detached heads have no pull request worth a network call.
  const refreshPullRequest = (cwd: string): void => {
    const branch = currentBranch()
    if (repo.url === undefined || branch === null || branch === 'detached' || branch === repo.defaultBranch) return
    const last = pullRequest
    if (lookingUp || (last?.cwd === cwd && last.branch === branch && Date.now() - last.checkedAt < PULL_REQUEST_TTL_MS)) return
    lookingUp = true
    void readPullRequest(cwd, branch).then(value => {
      lookingUp = false
      pullRequest = { cwd, branch, checkedAt: Date.now(), ...(value === undefined ? {} : { value }) }
      if (value?.number !== last?.value?.number || value?.state !== last?.value?.state || branch !== last?.branch) requestRender?.()
      // A checkout or session switch during the lookup asks again for the new branch.
      const now = active?.sessionManager.getCwd()
      if (now !== undefined && (now !== cwd || currentBranch() !== branch)) refreshPullRequest(now)
    })
  }

  // One read at a time: a request during a read reruns it once afterwards with the current session.
  const refreshRepo = (ctx: ExtensionContext): void => {
    if (!enabled) return
    if (reading) {
      stale = true
      return
    }
    reading = true
    const cwd = ctx.sessionManager.getCwd()
    void readRepoFacts(cwd).then(facts => {
      reading = false
      if (stale) {
        stale = false
        if (active !== undefined) refreshRepo(active)
        return
      }
      if (!sameFacts(facts, repo)) {
        repo = facts
        requestRender?.()
      }
      refreshPullRequest(cwd)
    })
  }

  const currentStats = (ctx: ExtensionContext): SessionStats => {
    const { sessionManager } = ctx
    const key = `${sessionManager.getSessionId()}\0${sessionManager.getLeafId()}\0${ctx.model?.provider}/${ctx.model?.id}`
    if (key !== statsKey) {
      statsKey = key
      stats = sessionStats(sessionManager.getEntries(), sessionManager.getBranch())
      contextUsage = ctx.getContextUsage()
    }
    return stats
  }

  const install = (ctx: ExtensionContext): void => {
    if (!enabled) {
      ctx.ui.setFooter(undefined)
      return
    }
    ctx.ui.setFooter((tui: TUI, _theme, footerData) => {
      let tick: NodeJS.Timeout | undefined
      let last: string[] = []
      requestRender = () => tui.requestRender()
      currentBranch = () => footerData.getGitBranch()
      const unsubscribe = footerData.onBranchChange(() => {
        if (active !== undefined) refreshRepo(active)
        tui.requestRender()
      })
      const scheduleTick = (remainingMs: number): void => {
        if (tick !== undefined) return
        tick = setTimeout(() => {
          tick = undefined
          tui.requestRender()
        }, (remainingMs % 1000) + 1)
        tick.unref()
      }
      return {
        invalidate() {},
        dispose() {
          unsubscribe()
          if (tick !== undefined) clearTimeout(tick)
          requestRender = undefined
          currentBranch = () => null
        },
        render(width: number): string[] {
          const ctx = active
          if (ctx === undefined) return last
          const { theme } = ctx.ui
          const current = currentStats(ctx)
          const lastRequestAt = Math.max(current.lastRequestAt ?? -Infinity, respondedAt ?? -Infinity)
          const remaining = cacheRemaining(Number.isFinite(lastRequestAt) ? lastRequestAt : undefined, Date.now())
          let clock: CacheClock
          if (remaining !== undefined && remaining > 0) {
            clock = { remainingMs: remaining }
            scheduleTick(remaining)
          } else if (remaining !== undefined) clock = 'cold'

          const cwd = ctx.sessionManager.getCwd()
          const branch = footerData.getGitBranch()
          const pr = pullRequest !== undefined && pullRequest.cwd === cwd && pullRequest.branch === branch ? pullRequest.value : undefined
          const session = ctx.sessionManager.getSessionName()
          const model = ctx.model
          const linked = getCapabilities().hyperlinks
          const rows = [
            theme.fg('dim', '─'.repeat(width)),
            placeRow(
              theme,
              {
                path: homePath(cwd),
                folder: basename(cwd),
                worktrees: repo.worktrees,
                ...(repo.url === undefined ? {} : { repoUrl: repo.url }),
                ...(branch === null ? {} : { branch }),
                ...(pr === undefined ? {} : { pullRequest: pr }),
                ...(repo.diff === undefined ? {} : { diff: repo.diff }),
                ...(session === undefined ? {} : { session }),
                ...(model === undefined ? {} : { model: model.id }),
                ...(model?.reasoning ? { thinking: pi.getThinkingLevel() } : {}),
              },
              width,
              linked,
            ),
            telemetryRow(
              theme,
              {
                ...(contextUsage === undefined
                  ? {}
                  : {
                      context: { percent: contextUsage.percent },
                    }),
                cost: current.cost,
                ...(current.cacheHit === undefined ? {} : { cacheHit: current.cacheHit }),
                clock,
                runs: current.runs,
              },
              width,
            ),
            ...statusRows(theme, footerData.getExtensionStatuses(), width),
          ]
          last = rows
          return rows
        },
      }
    })
  }

  pi.on('session_start', (_event, ctx) => {
    if (ctx.mode !== 'tui') return
    active = ctx
    respondedAt = undefined
    statsKey = ''
    install(ctx)
    refreshRepo(ctx)
  })
  // Pi invalidates ctx right after shutdown, but the TUI can still render before
  // the next session_start; render() then repeats its last rows.
  pi.on('session_shutdown', () => {
    active = undefined
  })
  pi.on('after_provider_response', () => {
    respondedAt = Date.now()
  })
  pi.on('turn_end', (_event, ctx) => {
    if (active !== undefined) refreshRepo(ctx)
  })
  pi.on('agent_end', (_event, ctx) => {
    if (active !== undefined) refreshRepo(ctx)
  })

  pi.registerCommand('footer', {
    description: 'Toggle the HUD footer and Pi’s default footer',
    handler: async (_args, ctx) => {
      enabled = !enabled
      install(ctx)
      refreshRepo(ctx)
      ctx.ui.notify(enabled ? 'HUD footer enabled' : 'Default footer restored', 'info')
    },
  })
}
