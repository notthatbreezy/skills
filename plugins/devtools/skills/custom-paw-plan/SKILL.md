---
name: custom-paw-plan
description: Discover repository constraints and produce a requirements-traceable plan with concrete production-path proof.
---

# Phase 2: Research and executable planning

## 1. At entry

**Review and execution:** This workflow determines required review coverage and gates; risk-based review is the fallback where no specific guidelines apply. The `delegation-orchestrator` agent runtime instructions govern direct versus delegated work, model/effort selection and execution tools. See [custom-paw-delegation](../custom-paw-delegation/SKILL.md); stop and report genuine conflicts.

Require the working agreement and permitted research sources. Resolve requirements before planning implementation; do not treat hypotheses as guarantees.

**Consult before work:** Use the named assignments below in order. Every workflow mode produces the complete planning bundle; no issue-only or Lite exception applies. Load the required skills at their assigned stage and follow their instructions.

**Required-skill availability:** If any skill required for the current phase is unavailable or cannot be loaded, stop the phase and report BLOCKED to the user. Name the missing skill, explain which work it blocks, and state what is needed to proceed. Do not skip it, reconstruct its instructions from memory, or substitute another skill or reviewer without explicit user approval. Resume only after the required skill is available or the user explicitly approves a revised requirement. Missing required external skills, named agents, or specialist personas remains BLOCKED until resolved or explicitly waived by the user.

**Exit gate:** Requirements, exclusions, concrete deliverables, dependency order, test contracts, coverage map, and documentation owners form a complete planning bundle. Then run [custom-paw-plan-gate](../custom-paw-plan-gate/SKILL.md), where the generalist performs `paw-plan-review` as one of five reviewers. Author preflight does not replace panel approval.

## 2. Required skill assignments

| When | Actor and named skill | Required purpose / output |
| --- | --- | --- |
| Before specification drafting | Planning author loads `paw-work-shaping`. | Resolve objective, scope, exclusions, constraints, and unsettled decisions. |
| During specification research and drafting | Researcher loads `paw-spec-research`; specification author loads `paw-spec`. | Establish existing behavior and write explicit requirements and acceptance criteria in Spec.md. |
| After the specification is drafted, before implementation planning | Reviewer loads `paw-spec-review`. | Review requirements for clarity, consistency, and testability; close material gaps before proceeding. |
| Before implementation planning | Researcher loads `paw-code-research`. | Produce CodeResearch.md with production entry points, consumers, repository conventions, runners, and prerequisites. |
| While designing the plan | Planning author loads `paw-planning` and `type-driven-development`. | Define bounded phases and test contracts; make domain invariants, parsing boundaries, legal states, errors, and compatibility explicit. Use proportionate type design, not speculative wrappers. |
| While assigning documentation work | Planning author loads `paw-docs-guidance`. | Name enduring documentation, Docs.md ownership, and the phase that completes each obligation. |
| After authoring the complete bundle, before implementation | Coordinator runs [custom-paw-plan-gate](../custom-paw-plan-gate/SKILL.md) using `paw-planning-docs-review` and `paw-sot`. | Obtain five independent reviews: general rubber duck using `paw-plan-review`, clear writing, test plan, type safety, and a risk-selected specialist. Preserve all five current-input PASS reports and source-verified synthesis, then obtain explicit human approval. |

## 3. Discover repository constraints before planning implementation

Inspect repository instructions, PR templates, design indexes and decision conventions, relevant compatibility/schema guidance, and a nearby completed workstream. Discover the documentation system, actual test/build/lint runners, working directories, private-feed or service prerequisites, and any full pre-push validation requirement.

Record documentation ownership during research. Identify whether Docs.md is mandatory, where enduring design documentation belongs, how amendments and indexes work, and whether documentation has a build. Do not discover these conventions for the first time when a PR advisory fails.

Trace the real production path from entry point to the changed behavior and its consumers. Distinguish production wiring from compatibility shims and test-only paths. Identify existing ownership, normalization, admission, error, and persistence helpers before proposing new ones.

Honor the selected source-isolation policy. A fetched prerequisite worktree, a fresh authenticated clone, and a local checkout are not interchangeable. Verify actual repository identity and revision; preserve protected checkout state and unrelated edits. Do not consult excluded branches or derived notes through a worker as a workaround.

Separate source facts from hypotheses. If source cannot establish a required historical or runtime guarantee, state the gap and its consequences. Do not inflate logical deduplication into exactly-once execution, or a successful nominal path into crash recovery.

## 4. Produce an executable plan

Map each authoritative requirement to a phase, concrete deliverable, and acceptance evidence. Also map plan work back to requirements so speculative scope is visible. Include intentional exclusions and supported compatibility behavior.

Each phase needs:

| Contract | Required content |
| --- | --- |
| Inputs | Exact baseline, prerequisite artifacts/interfaces, settled decisions, relevant source locations. |
| Ownership | Bounded output and write claims, integration owner, cross-worker interface handoffs. |
| Changes | Concrete production behavior and every directly affected surface or consumer. |
| Proof | Existing commands, execution directory, prerequisites, fixtures, positive and negative controls, independent expected results. |
| Exit | Measurable success conditions; evidence that would falsify success; unresolved dependencies that prevent advancement. |
| Risk | Security/error behavior, compatibility and migration effects, rollback/recovery where applicable. |
| Documentation | Named owner and affected documents/indexes, including final Docs.md when required. |
| Human boundary | Exact stop, its reason, and the next action requiring a decision or grant. |

Replace open-ended tasks such as "investigate integration" with a bounded question and an output that closes it. Research may be a phase, but its exit must say what decision or evidence it produces.

File estimates are planning aids unless the current user explicitly makes them limits. Extra files alone are not a reason to stop or weaken requirements. Stop for a concrete contradiction, untenable requirement, material scope or interface change, or an explicit user boundary.

### 4.1. Test contracts describe proof, not decorations

For each significant behavior, specify concrete inputs, the production system under test, independent expected outputs or absences, explicit fakes, a positive control, a negative control, execution ownership, and an exit criterion. Describe retained-consumer behavior and old supported schemas where the change requires them.

Reject count-only coverage, empty or skipped suites, TODO assertions, import failures presented as meaningful red tests, mocked services presented as production integration, and expected values generated by the implementation under test. Missing prerequisites must surface as unavailable evidence, not success-shaped fallbacks.

Preserve what a test proves rather than freezing its filename. Equivalent reorganization is acceptable with updated mappings; weakening the production boundary, independent oracle, controls, security property, or numeric threshold is not.

Keep four claims separate: design fit, planning adequacy, executed conformance, and measured/live acceptance. A test recipe or planned command establishes none of the latter two.

## 5. Handoff

Return the current input hashes, outputs and evidence, unresolved findings, authority boundary, and next permitted action to [custom-paw-workflow](../custom-paw-workflow/SKILL.md). Routing is not permission to advance.
