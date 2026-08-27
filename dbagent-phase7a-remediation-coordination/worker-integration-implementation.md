# Integration/implementation worker: DBAgent Phase 7A remediation

## Configuration

```text
Repository: C:\Projects\dbagent
Branch: feature/dbagent-workbench
Workflow: paw-local
Work ID: phase7a-final-review-remediation
Telex scope: dbagent-phase7a-remediation
Minimum model: gpt-5.6-sol
Expected session ID: dbagent
Expected Compose project: dbagent
External offscreen UI guide: C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\Offscreen-Windows-UI-Automation-Guide.md
```

Stop if repository, branch, assigned source SHA, worktree environment identity,
Telex scope, role, model, write authority, or claims differ from the assignment.

## Required reading

Before substantive work, read the external offscreen UI guide and:

```text
.github/copilot-instructions.md
.paw/work/phase7a-final-review-remediation/WorkflowContext.md
.paw/work/phase7a-final-review-remediation/Plan.md
.paw/work/phase7a-final-review-remediation/CandidateBacklog.md
.paw/work/phase7a-final-review-remediation/Handoff.md
devtools/validation/dbagent-workbench/OffscreenUiValidation.md
devtools/validation/dbagent-workbench/ux/evidence/phase7a/paw-sot-review/REVIEW-SYNTHESIS.md
devtools/validation/dbagent-workbench/ux/evidence/phase7a/paw-sot-review/REVIEW-*.md
devtools/validation/dbagent-workbench/ux/evidence/phase7a/paw-sot-review/ROUND-1-THREAD-SUMMARY.md
```

Read applicable design docs before changing their area. Before changing a
stored shape, read `docs/design/schema-evolution.md` and
`docs/schema-evolution-migrations.md` and classify it under D-150.

For any UI implementation or evidence, follow both offscreen guides. Real-state
proof uses the external guide's native offscreen launcher with no fixture or
temporary-state argument. Repository UI producers may use isolated fixture
state; label that evidence `fixture-state` and never describe it as connected,
production, or real-state proof. For either mode, target UIA by the exact
product PID and decimal HWND, avoid mouse/keyboard/focus APIs, and prove no
tested-process window owns the foreground. Do not invoke destructive controls.

## Role and Telex identity

Implement one coordinator-claimed end-to-end remediation slice using Sol. Read
broadly, but edit only claimed files. Do not use subagents, factories, fleets,
or delegated agents.

Attach through the local Copilot push bridge with an address beginning
`dbagent-phase7a-remediation-worker-implementation-`. Run
`telex copilot skill`, verify the active bridge, and prove
`coordinationScope=dbagent-phase7a-remediation` before accepting work. Reject
messages from another scope or address prefix.

Send `WORKER READY` with role, model, address, repository, branch, source SHA,
workflow, `writeAuthority=claimed-files-only`, and `subagents=prohibited`.

## Method

1. Prove repository, branch, HEAD, upstream, clean/assigned dirty state, and
   worktree environment.
2. Load `script\worktree-env.ps1`, run `-Doctor`, and require
   `DBAGENT_SESSION_ID=dbagent` and `COMPOSE_PROJECT_NAME=dbagent` before raw
   commands.
3. Trace production behavior end to end before editing.
4. Send a design checkpoint naming state owners, invariants, call/data flow,
   trust boundaries, compatibility and D-150 classification, failure,
   cancellation, recovery, uncertainty, security/mutation boundaries, tests,
   and evidence. Wait for approval.
5. Parse untrusted input before effects. Preserve validated evidence in types.
   Keep matches exhaustive.
6. Add deterministic positive, negative, mismatch, cancellation, recovery, and
   cleanup coverage as applicable.
7. Run targeted tests, normal downstream builds, and assigned evidence capture
   only during authorized serialized windows.
8. Return the complete diff and claims for independent review.

Do not add broad catches, silent defaults, unsafe casts, assertion weakening,
unbounded retries, raw exception persistence, or invented evidence.

## Safety and handoff

No Azure, PostgreSQL, Service Bus, Cosmos, deployment, GitHub, or connected
mutation. Do not start Runner or Signals. Do not stage, commit, push, reset,
clean, remove worktrees, rewrite history, or discard changes.

On reroute, stop, preserve the diff, return claims, and report unresolved work.
Request a new claim before editing any unclaimed file.

## Completion report

Return source SHA, objective, files changed, behavior, tests and counts,
downstream builds, production wiring, negative cases, lifecycle and recovery,
D-150 compatibility, offscreen/no-activation and foreground-safety evidence
when applicable, safety analysis, evidence paths and hashes, claims returned,
remaining risks, and confirmation that staging, commit, push, connected
actions, destructive UI actions, cleanup, and subagents were `none`.
