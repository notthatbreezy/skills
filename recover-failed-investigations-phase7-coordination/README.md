# Recover Failed Investigations Phase 7 coordination pack

This local Telex prompt pack coordinates Phase 7 of the PAW work item `recover-failed-investigations`: cross-component integration and end-to-end validation.

## Bound execution configuration

```text
Repository: C:\Projects\dbagent-recover-phase7
Repository slug: azure-data-database-platform/dbagent
Target branch: feature/recover-failed-investigations_phase7
Base branch: feature/recover-failed-investigations_phase6
Base commit: 336e7c3970ac0f88740a97a923e18c2cd97dcd24
Workflow: paw-prs
Primary plan: C:\Projects\dbagent-recover-phase7\.paw\work\recover-failed-investigations\ImplementationPlan.md
Workflow context: C:\Projects\dbagent-recover-phase7\.paw\work\recover-failed-investigations\WorkflowContext.md
Prompt pack: C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\recover-failed-investigations-phase7-coordination
```

Worktree: [Open worktree](file:///C:/Projects/dbagent-recover-phase7)

Coordinator prompt: [Open coordinator prompt](file:///C:/Users/brownch/OneDrive%20-%20Microsoft/Documents/DevTools/recover-failed-investigations-phase7-coordination/coordinator.md)

Coordination manifest: `C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\recover-failed-investigations-phase7-coordination\coordination.json`

The launcher creates the Phase 7 worktree from the clean local Phase 6 commit when it is missing. Creation fails closed if the Phase 6 branch, commit, or dirty state differs.

## Launch

Validate configuration and create the worktree if needed:

```powershell
& 'C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\generic-coordination\Start-Coordination.ps1' `
  'C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\recover-failed-investigations-phase7-coordination\coordination.json' `
  -ValidateOnly
```

Render every session bootstrap without opening sessions:

```powershell
& 'C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\generic-coordination\Start-Coordination.ps1' `
  'C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\recover-failed-investigations-phase7-coordination\coordination.json' `
  -RenderOnly
```

Start, inspect, and stop:

```powershell
& 'C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\generic-coordination\Start-Coordination.ps1' `
  'C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\recover-failed-investigations-phase7-coordination\coordination.json'

& 'C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\generic-coordination\Get-CoordinationStatus.ps1' `
  'C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\recover-failed-investigations-phase7-coordination\coordination.json'

& 'C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\generic-coordination\Stop-Coordination.ps1' `
  'C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\recover-failed-investigations-phase7-coordination\coordination.json'
```

## Local Telex network

```text
Telex backend: local
Telex transport: local Copilot push bridge
Telex scope: recover-failed-investigations-phase7
Coordinator address: recover-failed-investigations-phase7-coordinator-sol
Required address prefix: recover-failed-investigations-phase7-
```

One-time local backend setup:

```powershell
telex backend add local --sqlite --path "$HOME\.telex\telex.db" --default
telex init --backend local
telex backend list
```

Use a dedicated Copilot session for this scope. Every address, message, claim, disposition, and ledger entry must use the configured prefix and scope. Load exact commands from the installed `telex copilot skill`. Stop before assigning work unless the local backend, local bridge, expected scope, push registration, and `attended_push` state are proven.

## PAW phase-branch note

`WorkflowContext.md` retains the original PAW planning target and execution binding. Because the workflow uses `Review Strategy: prs`, Phase 7 runs from the stacked phase branch and worktree configured by this packet. The coordinator must verify the Work ID, review strategy, Phase 7 plan, branch, and exact Phase 6 base commit, but must not stop solely because the planning-origin binding names `feature/recover-failed-investigations`.

## Roles

| Role | Authority | Purpose |
| --- | --- | --- |
| Coordinator | PAW and coordination records only | Routes work, owns claims, accepts evidence, and updates Phase 7 records |
| Integration implementation | Claimed files only | Implements the cross-component crash, restart, transport, and E2E slice |
| Validation | Read-only unless granted one exact mechanical correction | Runs serialized integration, E2E, CI, and teardown gates |
| Independent review | Read-only and independent | Reviews the complete integrated Phase 7 diff and evidence |

Workers must not use subagents, factories, fleets, or delegated agents.

## Phase 7 outcome

Phase 7 proves the complete unhealthy-episode recovery lifecycle across real infrastructure boundaries:

1. Runner integration covers technical failure, Critic rejection, create-or-adopt, stale work, exclusions, and fenced abort.
2. Grains integration covers real Cosmos transactions, ETag/status/fence races, capacity, owner-outbox ordering, policy bounds, token/429 behavior, and projection conflict.
3. Health-runtime E2E traverses Health, Launcher, Runner stand-in, Coordinator/ServerGrain, delivery acknowledgment, audit, and projection.
4. Crash injection covers every source-fact, outbox, claim, send, disposition, acknowledgment, fence, Run, Investigation, audit, projection, cancellation, and repair boundary.
5. API/MCP integration consumes the frozen Phase 6 operation, history, lag, provenance, and size contracts without reimplementation.
6. CI invokes the health-runtime E2E for every cross-component producer, contract, router, store, and consumer path.
7. Every Docker, Cosmos, Service Bus, Kusto, and worktree resource tears down after validation.

## Safety boundaries

- Local source edits and local validation only.
- No deployment, migration, production data access, credentials, connected measurements, or cohort promotion without explicit operator authorization.
- Preserve durable `202`, closed recovery models, authoritative `stageNumber`, and the frozen Phase 6 API/MCP contract.
- Treat storage, queue, cursor, and external API values as untrusted and parse them at boundaries.
- Do not restore compatibility for nonexistent version-1 recovery records.
- Do not push, create a PR, merge, rewrite history, remove worktrees, or delete branches without operator authorization.
- Load the worktree environment before package-manager, build, Docker, integration, or E2E commands, and always tear down infrastructure.

## Required validation

Run from `C:\Projects\dbagent-recover-phase7` after the worktree environment doctor passes:

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

The health-runtime E2E and Runner Signals E2E are complementary. Neither substitutes for the other. Confirm teardown after every infrastructure-backed command.

## Files

- `coordination.json`: launcher manifest.
- `New-Phase7Worktree.ps1`: fail-closed local worktree creator.
- `coordinator.md`: Phase 7 coordinator prompt.
- `worker-integration-implementation.md`: Sol implementation role.
- `worker-validation.md`: independent validation role.
- `worker-independent-review.md`: independent Opus review role.
- `assignment-template.md`: exact task, claims, acceptance, and handoff contract.
