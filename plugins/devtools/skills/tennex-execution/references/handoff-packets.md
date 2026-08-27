# Tennex Handoff Packets

Use these exact shapes for cross-session and Milestone handoffs. Keep packets compact, factual, and tied to immutable identities.

Serialize closed vocabulary values as lower-case `snake_case`, matching [`domain-and-states.md`](domain-and-states.md).

## Activation packet

```text
Status: ready | blocked
Worker and run:
Assigned model ID and dispatch record:
Assignment revision:
Execution-boundary policy revision:
Source identity:
Claims accepted:
Stop conditions:
First intended action or blocker:
Observed at:
```

## Worker status packet

```text
Run state:
Assignment revision:
Current intent:
Work observed:
Claims held:
Evidence produced:
Blockers or questions:
Budget used and remaining:
Next safe stop:
```

## Worker result packet

```text
Status: complete | partial | blocked | failed | fenced
Worker, run, and assignment revision:
Exact source or artifact identity:
Outcome attempted:
Claims held and released:
Produced files, commits, or artifacts:
Evidence mapped to criteria:
Validation performed:
Implementer or author model ID:
External effects:
Cleanup and active processes:
Findings, blockers, and limitations:
Resource usage:
Recommended next action:
```

## Recovery or transfer packet

```text
Reason for recovery or transfer:
Fenced assignment and run:
Preserved exact state:
Observed external effects:
Provisional files, commits, artifacts, and evidence:
Claims released:
Claims requiring cleanup or transfer:
Open processes and cleanup:
Unresolved risks:
Replacement authority required:
```

## Task result assessment

```text
Disposition: accepted | rejected | superseded | provisional
Returned result:
Accountable assessor:
Exact state assessed:
Criteria and evidence:
Reviewer A report:
Reviewer B report:
Accepting-lead moderation report:
Negative cases and consumers:
Limitations accepted or blocking:
Integration permission:
Decision record:
```

`provisional` records preserved or returned work that has not received accountable acceptance. The underlying result record remains `returned` until an assessment changes its disposition.

## Feature or Workstream acceptance

```text
Planning node:
Decision: accepted | rejected | revision_required
Accountable lead:
Exact integrated state:
Outcome assessed:
Supporting delivery checkpoints:
Reviewer A model, revision, and report:
Reviewer B model, revision, and report:
Validation:
Accepting-lead moderation report:
Project Steward pre-push Society-of-Thought report, if remote-ready:
Cross-node dependencies or coherence:
Open risks and disposition:
Decision record:
```

## Milestone handoff

```text
Milestone:
Engineering Lead:
Exact integrated state and ancestry:
Delivery forecast and confidence:
Accepted Task results:
Feature acceptance records:
Workstream acceptance records:
Delivery checkpoints and evidence:
Reviewer A model, revision, and report:
Reviewer B model, revision, and report:
Validation:
Accepting-lead moderation report:
Project Steward pre-push Society-of-Thought report, if remote-ready:
Unresolved risks, deferrals, and decisions:
Remote state and remaining approvals:
Progress projection cursor and freshness:
Recommended Milestone decision:
Next planning questions:
```

## Progress dashboard projection

```text
Project and Milestone:
Projection generated at:
Ledger cursor or source revision:
Accepted previous outcome:
Current planning and execution state:
Next gate:
Health and evidence freshness:
Active assignments and activation state:
Checkpoint graph:
Feature and Workstream acceptance:
Blockers, risks, and decisions:
Remote state:
```

The dashboard is regenerated from durable planning and evidence state. Human edits belong in authoritative commands or decisions, not in the projection.

## Independent reviewer report

```text
Status: pass | fail | blocked
Reviewer: reviewer_a | reviewer_b | auxiliary_specialist
Reviewer session or run:
Assigned model ID and dispatch record:
Observed provider model ID, if independently available:
Implementer or author model ID:
Model-distinctness exception:
Independence statement and claims:
Wall-clock deadline:
Replacement run, if any:
Reviewed immutable revision:
Manifest or integrity verification:
Checkpoint and fixed point:
Review plan identity and revision:
Coverage fingerprint:
Perspectives covered:
Specialists covered:
Separately attributable Specialist outputs, participant identities, and model IDs:
Type-safety applicability: required | not_applicable | applicable_unavailable
Type-safety triggers:
Type-safety omission rationale:
Failed type-safety execution evidence:
Engineering Lead omission approval:
Residual type-safety risk:
Applicable Specialists omitted and rationale:
Authoritative requirements:
Scope reviewed:
Blocking findings:
Non-blocking findings:
Pre-1.0 defect candidates:
Evidence gaps:
Reviewed paths or artifacts:
Recommended next mode:
Submitted at:
```

This is the one Tennex reviewer output contract. It is a strict superset of the installed generic `reviewer` completion contract. Reviewer A and Reviewer B run as separate `paw-workflow:PAW-Review` sessions and submit this packet independently before either report is shared with the other. An auxiliary Specialist report is additional evidence and never replaces Reviewer A or Reviewer B.

## Dual-review acceptance register

```text
Substantive delegated deliverable:
Immutable revision:
Review plan identity and revision:
Implementer or author model ID:
Reviewer A session and model ID:
Reviewer A assignment and dispatch record:
Reviewer A status and report:
Reviewer B session and model ID:
Reviewer B assignment and dispatch record:
Reviewer B status and report:
Blind-review confirmation:
Reviewer A coverage fingerprint:
Reviewer B coverage fingerprint:
Coverage-fingerprint equality result:
Specialist-attribution confirmation:
Deadline and replacement disposition:
Author, Reviewer A, and Reviewer B pinned model IDs:
Pairwise model comparison result:
Distinct-model exception and approval:
Remediation revision, if any:
Final qualifying reports:
Accepting-lead moderation report:
Accountable acceptance decision:
```

## Accepting-lead moderation report

```text
Status: pass | fail | blocked
Acceptance scope: Task result | delivery checkpoint | Feature | Workstream | Milestone | remote readiness
Accepting role:
Moderator kind: qualifying_automated_model | direct_human
Human moderator role, when direct:
Automated moderator session or run:
Automated moderator assignment and dispatch record:
Automated moderator model ID:
Author or implementer model ID:
Reviewer A model ID:
Reviewer B model ID:
Pairwise moderator-model comparison result:
Reviewed immutable revision:
Review plan identity and revision:
Reviewer A report:
Reviewer B report:
Validation and integration evidence:
Perspective consensus and disagreements:
Specialist findings and dispositions:
Moderator decisions and rationale:
Unresolved risks:
Wall-clock deadline:
Replacement run and disposition:
Submitted at:
```

Every moderation that consumes independent reports uses this packet. An automated moderator differs from the author and both reviewers. When no qualifying automated model is available, the accepting lead moderates directly as a human. Missing model identities, failed pairwise comparison, unavailable human moderation, a second automated failure, or a late report makes the status `blocked`.

## Project Steward pre-push PAW Society-of-Thought report

```text
Status: pass | fail | blocked
Moderator and accepting role: Project Steward
Moderator kind: qualifying_automated_model | direct_human
Human moderator role, when direct:
Automated moderator session or run:
Automated moderator assignment and dispatch record:
Automated moderator model ID:
Author, Reviewer A, Reviewer B, and moderator pinned model IDs:
Pairwise moderator-model comparison result:
Reviewed immutable revision:
Review plan identity and revision:
Reviewer A report:
Reviewer B report:
Validation evidence:
Accepted scope and non-goals:
Final diff:
Perspective consensus and disagreements:
Participant model IDs:
Specialist lenses and model IDs:
Review Mode: society-of-thought
Review Specialists: all
Review Interaction Mode: parallel
Type-safety lens included:
Type-safety applicability and exception record:
Type-safety output identity and model ID:
Specialist findings and dispositions:
Moderator decisions and rationale:
Unresolved risks:
Remote-readiness decision:
Wall-clock deadline:
Replacement run and disposition:
Submitted at:
```

This packet is the additional remote-readiness specialization of the accepting-lead moderation contract. Select all discovered final-review Specialist lenses and include separately attributable type-safety output. The automated moderator model differs from the author and both foundational reviewers; otherwise the Project Steward moderates directly as a human. Missing identity or diversity evidence fails closed. The report is valid only for the exact revision, review coverage, and current validation/integration evidence it assessed.
