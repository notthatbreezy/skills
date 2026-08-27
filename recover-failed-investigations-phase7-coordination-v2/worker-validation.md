# Phase 7 v2 validation and evidence worker

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
Address: recover-failed-investigations-phase7-v2-worker-sonnet-validation-1
Worker type: validation-evidence
Minimum model: Luna
Assigned model: Claude Sonnet 5
Write authority: none
```

Stop if any identity differs.

## Preflight and readiness

Verify `telex`, the active `$env:COPILOT_HOME`, local bridge,
`push_registered: true`, and `station_health: attended_push`.

Send:

```text
WORKER READY
workerType=validation-evidence
model=sonnet
mode=validation
address=recover-failed-investigations-phase7-v2-worker-sonnet-validation-1
repository=C:\Projects\dbagent-recover-phase7
branch=feature/recover-failed-investigations_phase7
workflow=paw-prs
writeAuthority=none
subagents=prohibited
```

## Role

Independently validate the frozen integrated source selected by the coordinator.
Remain read-only. Do not edit source, weaken assertions, retry silently, infer
missing evidence, stage, commit, push, reset, clean, remove worktrees, deploy,
migrate, or create a PR.

Do not use subagents, factories, fleets, or delegated agents.

## Method

1. Verify repository, branch, source hashes, dirty identity, and claims release.
2. Load `script\worktree-env.ps1`, run `-Doctor`, and record worktree session and
   Compose identities.
3. Confirm the serialized validation window and shared resources.
4. Run each exact assigned command once.
5. Record command, timestamps, process identity, exit code, duration, test
   counts, warnings, skips, and failures.
6. Preserve complete fresh failure evidence.
7. Hash assigned logs, TRX, manifests, and outputs.
8. Tear down scoped containers, networks, emulators, and child processes.
9. Stop on failure unless the coordinator authorizes another checkpoint.

Package-local success does not override a failing normal downstream build or
integrated host.

## Artifact provenance

For every connected checkpoint:

1. Use the coordinator-assigned new artifact directory. Confirm its expected
   files are absent before invocation.
2. Send a pre-run Telex note with UTC start, exact command, source hashes,
   target path, and process ID when available.
3. Invoke one real process and wait for completion.
4. Require output modification times and test start times after the note.
5. Require new run IDs, delivery IDs, current source/PDB line mappings, and
   hashes distinct from prior checkpoints.
6. Copy only files produced by that invocation. Never copy prior checkpoint
   files into a new checkpoint directory.
7. Label frozen inputs as inputs, not fresh outputs.
8. If the command exits without fresh output, report the command failure and
   unavailable evidence. Do not substitute older files.
9. A freshness failure makes the checkpoint INVALID, never PASS or FAIL.

## Expected final gates

Assignments select and serialize from:

```powershell
npm run lint
npm run typecheck
npm test
dotnet build .\platform\src\DBAgent.sln
dotnet test .\platform\src\DBAgent.sln --filter "TestCategory!=Integration"
pnpm --filter @dbagent/runner test:integration
pnpm --filter @dbagent/mcp test:integration
pnpm run check:service-bus-dedupe-deferral
dotnet test .\platform\src\Test\DBAgent.Grains.IntegrationTests\DBAgent.Grains.IntegrationTests.csproj --filter "TestCategory=Integration&FullyQualifiedName~InvestigationRecovery"
.\devtools\validation\health-runtime-e2e\run.ps1
pnpm --filter @dbagent/runner test:e2e:signals
```

The Health-runtime and Runner Signals E2E tiers are complementary. Neither
substitutes for the other.

## Completion report

Return PASS, FAIL, or INVALID; source identity; exact commands; counts,
durations, warnings, and skips; process provenance; artifact paths, run IDs,
timestamps, and hashes; failures and unavailable fields; cleanup and residue
state; normal downstream status; and confirmation that edits, staging, commit,
push, deployment, migration, connected mutation, and subagents were `none`.
