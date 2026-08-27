# Checkpoints, Evidence, and Acceptance

Use this reference when designing a validation-first DAG, accepting a returned result, integrating work, or closing a planning node.

Use [`review-plans.md`](review-plans.md) for Perspective, Specialist, selection, coverage-expansion, and durable review-record rules.

## Validation-first shape

A demanding delivery graph normally contains:

1. approved outcome and immutable base;
2. independent intended-behavior or harness checkpoint;
3. shared contract or scaffold checkpoint;
4. parallel implementation checkpoints with disjoint ownership;
5. integration checkpoint;
6. independent Reviewer A checkpoint;
7. independent Reviewer B checkpoint;
8. separately attributable required Specialist outputs within each PAW review;
9. independent validation checkpoint;
10. accepting-lead moderation with complete model-identity evidence;
11. accountable planning acceptance;
12. Project-Steward-moderated PAW Society-of-Thought checkpoint before connected remote work;
13. separate remote-mutation gate.

Use only the checkpoints the risk requires. Each checkpoint removes a named uncertainty.

## Checkpoint contract

Each delivery checkpoint names:

- purpose and linked planning nodes;
- frozen observable claims;
- required evidence for every claim;
- pass/fail interpretation;
- owner, evidence producer, independent assessor, and acceptance authority;
- exact immutable state;
- revision rule.

Accepted checkpoints are immutable. Changed claims, evidence requirements, authority, or exact state produce a new checkpoint or revision.

## Evidence quality

Evidence identifies:

- supported criterion and planning nodes;
- producer and method;
- exact commit, artifact version, environment, or run;
- result and limitations;
- durable source and timestamp.

Demand direct evidence:

- tests select the required nonzero cases;
- runtime evidence observes the claimed behavior;
- restart evidence uses a different process;
- generated or shared contracts pass normal consumers;
- mirror policy is tested against hostile configuration;
- remote preflight observes current authentication and ancestry;
- UI evidence observes the supported desktop-class behavior.

A proxy can inform but cannot close a claim it does not directly measure.

## Acceptance layers

Keep these decisions separate:

| Decision | Authority | Meaning |
|---|---|---|
| Delivery-checkpoint acceptance | Named checkpoint authority | Frozen evidence satisfies the checkpoint claims |
| Task result acceptance | Accountable lead for the parent Feature; Engineering Lead by default in v0 | Returned result is fit for integration |
| Feature acceptance | Engineering Lead or explicitly delegated Feature Lead | Stakeholder-visible capability satisfies its outcome |
| Workstream acceptance | Engineering Lead | Cross-Feature coherence, dependencies, and integration satisfy the lane |
| Milestone acceptance | Project Steward | Milestone outcome and final evidence satisfy approved intent |
| Merge approval | Human by default | Exact remote merge may occur |

All are first-class records linked to exact evidence. None is inferred from child completion. Every substantive decision that consumes independent reports requires a passing accepting-lead moderation record before the decision is recorded.

## Dual independent review and validation

A **substantive delegated deliverable** is any delegated plan, design, migration, implementation, integration, workflow artifact, or evidence package whose acceptance advances a Task, Feature, Workstream, Milestone, or delivery checkpoint.

Before accepting one:

1. freeze one immutable artifact revision;
2. bind the declared review-plan revision to that artifact revision;
3. create Reviewer A and Reviewer B as fresh separate `paw-workflow:PAW-Review` sessions;
4. give both read-only scope and no implementation claims;
5. assign the same immutable revision, Perspectives, Specialists, evidence expectations, and authoritative requirements;
6. use different model IDs for A and B and, when available, model IDs different from the implementer or author;
7. require separately attributable outputs for every required Specialist within each PAW run;
8. enforce the 20-minute wall-clock deadline and one-replacement budget in [`review-plans.md`](review-plans.md);
9. keep the reviews blind until both reports are submitted;
10. require both PAW reports to use the exact Tennex independent-review packet in [`handoff-packets.md`](handoff-packets.md), a strict superset of the generic `reviewer` completion contract;
11. record any inability to obtain a third distinct model as an explicit exception for Project Steward or human decision;
12. run independent validation for measurable evidence;
13. moderate the final report pair under the universal accepting-lead moderator identity, diversity, deadline, replacement, and fail-closed rules in [`review-plans.md`](review-plans.md).

Tests and deterministic tools never satisfy the reviewer count by themselves. A validator may count as one reviewer only when its assignment includes substantive acceptance assessment, it satisfies every independence rule above, and its report uses the reviewer output contract.

Acceptance requires two qualifying final reports on the same immutable revision and review-plan coverage plus a passing accepting-lead moderation record. A blocking finding from either reviewer invalidates acceptance until:

1. a narrow implementation assignment corrects the invariant;
2. the new exact state is frozen as a new revision;
3. two fresh qualifying reviewers independently assess the new revision;
4. required validation is repeated for changed evidence.

Neither prior reviewer report transfers to a changed revision. Deterministic evidence may be reused only when its source and measured requirement remain unchanged.

When a finding requires another Perspective or Specialist, revise the review plan, fence affected reviewer runs, and dispatch replacements. A completed report with incomplete required coverage cannot be accepted.

When the returned Task result and integrated state are the same immutable revision and both reviewers' declared coverage includes result fitness and integration, one qualifying dual-review pair may satisfy both gates. A changed revision, changed diff meaning, or expanded coverage requires two fresh reviews.

Refresh validation and integration evidence after a rebase, dependency resolution, toolchain, credential, mirror, or execution-environment shift, even when the immutable artifact hash is unchanged. Repeat every moderation whose evidence changed. Preserve prior artifact reviews only when content, diff meaning, authoritative requirements, and required coverage remain unchanged.

## Moderated Society-of-Thought before remote work

After both qualifying reviewers pass, the applicable accepting lead has completed ordinary acceptance moderation, and required validation passes on the same final immutable revision, the Engineering Lead stops and returns the evidence to the Project Steward. The Project Steward is the accepting lead for remote readiness and moderates the additional PAW Society-of-Thought review before any remote preflight begins.

The moderator provides:

- the bound review plan;
- both independent reports;
- validation evidence;
- accepted scope and non-goals;
- final diff and immutable revision;
- unresolved risks and deferrals.

Follow the exact PAW ReviewContext, Specialist attribution, moderator-model diversity, timeout, and human-moderation rules in [`review-plans.md`](review-plans.md). Record participant and Specialist model IDs, Perspective consensus, disagreements, dispositions, moderator decisions, unresolved risks, and pass/fail.

The Project Steward always moderates this pre-push gate. Society-of-Thought does not replace either blind reviewer or deterministic validation. Artifact or coverage changes require two fresh blind reviews, changed validation, and a new moderated Society-of-Thought record. Evidence-context changes require refreshed validation and moderation under the rule above.

Apply this gate to unaccepted work and future remote mutations. Do not reopen accepted or merged work solely for retroactive process compliance; a concrete new defect or revised outcome creates new work that follows the current gates.

## Result acceptance

Record `result_returned` before assessment.

The accountable assessor checks:

- assignment and policy revision;
- exact source identity and diff/artifact scope;
- claims held and released;
- required evidence mapped to every criterion;
- negative cases and downstream consumers;
- cleanup and remaining processes;
- blockers, limitations, and external effects.

Then record `result_accepted` or `result_rejected` linked to the returned result, exact evidence, the two qualifying final review reports, and the passing accepting-lead moderation record. A run ending successfully is not result acceptance.
