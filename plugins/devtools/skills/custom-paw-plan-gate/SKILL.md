---
name: custom-paw-plan-gate
description: Review exact planning inputs independently and close grounded findings without conflating PASS with authority.
---

# Phase 3: Mandatory planning review

## 1. At entry

**Review and execution:** This workflow determines required review coverage and gates; risk-based review is the fallback where no specific guidelines apply. The `delegation-orchestrator` agent runtime instructions govern direct versus delegated work, model/effort selection and execution tools. See [custom-paw-delegation](../custom-paw-delegation/SKILL.md); stop and report genuine conflicts.

Freeze the declared complete bundle. Consult [custom-paw-review-policy](../custom-paw-review-policy/SKILL.md) before review and [custom-paw-delegation](../custom-paw-delegation/SKILL.md) before staffing reviewers.

**Consult before work:** The coordinator loads `paw-planning-docs-review` in society-of-thought mode and `paw-sot` to run the five-reviewer planning panel below. Cross-document review means checking the specification, research, plan, test contracts, coverage map, and WorkflowContext together. It is the panel's job, not an additional review by the coordinating agent.

**Required-skill availability:** If any skill required for the current phase is unavailable or cannot be loaded, stop the phase and report BLOCKED to the user. Name the missing skill, explain which work it blocks, and state what is needed to proceed. Do not skip it, reconstruct its instructions from memory, or substitute another skill or reviewer without explicit user approval. Resume only after the required skill is available or the user explicitly approves a revised requirement. Missing required external skills, named agents, or specialist personas remains BLOCKED until resolved or explicitly waived by the user.

**Exit gate:** All five reviewers return current-input PASS reports, and the coordinator records a source-verified panel synthesis against every gate below. The synthesis is not a sixth reviewer or an independent approval. Then stop for explicit human approval of that bundle. Implementation additionally requires a grant for the specified phase; no earlier blanket grant bypasses this planning approval.

For the planning handoff or canvas, consult [custom-paw-recovery](../custom-paw-recovery/SKILL.md).

## 2. Run the mandatory planning gate

Freeze the input bundle and source revision. Record artifact owner, filename, hash, review scope, and missing evidence. A verdict belongs to those inputs, not to whichever document currently has the same filename.

Require the complete specification, research, implementation plan, test contracts, coverage map, and WorkflowContext. The generalist seat performs `paw-plan-review` within this panel, rather than requiring an extra reviewer before it. Missing required inputs block this gate in Full, Lite, and custom modes alike.

### 2.1. Fixed review assignments: five reviewers total

| Seat | Reviewer / exact dependency | Responsibility and required result |
| --- | --- | --- |
| 1. General rubber duck | Independent generalist loading `paw-plan-review`. | Challenge assumptions, requirement-to-plan traceability, cross-document consistency, feasibility, phase dependencies, and omissions. Review the whole bundle rather than only summarizing specialist findings. |
| 2. Clear writing | Separate reviewer loading `clear-workplace-writing`. | Review structure, terminology, explicit actors, unambiguous requirements, and executable instructions. Preserve technical meaning and uncertainty; distinguish material ambiguity from optional style suggestions. |
| 3. Test plan | Dedicated `test-plan-reviewer` agent, package/agent v1.0.0. | Review requirement coverage, concrete fixtures, independent oracles, real production boundaries, permitted fakes, meaningful failure controls, runner prerequisites, and phase exits. Planning-only: do not execute tests or implement. |
| 4. Type safety | Separate reviewer loading `delegation-type-safety`. | Review proposed trust boundaries, parsing, invalid representable states, identifiers, transitions, exhaustive consumers, errors, and compatibility. Absence of applicable type changes must be justified in the report, not used to skip this seat. |
| 5. Risk specialist | Independent reviewer loading a named specialist persona resolved through `paw-sot` specialist discovery. | Review architecture/integration by default; prioritize security for security-sensitive work, or another justified risk such as migrations or concurrency. Before review, record persona name, actual source identity/version or hash, rubric, and scope; missing persona instructions block the gate. |

Each seat is a distinct read-only reviewer, separate from the author and coordinator. Each receives the same frozen complete bundle and cross-document criteria, then returns its own hash-bound PASS/FAIL/BLOCKED report with findings and limitations. All five roles are mandatory in every mode. PASS requires no unresolved material gap within the seat's scope; optional editorial preferences need not block it.

Configure `paw-sot` with this explicit roster and `Planning Review Perspectives: none`. Automatic specialist or perspective expansion must not create extra seats or remove a required role; this is five reviewers total, not five specialists plus a generalist. The coordinator orchestrates, verifies surviving findings against source, preserves dissent, and synthesizes the five reports. It neither counts toward the five nor supplies a substitute PASS. `test-plan-reviewer` is a packaged agent supplying its own rubric, not a skill. If its registration/version or a required skill is unavailable, return BLOCKED and resolve the dependency before review.

`Planning Review Perspectives: none` disables perspective overlays, not specialist discovery or the explicitly selected fifth seat. Load the selected persona and its applicable shared rules; do not replace it with an invented generic brief. Use the governing `delegation-orchestrator` instructions for spawning, model selection and lifecycle, even where `paw-sot` prescribes different mechanics.

After authorized corrections, retain the five seats and have affected reviewers re-review using their original agent/skill. Every seat must publish a current-manifest closure report, identifying re-reviewed scope and any explicitly revalidated unchanged evidence. The coordinator updates the synthesis. No stale PASS transfers automatically.

After all five current-input PASS reports and synthesis closure, present the bundle through `planning-review-canvas` and ask for explicit human approval. Record the exact input hashes, non-blocking risks, and separately the implementation action grant.

Stock `paw-planning-docs-review` disabled/reduced-input/cycle-limit completion and moderator "continue" behavior do not override this gate. A generalist report, compiler success, or review `complete` status is not specialist PASS or human approval.

Initial reviewers receive requirements and source evidence without the author's preferred verdict or earlier reviewers' conclusions. After the first reports are preserved, reuse seats for bounded correction closure. Label those rounds accurately: **independent initial review**, **prompted closure**, and **coordinator synthesis of panel findings** are different evidence.

| Gate | PASS requires |
| --- | --- |
| Traceability | Requirements and plan deliverables map both ways; no lost acceptance obligations or unexplained scope. |
| Production feasibility | Research supports actual entry points, ownership, interfaces, consumers, and execution prerequisites. |
| Proof quality | Concrete falsifiable outcomes, meaningful negative controls, independent truth, and real boundary coverage. |
| Panel coverage | Five distinct current-input PASS reports: general rubber duck, clear writing, test plan, type safety, and the selected risk specialist; source-verified synthesis with no unresolved blocker. |
| Test-plan approval | Current-input PASS from the named `test-plan-reviewer` agent with no unresolved material test-design gap. |
| Type-safety approval | Current-input PASS from the separate `delegation-type-safety` reviewer with explicit invariant and proof-boundary coverage. |
| Cross-artifact consistency | Spec, plan, research, test contracts, coverage, and WorkflowContext agree with the governing requirements and latest user clarifications. |
| Safety and compatibility | Relevant trust boundaries, error paths, supported shapes, migration/recovery effects, and security obligations addressed. |
| Executability | Bounded phases, ownership, dependency order, documentation work, and known commands are sufficient to begin the authorized phase. |
| Disposition | No unresolved blocker; non-blocking risks have an explicit disposition, owner, and checkpoint where needed. |

Use PASS, FAIL, or BLOCKED with reasons. A waived acceptance obligation remains an explicit waiver or approved scope amendment; do not relabel it satisfied. Requirements cannot be weakened by a reviewer or by the coordinator to obtain a green label.

After revisions, freeze new inputs and re-review affected obligations. If a defect is systematic, inspect its affected population rather than only the examples the reviewer named. A structural/schema PASS does not establish semantic correctness.

Preserve failed reports, dissent, rejected findings, and the reasons for demotions. Neither a cycle cap nor agreement among reviewers authorizes advancement with an unresolved blocker. At the budget limit or repeated no-progress, present the blocker and a bounded next decision.

Planning PASS permits an approval handoff. Stop until the human explicitly approves the exact reviewed plan, test contracts, and type-safety obligations. Record that decision independently from the grant to implement a named phase; one explicit message may supply both. Material changes to the approved requirements, design, or proof obligations reopen affected specialist reviews and require renewed human approval. Planning approval does not prove implemented behavior or grant publication authority.

## 3. Handoff

Return the current input hashes, outputs and evidence, unresolved findings, authority boundary, and next permitted action to [custom-paw-workflow](../custom-paw-workflow/SKILL.md). Routing is not permission to advance.
