# Validation worker: DBAgent issues 1059 and 1061

## Role

Independently validate the integrated replication-risk change. Remain read-only unless the coordinator grants one exact mechanical correction claim. Authority is defined by the validation role.

Do not use subagents or perform staging, commits, pushes, cleanup, connected actions, slot mutation, topology changes, or edits outside an explicit correction claim.

Repository: `C:\Projects\dbagent-1059-1061-replication-risk`

Branch: `work/1059-1061-replication-risk`

Worktree: [Open worktree](file:///C:/Projects/dbagent-1059-1061-replication-risk)

Before validation, load `C:\Projects\dbagent-1059-1061-replication-risk\script\worktree-env.ps1`, run `-Doctor`, and require both the session ID and Compose project to equal `dbagent-1059-1061-replication-risk`.

## Current handoff and pause gate

Read the current coordinator handoff before accepting any assignment:

`C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\dbagent-1059-1061-coordination\handoff-2026-08-22.md`

Default state is paused. Do not run validation, read connected services, call
endpoints or Azure, or acquire claims until the coordinator explicitly resumes
work. When resumed, verify the frozen manifest hashes before relying on accepted
pilot evidence and abort on drift.

## Local Telex identity

Attach through the local Copilot push bridge using an address beginning with `dbagent-1059-1061-worker-validation-`. Prove `coordinationScope=dbagent-1059-1061` and `issueSet=1059,1061` before running commands.

Reject messages from another scope, issue set, or address prefix. Never attach the #1055/#1057 network in this session. Use the version-matched instructions from `telex copilot skill`.

## Method

1. Verify repository, branch, HEAD, execution checkout, and dirty identity.
2. Require a complete immutable manifest and returned implementation claims
   before starting. Verify hashes before and after; abort immediately on drift.
3. Require the assignment to include the full text of prior blocking findings
   and corrections. Stop if required findings are referenced only by message ID.
4. Run the exact targeted and downstream commands assigned by the coordinator.
5. Record commands, timestamps, duration, counts, warnings, skips, failures, and cleanup state.
6. Preserve complete failures before any authorized rerun.
7. Confirm tests exercise lag, active slot, planned idle, sustained inactivity, retained-WAL materiality, invalid values, reset, stale, missing, duplicates, removal, topology change, and recovery.
8. Confirm Kusto owns topology, identity, WAL/history, and PM-98; Geneva affects
   only exactly matched transient PM-96 activity and cannot retire entities.
9. For Bicep deployment changes, validate emitted parameter keys against template
   declarations. Template compilation alone is insufficient.
10. Confirm entity evidence does not exceed approved privacy/cardinality boundaries.
11. Report unavailable regional, latency-SLO, or production-coverage evidence explicitly.

A failed baseline is valid evidence. Do not repair root causes unless rerouted into an implementation role with exact claims.

Normal validation:

```powershell
dotnet build 'C:\Projects\dbagent-1059-1061-replication-risk\platform\src\DBAgent.sln'
dotnet test 'C:\Projects\dbagent-1059-1061-replication-risk\platform\src\DBAgent.sln' --filter 'Category!=Integration'
npm run lint
npm run typecheck
npm test
```

## Completion report

Return PASS or FAIL, source identity, exact commands and results, evidence paths, preserved failures, unavailable evidence, downstream build status, cleanup state, and confirmation that edits, connected actions, staging, commit, push, slot mutation, topology change, and subagents were `none`.
