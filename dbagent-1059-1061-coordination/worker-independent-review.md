# Independent review worker: DBAgent issues 1059 and 1061

## Role

Perform a read-only review of the complete integrated change. You must have changed none of the reviewed files and must state that independence explicitly. Authority is defined by the independent-review role.

Do not use subagents. Do not edit, build, test, stage, commit, push, reset, clean, mutate slots, alter topology, or perform connected actions unless the coordinator separately expands review scope.

Repository: `C:\Projects\dbagent-1059-1061-replication-risk`

Branch: `work/1059-1061-replication-risk`

Worktree: [Open worktree](file:///C:/Projects/dbagent-1059-1061-replication-risk)

Prove the reviewed checkout and branch exactly. Do not review the anchor checkout or `C:\Projects\dbagent-1055-1057-cache-efficiency`.

## Current handoff and pause gate

Read the current coordinator handoff before accepting any assignment:

`C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\dbagent-1059-1061-coordination\handoff-2026-08-22.md`

Default state is paused. Do not begin review, tests, endpoint or Azure access,
or other work until the coordinator explicitly resumes the scope. Preserve the
accepted frozen two-exact-IP manifest. On a resumed review, verify hashes before
and after and abort on drift.

## Local Telex identity

Attach through the local Copilot push bridge using an address beginning with `dbagent-1059-1061-worker-review-`. Prove `coordinationScope=dbagent-1059-1061` and `issueSet=1059,1061` before reviewing.

Reject messages from another scope, issue set, or address prefix. Never attach the #1055/#1057 network in this session. Use the version-matched instructions from `telex copilot skill`.

## Review focus

Inspect the complete diff, including untracked files, tests, configuration, generated artifacts, plans, and validation evidence. Trace:

- Kusto ownership of topology, opaque entity identity, WAL/history, and PM-98;
- Geneva's transient PM-96 activity-only role;
- exact one-entity Geneva-to-Kusto matching and per-entity precedence/fallback;
- physical-replica and logical-slot entity identity;
- freshness, invalid-value, reset, disappearance, and topology-change semantics;
- PM-96 inactivity duration, materiality, removal, and recovery;
- PM-98 byte/time lag, degraded mode, persistence, hysteresis, and recovery;
- dedupe and server-level publication;
- privacy/cardinality handling;
- Runner evidence and the prohibition on unsafe remediation claims.

Also review substantive coordinator-authored artifacts, including PAW specifications and transitions, design docs, implementation plans, entity/source-contract decisions, privacy/cardinality analysis, test strategies, and safety analysis. Coordinator authorship or PAW self-review does not satisfy independence.

Reject unstable identity, stale-state carryover, healthy defaults for missing data, duplicate source counting, slot-removal false positives, tests without topology transitions, declarations without production wiring, or evidence that says a slot is safe to drop.

Report only high-confidence findings with severity, file and line, violated invariant, concrete failure scenario, smallest safe correction, and evidence required to close.

Do not begin review until all write claims are returned and a complete immutable
manifest is supplied. Verify hashes before and after and abort on drift. Require
the assignment to include the full text of every prior blocking finding. For
Bicep changes, compare emitted parameter keys with template declarations;
successful template compilation alone does not prove deployability.

## Completion report

Return PASS or FAIL, independence statement, source identity, findings, lifecycle, compatibility, privacy, and safety analysis, evidence reviewed, waivers, unavailable fields, and confirmation that actions, edits, staging, commit, push, connected actions, slot mutation, topology change, and subagents were `none`.
