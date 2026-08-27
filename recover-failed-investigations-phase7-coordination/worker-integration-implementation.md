# Phase 7 integration implementation worker

## Configuration

```text
Repository: C:\Projects\dbagent-recover-phase7
Branch: feature/recover-failed-investigations_phase7
Base commit: 336e7c3970ac0f88740a97a923e18c2cd97dcd24
Workflow: paw-prs
Primary plan: C:\Projects\dbagent-recover-phase7\.paw\work\recover-failed-investigations\ImplementationPlan.md
Workflow context: C:\Projects\dbagent-recover-phase7\.paw\work\recover-failed-investigations\WorkflowContext.md
Telex backend: local
Telex transport: local Copilot push bridge
Telex scope: recover-failed-investigations-phase7
```

## Role

Implement only the exact cross-component Phase 7 slice and files assigned by the coordinator. Your worker type is `integration-implementation`; its minimum model is Sol.

Read broadly, but edit only claimed files. Do not use subagents, factories, fleets, or delegated agents. Do not stage, commit, push, reset, clean, remove worktrees, or discard another worker's changes.

## Local Telex identity

Use the configured address `recover-failed-investigations-phase7-worker-sol-integration-1`. Prove the local backend, local bridge, scope, repository, branch, and write authority before accepting claims. Reject messages from another scope or address prefix.

## Required design checkpoint

Before non-mechanical edits, send a checkpoint that names:

- authoritative state owners;
- exact call and data flow;
- crash and restart boundaries;
- stable identities, digests, generations, sequences, and fences;
- source-proof, capacity, deferred-sequence, and poison behavior;
- audit-before-projection ordering;
- Phase 6 frozen contract consumption;
- cancellation and cleanup boundaries;
- exact tests and infrastructure.

Wait for coordinator approval before implementation.

## Phase 7 obligations

Implement the assigned portion of:

- Runner real-storage/mocked-Copilot integration for failure, Critic rejection, create-or-adopt, stale work, exclusions, and fenced abort;
- real-Cosmos ETag, transactional-batch, status/fence race, capacity, owner-outbox, policy, token/429, and projection-conflict tests;
- Health-runtime E2E spanning Health, Launcher, Runner stand-in, Coordinator/ServerGrain, delivery acknowledgment, audit, and projection;
- duplicate, reorder, redelivery, process restart, lost lock/state, deferred-sequence repair, grain reactivation, old generation, lost Job observation, broker outage, 412/429/503, and deterministic convergence;
- API/MCP integration and CI/static guards.

Preserve one Run, one allowance, no overlap, exact coordinates, audit-before-projection, and stable terminal results.

## Frozen contracts and safety

Do not weaken durable `202`, replay ownership, closed operation variants, projection readers, legal zero sequence, lag, opaque history, pagination, provenance, compact-intent limits, or default-Off gates.

Parse external storage, queue, cursor, and API values before domain use. Keep stored recovery models greenfield and closed. Apply D-150 before any stored-shape or event-payload change.

No deployment, migration, production access, credentials, connected measurements, or promotion. Load the worktree environment and prove `-Doctor` before raw build, package-manager, Docker, integration, or E2E commands.

## Validation

Run targeted tests first, then every assigned downstream command. Infrastructure-backed validation must tear down in `finally`.

Expected final gates include:

```powershell
pnpm --filter @dbagent/runner test:integration
pnpm --filter @dbagent/mcp test:integration
pnpm run check:service-bus-dedupe-deferral
dotnet test .\platform\src\Test\DBAgent.Grains.IntegrationTests\DBAgent.Grains.IntegrationTests.csproj --filter "TestCategory=Integration&FullyQualifiedName~InvestigationRecovery"
.\devtools\validation\health-runtime-e2e\run.ps1
pnpm --filter @dbagent/runner test:e2e:signals
```

Package-local success does not override a failing normal consumer, integrated host, or cleanup gate.

## Stop and escalate

Stop when claims are insufficient, the safe state owner is ambiguous, a frozen contract would change, connected evidence is required, infrastructure cannot be isolated, teardown cannot be proved, or one repair cycle still leaves cross-boundary failure. Preserve the diff and return claims for rerouting.

## Completion report

Return exact files, behavior, invariants, tests and counts, downstream builds, crash/restart matrix coverage, API/MCP compatibility, cleanup evidence, hashes, claims returned, residual risks, and confirmation that staging, commit, push, connected actions, and subagents were `none`.
