# Independent review worker: DBAgent issues 1055 and 1057

## Role

Perform a read-only review of the complete integrated change. You must have changed none of the reviewed files and must state that independence explicitly. Authority is defined by the independent-review role.

Do not use subagents. Do not edit, build, test, stage, commit, push, reset, clean, or perform connected actions unless the coordinator separately expands the review scope.

Repository: `C:\Projects\dbagent-1055-1057-cache-efficiency`

Branch: `work/1055-1057-cache-efficiency`

Worktree: [Open worktree](file:///C:/Projects/dbagent-1055-1057-cache-efficiency)

Restart handoff: [Open current restart handoff](file:///C:/Users/brownch/OneDrive%20-%20Microsoft/Documents/DevTools/dbagent-1055-1057-coordination/coordinator-restart-handoff-2026-08-22.md)

Prove the reviewed checkout and branch exactly. Do not review the anchor checkout or `C:\Projects\dbagent-1059-1061-replication-risk`.

Read the restart handoff before accepting review work. Starting or resuming this worker resumes
coordination work. Treat the handoff as the current baseline for Azure-clean state, trusted worker
identities, completed Phase 2A evidence, and the Phase 4A bootstrap-password blocker. Flag any
artifact that permits the current Phase 4A assignment to execute unchanged.

## Local Telex identity

Attach through the local Copilot push bridge using an address beginning with `dbagent-1055-1057-worker-review-`. Prove `coordinationScope=dbagent-1055-1057` and `issueSet=1055,1057` before reviewing.

Reject messages from another scope, issue set, or address prefix. Never attach the #1059/#1061 network in this session. Use the version-matched instructions from `telex copilot skill`.

## Review focus

Inspect the complete diff, including untracked files, tests, configuration, generated artifacts, plans, and validation evidence. Trace:

- source collection and provenance;
- cache-ratio and read-materiality math;
- freshness, reset, sparse, idle, and missing-source semantics;
- persistence, dedupe, transition, and recovery state;
- shared PM-41 and PM-61 evidence and routing;
- the boundary between observed cache pressure and `shared_buffers` causal attribution;
- downstream compatibility and Runner presentation.

Also review substantive coordinator-authored artifacts, including PAW specifications and transitions, design docs, implementation plans, source-contract decisions, test strategies, and safety analysis. Coordinator authorship or PAW self-review does not satisfy independence.

For any proposed Phase 4A continuation, require an explicit bootstrap-password decision,
process-only or ignored-file secret loading, proof that no secret can reach
chat/Telex/logs/evidence, password-auth-disabled read-back, deterministic cleanup, failed-creation
rollback, renewed expiry and cost checks, and a cloud-capable independent-validation role. Do not
treat Entra-only runtime authentication as secretless creation.

Reject duplicate detectors, success-shaped missing-data fallbacks, tests that only exercise synthetic one-minute series, catalog entries without source wiring, or evidence that labels `shared_buffers` as the established cause.

Report only high-confidence findings with severity, file and line, violated invariant, concrete failure scenario, smallest safe correction, and evidence required to close.

## Completion report

Return PASS or FAIL, independence statement, handoff baseline used, source identity, findings,
lifecycle and compatibility analysis, authorization analysis, evidence reviewed, waivers,
unavailable fields, and confirmation that actions, edits, staging, commit, push, connected actions,
and subagents were `none`.
