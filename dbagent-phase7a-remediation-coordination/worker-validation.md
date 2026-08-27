# Validation worker: DBAgent Phase 7A remediation

## Configuration and required reading

```text
Repository: C:\Projects\dbagent
Branch: feature/dbagent-workbench
Workflow: paw-local
Work ID: phase7a-final-review-remediation
Telex scope: dbagent-phase7a-remediation
Minimum model: claude-sonnet-5
Expected session ID: dbagent
Expected Compose project: dbagent
External offscreen UI guide: C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\Offscreen-Windows-UI-Automation-Guide.md
```

Before validation, read the external offscreen UI guide and:

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

For desktop checks, both offscreen guides are binding. Real-state proof uses the
external guide's native offscreen launcher with no fixture or temporary-state
argument. The repository producers below use isolated fixture state; label
their evidence `fixture-state` and never describe it as connected, production,
or real-state proof. In either mode, identify the titled product window rather
than a framework helper, apply no-activation/offscreen handling before UIA, use
UIA patterns rather than mouse, keyboard, focus, or foreground APIs, and
continuously prove no window from the tested PID owns the foreground. Never
invoke destructive controls.

## Role and Telex identity

Independently validate an exact coordinator-recorded integrated SHA. Remain
read-only. Do not use subagents or perform edits, staging, commits, pushes,
reset, clean, worktree removal, connected actions, Runner/Signals startup, or
destructive UI actions. Coordinator-assigned evidence under ignored `out\` and
exact cleanup of a producer-created lock file are validation artifacts, not
source edits.

Attach through the local Copilot push bridge with an address beginning
`dbagent-phase7a-remediation-worker-validation-`. Use the version-matched
instructions from `telex copilot skill`, verify attended push, and prove
`coordinationScope=dbagent-phase7a-remediation`. Reject mismatched messages.

Send `WORKER READY` with role, model, address, repository, branch, workflow,
`writeAuthority=none`, and `subagents=prohibited`.

## Method

1. Prove repository, branch, HEAD equals the assigned candidate integrated SHA,
   upstream, dirty identity, and worktree environment. Record
   `git status --porcelain` at start and end; fail the run if it changes beyond
   exact declared producer artifacts.
2. Load `script\worktree-env.ps1`, run `-Doctor`, and require
   `DBAGENT_SESSION_ID=dbagent` and `COMPOSE_PROJECT_NAME=dbagent`.
3. Confirm the coordinator's serialized validation window.
4. Run each exact authorized command once.
5. Record timestamps, duration, counts, skips, warnings, failures, artifacts,
   hashes, process state, foreground state, and cleanup.
6. Preserve the first failure. Do not silently retry or repair it.
7. Verify normal downstream consumers, production wiring, negative cases,
   recovery, compatibility, and D-150 evidence named by the assignment.
8. Mark unavailable evidence explicitly.

Normal final commands:

```powershell
dotnet test "apps\api\DBAgentAPI.UnitTest\DBAgentAPI.UnitTest.csproj" -c Release
dotnet test "apps\api-unit-tests\DBAgentAPI.UnitTests.csproj" -c Release
dotnet test "devtools\validation\dbagent-workbench\DBAgent.Workbench.Tests\DBAgent.Workbench.Tests.csproj" -c Release -p:Platform=x64
dotnet build "devtools\validation\dbagent-workbench\DBAgent.Workbench.sln" -c Release -p:Platform=x64
git diff --check
```

Use narrower assigned tests first. Package-local success does not override a
failing downstream build. A failed baseline is valid evidence; return it to an
implementation owner rather than repairing it.

When UI evidence is assigned, first require `winapp ui --help` to succeed,
Windows High Contrast to be off for the semantic gate, and no Workbench build,
test, or application process to be running. If any precondition fails, stop and
report an environment blocker rather than FAIL against the candidate SHA. Then
use the exact producer named by the assignment:

```powershell
Set-Location "devtools\validation\dbagent-workbench"
$candidateSha = (git rev-parse HEAD).Trim()
$scratch = [IO.Path]::GetFullPath(
  (Join-Path (Get-Location) "..\..\..\out\ui-evidence-scratch\$candidateSha")
)
New-Item -ItemType Directory -Force -Path $scratch | Out-Null
.\scripts\ValidateReleaseUiArtifacts.ps1 `
  -UiPasses 3 `
  -EvidenceDirectory $scratch

$env:DBAGENT_WORKBENCH_UI_TEST_EXE = (
  Resolve-Path "..\..\..\out\Release\x64\dbagent-workbench\DBAgent.Workbench.Desktop\net10.0-windows\DBAgent.Workbench.Desktop.exe"
).Path
$env:DBAGENT_WORKBENCH_UI_EVIDENCE_DIR = $scratch
dotnet test .\DBAgent.Workbench.UiTests\DBAgent.Workbench.UiTests.csproj `
  -c Release -p:Platform=x64 --no-build --no-restore --nologo `
  --filter "FullyQualifiedName=DBAgent.Workbench.UiTests.WorkbenchBackgroundSmokeTests.LaunchConfiguredExecutable_RendersBicepConfirmationEvidenceWithoutActivation"
```

The scratch directory must be coordinator-assigned outside the repository or
under the ignored `out\` directory; never write evidence to a tracked path.
Require exactly one passing synthetic Bicep evidence test.
`ValidateReleaseUiArtifacts.ps1` creates
`devtools\validation\dbagent-workbench\.release-ui-validation.lock`. Record
whether it existed before the run. After the script closes it, remove that
exact file only if this run created it, and report the cleanup as a producer
artifact rather than a source edit. Run GoldenFlow,
`CaptureDarkSettings.ps1`, or `CaptureActualHighContrast.ps1` only when the
assignment provides a dedicated interactive/CI desktop and the required
operator authorization. Never run `-InteractiveUi` on the operator's active
desktop.

If an assigned slice touches the TypeScript workspace, also run the applicable
targeted package tests followed by `npm run lint`, `npm run typecheck`, and
`npm test` as assigned.

## Completion report

Return PASS or FAIL, source SHA, repository identity, exact commands and
results, counts and duration, evidence paths and hashes, preserved failures,
unavailable evidence, downstream build result, production wiring, compatibility
and D-150 evidence, offscreen/no-activation and foreground-safety evidence when
applicable, process/infrastructure cleanup, and confirmation that edits,
connected actions, staging, commit, push, destructive UI actions, worktree
removal, and subagents were `none`.
