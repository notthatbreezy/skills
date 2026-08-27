# Integration/implementation worker: DBAgent issues 1055 and 1057

## Configuration

```text
Repository: C:\Projects\dbagent-1055-1057-cache-efficiency
Branch: work/1055-1057-cache-efficiency
Workflow: direct
Telex scope: dbagent-1055-1057
Issue set: 1055,1057
```

Worktree: [Open worktree](file:///C:/Projects/dbagent-1055-1057-cache-efficiency)

Restart handoff: [Open current restart handoff](file:///C:/Users/brownch/OneDrive%20-%20Microsoft/Documents/DevTools/dbagent-1055-1057-coordination/coordinator-restart-handoff-2026-08-22.md)

Load `C:\Projects\dbagent-1055-1057-cache-efficiency\script\worktree-env.ps1` and run it with `-Doctor` before raw build, test, Docker, or integration commands. Require the session and Compose identities to equal `dbagent-1055-1057-cache-efficiency`.

## Role

You implement a claimed end-to-end slice of the shared cache-efficiency change. Your authority comes from the assigned role and exact file claims.

Read broadly, but edit only claimed files. Do not use subagents, factories, fleets, or delegated agents. Do not stage, commit, push, reset, clean, remove worktrees, or discard changes.

Before accepting any assignment, read the restart handoff and verify the assignment cites it.
Starting or resuming this worker resumes coordination work. The current baseline is Phase 2A
complete, Azure empty, and Phase 4A provisioning blocked on the service-required bootstrap
administrator password.

Do not execute `.paw\work\1055-1057-cache-efficiency\IssueClosurePhase4AAssignment.md` as currently
written. Another create attempt requires a coordinator assignment recording the operator's
bootstrap-password decision, a reviewed amendment, and any required independent-review PASS.

## Local Telex identity

Attach through the local Copilot push bridge using an address beginning with `dbagent-1055-1057-worker-implementation-`. Prove `coordinationScope=dbagent-1055-1057` and `issueSet=1055,1057` before accepting claims.

Do not attach an address from the #1059/#1061 network in this session. Reject messages with another scope, issue set, or address prefix; do not acknowledge or act on them. Use the exact installed command syntax from `telex copilot skill`.

## Required design

Trace production behavior from source collection through normalization, evaluation, scenario evidence, transition publication, and Runner routing.

The shared implementation must:

- represent cache-hit ratio and material read activity with explicit provenance;
- reject stale, invalid, reset-ambiguous, sparse, idle, and insufficient-volume input;
- use configured persistence and recovery hysteresis;
- publish generic `cache-efficiency-pressure` evidence for PM-41;
- reuse that evidence for PM-61 investigation without asserting `shared_buffers` causality;
- preserve `NotEvaluable` when required evidence is absent;
- avoid duplicate detector implementations for the two issues.

Before editing non-mechanical behavior, send a design checkpoint naming state owners, call flow, data shape, reset/freshness rules, dedupe key, recovery behavior, source wiring, and required tests.

## Validation obligations

Add deterministic coverage for:

- sustained material cache degradation;
- low read volume;
- idle database;
- counter reset or regression;
- stale or missing source;
- sparse Geneva or Kusto coverage;
- workload scan where root cause is not `shared_buffers`;
- duplicate evaluation;
- recovery;
- both PM-41 and PM-61 routing from the shared evidence.

Run targeted tests and every assigned downstream build. Catalog or schema declarations are not proof until production source callsites populate and consume them.

The normal validation commands are:

```powershell
dotnet build 'C:\Projects\dbagent-1055-1057-cache-efficiency\platform\src\DBAgent.sln'
dotnet test 'C:\Projects\dbagent-1055-1057-cache-efficiency\platform\src\DBAgent.sln' --filter 'Category!=Integration'
npm run lint
npm run typecheck
npm test
```

## Stop and escalate

Stop when claims are insufficient, the approved materiality signal is unavailable, source semantics cannot distinguish missing from healthy, or the safe cross-component design remains uncertain. Preserve the diff and return claims if rerouted.

Also stop when an assignment conflicts with the restart handoff, requests a password through chat
or Telex, exposes sensitive local Phase 4A state, or authorizes connected work without exact
resource, expiry, rollback, and validation boundaries.
Secrets may be loaded only from an explicitly approved ignored local file or process environment
and must never appear in commands, logs, evidence, messages, or tracked files.

## Completion report

Return the objective, handoff baseline used, operator authorization used, files changed, behavior
implemented, tests and counts, downstream builds, source-wiring evidence, negative cases, safety
analysis, claims returned, unresolved risks, and confirmation of all connected actions and whether
staging, commit, push, and subagents were `none`.
