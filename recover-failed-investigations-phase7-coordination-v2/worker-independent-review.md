# Phase 7 v2 independent review worker

## Configuration

```text
Repository: C:\Projects\dbagent-recover-phase7
Branch: feature/recover-failed-investigations_phase7
Workflow: paw-prs
Primary plan: C:\Projects\dbagent-recover-phase7\.paw\work\recover-failed-investigations\ImplementationPlan.md
Workflow context: C:\Projects\dbagent-recover-phase7\.paw\work\recover-failed-investigations\WorkflowContext.md
Telex backend: local
Telex transport: local Copilot push bridge
Telex scope: recover-failed-investigations-phase7-v2
Coordinator: recover-failed-investigations-phase7-v2-coordinator-sol
Address: recover-failed-investigations-phase7-v2-worker-opus-review-1
Worker type: independent-review
Minimum model: Sol
Assigned model: Claude Opus 5
Write authority: none
```

Stop if any identity differs.

## Readiness and independence

Verify `telex`, the active `$env:COPILOT_HOME`, local bridge,
`push_registered: true`, and `station_health: attended_push`.

Send:

```text
WORKER READY
workerType=independent-review
model=opus
mode=review
address=recover-failed-investigations-phase7-v2-worker-opus-review-1
repository=C:\Projects\dbagent-recover-phase7
branch=feature/recover-failed-investigations_phase7
workflow=paw-prs
writeAuthority=none
subagents=prohibited
```

State that you changed none of the reviewed files. Never review your own work.
Do not use subagents, factories, fleets, or delegated agents.

## Role

Review the complete integrated tracked and untracked Phase 7 diff, not worker
summaries. Remain read-only. Do not edit, build, test, stage, commit, push,
reset, clean, remove worktrees, deploy, migrate, or run connected commands
unless the coordinator explicitly adds a read-only evidence command.

Also review substantive coordinator-authored PAW, design, compatibility,
migration, rollout, safety, and test-strategy artifacts.

## Review focus

Trace:

- Health source fact, durable record, outbox, publication, acknowledgment,
  confirmation, expiry, and repair;
- Coordinator sessions, source proof, capacity, deferral, poison, and restart;
- Launcher reservation, distinct dispatch identities, Job adoption, lifecycle
  outbox, acknowledgment receipt, precision, and repair;
- Runner Run adoption, Investigation preservation, stale fencing, and terminal
  result;
- audit-before-projection ordering, replay, conflict, and highest sequence;
- cancellation through outage, retry, result, history, lag, and provenance;
- duplicate, reorder, restart, 412, 429, 503, quota, serialization, and cleanup;
- frozen Phase 6 API/MCP contracts;
- CI/source wiring and real validation artifact provenance.

Reject declarations without production emitters, false-positive tests, stale
state, broad catches, healthy defaults, assertion weakening, unsupported
fallbacks, duplicate mutation, inaccessible behavior, teardown gaps, and
evidence copied from another checkpoint.

Report only high-confidence findings with severity, exact file and line,
violated invariant, concrete failure scenario, smallest safe correction, and
closure evidence.

## Completion report

Return PASS or FAIL; independence statement; source identity and complete
reviewed scope; findings; lifecycle, compatibility, D-150, and safety analysis;
validation evidence and provenance reviewed; unavailable fields and waivers;
and confirmation that edits, tests, connected actions, staging, commit, push,
deployment, migration, and subagents were `none`.
