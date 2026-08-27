# Tennex Execution Domain and States

Use this reference when assigning authority, selecting a lifecycle state, recording a transition, or checking whether two concepts have been conflated.

## Authority and responsibility

| Role | Durable responsibility | Acceptance authority |
|---|---|---|
| Project Steward | Charter, product scope, Milestone outcome, human relationship, final recommendation | Milestone final acceptance; human-owned gates remain human decisions |
| Engineering Lead | Technical decomposition, validation strategy, delivery forecast, Workstream and Feature integration, repository integration | Tasks by default, Features, Workstreams, technical adequacy of delivery checkpoints |
| Engineering worker | One bounded Task under delegated authority | None beyond self-report; returns a result for accountable assessment |
| Independent QA | Review and validation evidence across levels | None; reports findings and measured evidence |
| Feature Lead | Deferred until a real independent Feature integration boundary exists | Only the explicitly delegated Feature boundary |

Roles do not map one-to-one to Project, Milestone, Workstream, Feature, or Task nodes.

## Planning and linked records

Planning hierarchy:

`Project -> Milestone -> optional Workstream -> Feature -> Task`

Linked records, not hierarchy levels:

- delivery checkpoint;
- workflow checkpoint;
- assignment and assignment revision;
- review plan and review-plan revision;
- Perspective and Specialist coverage assignment;
- agent run;
- result;
- evidence item;
- acceptance decision;
- progress dashboard projection;
- pull request, commit, or artifact;
- risk, blocker, question, approval, or decision.

A delivery checkpoint is an immutable delivery gate. A Microsoft Agent Framework workflow checkpoint is a recoverable execution snapshot. Use the full terms.

A Perspective defines review questions from a stakeholder or concern viewpoint. A Specialist defines a focused expert lens. Neither creates acceptance authority.

## Planning-node lifecycle

Closed states:

- `draft`
- `approved`
- `active`
- `acceptance_review`
- `accepted`
- `superseded`
- `cancelled`

Project operation has a separate closed state:

- `active`
- `paused`
- `retired`

Project-operation transition evidence:

| Transition | Required evidence |
|---|---|
| active -> paused | Accountable pause decision, reason, and authority disposition |
| paused -> active | Resume decision, current authority, and refreshed readiness evidence |
| active or paused -> retired | Accountable retirement decision and final handoff |

Transition evidence:

| Transition | Required evidence |
|---|---|
| draft -> approved | Named scope, acceptance intent, dependencies, authority, and approval record |
| approved -> active | Ready prerequisites or explicit exception, plus active authorized assignment |
| active -> acceptance_review | Returned result or integrated outcome evidence |
| acceptance_review -> accepted | First-class accountable acceptance decision linked to exact evidence |
| acceptance_review -> active | First-class rejection or revision-required decision linked to exact evidence and replacement work |
| any nonterminal -> superseded | Replacement revision and impact record |
| any nonterminal -> cancelled | Authority decision and disposition of partial work |

No child state changes a parent state.

For a substantive delegated deliverable, `acceptance_review -> accepted` also requires two qualifying independent reviewer reports on the same immutable revision. Reviewer model IDs differ from each other and, when available, from the implementer model.

Acceptance decision values are:

- `accepted`
- `rejected`
- `revision_required`

## Delivery health

Closed values:

- `on_track`
- `at_risk`
- `blocked`
- `unknown`

Health is a projection over evidence and forecast. It is not a lifecycle state.

## Delivery-checkpoint state

Closed states:

- `draft`
- `active`
- `acceptance_review`
- `accepted`
- `superseded`
- `cancelled`

Acceptance freezes claims, evidence, pass/fail interpretation, authority, and exact state. It does not accept a planning node.

Transition evidence:

| Transition | Required evidence |
|---|---|
| draft -> active | Checkpoint contract, owner, claims, dependencies, and exact source state |
| active -> acceptance_review | Produced evidence and assessor assignment |
| acceptance_review -> accepted | Accountable checkpoint decision linked to frozen evidence |
| acceptance_review -> active | Rejection or revision-required decision and replacement work |
| any nonterminal -> superseded | Replacement checkpoint identity and impact record |
| any nonterminal -> cancelled | Accountable cancellation and evidence disposition |

`accepted`, `superseded`, and `cancelled` are terminal for that checkpoint identity. Changed claims or evidence create a new checkpoint revision.

## Run state

Closed states:

- `registered`
- `starting`
- `running`
- `waiting_for_input`
- `blocked`
- `idle`
- `stopping`
- `stopped`
- `failed`
- `recovery_required`

Process or session existence is evidence about a run, not its authoritative state.

Allowed run transitions:

- `registered -> starting | stopped | failed`
- `starting -> running | stopped | failed | recovery_required`
- `running -> waiting_for_input | blocked | idle | stopping | failed | recovery_required`
- `waiting_for_input -> running | stopping | failed | recovery_required`
- `blocked -> running | stopping | failed | recovery_required`
- `idle -> running | stopping | stopped`
- `stopping -> stopped | failed | recovery_required`

`stopped`, `failed`, and `recovery_required` are terminal for that run identity. Resume or recovery creates a new run.

## Explicit execution records

Record these durable events separately:

1. `assignment_authorized`
2. `dispatch_requested`
3. `activation_observed`
4. `work_observed`
5. `result_returned`
6. `result_accepted` or `result_rejected`

`result_accepted` is an accountable planning decision linked to the returned result. It is not a run state and is not inferred from a successful run.

Minimum event identity:

- Project, planning node, assignment, run, and agent identifiers;
- assignment and execution-boundary policy revisions;
- correlation and causation identifiers;
- exact source state when code or artifacts are involved;
- actor, timestamp, and supporting evidence.
- monotonic sequence within the assignment or aggregate.

## Assignment authority

Closed authority status:

- `prepared`
- `authorized`
- `active`
- `fenced`
- `completed`
- `cancelled`

Only one revision may be active for a claim at a time. Material changes fence the active revision and require a complete replacement assignment and run.

Allowed authority transitions:

- `prepared -> authorized | cancelled`
- `authorized -> active | fenced | cancelled`
- `active -> completed | fenced | cancelled`

`completed`, `fenced`, and `cancelled` are terminal for that assignment revision. No message or reboot can transition a fenced revision back to active.

## Message and action evidence

Per-recipient delivery evidence:

- `sent`
- `persisted`
- `delivered`
- `observed`
- `acknowledged`
- `resolved`
- `failed`

`acted_upon` is a separate execution event linked to the message and resulting command, assignment, decision, or effect. It is not implied by acknowledgment.

## Result disposition

Closed values:

- `returned`
- `accepted`
- `rejected`
- `superseded`
- `provisional`

Recovered files or commits default to `provisional` until a currently authorized assessor accepts them with exact-state evidence.

Worker result status is a separate closed set:

- `complete`
- `partial`
- `blocked`
- `failed`
- `fenced`

## Review contract vocabularies

Reviewer kind:

- `reviewer_a`
- `reviewer_b`
- `auxiliary_specialist`

Review report status:

- `pass`
- `fail`
- `blocked`

Activation packet status:

- `ready`
- `blocked`

Type-safety applicability:

- `required`
- `not_applicable`
- `applicable_unavailable`

`applicable_unavailable` requires failed-execution evidence, Engineering Lead approval, and residual risk. It is not a passing type-safety assessment.

Moderator kind:

- `qualifying_automated_model`
- `direct_human`

Moderation status:

- `pass`
- `fail`
- `blocked`

## Review-plan state

Closed states:

- `draft`
- `declared`
- `bound`
- `active`
- `completed`
- `superseded`
- `cancelled`

Required transitions:

| Transition | Required evidence |
|---|---|
| draft -> declared | Accepting lead, scope, Perspectives, Specialists, rationale, omissions, and evidence expectations |
| declared -> bound | Exact immutable artifact revision |
| bound -> active | Independent coverage assignments or an authorized specialist run |
| active -> completed | Required reports completed; completion does not imply acceptance |
| any nonterminal -> superseded | Replacement coverage or artifact revision and affected-run fencing |
| any nonterminal -> cancelled | Accountable cancellation decision and disposition of active or completed review evidence |

Durable review events:

- `review_plan_declared`
- `review_plan_bound`
- `review_coverage_assigned`
- `review_finding_recorded`
- `review_report_completed`
- `review_run_timed_out`
- `review_run_failed`
- `review_moderation_recorded`
- `review_plan_cancelled`
- `acceptance_decided`

## Type candidates for Tennex

The product should make these boundaries compiler checked:

- semantic IDs for Project, planning nodes, agents, assignments, runs, leases, approvals, results, messages, evidence, and checkpoints;
- discriminated unions for all closed states above;
- private or validated construction for assignment revision, authority lease, writable claim, exact Git state, and approval packet;
- an activation event that can only be created from an observed run pinned to the expected revisions;
- a result-acceptance command that requires a returned result, accountable authority, and exact evidence state;
- a substantive result-acceptance command that additionally requires the qualifying dual-review proof and a passing accepting-lead moderation proof;
- a dual-review proof that requires fresh distinct PAW reviewer identities, separate read-only sessions, no implementation claims, different model IDs, one immutable revision, identical declared coverage, separately attributable Specialist outputs, bounded deadlines, blind submission, qualifying reports, and an explicit Project Steward or human exception when a third distinct model is unavailable;
- a canonical coverage fingerprint over ordered Perspectives, Specialist mappings, questions, evidence expectations, and authoritative sources;
- an accepting-lead moderation proof that requires one immutable revision, both qualifying reports, current evidence, author and reviewer model IDs, either a dispatch-pinned automated moderator distinct from all three models or direct human moderation, pairwise comparison, bounded execution, dispositions, residual risks, and pass/fail;
- a claim-lease index that enforces at most one active assignment revision per writable claim;
- review-plan types that distinguish Perspectives from Specialists, require rationale and omission evidence, and bind identical coverage to both independent runs;
- a Project Steward pre-push Society-of-Thought proof that extends accepting-lead moderation with the same immutable revision, both qualifying reports, current validation and integration evidence, all discovered Specialist lenses plus separately attributable type-safety output, participant model IDs, disagreements, moderator decisions, unresolved risks, and pass/fail;
- validation-context identities that distinguish immutable artifact bytes from base, dependency, toolchain, credential, mirror, and execution-environment evidence;
- distinct delivery-checkpoint and workflow-checkpoint types;
- distinct message-delivery and acted-upon event types;
- progress projections carrying cursor and freshness;
- remote approval capabilities that encode authenticated identity, branch, SHA, base, remote ancestry and divergence, checks and protections, expiry, parameterized mutation commands, dual-review proof, validation-context proof, and moderated Society-of-Thought proof.

External payloads remain untrusted until parsed into these types.
