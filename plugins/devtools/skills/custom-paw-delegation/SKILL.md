---
name: custom-paw-delegation
description: Consult before spawning workers to establish exact inputs, authority, output ownership and lifecycle.
---

# Bounded delegation and reviewer seats

## 1. At entry

Use before any research, reviewer or implementation worker. The coordinator remains accountable for acceptance and integration. Reviewer independence and remediation follow [custom-paw-review-policy](../custom-paw-review-policy/SKILL.md).

**Delegation precedence:** Read and follow the governing `delegation-orchestrator` agent instructions. They override conflicting delegation instructions in this workflow and every loaded PAW skill, including `paw-sot`, `paw-implement`, and review skills. Apply their rules for direct work, model/effort selection, briefs, ownership, native execution, evidence handoff and child cleanup. Record the conflict and chosen adaptation. Do not follow PAW model defaults or in-process spawning merely because a skill prescribes them.

**Review requirements versus execution:** The active PAW workflow or other specific review guidelines determine required roles, coverage, independence and gates. The agent's risk-based review strategy is the default only when no specific guidelines apply, not a reason to shrink a required panel. The required coverage does not require expensive models, different models or extra perspective fan-out. The agent's runtime rules still govern model/effort selection and execution tools; PAW model defaults and tool examples do not override them. Stop and report any genuine conflict that prevents satisfying both.

**Direct versus delegated work:** PAW verbs such as "research", "draft", "implement" and "run checks" describe work to accomplish, not an instruction for the coordinator to perform it all directly. The coordinator reads governing instructions and owns decomposition, judgment, integration oversight and acceptance. Delegate substantial research, drafting and implementation under the agent's policy; retain its bounded direct-work exceptions and scope reassessment rules.

**Complementary type-safety rules:** The workflow's separate type-safety reviewer supplies the agent's default dedicated type-safety lens with an explicit seat and gate. It is not an additional duplicate reviewer. Preserve the required seat and explain inapplicable boundaries without inventing findings.

## 2. Delegate bounded work and retain accountability

Use native `spawn_agent`, not an alternate in-process mechanism. Resolve exact available models before assigning them. Honor current owner staffing policy; choose a capable tier for the task without inferring universal speed, cost, or model superiority from anecdotes.

Every worker packet includes exact source/artifact identities, objective, bounded question or owned files, prerequisites, exclusions, completion evidence, read/write authority, stop conditions, output destinations, and whether further delegation is permitted. Default to no onward delegation unless the coordinator deliberately assigns it.

Initial reviewers are read-only. Parallelize independent research, review lenses, or disjoint implementation after interface contracts and prerequisites are ready. Keep one integration owner. Do not ask multiple workers to write the same shared interface independently.

For planning, staff exactly five distinct reviewers from [custom-paw-plan-gate](../custom-paw-plan-gate/SKILL.md): general rubber duck loading `paw-plan-review`, clear-writing reviewer loading `clear-workplace-writing`, named `test-plan-reviewer` agent v1.0.0, separate type-safety reviewer loading `delegation-type-safety`, and a risk-selected specialist. Resolve that specialist to a named `paw-sot` persona; load its actual instructions and record source identity/version or hash, rubric, and scope before staffing. Missing persona instructions block the gate. Keep the five seats separate from the author and coordinator. Require exact-input PASS/FAIL/BLOCKED reports from all five; coordinator synthesis is not a sixth review or a substitute report. Verify named-agent registration/version and every seat's scope receipt; a missing role blocks the gate rather than triggering a generic fallback.

For final pre-PR review, staff the full `paw-sot` specialist set through `paw-final-review`, explicitly including dedicated type-safety and test specialists. Do not carry the planning panel's five-seat limit into final review or substitute the planning-only test-plan report for implementation review. Reuse suitable seats where context and independence permit, but require fresh exact-diff reports.

Use `contract.wakeOn: material_change` for finite work whose result is needed. Qualifying results wake the parent; do not create timers merely to poll children. Reuse review seats through the active correction cycle. Verify the worker actually received the intended scope, particularly after generic agent startup or queued detail.

Parents and children do not share a filesystem. Transfer files through artifacts and verify hashes. Archive required outputs in the coordinating session before retiring children. Verify delivery rather than accepting "done" as evidence. Close finite seats once their outputs and closure obligations are accepted.

## 3. Return

Archive required outputs and verify their identities and scope before accepting them. Return verified evidence to the invoking phase; retain seats only while their closure obligations remain active.
