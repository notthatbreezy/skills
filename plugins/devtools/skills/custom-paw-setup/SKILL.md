---
name: custom-paw-setup
description: Establish PAW authority, baseline, artifact lifecycle, review policy and explicit adaptations before work.
---

# Phase 1: Setup and working agreement

## 1. At entry

Start here for a new workflow. On resumption, recover existing decisions first; do not recreate branches or artifacts.

**Consult before work:** `paw-init` only for a genuinely new authorized workflow; selected `paw-workflow` or `paw-lite`; `paw-status` for recovery. Before starting this phase, load the required skills and follow their instructions.

**Required-skill availability:** If any skill required for the current phase is unavailable or cannot be loaded, stop the phase and report BLOCKED to the user. Name the missing skill, explain which work it blocks, and state what is needed to proceed. Do not skip it, reconstruct its instructions from memory, or substitute another skill or reviewer without explicit user approval. Resume only after the required skill is available or the user explicitly approves a revised requirement. Missing required external skills, named agents, or specialist personas remains BLOCKED until resolved or explicitly waived by the user.

**Exit gate:** Objective, current baseline, authorized stages, artifact aliases/lifecycle, remediation policy and human stops are explicit.

Require WorkflowContext.md, Spec.md, CodeResearch.md, ImplementationPlan.md, concrete test contracts, and a requirement-to-proof coverage map for planning review. Plan documentation ownership and produce Docs.md at its designated phase. Equivalent filenames may be declared as aliases, but must preserve every required content area. Issues inform the specification; they do not replace the planning bundle. Full, Lite, and custom routing all use the same mandatory specialist reviews and human approval gate.

## 2. Establish the working agreement

Read current user instructions, repository instructions, and the selected PAW workflow before creating branches, worktrees, artifacts, or workers. On an existing task, recover its current WorkflowContext and decisions first. Do not bootstrap a second workflow because conversation history is missing.

Read the governing `delegation-orchestrator` agent instructions directly and record their agent/package identity and policy version. They govern delegation when this workflow or a loaded PAW skill conflicts. Carry the applicable clauses into worker briefs; retain the agent's required policy-feedback ledger. This workflow does not replace the agent instructions or amend the canonical agent package.

Distinguish review requirements from execution mechanics: this workflow specifies required reviewer roles, coverage and approval gates; risk-based review is the default where no specific review guidelines apply. The agent's runtime policy governs how work is delegated, which models/efforts and tools are used, and how workers are managed. The dedicated type-safety seat supplies the agent's type-safety lens; do not duplicate it.

Record the following in WorkflowContext or the explicitly selected equivalent:

| Field | Required decision |
| --- | --- |
| Objective and authority | User request, issue or specification, latest clarifications, non-goals, protected resources, authorized stage. |
| Source baseline | Actual repository root, remote, fetched base/head, prerequisite branches, allowed and excluded research sources, isolation strategy. |
| Workflow | Full, Lite, or custom; stages to run or skip; mandatory gates; artifact-name aliases; reason for adaptations. |
| Artifact lifecycle | `never-commit`, `commit-and-persist`, or `commit-and-clean`; exact paths; local checkpoint requirements; durable artifact owner. |
| Review policy | Five-reviewer planning SoT roster and full final SoT roster including test/type specialists; exact input hashes, closure scope, review budget, remediation policy, and explicit human planning approval. |
| Execution policy | Governing agent/package and delegation-policy identity; dependency order, write ownership, validation commands and prerequisites, integration owner; recorded conflicts/adaptations. |
| Action grants | Separately record permission for source edits, local commits, push, PR creation, comments/reviews, issue/project edits, merge, release, deployment. |
| Recovery | Current artifact hashes, decisions, outstanding findings, child sessions, completed writes, next authorized action. |

A grant may cover a clearly bounded sequence of actions; do not re-ask for every routine step inside that grant. Never infer a broader grant from a narrower one. Approval of an option, plan, canvas presentation, or review verdict does not itself authorize implementation or GitHub writes.

Do not confuse a **human check-in** with a **Git check-in**. A progress update is communication. A local commit changes repository history and follows the configured authorization and artifact lifecycle.

### 2.1. Explicit adaptations to stock PAW

Document these adaptations when adopting this workflow:

| Stock behavior or ambiguity | This workflow's proposed rule |
| --- | --- |
| A planning-bundle review may be disabled or complete with reduced inputs. | The complete planning bundle, five-reviewer SoT panel, source-verified synthesis, and explicit human approval are mandatory in every mode. Missing inputs or required reviewers block the gate; Lite does not bypass it. |
| Review modes and panel composition are configurable. | Planning uses exactly five reviewers as defined below; the generalist performs `paw-plan-review` within that panel. Final pre-PR review uses full SoT with dedicated type and test specialists, not a reduced panel. These are this workflow's staffing requirements, not claims about stock PAW defaults. |
| A review cycle limit can return completion with remaining findings. | A limit ends the automated cycle, not the defect. Return blocked or request a human disposition; never manufacture PASS. |
| Smart remediation can rely on agreement or confidence. | The parent first verifies grounding, authority, bounded scope, and absence of a design tradeoff. Consensus alone is insufficient. |
| Review completion can route directly to implementation or PR. | Routing identifies the next stage; the authorization ledger decides whether it may run. |
| Examples use fixed model families or an in-process task tool. | Resolve current model availability and owner policy; use the host's native durable `spawn_agent`. |
| PAW assigns delegation mechanics, worker models, direct execution, or cleanup. | Follow the governing `delegation-orchestrator` agent instructions instead wherever they conflict; record the adaptation. |
| Generic evidence guidance uses file-and-line citations. | Retain exact revision grounding. Honor repository-specific file-and-symbol conventions where required; use verified line locations for GitHub inline comments. |

If current user or repository instructions conflict with the proposed defaults, preserve those instructions and record the adaptation. Do not silently change an established workflow mode.

## 3. Adoption choices

Select the choices that source sessions do not establish as universal:

| Choice | Proposed default |
| --- | --- |
| Scope | Follow the user's requested endpoint; do not extend planning-only work. |
| Planning gate | `paw-planning-docs-review` in society-of-thought mode with `paw-sot`: five current-input PASS reports and source-verified synthesis, then explicit human approval of the exact reviewed bundle. The coordinator runs and synthesizes the panel; it is not an additional reviewer. |
| Planning staffing | Exactly five distinct reviewers: general rubber duck loading `paw-plan-review`; clear-writing reviewer loading `clear-workplace-writing`; `test-plan-reviewer` agent v1.0.0; separate type-safety reviewer loading `delegation-type-safety`; and one risk-selected specialist (architecture/integration by default, security for security-sensitive work). |
| Final review | `Final Review Mode: society-of-thought`; `Final Review Specialists: all`. Use `paw-final-review` and `paw-sot`, with dedicated type-safety and test specialists explicitly included. The planning panel's five-seat limit does not limit final review. |
| Remediation | Use the current owner's policy. If none is established, resolve human-first versus bounded autonomous before repairs. |
| Artifact lifecycle | Resolve explicitly; never infer local commit or publication authority. |
| Review budget | Bounded cycles with no-progress escalation; unresolved blockers remain blockers. |
| Check-ins | Milestones and real decisions, not an arbitrary timed cadence. |
| Publication | Grants specific enough to identify permitted actions; never implied by PASS or presentation. |

Confirm the `test-plan-reviewer` named agent and all required skills can be loaded before staffing review; record their versions or source identities. `test-plan-reviewer` is an agent, not a skill. If a dependency is unavailable, report BLOCKED rather than substituting a generalist or silently skipping it. See [custom-paw-plan-gate](../custom-paw-plan-gate/SKILL.md) for exact assignments and approvals.

## 4. Handoff

Return the current input hashes, outputs and evidence, unresolved findings, authority boundary, and next permitted action to [custom-paw-workflow](../custom-paw-workflow/SKILL.md). Routing is not permission to advance.
