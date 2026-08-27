# Tennex Planning Templates

Use only the sections that add decision value. Every hierarchy record keeps a narrative and acceptance criteria. Replace bracketed prompts with concrete content and remove unused prompts.

This reference is the complete template authority for the installed or plugin Tennex planning skill. It is self-contained and requires no parallel repository template.

For every durable state, status, decision, result, and discriminant, use the exact lower-case `snake_case` token. Human-readable display labels are presentation only, not alternate durable values. Select one conditional variant and omit fields belonging to mutually exclusive variants.

## Canonical durable values

| Axis | Allowed values |
|---|---|
| Planning node | `draft`, `approved`, `active`, `acceptance_review`, `accepted`, `superseded`, `cancelled` |
| Project operation | `active`, `paused`, `retired` |
| Delivery health | `on_track`, `at_risk`, `blocked`, `unknown` |
| Delivery checkpoint | `draft`, `active`, `acceptance_review`, `accepted`, `superseded`, `cancelled` |
| Run | `registered`, `starting`, `running`, `waiting_for_input`, `blocked`, `idle`, `stopping`, `stopped`, `failed`, `recovery_required` |
| Activation packet | `ready`, `blocked` |
| Assignment authority | `prepared`, `authorized`, `active`, `fenced`, `completed`, `cancelled` |
| Worker result | `complete`, `partial`, `blocked`, `failed`, `fenced` |
| Result disposition | `returned`, `accepted`, `rejected`, `superseded`, `provisional` |
| Feature or Workstream acceptance decision | `accepted`, `rejected`, `revision_required` |
| Review plan | `draft`, `declared`, `bound`, `active`, `completed`, `superseded`, `cancelled` |
| Reviewer kind | `reviewer_a`, `reviewer_b`, `auxiliary_specialist` |
| Review or moderation report | `pass`, `fail`, `blocked` |
| Type-safety applicability | `required`, `not_applicable`, `applicable_unavailable` |
| Moderator kind | `qualifying_automated_model`, `direct_human` |
| Message delivery | `sent`, `persisted`, `delivered`, `observed`, `acknowledged`, `resolved`, `failed` |

Where the execution contract defines no closed value, record observable facts rather than inventing an enum. For example, dashboard freshness comes from cursor and timestamp evidence; a risk records its current condition and linked decisions rather than borrowing planning lifecycle values.
`acted_upon` is a separate linked event, not a message-delivery state.

## Project

```markdown
# Project: [Plain-language product name]

## Narrative

[Explain why this durable product exists, who it serves, and what authority boundary it creates.]

## Charter goals

- [Long-lived product outcome.]

## Required product capabilities

- The product must [high-level behavior meaningful across Milestones].

## Success outcomes and measures

| Outcome | Evaluation | Desired direction or threshold |
|---|---|---|
| [Long-term outcome] | [How it will be assessed] | [Target, trend, or qualitative boundary] |

## Scope

### Included

- [Durable product boundary.]

### Non-goals

- [Adjacent product or operating model intentionally excluded.]

<!-- Omit non-goals only when the boundary cannot reasonably be misunderstood. -->

## Authority and governance

- Project Steward: [role or durable identity]
- Human approval boundary: [charter, plan, remote action, merge, retirement, or other authority]
- Engineering planning authority: [role]
- QA independence rule: [rule]

## Constraints and assumptions

- Constraint: [fixed boundary]
- Assumption: [condition the plan relies on]

<!-- Omit assumptions that do not affect planning. -->

## Dependencies and relationships

- Depends on: [external capability or decision and why]
- Related to: [record without implying containment]

<!-- Omit when no material external dependency exists. -->

## Risks, decisions, and open questions

- Risk or blocker: [link]
- Accepted decision: [link]
- Open question: [question, owner, and decision deadline]

<!-- Omit empty categories. -->

## Charter acceptance criteria

- The human has approved the named Project Steward, authority policy, goals, and non-goals.
- Each success outcome has an evaluation method independent of implementation Tasks.
- The first approved Milestone fits the charter and constraints.

## Evaluation and evidence

- Approved charter revision: [link]
- Supporting research or decisions: [links]
- Baseline measures: [links, if available]

## Lifecycle

- Charter revision state: [`draft` or `approved`]
- Project operation state: [`active`, `paused`, or `retired`]
- Delivery health: [`on_track`, `at_risk`, `blocked`, or `unknown`; omit when not useful]

## Retirement semantics

[State who may retire the Project, which obligations must be addressed, and which durable records remain available.]
```

## Milestone

```markdown
# Milestone: [Observable target outcome]

Parent Project: [Project title or link]

## Narrative

[Explain the outcome, beneficiary, and why it matters now.]

## Expected completion window

- Approved target window: [date, range, or planning period]
- Current delivery forecast: [forecast]
- Forecast confidence: [high, medium, or low, with reason]

## Outcome scope

### Included

- [Capability or result.]

### Non-goals

- [Adjacent outcome explicitly deferred.]

## Required outcome behavior

- The system or delivery process must [Milestone-wide observable behavior].

## Outcome measures

| Measure | Evaluation | Target or threshold |
|---|---|---|
| [Measure] | [How it will be assessed] | [Boundary] |

<!-- Omit when acceptance criteria fully define the outcome. -->

## Acceptance criteria

- [Observable Milestone-wide result.]
- [Required negative, recovery, integration, or operating result.]
- [Explicit authority or evidence condition not inferred from Feature completion.]

## Evaluation and evidence plan

- Delivery checkpoints: [links or planned gates]
- Independent review set: [two fresh model-diverse reports on the same immutable revision]
- PAW Society-of-Thought remote-action gate: [required before any GitHub preflight, approval, push, or PR action]
- Validation: [system-level evaluation]
- Human attestation: [when judgment is required]

## Ownership and acceptance

- Project Steward: outcome and final acceptance.
- Engineering Lead: engineering plan, integration, and forecast.
- Independent QA: [evidence scope]
- Final acceptance authority: [named role or human]

## Dependencies and sequencing

- Prerequisite: [node or decision and unblock condition]
- Cross-Milestone dependency: [relationship and impact]

<!-- Omit when no material prerequisite exists beyond Project approval. -->

## Risks, decisions, and open questions

- Risk or blocker: [link]
- Accepted decision: [link]
- Open question: [question, owner, and deadline]

<!-- Omit empty categories. -->

## Progress dashboard projection

- Projection: [durable generated dashboard link]
- Source cursor: [event or projection position]
- Generated at: [timestamp]
- Source position observed at: [timestamp]
- Freshness evidence: [cursor comparison, missing source, or other observable basis]

Generate this dashboard from planning, dependency, acceptance, evidence, risk, and execution state. It is not a hand-edited source of truth.

## Lifecycle

- Lifecycle state: [`draft`, `approved`, `active`, `acceptance_review`, `accepted`, `superseded`, or `cancelled`]
- Delivery health: [`on_track`, `at_risk`, `blocked`, or `unknown`; omit for inactive records]
- Rationale: [evidence-based explanation]

## Exit and acceptance semantics

[State the required evidence, final assessor, and explicit acceptance act. Child completion cannot accept the Milestone.]
```

## Workstream

```markdown
# Workstream: [Stable coordination purpose]

Parent Milestone: [Milestone title or link]

## Narrative

[Explain why multiple Features need one lane and what must remain coherent across them.]

## Why this Workstream exists

- Included Features: [at least two links]
- Coordination boundary: [shared dependency, integration seam, ownership lane, or specialized purpose]
- Reason direct Milestone-to-Feature containment is insufficient: [explanation]

## Coordination and integration requirements

- The Engineering Lead must [cross-Feature obligation].
- Participating Feature owners must [shared contract or handoff].
- Integration must [observable coherence result].

## Scope and exclusions

- Coordinates: [related Feature scope]
- Does not own: [adjacent work or standalone value claim]

<!-- Omit exclusions when the boundary is unambiguous. -->

## Coherence evaluation

| Concern | Evaluation |
|---|---|
| Cross-Feature compatibility | [integration test, review, contract comparison, or observation] |
| Dependency flow | [how blocked handoffs are detected] |
| Evidence completeness | [how Feature evidence is reconciled] |

<!-- Keep only applicable concerns. -->

## Acceptance criteria

- The accountable lead has explicitly assessed the integrated result.
- Shared contracts and handoffs satisfy the coordination requirements.
- Remaining cross-Feature risks are resolved, accepted, or escalated.
- Acceptance is recorded independently of child Feature states.

## Evidence

- Cross-Feature review: [link]
- Integration result: [link]
- Supporting delivery checkpoints: [links]
- Independent review set: [link when the integrated deliverable is substantive]
- Workstream acceptance decision: [link]

## Ownership

- Accountable lead: Engineering Lead
- Delegated Feature Leads: [links and authority, if any]
- Independent QA scope: [evidence to assess]

## Dependencies and risks

- Internal dependency: [relationship and unblock condition]
- External dependency: [node, decision, or system]
- Risk or blocker: [link]

<!-- Omit empty categories. -->

## Lifecycle

- Lifecycle state: [`draft`, `approved`, `active`, `acceptance_review`, `accepted`, `superseded`, or `cancelled`]
- Delivery health: [`on_track`, `at_risk`, `blocked`, or `unknown`; omit for inactive records]

## Exit and acceptance semantics

[State how the Engineering Lead records a first-class Workstream acceptance decision. Child Feature state and delivery-checkpoint acceptance are supporting evidence, not Workstream acceptance.]
```

## Feature

```markdown
# Feature: [Observable capability]

Parent: [Milestone or Workstream title or link]

## Narrative

[Explain which user or stakeholder gains what capability and how success differs from the current state.]

## Scope

### Included behavior

- [Behavior within this Feature.]

### Non-goals

- [Related behavior intentionally excluded.]

<!-- Omit non-goals when the boundary is precise. -->

## Functional requirements

- The user or system must be able to [observable behavior].
- When [condition], the system must [observable result].
- The system must reject or surface [important invalid or failure condition].

## Acceptance criteria

- Given [starting condition], when [action], then [observable outcome].
- [Boundary, failure, persistence, recovery, or permission result.]
- The accountable Feature authority has reviewed the required evidence and recorded acceptance.

## Evaluation and evidence

| Criterion or concern | Evaluation | Required evidence |
|---|---|---|
| [Behavior] | [test, review, observation, or attestation] | [result, artifact, commit, or checkpoint] |

- Independent review set: [link when the Feature deliverable is substantive]
- Feature acceptance decision: [link]

## Ownership and delegated authority

- Accountable lead: [Engineering Lead or justified Feature Lead]
- Implementing team or agents: [assignments]
- Writable claims and integration boundary: [resources]
- Acceptance authority: [named role]

<!-- Omit detailed claims until assignment when they are not known. -->

## Dependencies and relationships

- Prerequisite: [node and unblock condition]
- Related Feature: [cross-reference and reason]
- Supporting delivery checkpoint: [link]

<!-- Omit empty categories. -->

## Assumptions, risks, decisions, and open questions

- Assumption: [planning condition]
- Risk or blocker: [link]
- Accepted decision: [link]
- Open question: [question and owner]

<!-- Omit empty categories. -->

## Lifecycle

- Lifecycle state: [`draft`, `approved`, `active`, `acceptance_review`, `accepted`, `superseded`, or `cancelled`]
- Delivery health: [`on_track`, `at_risk`, `blocked`, or `unknown`; omit for inactive records]

## Exit and acceptance semantics

[State who records the first-class Feature acceptance decision and which evidence is required. Task completion, result return, and delivery-checkpoint acceptance cannot accept the Feature.]
```

## Task

```markdown
# Task: [Bounded assignable action]

Parent Feature: [Feature title or link]

## Narrative

[State the action, expected output, and why the Feature needs it.]

## Bounded scope

- Produce or change: [specific output or resource]
- Preserve: [behavior or resource]
- Exclude: [likely scope expansion]

<!-- Omit Preserve or Exclude when scope is already unambiguous. -->

## Execution requirements

- The assignee must [concrete action or output property].
- The assignee must preserve [constraint or contract].
- The assignee must stop and escalate if [authority, correctness, or safety condition].

## Acceptance criteria

- The expected output exists in the named scope and satisfies [condition].
- The required targeted validation passes against the produced state.
- The assignee returns evidence, releases claims, and reports unresolved findings.

## Validation and evidence

- Required check or observation: [method]
- Evidence to return: [result, diff, artifact, commit, or finding]
- Exact state: [revision, artifact version, or run]
- Review classification: [Substantive, or Not substantive with recorded reason]
- Independent review set: [link when the Task deliverable is substantive]

## Assignment linkage

- Assignee: [agent or team]
- Assignment and execution trail: [link]
- Current authorized revision: [immutable revision]
- Planning acceptance decision: [link when decided]

## Dependencies and stop conditions

- Ready when: [prerequisite condition]
- Blocked by: [linked blocker, if active]
- Stop when: [completion, decision, approval, budget, or failure condition]

## Risks and open questions

- Risk: [task-specific uncertainty]
- Open question: [question]

<!-- Omit for routine Tasks with no material uncertainty. -->

## Lifecycle

- Lifecycle state: [`draft`, `approved`, `active`, `acceptance_review`, `accepted`, `superseded`, or `cancelled`]
- Delivery health: [`on_track`, `at_risk`, `blocked`, or `unknown`; omit for inactive records]

## Completion and acceptance semantics

[State who checks the returned result and records Task result disposition `accepted`, `rejected`, `superseded`, or `provisional`. A requested Task correction uses `rejected`, with blocking rationale, a next safe action, and replacement work or assignment. Run state and result return remain distinct from planning acceptance.]
```

## Delivery checkpoint

```markdown
# Delivery checkpoint: [Gate name]

## Purpose

[Explain which uncertainty this immutable gate removes and which planning nodes it supports.]

## Linked planning nodes

- [Node link and relationship]

## Frozen claims

| Observable claim | Required evidence | Pass/fail interpretation |
|---|---|---|
| [Claim] | [Evidence kind] | [Unambiguous result] |

## Independence and authority

- Checkpoint owner: [role]
- Evidence producer: [role or agent]
- Independent assessor: [when required]
- Acceptance authority: [named role]

## Immutable accepted state

- Revision, commit, or artifact version: [exact reference]
- Accepted evidence: [links]
- Acceptance decision: [link]

## State

[`draft`, `active`, `acceptance_review`, `accepted`, `superseded`, or `cancelled`]

Delivery checkpoints skip a separate `approved` state: accepting the frozen gate is the approval decision.

Checkpoint acceptance establishes the gate's evidence state. It does not accept a Workstream, Feature, or Task.
It is distinct from a Microsoft Agent Framework workflow checkpoint.

## Revision rule

[State which change requires a new checkpoint.]
```

## Planning acceptance decision

Choose the Task-result or integrated-node variant. Do not combine their durable fields.

### Task result assessment

```markdown
# Task result assessment: [Task result]

- Task: [link]
- Exact returned result: [immutable result identity]
- Accountable assessor: [Engineering Lead or delegated Feature Lead]
- Disposition: [`accepted`, `rejected`, `superseded`, or `provisional`]
- Acceptance criteria and evidence assessed: [links]
- Supporting delivery checkpoints: [links]
- Negative cases and affected consumers: [evidence]
- Decision record: [link]
- Decided at: [timestamp]

## `accepted` variant

- Independent reviewer reports: [Reviewer A and Reviewer B passing report links]
- Accepting-lead moderation: [passing moderation link]
- Integration permission: [granted scope]
- Accepted limitations and residual risk: [links; omit when none]

## `rejected` variant

- Blocking rationale: [unmet criteria or evidence]
- Integration permission: none
- Next safe action: [bounded follow-up]
- Replacement work or assignment: [authorized replacement work or assignment; required when correction is requested]

## `superseded` variant

- Replacement result identity: [immutable result]
- Integration permission: none

## `provisional` variant

- Preserved exact state: [source and artifact identity]
- Reason accountable assessment cannot complete: [evidence or authority gap]
- Integration permission: none
- Authority note: the underlying result remains `returned`.

Keep only the variant selected by `disposition`. This assessment is distinct from run completion, `result_returned`, and delivery-checkpoint acceptance.
```

### Feature or Workstream acceptance

```markdown
# Planning acceptance: [Feature or Workstream]

- Planning node: [link]
- Exact integrated state assessed: [immutable identity]
- Outcome assessed: [observable Feature or Workstream outcome]
- Supporting delivery checkpoints and evidence: [links]
- Accountable authority: [Engineering Lead or explicitly delegated Feature Lead]
- Decision: [`accepted`, `rejected`, or `revision_required`]
- Cross-node dependencies or coherence: [assessment and links]
- Open risks and disposition: [links]
- Decision record: [link]
- Decided at: [timestamp]

## `accepted` variant

- Acceptance criteria and validation assessed: [links]
- Independent reviewer reports: [Reviewer A and Reviewer B model, revision, and passing report links]
- Accepting-lead moderation: [passing moderation link]
- Project Steward pre-push Society-of-Thought: [passing report link when remote-ready; omit otherwise]
- Integration permission: [granted scope]
- Accepted limitations and residual risk: [links; omit when none]

## `rejected` variant

- Blocking rationale: [unmet criteria or evidence]
- Integration permission: none

## `revision_required` variant

- Gap requiring revision: [unmet criterion, evidence gap, or integration defect]
- Replacement work: [linked Task or assignment]
- Integration permission: none

Keep only the variant selected by `decision`. Planning acceptance is distinct from result return and delivery-checkpoint acceptance.
```

## Assignment and execution trail

```markdown
# Assignment: [Bounded delegated outcome]

## Authorized revision

- Task: [link]
- Revision: [immutable identifier]
- Authority status: [`prepared`, `authorized`, `active`, `fenced`, `completed`, or `cancelled`]
- Authorized by: [named authority]
- Outcome and acceptance criteria: [links or concise statement]
- Writable claims: [resources]
- Tools, budget, and stop conditions: [bounded authority]
- Microsoft package-mirror enforcement policy: [versioned link; required for dependency work]
- Remote mutation preflight and approval policy: [versioned link; required for remote effects]
- Supersedes: [prior revision, if any]
- Fence event for prior revision: [required for material replacement]

## Durable execution events

| Event | Durable reference | Required meaning |
|---|---|---|
| `assignment_authorized` | [link] | This exact revision received authority. |
| `dispatch_requested` | [link] | Delivery of this exact revision was requested. |
| `activation_observed` | [link] | The assignee observed it and entered run state `running` or `blocked`. |
| `work_observed` | [link] | Later activity proves execution continued under this revision. |
| `result_returned` | [link] | Status, artifacts, evidence, findings, claims, and next action were returned. |
| `result_accepted` or `result_rejected` | [link] | The accountable planning authority assessed the returned result. |

## Activation packet

- Status: [`ready` or `blocked`]

### `ready` variant

- Worker and run: [links]
- Assigned model ID and dispatch record: [identity and link]
- Assignment revision and execution-boundary policy revision: [immutable identities]
- Source identity and claims accepted: [identities]
- Stop conditions and first intended action: [bounded statement]
- Observed at: [timestamp]

### `blocked` variant

- Blocker: [observable condition]
- Assignment and dispatch attempted: [links]
- `activation_observed` event: omitted

Keep only the variant selected by `status`.

## Worker result

- Worker result status: [`complete`, `partial`, `blocked`, `failed`, or `fenced`]
- Result disposition: `returned`
- Exact source and artifact identity: [immutable identities]
- Assignment and run: [links]
- Author model ID: [dispatch-pinned model]
- Evidence, effects, cleanup, and released or retained claims: [links or concise record]

### Unresolved-result variant

Include when worker result status is `partial`, `blocked`, `failed`, or `fenced`.

- Unresolved reason: [observable condition]
- Next safe action: [bounded action]
- Authority note: this output remains non-authoritative until accountable assessment.

## Watchdog and revision rules

- Activation watchdog: [condition]
- Dispatch failure response: [retry, replace, or escalate]
- Material revision rule: fence prior authority and issue a complete replacement revision.

Queued corrections do not amend authority or prove observation. Broad automatic post-activation health reboot is deferred.
```

## Milestone progress dashboard projection

```markdown
# Milestone progress: [Milestone title]

- Milestone: [link]
- Approved target window: [window]
- Current forecast and confidence: [forecast]
- Lifecycle state: [`draft`, `approved`, `active`, `acceptance_review`, `accepted`, `superseded`, or `cancelled`]
- Delivery health: [`on_track`, `at_risk`, `blocked`, or `unknown`]
- Current acceptance gate: [linked checkpoint, review, or decision]
- Workstream and Feature summary: [generated summary without parent status inference]
- Active blockers and risks: [links]
- Current evidence and freshness basis: [links, source position, and observation timestamp]
- Next decisions or actions: [generated list]
- Source cursor: [event or projection position]
- Generated at: [timestamp]
- Source position observed at: [timestamp]
- Freshness evidence: [cursor comparison, missing source, or other observable basis]

Generate this projection from authoritative planning and evidence state. Refresh it at every Milestone boundary and before Milestone acceptance review.
```

## Independent review set

```markdown
# Independent review set: [Substantive delegated deliverable]

- Deliverable and planning nodes: [links]
- Author model ID: [model]
- Immutable revision: [commit, artifact hash, or revision]
- Revision manifest and derivation method: [files, hashes, ordering, and combined-revision algorithm]
- Reviewed scope: [included and excluded scope]

## Review Plan

- Review plan state: [`draft`, `declared`, `bound`, `active`, `completed`, `superseded`, or `cancelled`]
- Author model ID: [model]
- Planned reviewer model IDs: [two different models, both different from author when available]
- Accepting lead: [role or person]
- Reviewer deadline: 20 minutes wall-clock per reviewer
- Replacement allowance: at most one replacement per reviewer slot after failure or timeout
- Automated moderation deadline: 20 minutes wall-clock
- Automated moderation replacement allowance: at most one after failure or timeout

| Kind | Perspective or Specialist | Rationale | Evidence expected | Omission rationale |
|---|---|---|---|---|
| Perspective | [stakeholder or concern viewpoint] | [why it matters] | [evidence the reviewers should inspect] | [leave empty when included] |
| Specialist | [focused expert lens] | [risk or boundary it covers] | [evidence the reviewers should inspect] | [leave empty when included] |

## Type-safety applicability

- Applicability: [`required`, `not_applicable`, or `applicable_unavailable`]

### `required` variant

- Specialist execution ID: [separately attributable execution]
- Specialist model ID: [model]
- Specialist output: [link]

### `not_applicable` variant

- Structural no-trigger rationale: [why the deliverable touches no typed code, schema, trust boundary, public contract, durable state or event, API payload, or cross-process message]

### `applicable_unavailable` variant

- Failed-execution evidence: [link]
- Engineering Lead approval: [identity and timestamp]
- Residual risk: [specific unevaluated risk]
- Gate effect: this variant cannot support a passing type-safety assessment.

Keep only the variant selected by `applicability`.

## Required independent reports

| Reviewer kind | Model ID | Fresh and read-only | Deadline evidence | Declared coverage complete | Findings and evidence gaps | Status | Report |
|---|---|---|---|---|---|---|---|
| `reviewer_a` | [model distinct from reviewer B] | `true` | [start, completion, and within-bound result] | [all declared Perspectives and Specialists] | [summary] | [`pass`, `fail`, or `blocked`] | [link] |
| `reviewer_b` | [different model] | `true` | [start, completion, and within-bound result] | [same complete declared set] | [summary] | [`pass`, `fail`, or `blocked`] | [link] |

Both reports assess this exact revision independently. Deterministic validation does not count as a reviewer.
A reviewer status is `pass` only when required coverage is complete on the same immutable revision, no blockers or evidence gaps remain, and completion occurred within the deadline. A late pass is non-qualifying. Exhausting the one replacement for a slot requires status `blocked`.
Use `fail` when the artifact has a blocking finding. Use `blocked` when identity, coverage, tooling, or deadline requirements prevent a qualifying judgment.
Review-plan completion records that required reports finished; it does not imply moderation or planning acceptance.

## Reviewer report contract

Each linked reviewer or auxiliary-specialist report records:

- Status: [`pass`, `fail`, or `blocked`]
- Reviewer kind: [`reviewer_a`, `reviewer_b`, or `auxiliary_specialist`]
- Reviewer session or run and dispatch record: [links]
- Assigned model ID and observed provider model ID: [identities and any discrepancy]
- Author model ID and model-distinctness exception: [identity and link when applicable]
- Independence statement and claims: [read-only scope and no writable claims]
- Wall-clock deadline and replacement run: [timestamps and disposition]
- Reviewed immutable revision and integrity verification: [identity and method]
- Review Plan identity, revision, and coverage fingerprint: [identities]
- Perspectives and Specialists covered: [complete declared set]
- Separately attributable Specialist outputs, participant identities, and model IDs: [links]
- Type-safety applicability and selected variant evidence: [link to `required`, `not_applicable`, or `applicable_unavailable` record]
- Authoritative requirements and scope reviewed: [links and boundaries]
- Blocking findings, non-blocking findings, and evidence gaps: [separate lists]
- Reviewed paths or artifacts and submitted at: [manifest and timestamp]

## Specialist reviews

- Trigger: [domain risk, disagreement, low confidence, or evidence gap]
- Reviewer kind: `auxiliary_specialist`
- Specialist execution ID, model ID, scope, findings, evidence gaps, status, and output: [use `pass`, `fail`, or `blocked`; omit this section when no specialist is warranted]
- Specialist finding disposition: [linked accountable decision]

Each required Specialist uses a separately attributable execution and output. One invocation cannot count as both a foundational independent reviewer and a required Specialist.

## Accepting-lead moderation

- Acceptance scope: [Task result, delivery checkpoint, Feature, Workstream, Milestone, or remote readiness]
- Accepting lead: [role or person]
- Moderator kind: [`qualifying_automated_model` or `direct_human`]
- Author and reviewer model IDs: [author, reviewer 1, reviewer 2]
- Reviewed immutable revision: [identity]
- Review Plan identity and revision: [link]
- Reviewer A and Reviewer B reports: [links]
- Validation and integration evidence: [links]
- Moderation status: [`pass`, `fail`, or `blocked`]
- Consensus: [shared findings]
- Disagreements: [different conclusions and evidence; omit when none]
- Finding dispositions: [linked decision and rationale for each finding]
- Residual risk: [accepted risk and authority; omit when none]
- Submitted at: [timestamp]

### `qualifying_automated_model` variant

Include only when `moderator_kind=qualifying_automated_model`.

- Moderator session or run: [link]
- Moderator assignment and dispatch record: [link]
- Moderator model ID: [model]
- Pairwise diversity check: [moderator differs from author, reviewer A, and reviewer B]
- Deadline and replacement evidence: [within 20 minutes; at most one replacement after failure or timeout]

### `direct_human` variant

Include only when `moderator_kind=direct_human`.

- Human accepting role: [accepting lead identity]
- Automated moderator availability: [why no qualifying distinct model was available]
- Automated moderator fields: omitted

Missing or invalid fields, a late result, or a second automated failure for the selected moderator variant require `moderation_status=blocked`.

## Third-model-unavailable exception

Include this section only when one reviewer shares the author model.

- Author model ID: [model]
- Reviewer model IDs: [two models that differ from each other]
- Unavailable distinct-model capability: [model or provider class]
- Reason unavailable: [concrete limitation]
- Compensating specialist or evidence: [link; omit when none]
- Recorded by and at: [authority and timestamp]

## Review completion

- Review plan state: [`completed` after both required foundational reports and every separately attributable required Specialist output finish; otherwise the applicable review-plan token]
- Separation rule: Review Plan completion does not imply passing moderation or planning acceptance.
- Author-model distinctness: [Both reviewer models differ from the author model, or exception recorded]
- Acceptance rule: both required reviewer statuses and moderation status are `pass`, and every triggered specialist finding is resolved or explicitly accepted.
- Availability floor: if fewer than two distinct reviewer models are available, moderation or review status is `blocked`.
- Invalidation rule: a revision change invalidates both reports; a declared coverage change invalidates every affected review.
- Remediation rule: freeze the new revision and coverage declaration, re-check model availability, and have two fresh reviewers assess the same complete declared set.
- Integration-context refresh rule: target-branch rebases and dependency, toolchain, credential, mirror, or execution-environment changes leave artifact-review identity unchanged unless artifact content, reviewed diff meaning, authoritative requirements, or required coverage changes. Refresh affected validation and integration evidence and repeat every accepting-lead moderation whose inputs changed. Repeat both foundational reviews only when artifact content, reviewed diff meaning, authoritative requirements, or required coverage changed.
```

## PAW Society-of-Thought pre-push review

```markdown
# PAW Society-of-Thought review: [Deliverable]

- Deliverable and planning nodes: [links]
- Moderator: Project Steward
- Review mode: `society-of-thought`
- Review Specialists: all
- Review interaction mode: `parallel`
- Moderator kind: [`qualifying_automated_model` or `direct_human`]
- Author and reviewer model IDs: [author, reviewer 1, reviewer 2]
- Final immutable revision: [same revision passed by both independent reviewers]
- Independent review set: [link]
- Validation evidence: [links]
- Accepted scope and non-goals: [links]
- Complete final diff: [link]

## Final-review specialists

- Lens source: [PAW final-review specialist registry or workflow configuration]
- Lens set: all
- Required explicit lens: type safety
- Type-safety specialist execution and output identity: [link]
- Type-safety applicability and exception record: [link]
- Minimum lenses: correctness, security, type safety, testing and evidence, integration, and operability
- Not-applicable lenses: [lens and structural reason; omit when none]

| Specialist lens | Execution or output | Model ID | Position or findings |
|---|---|---|---|
| [lens] | [separately attributable link] | [model] | [summary] |

One foundational independent-review invocation cannot concurrently count as a required Specialist execution.

## Moderator variant

### `qualifying_automated_model`

- Moderator session or run: [link]
- Moderator assignment and dispatch record: [link]
- Moderator model ID: [model]
- Pairwise diversity check: [moderator differs from author, reviewer A, and reviewer B]
- Deadline and replacement evidence: [within 20 minutes; at most one replacement after failure or timeout]

### `direct_human`

- Human accepting role: Project Steward
- Automated moderator availability: [why no qualifying distinct model was available]
- Automated moderator fields: omitted

Keep only the variant selected by `moderator_kind`. Missing or invalid fields, a late result, or a second automated failure require gate status `blocked`.

## Moderated synthesis

- Consensus: [agreed conclusions]
- Disagreements: [positions and evidence]
- Moderator decisions: [decision and rationale]
- Unresolved risks: [links; omit when none]
- Participant model IDs: [all attributable participants]

## Gate state

- Status: [`pass`, `fail`, or `blocked`]
- Wall-clock deadline: 20 minutes for automated support
- Replacement run and disposition: [link; at most one after failure or timeout]
- Remote-readiness decision: [decision and rationale]
- Submitted at: [timestamp]
- Independent-review relationship: [consumes but does not replace both reports]
- Remote-action relationship: [must pass before GitHub preflight/approval/push/PR begins; does not grant approval]
- Invalidation rule: any artifact change invalidates this review and requires a new revision, two fresh independent reviews, and a new moderated review.
- Evidence refresh rule: a target-branch rebase or dependency, toolchain, credential, mirror, or execution-environment change leaves artifact-review identity unchanged unless artifact content, reviewed diff meaning, authoritative requirements, or required coverage changes. Refresh affected validation and integration evidence and repeat this Project Steward moderation and every other affected accepting-lead moderation. Repeat both foundational reviews only when artifact content, reviewed diff meaning, authoritative requirements, or required coverage changed.
```

## Evidence item

```markdown
# Evidence: [What this proof demonstrates]

- Supports: [criteria and planning-node links]
- Produced by: [person, agent, system, or check]
- Method: [reproducible command, review, observation, or attestation]
- Exact state: [commit, artifact version, environment, or run]
- Observed outcome: [factual result, finding, or measured value]
- Limitations: [what this does not prove; omit when none]
- Source: [durable link or artifact path]
- Recorded at: [timestamp]
```

## Decision

```markdown
# Decision: [Chosen direction]

## Question

[What required a decision?]

## Context and options

- [Relevant fact or constraint.]
- Option: [choice and tradeoff.]

## Decision and rationale

[State the chosen option and decisive reasons.]

## Consequences

- Enables: [result]
- Requires: [follow-up obligation]
- Defers or excludes: [tradeoff]

## Authority and history

- Decision authority: [named role or human]
- Applies to: [linked planning nodes]
- Decided at: [timestamp]
- Supersedes: [prior decision, if any]
- Revisit trigger: [condition; omit for settled decisions]
```

## Risk or blocker

```markdown
# [Risk or Blocker]: [Concrete uncertain event or current impediment]

- Record kind: [`risk` or `blocker`]
- Affects: [linked planning nodes]
- Cause: [known source]
- Potential or current impact: [scope, quality, timing, authority, or recovery]
- Likelihood: [for a risk; omit for an active blocker]
- Severity presentation label: [low, medium, high, or critical, with reason; not a durable lifecycle or status]
- Owner: [role]
- Planned response: [plain-language response]
- Current condition: [observable facts]
- Trigger or unblock condition: [observable condition]
- Resolution decision and evidence: [links; omit until a disposition exists]
```
