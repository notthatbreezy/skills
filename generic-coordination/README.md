# Generic coordinator and worker prompt pack

This directory contains project-agnostic prompts for coordinating implementation, validation, evidence, and review across ordinary branches, worktrees, PAW workflows, and ExecPlans.

The prompts do not replace repository instructions. Before use, substitute every configuration token and require the coordinator to read the target repository's instructions, plans, workflow context, safety boundaries, and build commands.

Assignment template: `C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\generic-coordination\assignment-template.md`

## Configuration tokens

Replace these tokens before starting sessions:

| Token | Meaning |
| --- | --- |
| `<REPOSITORY_PATH>` | Absolute path to the execution checkout |
| `<REPOSITORY_SLUG>` | Repository identity such as `owner/repository` |
| `<TARGET_BRANCH>` | Branch that owns accepted work |
| `<BASE_BRANCH>` | Integration base, usually `main` |
| `<WORKFLOW_KIND>` | `direct`, `execplan`, `paw-local`, or `paw-prs` |
| `<PRIMARY_PLAN_PATH>` | Authoritative plan or `none` |
| `<WORKFLOW_CONTEXT_PATH>` | Active PAW `WorkflowContext.md` or `none` |
| `<TELEX_BACKEND>` | Configured Telex backend |
| `<TELEX_TRANSPORT>` | Copilot push bridge or another explicitly verified transport |
| `<TELEX_SCOPE>` | Durable coordination scope |
| `<COORDINATOR_ADDRESS>` | Durable coordinator address |
| `<SAFETY_BOUNDARIES>` | Project-specific mutation, data, deployment, and privacy restrictions |
| `<VALIDATION_COMMANDS>` | Project-approved targeted and final validation commands |

Do not start while an unresolved token remains.

## Worker types

| Worker type | Minimum model | Permitted models | Best use |
| --- | --- | --- | --- |
| `bounded-implementation` | Terra | Terra or Sol | One subsystem, explicit claims, established patterns, deterministic tests |
| `validation-evidence` | Luna | Luna, Terra, or Sol | Builds, tests, lint, evidence, hashes, mechanical documentation updates |
| `integration-implementation` | Sol | Sol | Cross-domain state, recovery, concurrency, process lifecycle, authorization, or high-risk architecture |
| `independent-review` | Sol | Sol | Read-only integrated review by a worker that did not implement the change |

Workers never use subagents, factories, or delegated agents. The coordinator may use subagents only when the operator explicitly requests a multi-model review or Society of Thought review.

The coordinator delegates research and implementation whenever a worker can own a coherent task. Direct coordinator work should concentrate on routing, claim control, acceptance review, validation, evidence, and workflow records.

## Coordinator operating mandate

The coordinator is an orchestrator, not an extra implementer. Its primary job is to:

1. decompose the requested outcome into coherent behavioral and state-owner boundaries;
2. identify which implementation lanes are genuinely disjoint and safe to run concurrently;
3. identify validation and review work that can proceed independently without observing stale or partial integration state;
4. assign each lane with exact claims, dependencies, acceptance criteria, and stop conditions;
5. serialize shared files, integration points, infrastructure, generated outputs, and final gates;
6. keep workers productive by preparing the next safe assignment or read-only analysis while another lane is blocked;
7. integrate accepted results into the authoritative target before independent validation and final review;
8. reroute work when a task no longer matches its declared role, claims, or risk.

The coordinator does not wait passively for workers or perform implementation to fill idle time. It continuously maintains the dependency graph, claim ledger, readiness of downstream work, and evidence required for acceptance.

## Mandatory independent review

All substantive artifacts receive independent review before acceptance, even when the coordinator rather than an implementation worker authored them. This includes:

- PAW specifications, design documents, planning documents, implementation plans, workflow contexts, and transition artifacts;
- design decisions, architecture changes, schemas, contracts, migration plans, and security or safety analysis;
- material test strategies, validation plans, rollout plans, and operator-facing runbooks;
- implementation diffs and generated artifacts.

The independent reviewer must not have authored the reviewed artifact. Coordinator ownership does not waive review. Minor mechanical coordination records, message ledgers, status updates, and typo-only edits may be exempt when they do not change requirements, design, behavior, safety, or acceptance criteria.

For PAW workflows, include independent review as an explicit dependency before the reviewed artifact's acceptance or phase transition. Do not treat PAW's internal authoring or self-check as the independent review gate.

## Worktree topology

Use one authoritative **integration worktree** for the target branch.

- The coordinator reads the integration worktree but does not implement there.
- With one implementation worker, that worker may own the integration worktree.
- With multiple implementation workers, assign exactly one integration owner to the integration worktree. Give every additional implementation lane a distinct worktree and branch.
- Never place two concurrent implementation workers in the same worktree.
- Lane workers commit coherent checkpoints on their lane branches. The integration owner incorporates accepted checkpoints into the integration worktree using the repository-approved merge or cherry-pick workflow.
- Validators and independent reviewers inspect only the integrated target after the required checkpoint is visible. They do not validate or review isolated lane worktrees as if those represented the final change.
- Validation and review sessions may share the integration worktree because they are read-only, but their commands and shared infrastructure must still be serialized when outputs can collide.
- Remote workers cannot see local uncommitted work. Provide a visible immutable checkpoint before remote validation or review.

The launcher validates this topology: at least one implementer, validator, and reviewer; exactly one coordinator; exactly one implementer assigned to the integration worktree; and no implementation worktree shared by multiple implementers.

## Manifest-driven launcher

Copy `coordination-template.json`, replace every placeholder, then validate without launching:

```powershell
& 'C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\generic-coordination\Start-Coordination.ps1' `
  'C:\absolute\path\to\coordination.json' `
  -ValidateOnly
```

Render and parse every generated session bootstrap without opening Windows Terminal or starting Agency/Copilot:

```powershell
& 'C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\generic-coordination\Start-Coordination.ps1' `
  'C:\absolute\path\to\coordination.json' `
  -RenderOnly
```

Start, inspect, and stop:

```powershell
& 'C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\generic-coordination\Start-Coordination.ps1' `
  'C:\absolute\path\to\coordination.json'

& 'C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\generic-coordination\Get-CoordinationStatus.ps1' `
  'C:\absolute\path\to\coordination.json'

& 'C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\generic-coordination\Stop-Coordination.ps1' `
  'C:\absolute\path\to\coordination.json'
```

Open the separately installed, read-only `telex-console` TUI as another tab in the configured terminal window:

```powershell
& 'C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\generic-coordination\Start-TelexConsole.ps1' `
  'C:\absolute\path\to\coordination.json'
```

Validate its generated bootstrap without launching:

```powershell
& 'C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\generic-coordination\Start-TelexConsole.ps1' `
  'C:\absolute\path\to\coordination.json' `
  -RenderOnly
```

The console reads the same configured Telex backend directly. It does not create an agent session, attach an address, claim a lease, heartbeat, send messages, or write dispositions. Quit it with `q`.

The launcher uses:

```text
agency copilot --yolo --mcp workiq --mcp enghub --mcp es-chat --hub
```

It appends a stable session ID, the configured worktree with `-C`, a session name with `-n`, and a generated interactive bootstrap prompt with `-i`.

The coordinator starts first. Other sessions launch only after its exact Telex session reaches `attended_push`.

### Creating missing worktrees

Set `createIfMissing` and provide an argv-safe creator rather than embedding an evaluated command string:

```json
{
  "name": "implementation-lane-2",
  "path": "C:\\Projects\\repo-lane-2",
  "branch": "work/lane-2",
  "baseBranch": "main",
  "integration": false,
  "createIfMissing": true,
  "environmentScript": "C:\\Projects\\repo-lane-2\\script\\worktree-env.ps1",
  "creator": {
    "executable": "C:\\Projects\\repo\\script\\worktree-new.ps1",
    "arguments": [
      "lane-2",
      "work/lane-2"
    ]
  }
}
```

Add one implementer session referencing that worktree. The launcher rejects two implementers sharing one worktree.

## Model capability floor

Use the capability order `Sol > Terra > Luna`. Capacity may move work upward, never downward:

- Sol may perform any worker type.
- Terra may perform bounded implementation or validation.
- Luna may perform validation only.

The assigned model must still obey the selected worker type's authority, claims, restrictions, and completion report. A Sol validation worker remains read-only. Never assign integration implementation or independent review below Sol, and never assign bounded implementation below Terra.

For Terra assignments, define the complete acceptance contract up front: exact invariants, negative cases, downstream consumers, normal consumer-level builds, generated-artifact parity, and stop conditions. Package-local tests alone are never sufficient when a change alters generated interfaces, shared contracts, schemas, or runtime consumers.

## Telex startup and profile isolation

Do not equate an installed `telex` binary with a working Copilot session.

1. Run `Get-Command telex`, `telex --version`, and the installed version-matched `telex copilot skill`.
2. Record `$env:COPILOT_HOME`.
3. Confirm the Telex plugin is installed and enabled in that active home. A plugin under `%USERPROFILE%\.copilot` is invisible to a CLI launched with a different `COPILOT_HOME`.
4. Attach or resume the assigned address with the configured scope, description, and `--copilot-bridge`.
5. Call `extensions_reload`.
6. Require `telex-bridge` to report `ready`, call `telex_bridge_info`, and verify the current session with `telex --json --address <address> status`.
7. Require `push_registered: true` and `station_health: attended_push`.

If reload reports zero extensions or the bridge tool is absent, stop. Report the active home, plugin path, generated bridge path, and session ID. Repair the profile mismatch before coordinating; never substitute informal messaging.

A common failure signature is: `telex --version` succeeds, attachment succeeds, but `extensions_reload` reports zero extensions. This means the binary and durable station exist while the active Copilot profile cannot load the bridge. Repair the active profile, restart any already-open CLI, then repeat attachment and liveness verification.

## Startup identity

Every worker sends this message before receiving work:

```text
WORKER READY
workerType=<declared worker type>
model=<sol|terra|luna>
mode=<implementation|validation|review>
address=<exact Telex address>
repository=<REPOSITORY_PATH>
branch=<TARGET_BRANCH>
workflow=<WORKFLOW_KIND>
writeAuthority=<none|claimed-files-only>
subagents=prohibited
```

The coordinator verifies the Telex address, tags, description, repository, branch, workflow, and write authority. Model name alone never establishes authority.

Telex delivery is at least once. The coordinator keeps a durable message-ID ledger, acknowledges redelivery idempotently, and records terminal disposition once. A late or semantically duplicate readiness/result message must not repeat assignments, claims, work, or dispositions.

## Distribution rules

1. Split work by authoritative state owner and behavioral boundary, not arbitrary file count.
2. Give each file one write owner.
3. Keep a continuous behavioral trace with one worker.
4. Run parallel lanes only when files, state owners, generated outputs, and validation processes are disjoint.
5. Serialize shared files, builds, UI automation, integration infrastructure, migrations, and connected actions.
6. Use Terra for bounded implementation, Luna for deterministic validation, and Sol for cross-domain implementation or independent review.
7. Use a separate review worker for high-risk changes.
8. Stop and reroute when a worker discovers unclaimed dependencies or work outside its declared type.
9. Prefer one capable worker over several overlapping workers.
10. Use blocked workers for read-only design or claim planning that does not conflict with their active assignment.
11. Generated declarations and dashboards are not proof of production wiring; track source emitters/callers as explicit work.
12. A remote worker cannot inspect uncommitted local changes. Use remote implementation/review only after an authorized commit/push or another approved immutable handoff makes the exact source visible.
13. Route every substantive coordinator-authored plan, specification, design artifact, and workflow transition artifact through independent review before acceptance.

## Review independence

A worker may independently review a different change when it changed none of the reviewed files and receives a separate read-only review assignment. It must state that independence explicitly. An implementation owner never reviews its own work. Use a dedicated Sol review address for final integrated review; a disjoint Sol implementation session may perform an earlier task-level review when it has no reviewed-file changes.

## Completion, acceptance, and claim transfer

Worker `PASS` or `COMPLETE` means "ready for acceptance," not accepted.

1. The coordinator or independent reviewer inspects the complete local diff, not only the completion summary.
2. Acceptance checks the exact requirement, negative cases, downstream consumer builds, generated parity, source wiring, and repository-wide compatibility required by the assignment.
3. Package-local green tests do not override a failing normal consumer build.
4. Independent validation uses the normal command unless the assignment explicitly authorizes an isolated diagnostic command.
5. On reroute, the current worker stops, preserves the working-tree diff, returns claims, and reports unresolved work. It never reverts, cleans, or discards the handoff.
6. The new owner inspects the preserved diff before editing and receives the exact transferred claims.
7. Terra receives one bounded correction cycle for missed acceptance criteria; unresolved cross-boundary work moves upward to Sol.

## PAW and ExecPlan support

- For PAW, the coordinator reads `WorkflowContext.md`, proves the execution checkout, obeys the target branch, strategy, execution binding, and artifact lifecycle, and loads the required PAW activity skill before acting.
- For ExecPlans, the coordinator reads `PLANS.md` and the active plan, keeps living sections current, and treats the plan's authority and milestone gates as binding.
- For direct branch work, the coordinator establishes the target branch, base branch, dirty-state ownership, validation gates, and commit/push policy explicitly.

## What can go wrong

| Risk | Mitigation |
| --- | --- |
| Unreplaced tokens route work to the wrong repository or branch | Refuse startup while any `<TOKEN>` remains |
| Generic instructions omit project safety rules | Read repository instructions and inject `<SAFETY_BOUNDARIES>` before assignment |
| PAW execution checkout differs from the caller checkout | Prove execution binding from `WorkflowContext.md`; never guess |
| Workers edit the same file or state transition | Maintain exact claims and one write owner per file |
| Parallel builds or UI tests corrupt shared outputs | Serialize validation windows |
| Generated interfaces break downstream consumers while package tests stay green | Require normal consumer builds and source-implementation completeness before acceptance |
| Luna or Terra receives ambiguous cross-domain work | Stop and reroute to Sol integration |
| An implementer performs its own independent review | Require a distinct Sol review address and session |
| A worker reviews a different task but has touched its files | Reject the review as non-independent; use a worker with zero reviewed-file changes |
| A lower-capability model receives higher-floor work | Enforce `Sol > Terra > Luna`; upgrades are allowed, downgrades are forbidden |
| Telex exists on `PATH` but the active CLI cannot load its plugin | Compare the plugin and bridge paths with `$env:COPILOT_HOME`; restart after installing in the active home |
| `extensions_reload` reports zero Telex extensions | Stop and repair bridge provisioning; require `telex_bridge_info` and `attended_push` before work |
| Telex at-least-once delivery duplicates work | Ack by message ID, deduplicate, and record terminal disposition |
| Late readiness/results repeat already completed coordination | Treat them as semantic duplicates; acknowledge without changing claims or resending assignments |
| Rerouting loses or overwrites useful uncommitted work | Stop the old owner, preserve the diff, transfer claims, and require a written handoff |
| Remote workers cannot see the local dirty tree | Wait for an authorized visible checkpoint before assigning remote implementation or review |
| Generic boilerplate overwhelms the actual assignment | Keep each task bounded with concrete files, behavior, tests, and stop conditions |
| Prompt guidance drifts from tool versions | Load installed version-matched skills and CLI help at session start |
| Cleanup deletes unique uncommitted work | Inspect worktrees, branches, status, ancestry, and untracked content before deletion |

## Files

- `coordinator-sol.md`: generic overall coordinator.
- `worker-terra-implementation.md`: bounded implementation.
- `worker-luna-validation.md`: validation and evidence.
- `worker-sol-integration-review.md`: high-risk integration or independent review.
- `assignment-template.md`: task and file-claim handoff.
- `coordination-template.json`: declarative launcher configuration.
- `Start-Coordination.ps1`: validate configuration, prepare worktrees, and launch sessions.
- `Get-CoordinationStatus.ps1`: show local process and Telex attendance state.
- `Stop-Coordination.ps1`: detach configured Telex sessions and stop their exact processes.
