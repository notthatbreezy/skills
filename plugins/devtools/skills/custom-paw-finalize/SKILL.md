---
name: custom-paw-finalize
description: Complete repository-required documentation and review the exact integrated result before PR preparation.
---

# Phase 5: Documentation and integrated final review

## 1. At entry

**Review and execution:** This workflow determines required review coverage and gates; risk-based review is the fallback where no specific guidelines apply. The `delegation-orchestrator` agent runtime instructions govern direct versus delegated work, model/effort selection and execution tools. See [custom-paw-delegation](../custom-paw-delegation/SKILL.md); stop and report genuine conflicts.

Require integrated phase outputs and current source identities. Consult [custom-paw-review-policy](../custom-paw-review-policy/SKILL.md) and, when staffing reviewers, [custom-paw-delegation](../custom-paw-delegation/SKILL.md).

**Consult before work:** `paw-docs-guidance`, repository documentation conventions, `paw-final-review`, and `paw-sot`. Set `Final Review Mode: society-of-thought` and `Final Review Specialists: all`. Full SoT, including dedicated type-safety and test specialists, is mandatory before PR preparation. Before starting this phase, load the required skills and follow their instructions.

**Required-skill availability:** If any skill required for the current phase is unavailable or cannot be loaded, stop the phase and report BLOCKED to the user. Name the missing skill, explain which work it blocks, and state what is needed to proceed. Do not skip it, reconstruct its instructions from memory, or substitute another skill or reviewer without explicit user approval. Resume only after the required skill is available or the user explicitly approves a revised requirement. Missing required external skills, named agents, or specialist personas remains BLOCKED until resolved or explicitly waived by the user.

**Exit gate:** Required documentation is complete; full SoT review of the exact integrated diff has current reports from the complete roster, including type and test specialists, and source-verified synthesis with no unresolved blocker. Distinguish executed evidence from limitations.

## 2. Complete documentation and integrated final review

Documentation is implementation work with an owner and acceptance criteria. Follow the discovered system rather than inventing a universal document name or build command.

Docs.md explains the resulting behavior for future maintainers; the PR body explains why the change should be accepted. Design decisions follow the repository's amendment and indexing rules. Keep declarative design prose distinct from change history and review argument. State actions and known limits precisely instead of claiming global guarantees the evidence cannot support.

Before PR preparation, run `paw-final-review` with `paw-sot` over the exact integrated base/head diff, authoritative requirements, planned deliverables, phase evidence, and documentation. Resolve and record the full specialist roster from `all`; ensure correctness/integration, security, maintainability, and documentation/evidence integrity are covered. Empty scaffolding does not satisfy a promised deliverable.

Explicitly include a separate type-safety reviewer loading `delegation-type-safety` to examine implemented invariants and trust boundaries, and a test specialist to examine actual tests, independent oracles, production-path coverage, negative controls, and execution evidence. If the stock roster lacks either dedicated role, add it; do not treat incidental coverage by another specialist as sufficient. The planning-only `test-plan-reviewer` report does not replace this implementation test review.

The five-reviewer limit applies only to planning. Do not reduce final review to five seats, single-model self-review, or an adaptive subset. Missing required reviewers or skills block this gate. The coordinator preserves the independent reports, verifies findings, and synthesizes the result; synthesis alone is not full SoT review.

Apply the configured moderation policy, source-verify findings, repair within authority, rerun affected proof, and obtain exact-revision closure. Retain useful independent reviewers through the cycle. Re-review after material changes; an earlier PASS does not automatically carry to a new diff.

Final review must state actual executed evidence and its environment separately from planned commands, external acceptance obligations, and accepted limitations. A clean review is neither CI success nor merge, release, or deployment permission.

## 3. Handoff

Return the current input hashes, outputs and evidence, unresolved findings, authority boundary, and next permitted action to [custom-paw-workflow](../custom-paw-workflow/SKILL.md). Routing is not permission to advance.
