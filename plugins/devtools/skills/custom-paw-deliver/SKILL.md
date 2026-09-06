---
name: custom-paw-deliver
description: Run source-aware PR preflight and perform only specifically authorized GitHub actions.
---

# Phase 6: PR preparation and authorized delivery

## 1. At entry

**Review and execution:** This workflow determines required review coverage and gates; risk-based review is the fallback where no specific guidelines apply. The `delegation-orchestrator` agent runtime instructions govern direct versus delegated work, model/effort selection and execution tools. See [custom-paw-delegation](../custom-paw-delegation/SKILL.md); stop and report genuine conflicts.

Require current full SoT integrated review, including separate type-safety and test specialist reports and source-verified synthesis, complete documentation and the action ledger. The review must cover the exact base/head diff to be proposed. Preparation and publication are separate; reconcile remote state before every retried write.

**Consult before work:** `paw-pr`, `paw-git-operations`; `paw-review-response` or `paw-pr-lifecycle` only for authorized follow-through. Before starting this phase, load the required skills and follow their instructions.

**Required-skill availability:** If any skill required for the current phase is unavailable or cannot be loaded, stop the phase and report BLOCKED to the user. Name the missing skill, explain which work it blocks, and state what is needed to proceed. Do not skip it, reconstruct its instructions from memory, or substitute another skill or reviewer without explicit user approval. Resume only after the required skill is available or the user explicitly approves a revised requirement. Missing required external skills, named agents, or specialist personas remains BLOCKED until resolved or explicitly waived by the user.

**Exit gate:** Preflight passes, only authorized writes occur, and the requested endpoint is recorded without implying merge or deployment.

## 2. Prepare the PR, then perform only authorized writes

Run `paw-pr` preflight against the declared Full/Lite/custom artifact set and current source state. Before a dependent PR, recheck whether its prerequisite has merged and select the correct base. If base/head drift changes the reviewed diff, update evidence and review scope before publication.

| Preflight | Required outcome |
| --- | --- |
| Scope | Planned phases complete; candidates resolved; open questions and risks disposed honestly. |
| Final review | Full SoT roster reports and synthesis cover the current diff, including dedicated type and test specialists; accepted repairs have current closure and no unresolved blocker remains. |
| Repository | Correct repository/remote/branch/base, no conflicts, unrelated changes preserved, exact intended staged diff. |
| Evidence | Repository/user-mandated build/lint/type/test checks pass at the required checkpoint, or a specific failure/unavailability has an explicit user-approved exception before publication, consistent with governing requirements. Retain the failed/missing evidence and exception; do not relabel it PASS. |
| Documentation | Required Docs.md and affected design/user/index surfaces complete; actual PR template/title/body/footer conventions honored. |
| Artifacts | Lifecycle applied deliberately; no accidentally tracked scratch ignore markers or prohibited planning artifacts. |
| Authority | Exact push, PR, comment/review, or other GitHub write covered by a current user grant. |

For `never-commit`, exclude planning artifacts from commits and summarize necessary context in the PR. For `commit-and-persist`, include only approved artifacts and link their retained paths. For `commit-and-clean`, preserve the last artifact commit and perform the authorized stop-tracking step before final PR creation. Never treat lifecycle configuration alone as commit permission, and never remove unrelated index changes.

If a mandated check fails or cannot run, stop before push, PR creation or another publication write. Present the exact failure, impact and proposed exception to the user and wait for a decision; disclosure in a PR body is not approval. A general action grant does not authorize publication over newly discovered failed or missing mandated evidence. Resume only after passing evidence or an explicit applicable exception and the necessary action grant. An exception cannot waive a higher-priority prohibition.

Prepare the PR description before publication. Scale it to the work and include truthful evidence, behavior changes, limitations, compatibility and deployment considerations, issue references, and the actual repository-required format. Do not copy another project's title, decision IDs, commands, or collapsed section convention as a universal rule.

Separate review generation from GitHub posting. Creating a pending review, submitting it, editing or deleting comments, and posting duplicate comments are distinct writes. Reconcile existing remote state before retrying a write after a restart. Do not turn a pending review into a submitted review without the required grant.

PR creation is the end of this workflow unless follow-through was authorized. Merge, release, deployment, and ongoing CI/review monitoring each need an appropriate grant; "Done" is not deployment evidence. For authorized monitoring, use native durable schedules and stop at the agreed outcome.

## 3. Handoff

Return the current input hashes, outputs and evidence, unresolved findings, authority boundary, and next permitted action to [custom-paw-workflow](../custom-paw-workflow/SKILL.md). Routing is not permission to advance.
