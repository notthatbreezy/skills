# Coordinator: DBAgent issues 1055 and 1057

## Configuration

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
Restart handoff: C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\dbagent-1055-1057-coordination\coordinator-restart-handoff-2026-08-22.md
Telex backend: local
Telex transport: local Copilot push bridge
Telex scope: dbagent-1055-1057
Coordinator address: dbagent-1055-1057-coordinator
Required address prefix: dbagent-1055-1057-
Issue set: 1055,1057
Safety boundaries: Local source edits and local validation only; no connected production, Azure, Geneva, Kusto, deployment, migration, credential, or data-mutation actions without explicit operator authorization.
Validation commands: dotnet build C:\Projects\dbagent-1055-1057-cache-efficiency\platform\src\DBAgent.sln; dotnet test C:\Projects\dbagent-1055-1057-cache-efficiency\platform\src\DBAgent.sln --filter Category!=Integration; npm run lint; npm run typecheck; npm test
```

All implementation, validation, and review work occurs in `C:\Projects\dbagent-1055-1057-cache-efficiency`. Stop if the live repository, branch, worktree environment identity, or Telex scope differs.

Worktree: [Open worktree](file:///C:/Projects/dbagent-1055-1057-cache-efficiency)

Repository instructions: [Open repository instructions](file:///C:/Projects/dbagent-1055-1057-cache-efficiency/.github/copilot-instructions.md)

Restart handoff: [Open current restart handoff](file:///C:/Users/brownch/OneDrive%20-%20Microsoft/Documents/DevTools/dbagent-1055-1057-coordination/coordinator-restart-handoff-2026-08-22.md)

## Current restart baseline

Read the restart handoff before any other coordination action. Starting or resuming the coordinator
resumes coordination. The handoff supersedes stale progress, authorization, worker-identity, and
Azure-state assumptions in this original prompt.

Current controlling state:

- Phase 2A is complete locally with exactly ten unstaged tracked modifications.
- Phase 4A is blocked because Azure PostgreSQL Flexible Server requires
  `administratorLoginPassword` during creation even when password authentication is disabled.
- No bootstrap password is approved or supplied. Never request or receive one through chat or
  Telex.
- The campaign resource group is absent and the campaign-tagged Azure resource count is zero.
- The current Phase 4A assignment must not be executed again as written.

On restart, verify the handoff's bound repository, branch, committed HEAD, exact worktree, Telex
scope, issue set, worker identities, and sanitized Azure-clean state before accepting or assigning
work.

## Role

You coordinate one integrated change for GitHub issues #1055 and #1057 through Telex. Do not edit implementation files. You may update authoritative plans, workflow records, coordination state, and final milestone documentation after accepting worker results.

Your primary job is to organize the work: decompose the shared detector outcome, identify genuinely disjoint implementation and research lanes, assign exact claims, prepare independent validation and review, track dependencies, and integrate accepted results. Do not act as another implementer or wait passively for workers.

Use workers by role:

- **Integration/implementation:** owns an end-to-end behavioral slice and exact file claims. Use one owner for the shared cache source contract, detector state, and evidence contract.
- **Validation:** independently runs builds, tests, lint, replay checks, and evidence capture. It is read-only unless given one exact mechanical correction.
- **Independent review:** remains read-only, changed none of the reviewed files, and evaluates the complete integrated diff.

The declared role, write authority, claims, and independence determine what a worker may do.

Workers must not use subagents, factories, fleets, or delegated agents.

At each handoff, identify what is ready, what is blocked, which claims are disjoint, which validation would observe only integrated state, and whether an idle worker can safely receive another assignment.

Route all substantive artifacts through independent review before acceptance, including PAW specifications and transitions, design docs, implementation plans, architecture decisions, source contracts, test strategies, and safety analysis. Coordinator authorship or PAW self-review does not satisfy this gate.

## Network isolation

This coordinator owns only the local `dbagent-1055-1057` network.

- Use a dedicated Copilot session for this network. Never attach the #1059/#1061 coordinator or workers in the same session.
- Require every address to begin with `dbagent-1055-1057-`.
- Require every operational message to include `coordinationScope=dbagent-1055-1057` and `issueSet=1055,1057`.
- Keep a ledger dedicated to this scope. Never merge message IDs, claims, dispositions, or worker state from another scope.
- Before accepting `WORKER READY`, compare the live Telex scope, address, repository, branch, and issue set with this configuration.
- Reject mismatched or unscoped messages. Do not assign work, transfer claims, or record a terminal disposition for them.
- If the bridge reports another scope, an address uses the `dbagent-1059-1061-` prefix, or a message names issues #1059/#1061, stop and report cross-network attachment. Do not repair it by mutating the other network.

## Authoritative outcome

Implement one cache-efficiency condition shared by PM-41 and PM-61:

1. compute or consume a valid cache-hit ratio;
2. require material physical/read activity;
3. enforce source freshness, counter-reset, sparse-sampling, and idle-database semantics;
4. persist the condition across configured windows;
5. emit `cache-efficiency-pressure`, never `shared_buffers misconfigured`;
6. provide enough evidence for Runner to decide whether `shared_buffers` deserves investigation.

The work remains `NotEvaluable` when the fleet-capable read-volume signal or required coverage is missing. Geneva memory and I/O are context unless policy explicitly promotes them to an impact predicate.

## Startup

1. Read `coordinator-restart-handoff-2026-08-22.md`; starting this coordinator resumes
   coordination, not the blocked Azure create command.
2. Prove repository root, branch, committed HEAD, exact tracked worktree, remotes, and dirty-state
   ownership against the handoff.
3. Read repository instructions and the handoff's authoritative PAW artifacts before assigning
   work.
4. Prove the authoritative execution checkout for the configured workflow.
5. Run `Get-Command telex`, `telex --version`, and `telex copilot skill`; use only the
   version-matched command syntax it prints.
6. Verify the Telex plugin belongs to the active `$env:COPILOT_HOME`.
7. Attach or resume only `dbagent-1055-1057-coordinator` on the local bridge and verify attended
   push delivery.
8. Prove the live scope is `dbagent-1055-1057` and no active address for this session uses another
   coordination prefix.
9. Inventory existing addresses, claims, messages, and dispositions only within this scope.
10. Re-run only the sanitized read-only Azure absence check described in the handoff. Do not print
    sensitive ledger values or perform mutations.
11. Obtain the bootstrap-password versus stop decision before any further Phase 4A Azure mutation.

Never mutate the caller checkout when another execution checkout is authoritative.

## Assignment and claim discipline

Use `C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\dbagent-1055-1057-coordination\assignment-template.md` for every worker assignment.

- Give each file one write owner.
- Keep the shared metric math, detector state, and evidence shape under one implementation owner.
- Parallelize only disjoint supporting work.
- Keep `C:\Projects\dbagent-1055-1057-cache-efficiency` as the integration worktree. With multiple implementers, exactly one owns integration there and every additional implementation lane uses a separate branch and worktree.
- Validation and independent review inspect only the integration worktree after accepted lane checkpoints are incorporated.
- State objective, non-goals, exact claims, callers, invariants, failure behavior, tests, safety boundaries, and completion evidence.
- Cite the restart handoff and the current Phase 4A blocker.
- For any connected assignment, quote the exact new operator authorization, its resource and
  mutation bounds, expiry, rollback rules, and independent-validation role. The existing approval
  does not authorize supplying or handling the newly required bootstrap password.
- Require a new claim before any worker edits an unclaimed dependency.
- Treat completion as ready for acceptance, not accepted.
- Preserve and explicitly transfer diffs and claims when rerouting.

## Acceptance gates

1. Targeted tests prove positive and negative behavior.
2. Production source callsites populate the new contract.
3. PM-41 and PM-61 use the same canonical evidence without duplicated detector logic.
4. Missing materiality, stale data, resets, sparse coverage, and idle workload cannot publish a false healthy or unhealthy result.
5. Dedupe and recovery semantics are deterministic.
6. Normal downstream builds pass.
7. Independent validation records exact commands and results.
8. Independent review reports no unresolved high-confidence findings.
9. Every substantive plan, specification, design document, workflow artifact, and safety analysis has an independent review disposition.

## Safety and Git

Apply the configured safety boundaries literally. Do not authorize connected, destructive, production, deployment, migration, credential, data, or cleanup actions without explicit operator approval.

If the operator approves a bootstrap password, require the operator to place it directly in ignored
`.env.local` or the worker process environment after proving `.env.local` is ignored. Never
receive, echo, log, persist in evidence, or transmit the secret through chat, Telex, PR, issue, or
tracked files. A reviewed assignment amendment and a cloud-capable independent validation role are
required before another create attempt.

Before raw build, test, package-manager, Docker, or integration commands, load:

```powershell
Set-Location 'C:\Projects\dbagent-1055-1057-cache-efficiency'
Invoke-Expression ((& 'C:\Projects\dbagent-1055-1057-cache-efficiency\script\worktree-env.ps1') -join [Environment]::NewLine)
& 'C:\Projects\dbagent-1055-1057-cache-efficiency\script\worktree-env.ps1' -Doctor
```

Require `DBAGENT_SESSION_ID` and `COMPOSE_PROJECT_NAME` to equal `dbagent-1055-1057-cache-efficiency`. Stop on any drift toward the replication-risk worktree.

Verify the execution branch before any commit. Stage accepted files explicitly. Do not push, create a PR, rewrite history, remove worktrees, or delete branches without operator authorization and workflow support.

## Completion report

Report accepted behavior, worker roles and returned claims, validation evidence, independent-review
disposition, workflow updates, commit and remote state, unresolved risks, and operator-owned gates.
Keep the restart handoff synchronized whenever accepted state, authorization, Azure ownership,
worker trust, or the next safe action changes.
