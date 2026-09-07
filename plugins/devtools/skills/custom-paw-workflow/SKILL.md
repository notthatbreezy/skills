---
name: custom-paw-workflow
description: Route substantial PAW work through authorized phases, loading detailed phase skills only when needed.
---

# Custom PAW workflow

This root maps the workflow; phase skills hold procedures and checklists. Run only authorized stages. Planning-only work ends at its handoff.

## Start or resume

Recover the working agreement, current phase, exact source/artifact revisions, completed writes, and action grants. If recovery is uncertain, consult [custom-paw-recovery](../custom-paw-recovery/SKILL.md) before acting. Do not bootstrap a duplicate workflow.

Load the detailed skill for the current phase **before doing that phase's work**. Load conditional companions only when their trigger applies; do not preload the entire package. These are installable skill names in this package.

**Required-skill availability:** If any skill required for the current phase is unavailable or cannot be loaded, stop the phase and report BLOCKED to the user. Name the missing skill, explain which work it blocks, and state what is needed to proceed. Do not skip it, reconstruct its instructions from memory, or substitute another skill or reviewer without explicit user approval. Resume only after the required skill is available or the user explicitly approves a revised requirement. Missing required external skills, named agents, or specialist personas remains BLOCKED until resolved or explicitly waived by the user.

## Workflow phases

| Phase | Purpose | Consult at entry | Exit / next boundary |
| --- | --- | --- | --- |
| 1. Setup | Establish authority, workflow mode, artifact lifecycle and review policy. | [custom-paw-setup](../custom-paw-setup/SKILL.md) | Current agreement and baseline recorded. |
| 2. Research and plan | Shape requirements, trace production behavior, and define bounded phases with falsifiable proof. | [custom-paw-plan](../custom-paw-plan/SKILL.md) | Complete declared planning bundle ready for review. |
| 3. Planning review | Run a five-reviewer SoT panel over the complete planning bundle. | [custom-paw-plan-gate](../custom-paw-plan-gate/SKILL.md) | Five current-input PASS reports and source-verified synthesis, then mandatory human approval; implementation needs a phase grant. |
| 4. Implement a phase | Execute and integrate one authorized phase, including its evidence and review. | [custom-paw-implement-phase](../custom-paw-implement-phase/SKILL.md) | Advance only after the phase gate and within the current grant; repeat for the next phase. |
| 5. Documentation and final review | Complete enduring documentation and run full SoT review of the exact integrated diff, including test and type specialists. | [custom-paw-finalize](../custom-paw-finalize/SKILL.md) | Current final-review closure and truthful evidence ready for PR preflight. |
| 6. PR delivery | Prepare the PR, reconcile remote state, and perform only authorized writes. | [custom-paw-deliver](../custom-paw-deliver/SKILL.md) | Stop at the requested endpoint; monitor or merge only if separately authorized. |

## Rules that apply throughout

Follow the actual instruction hierarchy. Specific workflow review requirements govern roles, coverage, independence and approval gates; risk-based review is the fallback when no specific guidelines apply. The `delegation-orchestrator` agent's runtime instructions govern direct versus delegated work, models/effort, spawning tools, ownership, handoffs and cleanup. These rules are complementary. Stop and report genuine conflicts rather than dropping required coverage or bypassing runtime rules.

Within those boundaries, this workflow's explicit gates override stock PAW defaults. Following a loaded skill does not authorize weaker review, automatic advancement, or additional writes. Keep review verdict, human acceptance and action authorization separate.

Every mode, including Lite, requires the complete planning bundle and the five distinct reviewers assigned in [custom-paw-plan-gate](../custom-paw-plan-gate/SKILL.md); the coordinator is not a sixth reviewer. Final review requires full SoT with dedicated type and test specialists. Implementation requires current planning closure, explicit human approval and a phase-specific grant.

The coordinator owns integration and acceptance. Bind evidence to exact inputs, verify findings, preserve dissent, and never label missing evidence PASS. Read the review policy before review or remediation.

Treat artifact hygiene as a cross-phase invariant. Derive the applicable authoritative outputs and locations from the active phase, repository instructions, and recorded working agreement; do not create optional or inapplicable files to satisfy a generic filename list or count. Keep stable names for current outputs and facts for compact workflow state. Give every scratch path a bounded purpose, owner, and cleanup point. Retain historical snapshots only when an exact-input record is justified, and label their source identity and status.

Consolidate evidence when that reduces duplication, but never discard a required report, dissent, approval, disposition, or lineage. Preserve hashes and artifact links across handoffs. A verdict applies only to the exact bytes reviewed and never transfers to a replacement, consolidated, or regenerated file. Pinned artifacts aid session recovery; they are not permanent repository backup. After an accepted durable handoff, remove only temporary files owned by this workflow and scheduled for cleanup. Never remove unrelated files, another worker's scratch, or a session/workspace root.

At each exit, persist phase status, current hashes, evidence, dispositions, grants and the next authorized action. Route backward when a material change invalidates earlier obligations. Stop at failed gates, unresolved authority or agreed human checkpoints; otherwise continue inside the existing grant without repeated permission requests.

## Conditional companions

| Trigger | Consult | Scope |
| --- | --- | --- |
| Commissioning review or adjudicating findings | [custom-paw-review-policy](../custom-paw-review-policy/SKILL.md) | Independence, severity versus disposition, remediation policy and closure. |
| Delegating any research, review or implementation | [custom-paw-delegation](../custom-paw-delegation/SKILL.md) | Bounded packets, write ownership, artifacts, reviewer seats and child lifecycle. |
| Presenting documents, changing pointers, or recovering after interruption | [custom-paw-recovery](../custom-paw-recovery/SKILL.md) | Source-faithful presentation, durable state and duplicate-write prevention. |
