# DBAgent replication-risk coordination pack

This Telex prompt pack coordinates one change covering:

- [#1059 PM-96: Detect unsafe inactive PostgreSQL replication slots](https://github.com/azure-data-database-platform/dbagent/issues/1059)
- [#1061 PM-98: Detect PostgreSQL replication lag](https://github.com/azure-data-database-platform/dbagent/issues/1061)

The change establishes shared normalized replication entity semantics with
source-specific authority: Kusto owns topology, identity, WAL/history, and
PM-98; Geneva contributes transient exactly matched PM-96 activity.

## Bound execution configuration

```text
Repository: C:\Projects\dbagent-1059-1061-replication-risk
Repository slug: azure-data-database-platform/dbagent
Target branch: work/1059-1061-replication-risk
Base branch: main
Workflow: direct
Primary plan: none
Workflow context: none
Anchor checkout: C:\Projects\dbagent
Prompt pack: C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\dbagent-1059-1061-coordination
```

Worktree: [Open worktree](file:///C:/Projects/dbagent-1059-1061-replication-risk)

Coordinator prompt: [Open coordinator prompt](file:///C:/Users/brownch/OneDrive%20-%20Microsoft/Documents/DevTools/dbagent-1059-1061-coordination/coordinator.md)

Assignment template: `C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\dbagent-1059-1061-coordination\assignment-template.md`

Current handoff: [Open 2026-08-22 handoff](file:///C:/Users/brownch/OneDrive%20-%20Microsoft/Documents/DevTools/dbagent-1059-1061-coordination/handoff-2026-08-22.md)

Repository instructions: [Open repository instructions](file:///C:/Projects/dbagent-1059-1061-replication-risk/.github/copilot-instructions.md)

Coordination manifest: `C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\dbagent-1059-1061-coordination\coordination.json`

## Current paused state

Read `handoff-2026-08-22.md` before launching or assigning sessions. The scope
is paused, the final two-exact-IP pilot revision is frozen and accepted, and no
endpoint/Azure execution is authorized. Starting the coordination pack does not
itself resume work; the operator must explicitly authorize resumption.

Launch:

```powershell
& 'C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\generic-coordination\Start-Coordination.ps1' `
  'C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\dbagent-1059-1061-coordination\coordination.json'
```

Status and stop use `Get-CoordinationStatus.ps1` and `Stop-Coordination.ps1` from the same generic directory with this manifest path.

Open the read-only Telex console in another tab of the same terminal window:

```powershell
& 'C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\generic-coordination\Start-TelexConsole.ps1' `
  'C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\dbagent-1059-1061-coordination\coordination.json'
```

Load the worktree environment once per PowerShell session:

```powershell
Set-Location 'C:\Projects\dbagent-1059-1061-replication-risk'
Invoke-Expression ((& 'C:\Projects\dbagent-1059-1061-replication-risk\script\worktree-env.ps1') -join [Environment]::NewLine)
& 'C:\Projects\dbagent-1059-1061-replication-risk\script\worktree-env.ps1' -Doctor
```

The expected environment identity is:

```text
DBAGENT_SESSION_ID=dbagent-1059-1061-replication-risk
COMPOSE_PROJECT_NAME=dbagent-1059-1061-replication-risk
```

Do not use the anchor checkout or the cache-efficiency worktree for implementation, validation, or review of this change.

## Local Telex network

This pack uses a local Copilot push bridge with a dedicated network identity:

```text
Telex backend: local
Telex transport: local Copilot push bridge
Telex scope: dbagent-1059-1061
Coordinator address: dbagent-1059-1061-coordinator
Required address prefix: dbagent-1059-1061-
Issue set: 1059,1061
```

Do not reuse these addresses for issues #1055/#1057. Do not attach both coordination networks in one Copilot session. Every worker address, message, claim, ledger entry, and disposition in this pack must use the `dbagent-1059-1061-` prefix and identify issue set `1059,1061`.

Load exact bridge commands from the installed `telex copilot skill`; do not copy command syntax from another environment. Stop before assigning work if the local binary, local bridge, expected scope, or attended-push registration cannot be proven.

## Roles

| Role | Authority | Purpose |
| --- | --- | --- |
| Coordinator | Coordination records and accepted planning artifacts only | Owns routing, claims, acceptance, evidence, and workflow state |
| Integration/implementation | Claimed files only | Implements shared normalization, entity identity, policies, routing, and tests |
| Validation | Read-only unless granted one exact mechanical correction | Runs approved checks and records reproducible evidence |
| Independent review | Read-only and independent of implementation | Reviews the integrated change for correctness, wiring, privacy, and safety |

Roles define authority. Route workers by role, scope, risk, write authority, and independence.

Reject and leave untouched any message whose scope, address prefix, or issue set belongs to another network. Report cross-network delivery to the operator; never acknowledge it as work for this pack.

## Change boundaries

The implementation must:

1. Keep Kusto authoritative for topology, opaque entity identity, WAL/history,
   and PM-98 evidence.
2. Use Geneva only for transient PM-96 activity after an exact one-entity match.
3. Require Kusto WAL and fail closed on missing, stale, malformed, ambiguous,
   negative, reset, regression, or contradictory evidence.
4. Prevent Geneva disappearance from retiring an entity.
5. Define stable physical-replica and logical-slot entity keys.
6. Evaluate lag and inactive-slot risk as separate policies without asserting a
   remediation or that a slot is safe to drop.
7. Publish server-level Runner wake-ups while retaining entity-scoped evidence
   under approved privacy/cardinality rules.
8. Cover positive, adjacent-negative, planned-idle, source-gap,
   topology-change, removal, dedupe, and recovery behavior.

Do not split shared normalization, entity identity, or lifecycle semantics across implementation workers.

## Safety boundaries

- Local source edits and local validation only.
- Treat public endpoint/live-source observation, Azure read-only preflight,
  Azure provisioning, and physical replication interruption as separate
  authorization gates. Approval for one does not approve another.
- Do not run connected production, Azure, Geneva, Kusto, deployment, migration,
  credential, replication-slot, topology, or data-mutation actions without the
  corresponding explicit operator authorization.
- Do not place secrets in tracked files. No anchor `.env.local` was present when this worktree was created.
- Start Docker infrastructure only when an assigned validation tier requires it, load this worktree's environment first, and tear it down with `docker compose down --remove-orphans`.
- Do not delete volumes unless the operator explicitly authorizes loss of local emulator or database state.

## Validation commands

Run from `C:\Projects\dbagent-1059-1061-replication-risk` after loading `worktree-env.ps1`:

```powershell
dotnet build 'C:\Projects\dbagent-1059-1061-replication-risk\platform\src\DBAgent.sln'
dotnet test 'C:\Projects\dbagent-1059-1061-replication-risk\platform\src\DBAgent.sln' --filter 'Category!=Integration'
npm run lint
npm run typecheck
npm test
```

Use narrower affected test projects first. Run Docker-backed integration or E2E only if the implemented source/evaluation path requires that tier or the operator explicitly requests it.

For implementation handoff and review:

- Freeze the reviewed scope only after all writes stop and claims are returned.
- Publish two identical manifests after a quiescence interval.
- Validators and reviewers verify hashes before and after and abort on drift.
- Reassignments include prior blocking findings in full.
- Bicep changes require emitted parameter-file keys to match template
  declarations; successful compilation alone is insufficient.

## Files

- `coordinator.md`: overall coordination prompt.
- `worker-integration-implementation.md`: implementation role prompt.
- `worker-validation.md`: validation role prompt.
- `worker-independent-review.md`: independent review prompt.
- `assignment-template.md`: exact task and claim handoff.
- `handoff-2026-08-22.md`: accepted state, immutable evidence, pause gate, and restart workflow.
