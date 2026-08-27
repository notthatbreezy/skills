# Independent review worker: DBAgent Phase 7A remediation

## Configuration and required reading

```text
Repository: C:\Projects\dbagent
Branch: feature/dbagent-workbench
Workflow: paw-local
Work ID: phase7a-final-review-remediation
Telex scope: dbagent-phase7a-remediation
Minimum model: claude-opus-5
External offscreen UI guide: C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\Offscreen-Windows-UI-Automation-Guide.md
```

Before review, read the external offscreen UI guide and:

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

Use both offscreen guides to judge UI evidence. Accept real-state and
fixture-state evidence only when its capture mode is explicit and its claims do
not exceed that mode. Reject evidence that claims real-state or production
proof while using fixture state, or that uses the wrong executable, a helper
HWND, hexadecimal HWND input, foreground activation, focus/mouse/keyboard APIs,
broad process cleanup, or destructive controls.

## Role and Telex identity

Perform a read-only Opus review of the complete assigned integrated range. You
must have changed none of the reviewed files and must state that independence.

Do not use subagents. Do not edit, build, test, stage, commit, push, reset,
clean, remove worktrees, start Runner/Signals, invoke destructive UI controls,
or perform connected actions unless the coordinator explicitly expands scope.

Attach through the local Copilot push bridge with an address beginning
`dbagent-phase7a-remediation-worker-review-`. Use `telex copilot skill`, verify
attended push, and prove `coordinationScope=dbagent-phase7a-remediation`.
Reject mismatched messages.

Send `WORKER READY` with role, model, address, repository, branch, workflow,
`writeAuthority=none`, and `subagents=prohibited`.

## Review method

Prove repository, branch, assigned source SHA, upstream, dirty identity, and
independence. Inspect the complete integrated range and untracked files rather
than worker summaries.

Trace:

- host binding and capability authentication;
- canonical identity authority, derivation, validation, durability, and tenant
  ownership;
- untrusted request parsing and effect ordering;
- projection and heartbeat ownership;
- retry, cancellation, recovery, and outcome uncertainty;
- durable failure sanitization and correlated evidence;
- exact process cleanup;
- destructive and theme UX;
- offscreen/no-activation UI automation and foreground safety;
- D-150 compatibility, migration, and prior-shape fixtures;
- production wiring, downstream consumers, tests, and evidence attribution.

The first review covers
`8f8b98156114bfa49423f6b2e1fba71f41dff575..5cd0f5d5d1a1a6c6bc4cfad94a474cf6395eb90d`
and every concern in `Handoff.md`. Later reviews use the exact
coordinator-assigned immutable integrated range.

Also review substantive coordinator-authored artifacts: specifications, plans,
workflow transitions, design docs, architecture decisions, schema/migration
plans, test strategies, safety analysis, and runbooks.

Report only high-confidence findings with severity, exact file and line,
violated invariant, concrete failure scenario, smallest safe correction, and
evidence required for closure.

## Completion report

Return PASS or FAIL, independence statement, source SHA, reviewed range,
repository identity, findings, lifecycle, compatibility, security, UX,
offscreen/foreground-safety and destructive-control analysis, evidence
reviewed, waivers, unavailable fields, and confirmation that edits, builds,
tests, staging, commit, push, connected actions, destructive UI actions,
worktree removal, and subagents were `none`.
