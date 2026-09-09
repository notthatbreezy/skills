---
name: custom-paw-workflow
description: Route substantial PAW work through authorized phases, loading detailed phase skills only when needed.
---

# Custom PAW workflow

Custom extension to the paw-workflow and paw-lite skills. Use this skill as the primary workflow guide overlaid on top of the base paw skills. Where this skill conflicts with the base skills, follow the instructions in this skill.

## Start or resume

Use paw-status for resumption and recovery.

Use custom-paw-setup for initial workflow setup.

## Phases

Load the corresponding skill for the current phase before doing that phase's work. If any skill required for the current phase is unavailable or cannot be loaded, stop the phase and report BLOCKED to the user along with diagnostic information.

## Workflow phases

| Phase | Purpose | Consult at entry | Exit / next boundary |
| --- | --- | --- | --- |
| 1. Setup | Establish authority, workflow mode, artifact lifecycle and review policy. | [custom-paw-setup](../custom-paw-setup/SKILL.md) | Current agreement and baseline recorded. |
| 2. Research and plan | Shape requirements, trace production behavior, and define bounded phases with falsifiable proof. | [custom-paw-plan](../custom-paw-plan/SKILL.md) | Complete declared planning bundle ready for review. |
| 3. Planning review | Run a six-reviewer SoT panel over the complete planning bundle. | [custom-paw-plan-gate](../custom-paw-plan-gate/SKILL.md) | Six current-input PASS reports and source-verified synthesis, then mandatory human approval; implementation needs a phase grant. |
| 4. Implement a phase | Execute and integrate one authorized phase, including its evidence and review. | [custom-paw-implement-phase](../custom-paw-implement-phase/SKILL.md) | Advance only after the phase gate and within the current grant; repeat for the next phase. |
| 5. Documentation and final review | Complete enduring documentation and run full SoT review of the exact integrated diff, including test and type specialists. | [custom-paw-finalize](../custom-paw-finalize/SKILL.md) | Current final-review closure and truthful evidence ready for PR preflight. |
| 6. PR delivery | Prepare the PR, reconcile remote state, and perform only authorized writes. | [custom-paw-deliver](../custom-paw-deliver/SKILL.md) | Stop at the requested endpoint; monitor or merge only if separately authorized. |

## Rules that apply throughout

Specific workflow review requirements govern roles, coverage, independence and approval gates; risk-based review is the fallback when no specific guidelines apply.

Every mode, including Lite, requires the complete planning bundle and the six distinct reviewers assigned in [custom-paw-plan-gate](../custom-paw-plan-gate/SKILL.md); you are not a seventh reviewer. Final review requires full SoT with dedicated type and test specialists. Implementation requires current planning closure, explicit human approval and a phase-specific grant.

At each exit, persist phase status, current hashes, evidence, dispositions, grants and the next authorized action. Update PAW artifacts throughout the workflow.

Stop at failed gates, unresolved authority or agreed human checkpoints; otherwise continue inside the existing grant without repeated permission requests.

## Additional companions

| Trigger | Consult | Scope |
| --- | --- | --- |
| Commissioning review or adjudicating findings | [custom-paw-review-policy](../custom-paw-review-policy/SKILL.md) | Independence, severity versus disposition, remediation policy and closure. |
| Recovering after interruption | `paw-status` | Recover durable workflow state, action grants, and the next permitted action before writing. |
