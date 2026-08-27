# DBAgent cache-efficiency coordination pack

This Telex prompt pack coordinates one change covering:

- [#1055 PM-41: Detect PostgreSQL cache-efficiency degradation](https://github.com/azure-data-database-platform/dbagent/issues/1055)
- [#1057 PM-61: Detect shared_buffers-related cache pressure](https://github.com/azure-data-database-platform/dbagent/issues/1057)

The change implements one shared cache-efficiency detector. PM-41 owns the generic condition; PM-61 consumes the same evidence as a reason for Runner to investigate `shared_buffers` without Platform asserting that configuration as the cause.

## Current status

- **Launching the packet starts coordination immediately:** no separate confirmation is required.
- **Phase 2A is complete locally:** the integration worktree has exactly ten unstaged tracked
  modifications.
- **Azure is empty:** the campaign resource group is absent and campaign-tagged resource count is
  zero.
- **Phase 4A is blocked:** Azure requires a bootstrap `administratorLoginPassword` during server
  creation even when password authentication is disabled.

Read the [current restart handoff](file:///C:/Users/brownch/OneDrive%20-%20Microsoft/Documents/DevTools/dbagent-1055-1057-coordination/coordinator-restart-handoff-2026-08-22.md)
before launching or resuming any coordinator or worker. The handoff supersedes stale progress,
worker-identity, and Azure-state assumptions in the original prompts.

## Bound execution configuration

```text
Repository: C:\Projects\dbagent-1055-1057-cache-efficiency
Repository slug: azure-data-database-platform/dbagent
Target branch: work/1055-1057-cache-efficiency
Base branch: main
Workflow: direct
Primary plan: none
Workflow context: none
Anchor checkout: C:\Projects\dbagent
Prompt pack: C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\dbagent-1055-1057-coordination
```

Worktree: [Open worktree](file:///C:/Projects/dbagent-1055-1057-cache-efficiency)

Coordinator prompt: [Open coordinator prompt](file:///C:/Users/brownch/OneDrive%20-%20Microsoft/Documents/DevTools/dbagent-1055-1057-coordination/coordinator.md)

Assignment template: `C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\dbagent-1055-1057-coordination\assignment-template.md`

Restart handoff: `C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\dbagent-1055-1057-coordination\coordinator-restart-handoff-2026-08-22.md`

Repository instructions: [Open repository instructions](file:///C:/Projects/dbagent-1055-1057-cache-efficiency/.github/copilot-instructions.md)

Coordination manifest: `C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\dbagent-1055-1057-coordination\coordination.json`

Launch:

```powershell
& 'C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\generic-coordination\Start-Coordination.ps1' `
  'C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\dbagent-1055-1057-coordination\coordination.json'
```

Status and stop use `Get-CoordinationStatus.ps1` and `Stop-Coordination.ps1` from the same generic directory with this manifest path.

Load the worktree environment once per PowerShell session:

```powershell
Set-Location 'C:\Projects\dbagent-1055-1057-cache-efficiency'
Invoke-Expression ((& 'C:\Projects\dbagent-1055-1057-cache-efficiency\script\worktree-env.ps1') -join [Environment]::NewLine)
& 'C:\Projects\dbagent-1055-1057-cache-efficiency\script\worktree-env.ps1' -Doctor
```

The expected environment identity is:

```text
DBAGENT_SESSION_ID=dbagent-1055-1057-cache-efficiency
COMPOSE_PROJECT_NAME=dbagent-1055-1057-cache-efficiency
```

Do not use the anchor checkout or the replication-risk worktree for implementation, validation, or review of this change.

## Local Telex network

This pack uses a local Copilot push bridge with a dedicated network identity:

```text
Telex backend: local
Telex transport: local Copilot push bridge
Telex scope: dbagent-1055-1057
Coordinator address: dbagent-1055-1057-coordinator
Required address prefix: dbagent-1055-1057-
Issue set: 1055,1057
```

Do not reuse these addresses for issues #1059/#1061. Do not attach both coordination networks in one Copilot session. Every worker address, message, claim, ledger entry, and disposition in this pack must use the `dbagent-1055-1057-` prefix and identify issue set `1055,1057`.

Load exact bridge commands from the installed `telex copilot skill`; do not copy command syntax from another environment. Stop before assigning work if the local binary, local bridge, expected scope, or attended-push registration cannot be proven.

## Roles

| Role | Authority | Purpose |
| --- | --- | --- |
| Coordinator | Coordination records and accepted planning artifacts only | Owns routing, claims, acceptance, evidence, and workflow state |
| Integration/implementation | Claimed files only | Traces and implements the shared source contract, detector, scenario evidence, routing, and tests |
| Validation | Read-only unless granted one exact mechanical correction | Runs approved checks and records reproducible evidence |
| Independent review | Read-only and independent of implementation | Reviews the complete change for correctness, wiring, safety, and evidence gaps |

Roles define authority. Route workers by role, scope, risk, write authority, and independence.

Reject and leave untouched any message whose scope, address prefix, or issue set belongs to another network. Report cross-network delivery to the operator; never acknowledge it as work for this pack.

## Change boundaries

The implementation must:

1. Define one source contract for cache-hit ratio, read-volume materiality, freshness, resets, sparse sampling, and idle databases.
2. Emit `cache-efficiency-pressure` evidence without claiming `shared_buffers` is misconfigured.
3. Route the generic condition to PM-41 and make the same evidence available to PM-61 investigation.
4. Keep the path `NotEvaluable` when the approved materiality signal or source coverage is unavailable.
5. Cover positive, low-volume, idle, reset, sparse, stale, missing-source, workload-scan, dedupe, and recovery behavior.
6. Prove production source wiring rather than relying only on catalog declarations or synthetic tests.

Do not split the shared detector, evidence contract, or state transition across implementation workers. Validation and review remain separate roles.

## Safety boundaries

- Local source edits and local validation only.
- Launching or resuming the coordinator and workers resumes coordination work.
- Do not run connected production, Azure, Geneva, Kusto, deployment, migration, credential, or data-mutation actions without explicit operator authorization.
- Do not place secrets in tracked files. No anchor `.env.local` was present when this worktree was created.
- Never request or receive a bootstrap password through chat or Telex. If later approved, the
  operator must place it directly in a proven-ignored `.env.local` or process environment under a
  reviewed assignment with redaction and cleanup controls.
- Start Docker infrastructure only when an assigned validation tier requires it, load this worktree's environment first, and tear it down with `docker compose down --remove-orphans`.
- Do not delete volumes unless the operator explicitly authorizes loss of local emulator or database state.

## Validation commands

Run from `C:\Projects\dbagent-1055-1057-cache-efficiency` after loading `worktree-env.ps1`:

```powershell
dotnet build 'C:\Projects\dbagent-1055-1057-cache-efficiency\platform\src\DBAgent.sln'
dotnet test 'C:\Projects\dbagent-1055-1057-cache-efficiency\platform\src\DBAgent.sln' --filter 'Category!=Integration'
npm run lint
npm run typecheck
npm test
```

Use narrower affected test projects first. Run Docker-backed integration or E2E only if the implemented source/evaluation path requires that tier or the operator explicitly requests it.

## Files

- `coordinator.md`: overall coordination prompt.
- `coordinator-restart-handoff-2026-08-22.md`: mandatory current state, restart, authorization, and
  blocker baseline.
- `worker-integration-implementation.md`: implementation role prompt.
- `worker-validation.md`: validation role prompt.
- `worker-independent-review.md`: independent review prompt.
- `assignment-template.md`: exact task and claim handoff.
