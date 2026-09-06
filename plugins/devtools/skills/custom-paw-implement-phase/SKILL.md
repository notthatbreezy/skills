---
name: custom-paw-implement-phase
description: Implement one authorized PAW phase, integrate its deliverables and establish meaningful closure evidence.
---

# Phase 4: Implement and close one phase

## 1. At entry

**Review and execution:** This workflow determines required review coverage and gates; risk-based review is the fallback where no specific guidelines apply. The `delegation-orchestrator` agent runtime instructions govern direct versus delegated work, model/effort selection and execution tools. See [custom-paw-delegation](../custom-paw-delegation/SKILL.md); stop and report genuine conflicts.

Require current PASS reports from all five planning reviewers (general rubber duck, clear writing, test plan, type safety, and risk specialist), with source-verified panel synthesis; explicit human approval of the same plan/test-contract/type-safety bundle; and an implementation grant for this phase. Verify hashes against the approval record and the roster in [custom-paw-plan-gate](../custom-paw-plan-gate/SKILL.md). Consult [custom-paw-delegation](../custom-paw-delegation/SKILL.md) if delegating and [custom-paw-review-policy](../custom-paw-review-policy/SKILL.md) before review or remediation.

**Consult before work:** `paw-implement`, then `paw-impl-review`; `type-driven-development` for substantial type-oriented changes. Consult `paw-docs-guidance` for phase documentation. Before starting this phase, load the required skills and follow their instructions.

**Required-skill availability:** If any skill required for the current phase is unavailable or cannot be loaded, stop the phase and report BLOCKED to the user. Name the missing skill, explain which work it blocks, and state what is needed to proceed. Do not skip it, reconstruct its instructions from memory, or substitute another skill or reviewer without explicit user approval. Resume only after the required skill is available or the user explicitly approves a revised requirement. Missing required external skills, named agents, or specialist personas remains BLOCKED until resolved or explicitly waived by the user.

**Exit gate:** Integrated deliverables, passing required evidence, usable downstream handoffs, and a current `paw-impl-review` report bound to the integrated phase revision satisfy the phase contract. Adjudicate findings under `custom-paw-review-policy`; unresolved blockers or FAIL/BLOCKED review outcomes prevent closure. Honor the phase human stop before advancing.

## 2. Implement and advance phase by phase

Begin only after the required planning reviews, exact-bundle human approval, and implementation grant. Execute one PAW phase per implementation invocation. Keep the approved requirements and proof obligations visible while allowing justified equivalent file organization. Material changes to requirements, design, or test/type proof obligations return to planning for affected specialist closure and renewed human approval before dependent implementation.

Make complete, focused changes across real producers, consumers, configuration, error paths, tests, and documentation. Reuse established helpers. Do not hide invalid input or missing prerequisites behind silent defaults, broad catches, casts, or successful early returns.

Run the smallest existing checks that establish the changed behavior, plus every command the repository or user mandates at its designated checkpoint. Install or restore dependencies only when the task requires dependency changes or a chosen command establishes that required tools are missing.

Where feasible, falsify a regression test by temporarily disabling the relevant guard in an isolated authorized checkout, confirm the intended assertion fails, then restore it. Verify injected failures reach the intended operation; an earlier consumer of the injection can make a test meaningless. Never perform fault injection against live systems without its own authorization.

After integration, run `paw-impl-review` against the exact phase revision, approved phase contract and execution evidence. Record the review owner, input revision/hash, findings, adjudication and closure report. Follow the governing agent's delegation rules; this phase review does not require full SoT unless separately specified.

A phase closes only when deliverables are integrated, required checks pass, review has current closure with no unresolved blocker, and downstream handoffs are usable. Failed or unavailable required checks and FAIL/BLOCKED review outcomes stop advancement; repair within existing authority and obtain fresh evidence/closure, or report the blocker for a user decision. Acknowledging a finding is not resolving it, and final SoT is not a substitute for phase closure. An explicit user-approved exception must revise the phase acceptance record; preserve the failed evidence and do not label it PASS. A worker's local green result is not an integration result.

At each material milestone, communicate the delta, evidence level, risk/blocker, and next authorized action. Do not turn routine progress into repeated permission requests. Stop at agreed human checkpoints, material ambiguity, authority boundaries, or failed gates. A heading called "Manual Verification" alone does not establish a human stop; the working agreement does.

When an issue suggests additional work, capture it as a phase candidate with a bounded description. Resolve promotion, deferral, or rejection explicitly; do not implement it opportunistically or leave unresolved candidates hidden at PR preflight.

## 3. Handoff

Return the current input hashes, outputs and evidence, unresolved findings, authority boundary, and next permitted action to [custom-paw-workflow](../custom-paw-workflow/SKILL.md). Routing is not permission to advance.
