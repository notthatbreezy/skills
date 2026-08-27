# DBAgent Phase 7A remediation coordination pack

This Telex prompt pack continues the Phase 7A final-review remediation on the
existing `feature/dbagent-workbench` integration branch.

## Bound execution configuration

```text
Repository: C:\Projects\dbagent
Repository slug: azure-data-database-platform/dbagent
Target branch: feature/dbagent-workbench
Base branch: main
Workflow: paw-local
Work ID: phase7a-final-review-remediation
Original checkpoint: 8f8b98156114bfa49423f6b2e1fba71f41dff575
Phase 1 WIP commit: 4d1cee9c8b8811914e1d2631a87baf6eda1944ba
Branch-resident handoff commit: 5cd0f5d5d1a1a6c6bc4cfad94a474cf6395eb90d
Prompt pack: C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\dbagent-phase7a-remediation-coordination
External offscreen UI guide: C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\Offscreen-Windows-UI-Automation-Guide.md
```

All implementation, validation, and review work occurs in
`C:\Projects\dbagent`. Stop if it is not a checkout of
`feature/dbagent-workbench` tracking `origin/feature/dbagent-workbench`, if HEAD
is not the coordinator-assigned source SHA, or if dirty paths exist outside
recorded operator-owned and claimed work.

The external offscreen UI guide is required reading for the coordinator and
every implementation, validation, and review worker. For UI work, use it
together with the branch-resident
`devtools\validation\dbagent-workbench\OffscreenUiValidation.md`. The external
guide defines the Windows offscreen/no-activation automation procedure; the
branch-resident guide defines repository-specific validation expectations.
All four sessions run locally on the operator's machine. `Handoff.md` and
`Plan.md` prohibit remote workers from depending on OneDrive; they do not
prohibit these explicitly local launcher sessions from reading the external
guide.

## Launch

```powershell
& 'C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\generic-coordination\Start-Coordination.ps1' `
  'C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\dbagent-phase7a-remediation-coordination\coordination.json'
```

Use `Get-CoordinationStatus.ps1`, `Stop-Coordination.ps1`, and
`Start-TelexConsole.ps1` from the same generic coordination directory with this
manifest path. Validate without launching by adding `-ValidateOnly`; render all
session bootstraps by adding `-RenderOnly`.

Before raw build, test, package-manager, Docker, or integration commands:

```powershell
Set-Location 'C:\Projects\dbagent'
Invoke-Expression ((& '.\script\worktree-env.ps1') -join [Environment]::NewLine)
& '.\script\worktree-env.ps1' -Doctor
```

## Required authority

Every role reads these files before substantive work:

```text
C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\Offscreen-Windows-UI-Automation-Guide.md
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

Read applicable design documentation before changing its area. Before changing
a stored shape, read `docs/design/schema-evolution.md` and
`docs/schema-evolution-migrations.md` and classify the change under D-150.

## First gate and continuation

Phase 1 is implemented but not accepted. First perform an independent Opus
review of
`8f8b98156114bfa49423f6b2e1fba71f41dff575..5cd0f5d5d1a1a6c6bc4cfad94a474cf6395eb90d`,
including every concern in `Handoff.md`. Route accepted corrections and the
recorded legacy `ServerReadModelCompatibilityTests` failure to the Sol
implementation owner. Then run independent validation and another independent
review before marking Phase 1 complete.

Continue `Plan.md` in dependency order. Keep Should-Fix and Consider items in
`CandidateBacklog.md` unless a Must-Fix root cause requires a narrow
compatibility hook. Run an independent Opus mini-review after each phase and
the configured all-specialist Society-of-Thought review at the final gate.

## Roles and safety

| Role | Authority | Purpose |
| --- | --- | --- |
| Coordinator | Candidate integration commits and workflow records only | Records immutable candidate checkpoints; acceptance still requires independent validation and review |
| Integration/implementation | Claimed files only | Implements one accepted remediation slice |
| Validation | Read-only | Runs approved checks and captures reproducible evidence |
| Independent review | Read-only and independent | Reviews the complete integrated range |

No connected mutation; no Azure, PostgreSQL, Service Bus, Cosmos, deployment,
GitHub mutation, Runner, or Signals. Do not invoke destructive UI controls.
Workers do not stage, commit, push, reset, clean, remove worktrees, rewrite
history, or use subagents. The coordinator must obtain explicit operator
authorization before push, PR creation, cleanup, branch deletion, or any
connected action.

## Files

- `coordinator.md`
- `worker-integration-implementation.md`
- `worker-validation.md`
- `worker-independent-review.md`
- `assignment-template.md`
- `coordination.json`
