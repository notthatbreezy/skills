---
name: tennex-planning
description: Tennex planning and decomposition. Use when planning or reviewing Tennex product work, creating Project/Milestone/Workstream/Feature/Task artifacts, defining requirements, acceptance, evidence, or PAW review Perspectives and Specialists, or mapping external tracker items into Tennex semantics.
---

# Tennex Planning

Turn Tennex product intent into a thin, testable work graph:

`Project -> Milestone -> optional Workstream -> Feature -> Task`

Use the hierarchy to express purpose and value. Use graph edges and linked records for dependencies, evidence, decisions, risks, pull requests, and execution provenance.

## 1. Choose the invocation branch

Choose the narrowest branch that satisfies the request. Combine branches only when the output genuinely needs both.

- **Decompose:** turn product intent into a Project, Milestone, optional Workstreams, Features, and Tasks.
- **Create or review artifacts:** draft, repair, or assess one or more hierarchy records.
- **Define acceptance:** separate functional requirements, acceptance criteria, evaluation, and evidence for a named planning node.
- **Define review coverage:** declare PAW Perspectives and Specialists, evidence expectations, omissions, and moderation authority.
- **Map tracker items:** preserve external labels while assigning Tennex semantic roles.

**Complete when:** the branch, requested output, authoritative inputs, and unresolved authority decisions are explicit.

## 2. Establish the planning boundary

Identify:

- the durable Project and its charter or product intent;
- the target Milestone outcome and expected completion window;
- the user or stakeholder who observes value;
- included scope and likely non-goals;
- accepted constraints and decisions;
- the accountable acceptance authority.

Use confirmed facts. Mark missing decisions as open questions rather than inventing dates, owners, thresholds, or scope.

**Complete when:** a reader can state the target outcome, beneficiary, boundary, authority, and unknowns without reading implementation details.

## 3. Build the thinnest valid hierarchy

Classify each node by meaning, not size or tracker label.

| Level | Definition | Classification test |
|---|---|---|
| Project | Durable product and authority boundary. | Does the work share one charter, authority policy, and long-lived Project Steward? |
| Milestone | Target outcome with an expected completion window and explicit final acceptance. | Can you state the outcome, window, and evidence needed for acceptance? |
| Workstream | Optional Milestone-scoped delivery lane for coordinating multiple related Features. It need not deliver standalone user value. | Are there at least two Features and a real coordination, ownership, dependency, or integration boundary? |
| Feature | Independently understandable capability that delivers observable value to a user or stakeholder. | Can a stakeholder explain and accept the value without referring to implementation Tasks? |
| Task | Bounded assignable action required to deliver a Feature. | Can one agent or team complete it within explicit scope and return evidence? |

### Workstream omission test

Add a Workstream only when:

1. it groups at least two related Features;
2. it has a stable coordination purpose;
3. an accountable lead must manage shared dependencies, coherence, ownership, or integration.

Attach Features directly to the Milestone when any of these conditions is absent.

### Value-bearing Feature test

A Feature passes when:

- a user or stakeholder can observe the changed capability;
- its narrative remains meaningful without its Task list;
- it has explicit acceptance criteria;
- it is bounded enough for one accountable lead to integrate and assess.

Reclassify an implementation action with no standalone value as a Task.

### Bounded Task test

A Task passes when:

- one agent or team can own it;
- scope, writable claims, and preserved behavior are clear;
- expected output and required evidence are explicit;
- dependencies and stop conditions are known;
- the delegated assignment can pin one immutable authority revision and centralized execution-policy references.

Split a Task that spans independent outputs or conflicting claims. Promote work to a Feature when it carries independently acceptable stakeholder value.

**Complete when:** every node passes its level test, every Workstream passes the omission test, every Feature passes the value test, and every Task passes the bounded-action test.

## 4. Separate behavior, acceptance, evaluation, and evidence

Keep four meanings distinct:

- **Functional requirement:** what behavior or value is required.
- **Acceptance criterion:** what observable claim must be true for the accountable authority to accept the node.
- **Evaluation:** how confidence in the claim will be established.
- **Evidence:** the durable result or reference produced by that evaluation.

For every serialized state, status, decision, result, and discriminant, use the exact lower-case `snake_case` value from the Tennex execution contract. Human-readable display labels may map one-to-one to those tokens but are not alternate durable values. Use conditional variants for mutually exclusive shapes; do not create contradictory optional-field bags.

Example:

| Kind | Statement |
|---|---|
| Functional requirement | After a backend restart, the system must replay the complete ordered coordination history. |
| Acceptance criterion | Messages posted before a real process restart appear afterward in the same order, with no missing or duplicated entries. |
| Evaluation | Run the restart-and-replay scenario against a different backend process and independently assess the result. |
| Evidence | Test output and runtime observation linked to the exact accepted commit. |

Write one obligation or observable claim per item. Include negative, recovery, permission, and persistence behavior when they affect the outcome. A command is evaluation, not acceptance language.

For Workstreams and Features, record a first-class planning acceptance decision. Delivery-checkpoint acceptance may support that decision but cannot replace it. Run state and result return also remain separate from planning acceptance.

**Complete when:** every material behavior has an observable acceptance claim, every important claim has an evaluation method, and every evaluation names the evidence it must leave behind.

## 5. Plan independent review

Every substantive delegated deliverable requires two fresh independent read-only reviewer agents on the same immutable revision.

1. Freeze the deliverable revision before review.
2. Choose two reviewer model IDs that differ from each other.
3. When a third distinct model is available, choose both reviewer models to differ from the author model.
4. Start new reviewer-agent sessions with no prior exposure to the deliverable, the author's reasoning, or another review.
5. Create a durable **Review Plan** declaring required **Perspectives** and **Specialists**. A Perspective is a stakeholder or concern viewpoint across the whole change. A Specialist is a focused expert lens for a material risk or boundary. Record each one's rationale, evidence expectations, and any omission.
6. Require type safety by default for typed code, schemas, trust boundaries, public contracts, durable state or events, API payloads, and cross-process messages. When none applies, record the structural reason for omission. When a trigger applies but evaluation is unavailable, require explicit Engineering Lead approval and record residual risk.
7. Give both reviewers the same revision, scope, requirements, evidence, and complete declared Perspective and Specialist set without sharing either review with the other.
8. Require each report to identify model ID, revision, scope, coverage, findings, evidence gaps, and pass/fail.
9. Keep the deliverable review-pending until both reports pass.
10. Give each reviewer a 20-minute wall-clock deadline. A late pass is non-qualifying. Allow at most one replacement per reviewer slot after failure or timeout, then record `blocked` and fail closed.

Deterministic tests, linters, builds, validators, and artifact checks support the review but do not count as reviewer agents.

Treat a deliverable as substantive when it changes product behavior, contracts, persistence, authority, security, recovery, remote effects, or evidence integrity; integrates multiple contributions; or establishes a delivery checkpoint or other material acceptance basis. Recording planning acceptance alone does not make it substantive.

A bounded, reversible editorial or administrative change may be not substantive when it leaves those concerns unchanged. Record the classification and reason; do not infer it from missing review records.

Treat any deliverable intended for GitHub preflight, approval, push, or pull-request action as substantive for review-gate purposes. Use the not-substantive classification only for local-only work.

Add focused specialist reviewer models for material domain-specific risk, reviewer disagreement, low confidence, or evidence gaps. Common specialist triggers include security, migrations, concurrency, recovery, and user-interface behavior. Specialist models deepen a declared lens; they augment the required pair and do not replace the reviewers or acceptance authority.

Require every specialist report to identify execution ID, model ID, revision, scope, findings, evidence gaps, result, and output. One agent invocation cannot count concurrently as a foundational independent reviewer and a required Specialist execution. A PAW review workflow may orchestrate both roles, but each required Specialist remains separately attributable. Resolve each specialist finding or record explicit acceptance by the accountable authority before planning acceptance.

If no third distinct model is available, keep the two reviewer models distinct from each other and record a third-model-unavailable exception: author model ID, both reviewer model IDs, unavailable distinct-model capability, reason, compensating specialist or evidence, and recording authority and timestamp. This exception permits one reviewer to share the author model; it never reduces the required pair.

If fewer than two distinct reviewer models are available, review remains blocked; no exception reduces that floor.

After both reports return, have the accepting lead moderate the findings and record consensus, disagreements, disposition, and residual risk. When moderation is automated, its model must differ from the author model and both reviewer models; record all model IDs. If no distinct moderator model is available, the accepting lead moderates as a human rather than reusing a conflicted model. Give automated moderation a 20-minute wall-clock deadline and at most one replacement after failure or timeout; a late result or exhausted replacement records `blocked`.

Any revision change invalidates both reports. Any declared Perspective or Specialist coverage change invalidates every affected review. Freeze the new revision and coverage declaration, re-check model availability, then start two fresh reviewers under the same diversity rules. Mark the Review Plan `completed` when both foundational reports and every separately attributable required Specialist output finish; completion does not imply moderation or planning acceptance.

A target-branch rebase or dependency, toolchain, credential, mirror, or execution-environment change does not change the immutable artifact-review identity unless artifact content, reviewed diff meaning, authoritative requirements, or required coverage changes. Refresh affected validation and integration evidence and repeat every accepting-lead moderation whose evidence inputs changed. Repeat both foundational reviews only when artifact content, reviewed diff meaning, authoritative requirements, or required coverage changed.

**Complete when:** two fresh qualifying reports pass the same immutable revision and declared Review Plan, each report contains the required identity, scope, coverage, findings, and evidence-gap fields, each required Specialist has a separate execution and output, any specialist trigger or third-model-unavailable exception is recorded, and the accepting lead records the moderated disposition and residual risk.

## 6. Moderate the PAW Society-of-Thought pre-push review

For a deliverable that may reach GitHub, the Project Steward moderates a PAW Society-of-Thought review only after both independent reviewers pass the final immutable revision.

Provide the review with:

- both independent reports;
- validation and acceptance evidence;
- accepted scope and non-goals;
- the complete final diff.

Use all lenses from the PAW final-review specialist registry or workflow configuration. At minimum include correctness, security, type safety, testing and evidence, integration, and operability. Record any not-applicable lens with its reason. In PAW Society-of-Thought configuration, use `specialists: all` or explicitly include every minimum lens; adaptive selection alone does not guarantee type-safety coverage. Every required Specialist must have a separately attributable execution and output. Record specialist model IDs, consensus, disagreements, moderator decisions, and unresolved risks.

When an agent assists moderation, its model ID must differ from the author model and both independent reviewer models. Record all model IDs. If no distinct moderator model is available, the Project Steward moderates as a human rather than reusing a conflicted model. Give automated support a 20-minute wall-clock deadline and at most one replacement after failure or timeout; a late result or exhausted replacement records `blocked`.

Keep the gates distinct:

- independent reviews provide two separate judgments;
- the Society-of-Thought review provides the Project Steward's moderated synthesis;
- after it passes, remote preflight and human approval may authorize a remote effect.

No remote GitHub preflight, approval, push, or pull-request action may begin before the Society-of-Thought review passes. Any artifact change invalidates both the independent-review set and the Society-of-Thought result; freeze a new revision and repeat both gates.

A target-branch rebase or dependency, toolchain, credential, mirror, or execution-environment change leaves artifact-review identity unchanged unless artifact content, reviewed diff meaning, authoritative requirements, or required coverage changes. Refresh affected validation and integration evidence and repeat this Project Steward moderation and every other affected accepting-lead moderation. Repeat both foundational reviews only when artifact content, reviewed diff meaning, authoritative requirements, or required coverage changed.

Apply these gates prospectively to unaccepted deliverables and future pull requests. Do not reopen already accepted or merged work solely because the policy was adopted later; apply the current gates to any new change.

**Complete when:** the Project Steward records a passing all-lens moderated review on the same final revision as both independent passes, no artifact changes follow it, and remote work remains unopened until then.

## 7. Assign authority and graph relationships

### Default authority

| Level | Default accountability |
|---|---|
| Project | Project Steward owns direction, charter, authority policy, and the human relationship. |
| Milestone | Project Steward owns outcome and final acceptance; Engineering Lead owns engineering plan and delivery forecast. |
| Workstream | Engineering Lead owns cross-Feature coordination, dependencies, coherence, and integration. |
| Feature | Engineering Lead owns acceptance unless a real independent integration boundary justifies a delegated Feature Lead. |
| Task | Engineering agent or team executes within delegated scope and writable claims; the parent Feature's lead accepts the result. |

QA is independent and cross-cutting. QA designs or assesses evidence at any level without replacing accountable acceptance authority.
For material implementation validation, the QA assessor must not be the implementation author.

Feature Leads are deferred in Tennex v0. Retain Engineering Lead accountability unless planning a later phase with a real delegated integration boundary.

### Graph rules

- Give every non-Project node one primary containment parent.
- Allow a Feature to sit directly under a Milestone.
- Use prerequisite edges for readiness; prerequisite dependencies must remain acyclic.
- Use cross-references for relevance without implying containment, authority, or status.
- Attach evidence to every node it supports; evidence relationships may be many-to-many.
- Record acceptance explicitly at each level. Child completion never changes parent status automatically.
- Record Workstream and Feature acceptance as first-class decisions distinct from delivery-checkpoint state.
- Preserve revisions and rationale. Supersede accepted delivery checkpoints and decisions rather than mutating history.

### Linked records, not hierarchy levels

| Record | Correct relationship |
|---|---|
| Pull request | Evidence and delivery provenance linked to the affected planning nodes. |
| Delivery checkpoint | Immutable gate that freezes claims, required evidence, pass/fail interpretation, authority, and accepted state. CP0 and CP5 are examples. |
| Workflow checkpoint | Microsoft Agent Framework execution snapshot used for runtime recovery; it is neither a planning node nor a delivery gate. |
| Planning acceptance record | One closed variant: a Task result assessment with disposition `accepted`, `rejected`, `superseded`, or `provisional`; or a Feature or Workstream acceptance decision with value `accepted`, `rejected`, or `revision_required`. |
| Assignment and execution events | Versioned authority and observable dispatch, activation, work, result, and acceptance provenance linked to a Task. |
| Milestone progress projection | Generated dashboard linked to a Milestone with source cursor, timestamp, and freshness evidence. |
| Independent review set | Two fresh model-diverse read-only reports on one immutable revision, plus specialists or a third-model-unavailable exception when needed. |
| PAW Society-of-Thought review | Project Steward's all-lens moderated synthesis after both independent passes and before any remote GitHub action; includes type safety and does not grant remote approval. |
| Evidence item | Reproducible proof linked to criteria and exact state. |
| Decision | Durable rationale and authority linked to affected nodes. |
| Risk or blocker | Cross-cutting uncertainty or impediment linked without replacing lifecycle state. |
| Agent run | Execution provenance linked to its assignment or Task. |

Example graph:

```text
Milestone: Durable Coordination Spine
  Workstream: Durable coordination
    Feature: Replay immutable coordination history after restart
      Task: Implement cursor-paged replay endpoint

Linked:
  CP0 delivery checkpoint -> Feature and implementation Tasks
  CP5 delivery checkpoint -> Milestone
  Feature acceptance decision -> Feature
  Workstream acceptance decision -> Workstream
  generated progress projection -> Milestone
  independent review set -> substantive deliverable
  PAW Society-of-Thought review -> deliverable pull request
  accepted pull request -> Milestone and affected Features
  persistence decision -> Project, Milestone, and Feature
  restart-risk record -> Feature and Workstream
  agent run -> Task
```

**Complete when:** containment, dependency, evidence, cross-reference, and authority relationships are explicit; dependency cycles are absent; linked records have not been promoted into the hierarchy.

## 8. Plan execution authority and observability

For each delegated Task, keep one versioned assignment and six distinct durable events:

1. `assignment_authorized`;
2. `dispatch_requested`;
3. `activation_observed`;
4. `work_observed`;
5. `result_returned`;
6. `result_accepted` or `result_rejected`.

Treat each event as evidence of only its named transition. A requested Task correction records `result_rejected`; its Task result assessment uses disposition `rejected`, with blocking rationale and a next safe action, followed by replacement work or assignment. A queued correction does not prove observation. A running or completed agent run does not accept the Task.

Require an early dispatch watchdog for assignments that never reach observed activation. Keep broad automatic health-based reboot after activation deferred; use explicit observation, blocker, recovery, stop, and reboot controls.

When scope, authority, or policy changes materially:

1. fence the prior assignment revision;
2. authorize a replacement that pins the complete new revision;
3. dispatch and observe activation of the replacement.

Reference centralized, versioned execution-boundary policies from the assignment. Do not copy their prose into Tasks:

- Microsoft package-mirror enforcement applies at canonical dependency execution boundaries.
- Remote mutation requires centralized preflight and narrowly scoped human approval for the exact effect.

At every Milestone boundary, require a durable progress-dashboard projection generated from planning and evidence state. It must expose its source cursor, generated timestamp, freshness evidence, current gate, blockers, risks, and next decisions. Refresh it before Milestone acceptance review.

**Complete when:** every delegated Task has a pinned assignment revision, required policy references, observable activation path, revision-fencing rule, and separate result and planning-acceptance records; every Milestone has a fresh generated projection.

## 9. Map external tracker items semantically

Preserve the source system's type and title. Add a separate Tennex semantic role based on meaning.

| Source label | Possible Tennex role | Mapping rule |
|---|---|---|
| Epic | Milestone, Workstream, or Feature | Inspect whether it names an outcome window, a coordination lane, or stakeholder value. |
| Product backlog item or User Story | Feature or Task | Use Feature only when it carries independently understandable value. |
| Bug | Feature or Task | Use Feature when the correction restores observable stakeholder value; use Task for a bounded implementation action. |
| Task | Task, occasionally Feature | Keep as Task unless it actually describes independently acceptable capability. |
| Release or deliverable | Linked artifact, evidence, or future release bundle | Do not make it a hierarchy level merely because the source tracker does. |

Report uncertain mappings with the competing semantic tests and the decision needed.

**Complete when:** every mapped item retains its source type, has one justified Tennex role, and passes that role's classification test.

## 10. Write or review the artifacts

Read [`references/templates.md`](references/templates.md) when drafting or repairing concrete records. Skip it for taxonomy-only explanations and reviews that do not need rewritten artifacts.

Write plain English:

- use outcome-oriented titles instead of shorthand identifiers;
- keep narratives to two to five sentences, or one to three for a small Task;
- name the beneficiary and changed outcome;
- use concrete verbs such as "replays," "rejects," "shows," or "recovers";
- use "must" for functional requirements;
- write one observable claim per acceptance criterion;
- omit optional sections that would be empty or repetitive;
- keep implementation details in Tasks, constraints, or decisions unless they define required interoperability.

For a review, report the smallest correction that restores the hierarchy, authority, or evidence invariant. Preserve valid source wording where no correction is needed.

**Complete when:** each artifact is proportionate to its level, small work stays concise, required unknowns are visible, and a human or agent can execute or assess the next action without guessing.

## 11. Run the final consistency review

Check every applicable statement:

- [ ] The hierarchy is Project -> Milestone -> optional Workstream -> Feature -> Task.
- [ ] Each Workstream coordinates at least two Features across a real boundary.
- [ ] Each Feature delivers observable stakeholder value.
- [ ] Each Task is bounded, assignable, and evidence-producing.
- [ ] Functional requirements, acceptance criteria, evaluation, and evidence are distinct.
- [ ] Every acceptance decision has one named accountable authority.
- [ ] Workstream and Feature acceptance decisions are distinct from delivery-checkpoint acceptance.
- [ ] Every substantive delegated deliverable has two fresh independent read-only reports on the same immutable revision.
- [ ] Every not-substantive classification records why the change is bounded, reversible, and leaves material concerns unchanged.
- [ ] Every GitHub-bound deliverable is treated as substantive for the independent-review and Society-of-Thought gates.
- [ ] Reviewer models differ from each other and, when available, both differ from the author model.
- [ ] Required Perspectives and Specialists declare rationale, evidence expectations, and omissions.
- [ ] Type safety is included by default for typed code, schemas, trust boundaries, public contracts, durable state or events, API payloads, and cross-process messages.
- [ ] A type-safety omission records either the structural reason no trigger applies or Engineering Lead approval and residual risk.
- [ ] Both reviewers cover the same complete declared Perspective and Specialist set.
- [ ] Each report identifies model ID, revision, scope, coverage, findings, evidence gaps, and pass/fail.
- [ ] Deterministic tools support but do not replace the two reviewers.
- [ ] Remediation was re-assessed by both reviewers on the new revision.
- [ ] Specialist triggers and any third-model-unavailable exception are recorded.
- [ ] Every third-model-unavailable exception includes recording authority and timestamp.
- [ ] Every triggered specialist finding is resolved or explicitly accepted by the accountable authority.
- [ ] Every required Specialist has a separately attributable execution and output and is not one of the foundational reviewer invocations.
- [ ] The accepting lead records consensus, disagreements, finding dispositions, and residual risk.
- [ ] Any automated accepting-lead moderator differs from the author and both independent reviewer models; unavailable diversity uses human accepting-lead moderation.
- [ ] Fewer than two distinct reviewer models blocks review; remediation re-checks availability and uses two fresh reviewers.
- [ ] A GitHub-bound deliverable has a passing Project-Steward-moderated PAW Society-of-Thought review after both independent passes.
- [ ] The Society-of-Thought review consumed both reports, validation evidence, accepted scope, and the complete final diff.
- [ ] All final-review specialist lenses ran, including type safety, with model IDs and synthesis recorded.
- [ ] Any automated moderator model differs from the author and both independent reviewer models; unavailable diversity uses human Project Steward moderation.
- [ ] The lens source and minimum lenses are explicit; any not-applicable lens has a reason.
- [ ] Society-of-Thought review remains distinct from independent review and remote approval, and no remote preflight/approval/push/PR began before it passed.
- [ ] No artifact revision or declared review coverage changed after the final reviews; otherwise every affected review gate was repeated.
- [ ] Target-branch, dependency, or environment changes have refreshed validation and integration evidence even when artifact-review identity is unchanged.
- [ ] Already accepted or merged work was not reopened solely for prospective policy compliance.
- [ ] QA remains independent from acceptance authority and, for material implementation validation, from implementation authorship.
- [ ] Every non-Project node has one primary parent.
- [ ] Prerequisite dependencies are acyclic and name their unblock condition.
- [ ] Parent status is not inferred from child status.
- [ ] `assignment_authorized`, `dispatch_requested`, `activation_observed`, `work_observed`, `result_returned`, and `result_accepted | result_rejected` are distinct durable records.
- [ ] Material assignment or policy revisions fence prior authority; replacements pin the complete new revision.
- [ ] Early dispatch/activation watchdogs are explicit; broad automatic post-activation reboot remains deferred.
- [ ] Every Milestone boundary has a generated progress projection with a visible cursor and freshness evidence.
- [ ] Assignments reference centralized Microsoft mirror and remote mutation policies rather than duplicating them.
- [ ] Pull requests, delivery checkpoints, acceptance decisions, independent reviews, Society-of-Thought reviews, assignments, progress projections, evidence, decisions, risks, and agent runs remain linked records.
- [ ] Delivery checkpoints are distinct from workflow checkpoints.
- [ ] External tracker types are preserved separately from Tennex semantic roles.
- [ ] Optional sections with no decision value are omitted.
- [ ] Unresolved decisions are listed instead of silently assumed.

**Complete when:** every item passes or the output names the exact failing invariant, affected nodes, and decision or correction required.

## Output contract

Return:

1. the selected invocation branch;
2. the resulting or reviewed hierarchy and linked graph records;
3. explicit authority, dependencies, acceptance, evaluation, evidence, declared review Perspectives and Specialists, independent review set, PAW Society-of-Thought gate, assignment revisions, and policy references;
4. unresolved decisions;
5. Milestone dashboard projection requirements;
6. the final consistency-review result.
