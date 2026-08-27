---
name: tennex-execution
description: Execute Tennex delivery work. Use when acting as Project Steward, Engineering Lead, worker, or independent QA; dispatching an assignment; coordinating validation-first checkpoints; declaring Perspective and Specialist coverage; accepting Feature or Workstream results; recovering or revising authority; or preparing an approved remote mutation.
---

# Tennex Execution

Emulate the Tennex execution model with current Copilot sessions. Preserve four separations throughout the run:

1. planning outcome from execution attempt;
2. delegated authority from produced files;
3. evidence from acceptance;
4. message delivery from observed action.

Apply review-plan, dual-review, and moderated pre-push Society-of-Thought gates prospectively to unaccepted work and future remote mutations. Do not reopen accepted or merged work solely to apply a later process gate; reopen it only for a concrete new defect or an explicitly revised planning outcome.

## 1. Establish role, authority, and fixed point

Identify:

- acting role: Project Steward, Engineering Lead, engineering worker, or independent QA;
- Project, Milestone, optional Workstream, Feature, Task, and delivery checkpoint in scope;
- authoritative charter, plan, assignment revision, and execution-boundary policy revision;
- repository, worktree, branch, base, exact source identity, and dirty state when code is involved;
- writable claims, tools, budget, lifetime, stop conditions, approval policy, and sub-delegation permission;
- accountable acceptance authority for the Task, Feature, Workstream, delivery checkpoint, and Milestone.

Read [`references/domain-and-states.md`](references/domain-and-states.md) when selecting lifecycle states, authority, or transition evidence.

Invoke `tennex-planning` when creating or changing the planning hierarchy, acceptance criteria, evaluation, or evidence plan. Invoke `domain-modeling` when execution reveals a conflicting or unresolved Tennex term. Invoke `type-driven-development` when designing commands, events, assignments, messages, approvals, state machines, recovery records, or public contracts.

Stop and escalate to the supervisor when the role, assignment revision, fixed point, claim boundary, or acceptance authority is ambiguous.

**Complete when:** the active role, exact authority revision, immutable source, planning nodes, linked delivery checkpoint, claims, dependencies, and acceptance authorities are explicit and mutually consistent.

## 2. Choose the execution branch

Choose one primary branch. A session may change branches only after returning or fencing its current authority.

### Project Steward

Own the human relationship, Milestone outcome, and final Milestone acceptance.

1. Confirm that the charter and Milestone outcome remain approved.
2. Ask the Engineering Lead for technical decomposition, validation strategy, forecast, and bounded execution packets.
3. Check plans against product scope and acceptance intent; use `tennex-planning` for the semantic hierarchy review.
4. Present human decisions and approvals through this role unless interaction authority was explicitly delegated.
5. Moderate any independent reports under the model-diversity rules in [`references/review-plans.md`](references/review-plans.md), then accept or reject the Milestone only from exact-state evidence, explicit Feature and Workstream acceptance records, open-risk disposition, and the required progress dashboard projection.

### Engineering Lead

Own technical decomposition, validation strategy, checkpoint graph, claims, repository integration, Feature and Workstream acceptance, and delivery forecast.

1. Invoke `coordinator` for multi-checkpoint execution mechanics.
2. Use `coordinator`'s native session mechanics for single-project checkpoint work. Invoke `orchestrate` only for multi-project or multi-repository work, a deliberate fork, or a PR stack.
3. Declare the risk-driven review plan before implementation dispatch.
4. Build the surface map and validation-first checkpoint DAG before dispatch.
5. Issue complete versioned assignments and supervise activation.
6. Integrate only accepted Task results; preserve one integration authority.
7. Record explicit Feature and Workstream acceptance decisions separately from delivery-checkpoint acceptance.
8. Return a Milestone evidence and forecast packet to the Project Steward.

### Engineering worker

Own one bounded Task under one active assignment revision.

1. Read the complete assignment and execution-boundary policy before effects.
2. Work only within claims, tools, budget, lifetime, and sub-delegation policy.
3. Load every required project skill or its assignment-provided exact fallback path before effects. Stop when required guidance is unavailable.
4. Stop at completion, blocker, approval boundary, budget exhaustion, cancellation, fence, or hard stop.
5. Return the result packet from [`references/handoff-packets.md`](references/handoff-packets.md). Produced files are provisional until accepted.

### Independent QA

Remain read-only and independent from the implementation being assessed.

- Invoke the custom agent `paw-workflow:PAW-Review` for each independent Reviewer A and Reviewer B run. Use `reviewer` as the read-only correctness and evidence-gap discipline inside the declared PAW coverage, not as a substitute for the PAW run.
- Invoke `validator` for builds, tests, type checks, UI observations, lifecycle scripts, artifacts, or measurable acceptance evidence.
- Reviewer sessions execute the declared PAW Perspectives and Specialists, then return the Tennex independent-review packet, which is a strict superset of the generic reviewer completion contract.
- Execute every Perspective and Specialist in the assigned review plan and map findings to that coverage.
- Keep the report blind from the peer reviewer until both complete.
- A validator counts as one reviewer only when it performs the same complete substantive review-plan coverage and satisfies every reviewer independence and report requirement; deterministic command execution alone never counts.
- Report findings and confidence. The accountable lead retains acceptance authority.

**Complete when:** the selected branch owns only its defined decisions and outputs, and any required generic skill has been invoked rather than copied.

## 3. Build the validation-first checkpoint graph

For engineering delivery:

1. Define observable acceptance claims from the approved planning outcome.
2. Read [`references/review-plans.md`](references/review-plans.md) and declare required Perspectives, Specialists, rationale, and evidence expectations before dispatch.
3. Create the earliest independent validation or harness checkpoint needed to prove the claims.
4. Freeze shared schemas, identifiers, lifecycle transitions, manifests, generated outputs, and migration ownership before parallel implementation.
5. Give every checkpoint one outcome, one owner, exact claims, dependencies, stop conditions, and required evidence.
6. Make prerequisite dependencies acyclic and name the evidence that unblocks each edge.
7. Parallelize only disjoint state owners, files, worktrees, generated outputs, and serialized resources.
8. Reserve integration for accepted immutable inputs.
9. Schedule two fresh independent PAW reviewers with different model IDs, separately attributable Specialist participants, 20-minute deadlines, one replacement each, and required validation against the exact integrated state and same bound review plan.

Read [`references/checkpoints-and-evidence.md`](references/checkpoints-and-evidence.md) for checkpoint, evidence, acceptance, and remediation rules.

Planning states never roll up automatically. Delivery-checkpoint acceptance freezes evidence; it does not accept a Task, Feature, Workstream, or Milestone.

**Complete when:** every acceptance claim has an evaluation and evidence type; required Perspectives and Specialists have risk-based rationale; applicable omissions are explained; every graph edge has an unblock condition; every writable surface has one owner; and every acceptance decision has one accountable authority.

## 4. Issue and activate assignments

Read [`references/assignment-and-dispatch.md`](references/assignment-and-dispatch.md) before creating or revising any worker assignment.

1. Persist or write the complete assignment revision before dispatch.
2. Record `assignment_authorized`.
3. Create the worker surface using the chosen generic orchestration mechanism.
4. Deliver the complete kickoff and record `dispatch_requested`.
5. Start the dispatch watchdog immediately and keep it active until activation succeeds, fails, or expires.
6. Observe an actual worker turn that identifies the pinned assignment and policy revisions.
7. Record `activation_observed` only after that handshake, then close the watchdog as activated.
8. Record `work_observed` only from an observed execution signal, not from session existence.

The kickoff requires the worker to return the activation packet from [`references/handoff-packets.md`](references/handoff-packets.md) before tool use or effects. A created session is registered capacity, not active work. A queued kickoff is not observed authority.

**Complete when:** the activation event identifies the worker, run, assignment revision, policy revision, source identity, and observed timestamp; otherwise the watchdog records `activation_failed` or `activation_expired`, delivery health becomes `blocked`, and the Task planning node remains `approved` until an accountable decision changes it.

## 5. Supervise execution and revisions

Use the closed message and run vocabularies in [`references/domain-and-states.md`](references/domain-and-states.md).

- Report only observed facts. Keep `sent`, `persisted`, `delivered`, `observed`, `acknowledged`, `resolved`, and `failed` distinct. Record `acted_upon` as a separate execution event linked to the resulting command, decision, assignment, or effect.
- Keep run state separate from planning lifecycle and result disposition.
- Treat useful partial work as recoverable evidence, not authority or completion.
- Apply Microsoft package mirrors and canonical lifecycle scripts through the centralized execution-boundary policy in [`references/execution-boundaries.md`](references/execution-boundaries.md).
- Preserve desktop-class browser scope; do not introduce mobile or responsive acceptance obligations.

For a material scope, claim, tool, budget, mirror, approval, or safety-policy change:

1. fence the old authority;
2. let in-flight effects reach a safe stop;
3. record the fence and preserved state;
4. issue a complete replacement assignment at a new revision;
5. start a replacement run pinned to that revision;
6. repeat activation observation before authoritative work resumes.

Queued corrections and message acknowledgments do not update authority.

**Complete when:** every active worker is pinned to one unfenced assignment revision, every material change has a replacement run, and preserved partial outputs are explicitly classified as provisional evidence.

### Reboot is not revision or recovery

A user-triggered reboot preserves durable agent identity, role, current authority, assignments, threads, decisions, and memory. It retires the provider session and active run, then starts a fresh run from a rebuilt context pack under the same current authority.

A material revision fences and replaces authority. Recovery preserves evidence without authority. Record which operation occurred.

## 6. Return, assess, integrate, and accept results

1. Record `result_returned` when the worker submits the required packet.
2. Verify source identity, claims, cleanup, active processes, evidence mapping, and unresolved findings.
3. Reject zero-test, proxy-only, stale-state, or success-shaped evidence.
4. For a substantive delegated result, freeze its immutable revision and bind the active review plan to it.
5. Dispatch two reviewers against the same Perspectives and Specialists and obtain reports satisfying [`references/checkpoints-and-evidence.md`](references/checkpoints-and-evidence.md), including separately attributable Specialist outputs and bounded deadlines.
6. Moderate the two reports under the accepting-lead model-diversity, identity-recording, deadline, replacement, and fail-closed rules in [`references/review-plans.md`](references/review-plans.md).
7. Record accountable Task result acceptance or rejection linked to the returned result, both final review reports, and the passing moderation record.
8. Integrate only accepted immutable Task states.
9. Freeze the integrated state and apply the review reuse-or-rerun rule in [`references/checkpoints-and-evidence.md`](references/checkpoints-and-evidence.md).
10. When a finding exposes a new risk, read [`references/review-plans.md`](references/review-plans.md), revise the required coverage, fence affected review runs, and repeat both reviews on the replacement immutable revision.
11. Route blocking findings to a narrow replacement implementation assignment. Freeze the remediated revision, bind the replacement review plan, require two fresh reviewers, and revalidate changed evidence.
12. Record Feature and Workstream acceptance as separate first-class decisions after their own outcome, integration, and a passing accepting-lead moderation record for the applicable Perspective and Specialist evidence.
13. Return the Milestone packet to the Project Steward; do not infer Milestone acceptance.

**Complete when:** each substantive delegated result has two qualifying final PAW reports on the reviewed immutable revision and a passing accepting-lead moderation record with complete model-identity evidence; both reviewers pass or every blocking finding is resolved and re-reviewed; integration contains only accepted inputs; and Task, Feature, Workstream, delivery-checkpoint, and Milestone decisions remain distinct.

### Return evidence for Project Steward Society-of-Thought

After both independent reviewers pass and required validation passes on the same final immutable revision and review plan, the Engineering Lead stops and returns the complete review and validation evidence to the Project Steward.

The Project Steward is the accepting lead and unconditionally moderates the PAW Society-of-Thought review before any push or pull-request mutation. This is an additional remote-readiness moderation after any earlier Task, checkpoint, Feature, Workstream, or Milestone moderation. Read [`references/review-plans.md`](references/review-plans.md) for exact PAW ReviewContext, separately attributable Specialist outputs, automated moderator diversity, human-moderation fallback, deadlines, and invalidation rules. Read [`references/checkpoints-and-evidence.md`](references/checkpoints-and-evidence.md) for required inputs and completion evidence.

The Engineering Lead does not self-moderate this gate. This gate is distinct from the two blind reviews and deterministic validation. Any artifact change or required-coverage change invalidates affected reviews and the Society-of-Thought result and requires the full sequence again.

## 7. Cross a remote-mutation boundary

Read [`references/remote-actions.md`](references/remote-actions.md) before any push, pull-request creation or update, or merge.

1. Verify a passing moderated PAW Society-of-Thought record for the exact final revision.
2. Perform read-only authentication, remote-state, ancestry, divergence, and conflict preflight.
3. Integrate newer or unrelated remote history locally.
4. Refresh affected validation and integration evidence after any rebase, dependency, toolchain, credential, mirror, or environment shift.
5. Repeat moderation whenever its evidence inputs changed; repeat both reviews when artifact content, diff meaning, authoritative requirements, or required coverage changed.
6. Route the exact approval packet through the Project Steward.
7. Apply only the named mutations to the named branch, SHA, and base after approval.
8. Record the observed remote result and any mismatch from the approved packet.

Approval for push or pull-request mutation never includes merge unless merge is named separately.

**Complete when:** the same immutable revision has two passing independent reviews, current integration and validation evidence, and a passing moderated Society-of-Thought record before preflight; approval names exact mutations and immutable identities; and the recorded remote result matches the approved boundary.

## 8. Close the Milestone boundary

The Engineering Lead returns:

- accepted exact integrated state and ancestry;
- delivery-checkpoint decisions and evidence;
- explicit Task, Feature, and Workstream acceptance records;
- dual independent review packets with model IDs, reviewed revision, scope, findings, evidence gaps, and pass/fail, plus validation packets;
- accepting-lead moderation packets with author, reviewer, and moderator model identities or direct-human moderation evidence;
- moderated PAW Society-of-Thought packet when the Milestone is remote-ready;
- unresolved risks, deferrals, and forecast impact;
- remote-state status and remaining operator gates.

The Project Steward:

1. assesses the Milestone outcome against approved acceptance intent;
2. records final acceptance, rejection, or revision need;
3. produces the required progress dashboard projection from durable planning and evidence state;
4. includes the projection freshness time and ledger cursor;
5. carries accepted decisions, unresolved risks, and next planning questions into the next cycle.

Use the Milestone handoff template in [`references/handoff-packets.md`](references/handoff-packets.md).

**Complete when:** final acceptance is explicit, the dashboard is a derived projection rather than authority, and the next planning cycle starts from durable accepted state rather than session memory.

Generate the same cursor-and-freshness-bearing projection at every other Milestone boundary: approval into active execution, rejection and reopening, supersession, and cancellation.
