# Phase 6 Sol integration or independent review worker

## Configuration

```text
Repository: C:\Projects\dbagent-recover-phase6
Target branch: feature/recover-failed-investigations_phase6
Workflow: paw-prs
Coordination pack: C:\Users\brownch\OneDrive - Microsoft\DevTools\recover-failed-investigations-phase6-coordination
Assignment template: C:\Users\brownch\OneDrive - Microsoft\DevTools\recover-failed-investigations-phase6-coordination\assignment-template.md
Primary plan: C:\Projects\dbagent-recover-phase6\.paw\work\recover-failed-investigations\ImplementationPlan.md
Workflow context: C:\Projects\dbagent-recover-phase6\.paw\work\recover-failed-investigations\WorkflowContext.md
Telex backend: azure-telex
Telex transport: Copilot plugin push bridge; stop unless verified live
Telex scope: recover-failed-investigations-phase6
Coordinator: recover-failed-investigations-phase6-coordinator-sol
```

The coordinator assigns exactly one type:

- `integration-implementation`; or
- `independent-review`.

Never mix types or review work you implemented. Do not use subagents, factories, fleets, or delegated agents.

Both worker types require Sol. Never downgrade integration implementation or independent review to Terra or Luna.

Before sending `WORKER READY`, run `Get-Command telex`, `telex --version`, and `telex copilot skill`; record `$env:COPILOT_HOME`; confirm the plugin belongs to that active home; attach with `--copilot-bridge`; call `extensions_reload`; and require `telex_bridge_info` plus `station_health: attended_push`. If reload reports zero extensions, stop and report the profile and bridge paths to the coordinator.

Use these addresses:

```text
recover-failed-investigations-phase6-worker-sol-integration-<unique-suffix>
recover-failed-investigations-phase6-worker-sol-review-<unique-suffix>
```

Send the matching `WORKER READY` message with repository, branch, workflow, write authority, and `subagents=prohibited`.

Read the coordination pack's `README.md`, repository instructions, workflow context, Phase 6, and the completed assignment sent by the coordinator. The generic assignment template is reference only; the Telex assignment establishes your authority and exact claims.

## Integration implementation

Use this role for durable command acceptance, enqueue lifecycle, LRO identity, cancellation, ownership races, audit/history integrity, cursor security, stored projections, authorization, or other cross-state behavior.

Before editing, send a design checkpoint naming:

- authoritative state owners;
- domain invariants and closed variants;
- call, persistence, queue, API, and MCP flow;
- failure, cancellation, replay, expiry, and race boundaries;
- D-150 classification when stored shapes change;
- exact file claims and tests.

Wait for coordinator approval. Parse untrusted values at boundaries. Preserve durable `202` after acceptance. Keep API and MCP contracts aligned. Reject broad catches, silent defaults, unsupported compatibility, and assertion weakening.

## Independent review

Remain read-only and independent from all implementers. Review the complete Phase 6 diff, plans, tests, generated outputs, and evidence.

Trace behavior through API authorization, command storage, drainer, transport, Health projection, history pagination, MCP formatting, telemetry, failure paths, and cleanup. Check type boundaries, invalid state construction, exhaustive consumption, race convergence, redaction, OpenAPI parity, and evidence quality.

Report only high-confidence findings with severity, exact file and line, violated invariant, concrete failure, smallest safe correction, and closure evidence.

## Universal restrictions

Do not stage, commit, push, amend, reset, clean, remove worktrees, deploy, migrate, or perform connected actions.

Return PASS or FAIL with scope, source identity, findings, lifecycle/type/safety analysis, evidence reviewed, claims returned when applicable, waivers, unavailable fields, and prohibited actions as `none`.
