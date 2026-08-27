# Recover Failed Investigations Phase 7 coordination pack v2

This pack continues Phase 7 of the PAW work item `recover-failed-investigations`
from the existing integrated worktree. It follows the launcher, worktree,
capability-floor, claim, validation, and independent-review rules in
`generic-coordination`.

## Bound configuration

```text
Repository: C:\Projects\dbagent-recover-phase7
Repository slug: azure-data-database-platform/dbagent
Target branch: feature/recover-failed-investigations_phase7
Base branch: feature/recover-failed-investigations_phase6
Current HEAD: 336e7c3970ac0f88740a97a923e18c2cd97dcd24
Workflow: paw-prs
Primary plan: C:\Projects\dbagent-recover-phase7\.paw\work\recover-failed-investigations\ImplementationPlan.md
Workflow context: C:\Projects\dbagent-recover-phase7\.paw\work\recover-failed-investigations\WorkflowContext.md
Prompt pack: C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\recover-failed-investigations-phase7-coordination-v2
Telex scope: recover-failed-investigations-phase7-v2
```

The worktree contains the inherited integrated Phase 7 diff. The v2 coordinator
must inventory and preserve it before assigning claims. It must not treat the
dirty state as disposable or reset it to HEAD.

## Cutover from v1

The v1 and v2 packs share one integration worktree. Never run both packs at the
same time. Stop v1 before launching v2:

```powershell
& 'C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\generic-coordination\Stop-Coordination.ps1' `
  'C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\recover-failed-investigations-phase7-coordination\coordination.json'
```

Stopping sessions does not reset, clean, stage, commit, or delete the worktree.
Confirm no v1 implementation or validation process remains before starting v2.

## Validate, render, and launch

```powershell
$launcher = 'C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\generic-coordination\Start-Coordination.ps1'
$config = 'C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\recover-failed-investigations-phase7-coordination-v2\coordination.json'

& $launcher $config -ValidateOnly
& $launcher $config -RenderOnly
& $launcher $config
```

Inspect, open the read-only Telex console, and stop:

```powershell
$generic = 'C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\generic-coordination'
$config = 'C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\recover-failed-investigations-phase7-coordination-v2\coordination.json'

& "$generic\Get-CoordinationStatus.ps1" $config
& "$generic\Start-TelexConsole.ps1" $config
& "$generic\Stop-Coordination.ps1" $config
```

## Roles

| Role | Model | Authority |
| --- | --- | --- |
| Coordinator | GPT-5.6 Sol | Coordination records, accepted PAW records, and final accepted local commit only |
| Integration implementation | GPT-5.6 Sol | Exact claimed files only |
| Validation and evidence | Claude Sonnet 5 | Read-only |
| Independent review | Claude Opus 5 | Read-only and independent |

Workers do not use subagents, factories, fleets, or delegated agents.

## Safety

- Local source edits and local validation only.
- No push, PR, merge, deployment, migration, production access, credential
  mutation, cohort promotion, or connected measurement without explicit
  operator authorization.
- Load `script\worktree-env.ps1` and run `-Doctor` before raw package-manager,
  build, Docker, integration, or E2E commands.
- Serialize Docker, Service Bus, Cosmos, PostgreSQL, Kusto, generated outputs,
  solution builds, and E2E suites.
- Tear down the worktree's infrastructure after every infrastructure-backed
  command, including failures.
- Apply D-150 before changing a stored document, event payload, or projection
  shape or value semantics.
- Preserve the frozen Phase 6 API, MCP, history, lag, provenance, pagination,
  cancellation, and size contracts.

## Validation evidence integrity

Each connected checkpoint uses a new artifact directory and one real process.
The validator records a pre-run UTC note, exact command, source hashes, target,
and process identity. It accepts evidence only when output timestamps, test run
IDs, delivery IDs, PDB mappings, and hashes belong to that invocation.

If a command exits without fresh output, the validator reports the command
failure. It never copies an earlier checkpoint into the new directory or
reports frozen inputs as fresh outputs.

## Files

- `coordination.json`
- `coordinator.md`
- `worker-integration-implementation.md`
- `worker-validation.md`
- `worker-independent-review.md`
- `assignment-template.md`
