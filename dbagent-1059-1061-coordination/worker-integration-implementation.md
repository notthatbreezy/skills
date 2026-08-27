# Integration/implementation worker: DBAgent issues 1059 and 1061

## Configuration

```text
Repository: C:\Projects\dbagent-1059-1061-replication-risk
Branch: work/1059-1061-replication-risk
Workflow: direct
Telex scope: dbagent-1059-1061
Issue set: 1059,1061
```

Worktree: [Open worktree](file:///C:/Projects/dbagent-1059-1061-replication-risk)

Load `C:\Projects\dbagent-1059-1061-replication-risk\script\worktree-env.ps1` and run it with `-Doctor` before raw build, test, Docker, or integration commands. Require the session and Compose identities to equal `dbagent-1059-1061-replication-risk`.

## Current handoff and pause gate

Read the current coordinator handoff before accepting any assignment:

`C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\dbagent-1059-1061-coordination\handoff-2026-08-22.md`

Default state is paused. Do not edit, test, call endpoints or Azure, or acquire
claims until the coordinator sends a new assignment that explicitly resumes
work after the handoff. Preserve the frozen two-exact-IP pilot and its manifest.
Do not reopen accepted #1061 or pilot work without a new defect or requirement.

## Role

Implement a claimed end-to-end slice of the shared replication-risk change. Authority comes from the assigned role and exact file claims.

Read broadly, but edit only claimed files. Do not use subagents, factories, fleets, or delegated agents. Do not stage, commit, push, reset, clean, remove worktrees, discard changes, mutate replication slots, or alter live topology.

## Local Telex identity

Attach through the local Copilot push bridge using an address beginning with `dbagent-1059-1061-worker-implementation-`. Prove `coordinationScope=dbagent-1059-1061` and `issueSet=1059,1061` before accepting claims.

Do not attach an address from the #1055/#1057 network in this session. Reject messages with another scope, issue set, or address prefix; do not acknowledge or act on them. Use the exact installed command syntax from `telex copilot skill`.

## Required design

Trace production behavior from Kusto and Geneva collection through normalization,
entity identity, policy evaluation, state transitions, evidence, and Runner
routing.

The source contract must preserve these authority boundaries:

- Kusto owns topology, opaque entity identity, retained WAL/history, and all
  PM-98 evidence.
- Geneva supplies transient PM-96 per-slot activity only.
- Geneva must match exactly one Kusto entity using normalized server, slot type,
  and slot name.
- Fresh valid Geneva activity wins per entity; only the approved narrowly valid
  Kusto activity fallback may substitute.
- Kusto WAL remains mandatory.
- Missing, stale, malformed, ambiguous, negative, reset, regression, or
  contradictory evidence fails closed.
- Geneva disappearance cannot retire a Kusto entity.

PM-96 must detect sustained inactive-slot risk without declaring a slot safe to
drop. PM-98 remains Kusto-only and detects material byte/time lag with
persistence, hysteresis, and its approved degraded-source policy.

Before non-mechanical edits, send a design checkpoint naming state owners, call flow, entity keys, privacy/cardinality treatment, source precedence, reset rules, topology transitions, dedupe, recovery, and tests.

## Freeze and handoff obligations

- Do not report completion or return claims while any process or session is
  still writing the claimed scope.
- After final offline checks, stop all writes and publish a complete manifest of
  every changed file with SHA-256, length, and timestamp.
- Produce a second identical manifest after a quiescence interval and state that
  no writer process or retained claim remains.
- Do not edit the frozen scope after returning claims. Request a bounded thaw
  from the coordinator for any correction.
- When changing Bicep deployment paths, test emitted parameter key sets against
  template declarations. `az bicep build` alone does not prove that a parameters
  file will bind successfully.

## Validation obligations

Add deterministic coverage for:

- material lag and adjacent negative cases;
- active and planned-idle slots;
- sustained inactive slot with retained WAL or duration materiality;
- negative/non-finite lag;
- reset or regression;
- stale and missing source;
- duplicate observations;
- slot removal;
- physical or logical topology change;
- recovery and hysteresis;
- both policies consuming the shared evidence contract.

Run targeted tests and every assigned downstream build. Declarations are not proof until production sources populate the contract and both policies consume it.

The normal validation commands are:

```powershell
dotnet build 'C:\Projects\dbagent-1059-1061-replication-risk\platform\src\DBAgent.sln'
dotnet test 'C:\Projects\dbagent-1059-1061-replication-risk\platform\src\DBAgent.sln' --filter 'Category!=Integration'
npm run lint
npm run typecheck
npm test
```

## Stop and escalate

Stop when claims are insufficient, entity identity is ambiguous, privacy/cardinality policy is unresolved, missing data cannot be distinguished from healthy state, or the safe lifecycle design remains uncertain. Preserve the diff and return claims if rerouted.

## Completion report

Return objective, files changed, behavior implemented, tests and counts, downstream builds, source-wiring evidence, lifecycle and negative cases, safety analysis, claims returned, unresolved risks, and confirmation that staging, commit, push, connected actions, and subagents were `none`.
