# Hermes runtime control surface (companion reachability)

Verified against the local Hermes source (`~/.hermes/hermes-agent`) while grilling an "auto-pause the running agents" idea. Question asked: can a macOS companion (HermesUsageMonitor) send a prompt to all active sessions? Answer: **it can enumerate; it cannot inject.**

## Enumerating active sessions (possible)

- Path: `$HERMES_HOME/runtime/active_sessions.json` (profile homes under `profiles/<name>/runtime/`).
- Read via `hermes_cli.active_sessions.active_session_registry_snapshot(registry_home=...)`.
- Entry fields: `session_id`, `surface` (`cli`/`desktop`/`gateway`), `pid`, `process_start_time`, `started_at`, optional `metadata` dict, `track_liveness`.
- `hermes sessions list` (CLI) shows the SQLite session STORE (title / workspace / last-active / id) — no model column, no live/inject capability. `hermes status --all` reports `Sessions: Active` and `Gateway Service` separately.
- The lease metadata does not carry model/provider, so per-model filtering of live sessions is not available.

## Why injection is blocked (by design)

- `/steer` is same-process, in-memory. `agent/agent_runtime_helpers.py:apply_pending_steer_to_tool_results()` calls `agent._drain_pending_steer()` and appends text to the last tool message in the running `messages` list. No durable cross-process queue exists for another process to append to.
- `hermes_cli/active_sessions.py:try_acquire_active_session()` enforces "at most one live owner may run a given stored session", returning `SESSION_NOT_OWNED` / `SESSION_COORDINATION_UNAVAILABLE`. The whole registry exists to prevent a second process writing to a session with a live owner.
- Hermes `AGENTS.md` lists "never a synthetic user message injected mid-loop" as a cache/alternation invariant.

## Controls that ARE reachable externally

- `hermes send`: gateway platforms only ("no LLM, no agent loop"). Requires a configured platform — `hermes send --list` returned none on this machine (no Telegram/Discord/Slack configured).
- `hermes pause [--reason]` / `hermes resume`: global emergency stop, "Halts NEW work only — cron dispatch, kanban dispatch, and new gateway turns — until `hermes resume`. In-flight work is never killed." Does not touch a live desktop/CLI session and produces no handoff.
- `hermes monitoring`: OTLP health export for the gateway; not quota-based auto-pause.

## Key source pointers

- `hermes_cli/active_sessions.py` — lease registry, snapshot, exclusivity refusals.
- `agent/agent_runtime_helpers.py` (around `apply_pending_steer_to_tool_results`) — `/steer` drain.
- `agent/conversation_loop.py` — pre-API-call steer drain (same process).
- `hermes_cli/commands.py` — `/steer` registered as in-session, `busy_policy="dispatch"`.

## Where an auto-pause could actually live

- The only place that can steer `delegate_task` children is the PARENT agent process (in-session `delegate_task(action='steer')`). Not reachable from an external companion.
- A Hermes-side cron/hook/agent that observes the quota and steers its own subagents is the natural home — outside HermesUsageMonitor.
