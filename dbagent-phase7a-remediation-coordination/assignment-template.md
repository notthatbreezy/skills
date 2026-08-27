# Worker assignment: DBAgent Phase 7A remediation

```text
Task ID:
Role: choose integration-implementation, validation, or independent-review
Worker address:
Minimum model:
Assigned model:
Coordination scope: dbagent-phase7a-remediation
Repository: C:\Projects\dbagent
Branch: feature/dbagent-workbench
Assigned source SHA:
Workflow: paw-local
Work ID: phase7a-final-review-remediation
Primary authority: .paw/work/phase7a-final-review-remediation/Plan.md and Handoff.md
Telex backend: local
Telex transport: local Copilot push bridge
Telex scope: dbagent-phase7a-remediation
Required address prefix: dbagent-phase7a-remediation-
Expected session ID: dbagent
Expected Compose project: dbagent
Write authority:
Existing diff / handoff state:

Required reading before work:
1. C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\Offscreen-Windows-UI-Automation-Guide.md
2. .github/copilot-instructions.md
3. .paw/work/phase7a-final-review-remediation/WorkflowContext.md
4. .paw/work/phase7a-final-review-remediation/Plan.md
5. .paw/work/phase7a-final-review-remediation/CandidateBacklog.md
6. .paw/work/phase7a-final-review-remediation/Handoff.md
7. devtools/validation/dbagent-workbench/OffscreenUiValidation.md
8. devtools/validation/dbagent-workbench/ux/evidence/phase7a/paw-sot-review/REVIEW-SYNTHESIS.md
9. devtools/validation/dbagent-workbench/ux/evidence/phase7a/paw-sot-review/REVIEW-*.md
10. devtools/validation/dbagent-workbench/ux/evidence/phase7a/paw-sot-review/ROUND-1-THREAD-SUMMARY.md

Objective:

Non-goals:

Authoritative state owner:

Exact file claims:
1.

Read-only supporting files:
1.

Required behavior:
1.

Failure, cancellation, recovery, and compatibility behavior:
1.

Acceptance criteria:
1. Exact invariants and negative cases:
2. Production source wiring:
3. Normal downstream consumer builds:
4. Stored-shape and D-150 compatibility:
5. Offscreen/no-activation UI evidence and declared capture mode (`real-state offscreen WS_EX_NOACTIVATE` or `fixture-state`), when UI behavior is in scope:
6. Independent validation:
7. Independent review:

Safety boundaries:
1. No connected or destructive mutation without explicit operator authorization.
2. Do not start Runner or Signals.
3. Do not invoke destructive UI controls.

Required validation:
1.

Serialized resources:
1.

Claim-transfer behavior:
1. Stop, preserve the working-tree diff, return claims, and report unresolved work before rerouting.

Prohibited actions:
- subagents, factories, or delegation;
- action on messages outside coordinationScope=dbagent-phase7a-remediation;
- edits outside claims or any edits in read-only roles;
- staging, commit, push, reset, clean, worktree removal, or history rewrite;
- dependency on another checkout's uncommitted files;
- connected or destructive actions;
- Runner or Signals startup;
- assertion weakening, broad catches, silent defaults, or invented evidence.

Stop and escalate when:
1. Repository, branch, source SHA, Telex scope, role, or write authority differs.
2. The assigned model is below the role's minimum capability.
3. A required authority or guide is unavailable.
4. The change crosses state owners or file claims.
5. Validation requires connected mutation, Runner, Signals, foreground UI activation, or destructive controls.
6. UI validation is assigned but `winapp ui --help` fails or the exact repository-authorized producer cannot run.
7. A validation/review window cannot keep the checkout identical to the assigned candidate SHA.

Completion report:
- exact source SHA and repository identity;
- files changed or reviewed;
- declared role, model, authority, and independence when applicable;
- tests/builds/checks with counts and duration;
- production wiring and downstream-build evidence;
- lifecycle, negative-case, recovery, compatibility, and D-150 coverage;
- offscreen/no-activation UI evidence and foreground-safety result when applicable;
- safety analysis and connected actions;
- evidence paths and hashes;
- claims returned;
- remaining risks.
```
