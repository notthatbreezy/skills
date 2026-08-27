# Review Plans, Perspectives, and Specialists

Use this reference before implementation dispatch, reviewer dispatch, review-plan revision, acceptance moderation, or the final pre-push Society-of-Thought gate.

## Concepts

### Perspective

A **Perspective** is a stakeholder or concern viewpoint that defines the questions and acceptance concerns used to assess an artifact.

Typical perspectives:

- Project Steward acceptance;
- Engineering Lead integration;
- operator and runtime;
- end user;
- maintainer.

A Perspective does not create a new acceptance authority. The accountable lead still decides.

### Specialist

A **Specialist** is a focused expert lens selected because the change crosses a relevant boundary.

Typical specialists:

- type safety;
- security;
- testing and validation;
- user experience and accessibility;
- data and durability;
- supply chain;
- operations.

Specialists produce findings and evidence. A Specialist lens, specialist agent, or specialist report does not replace an independent reviewer and does not become acceptance authority.

A single agent invocation cannot concurrently count as Reviewer A or Reviewer B and as a required Specialist. A PAW reviewer may orchestrate Specialist participants, but each Specialist output remains separately attributable by participant identity, model ID, scope, findings, and evidence gaps. Specialist participants never satisfy the two-reviewer count.

### Review plan

A **Review plan** declares the coverage every independent reviewer must execute.

```text
Review plan identity and revision:
Accepting lead:
Author or implementer model ID:
Planning nodes and delivery checkpoints:
Artifact scope:
Source or base revision:
Required Perspectives and their questions:
Required Specialists and their boundary rationale:
Normally applicable Specialists omitted and rationale:
Evidence expectations:
Reviewer independence and model-diversity requirements:
Reviewer wall-clock deadline and replacement budget:
Moderation authority:
Automated moderator model-diversity requirement:
Moderator wall-clock deadline and replacement budget:
Final pre-push Specialist requirement:
```

Declare the plan before implementation dispatch so assignments and evidence are shaped for review. Before reviewer dispatch, bind that plan revision to the exact immutable deliverable revision.

## Select risk-driven coverage

Choose coverage from the actual scope and failure modes.

For each Perspective:

1. name the stakeholder or concern;
2. state the questions it must answer;
3. identify which acceptance concerns it informs.

For each Specialist:

1. name the boundary that triggered it;
2. state the proof gaps or failure modes it must inspect;
3. identify required evidence.

Record why a normally applicable Specialist was omitted. Do not add a lens merely to complete a ceremonial list.

Additional Perspectives or Specialists may be added when findings expose new risk. A required coverage change creates a new review-plan revision, fences affected review runs, invalidates reports with incomplete coverage, and requires replacement runs.

## Type-safety default

Require the type-safety Specialist when work changes any of:

- typed production code;
- schemas or schema generation;
- parsing or trust boundaries;
- public contracts;
- durable events or state models;
- API payloads;
- cross-process messages.

The type-safety lens inspects:

- whether runtime assumptions can become compiler-checked types;
- external values trusted before parsing;
- contradictory optional fields or boolean state bags;
- non-exhaustive closed variants;
- unchecked casts, `Any`, non-null assertions, unsafe coercions, and impossible defaults;
- validation that returns no refined evidence;
- duplicated handwritten shapes that compete with an authoritative schema.

Omit this lens only under one of these conditions:

1. no trigger above applies, with structural rationale tied to the changed surfaces; or
2. the lens applies but cannot be executed, with explicit Engineering Lead approval, the failed execution evidence, and recorded residual risk for the accepting lead.

An applicable-but-impossible exception is not a passing type-safety assessment. It remains visible in moderation and may block acceptance.

## Bind and assign review coverage

Before Reviewer A or Reviewer B starts:

1. freeze the artifact revision;
2. bind the active review plan to that revision;
3. give both reviewers the same Perspectives, Specialists, questions, evidence expectations, and authoritative sources;
4. invoke separate fresh read-only `paw-workflow:PAW-Review` sessions with no implementation claims;
5. pin model IDs from the reviewer dispatch records and verify that A and B differ from each other and, when available, from the implementer;
6. configure each PAW run to produce separately attributable required Specialist outputs rather than treating the foundational reviewer as the Specialist;
7. give each reviewer a 20-minute wall-clock deadline and one replacement budget; a report submitted after its deadline is non-qualifying even if it says `pass`;
8. keep reports blind until both complete.

Each PAW reviewer executes the complete declared coverage independently. A Specialist is a lens inside that review; it never satisfies the second-independent-model requirement.

Configure each independent PAW ReviewContext with:

```text
Review Mode: society-of-thought
Review Specialists: <the explicit required Specialist set>
Review Interaction Mode: parallel
```

When the discovered PAW roster lacks a required Specialist, provide a separately attributable external Specialist report to that PAW run. Use `type-safety-reviewer` for required type-safety coverage when available.

Tennex Specialist names describe the required concern. PAW Specialist IDs select executable personas. Record the mapping when names differ so coverage remains native to Tennex without assuming a nonexistent PAW persona.

Compute one coverage fingerprint from the canonical ordered Perspectives, Specialist mappings, questions, evidence expectations, and authoritative-source identities. Encode the projection as UTF-8 lines in this order: `perspective`, `specialist`, `question`, `evidence`, then `source`; each line is `<kind><TAB><stable-id><TAB><normalized-value>`, values use LF for embedded line breaks, lines are sorted by kind order then stable ID using ordinal comparison, and the byte stream ends in one LF. The fingerprint is the lowercase SHA-256 of that byte stream. Bind the same projection and fingerprint into both reviewer assignments and compare exact equality in the dual-review register.

Do not poll a reviewer in a loop. Wait for its completion notification. When a reviewer fails, hangs, or exceeds 20 minutes:

1. stop that run;
2. record the failure or timeout;
3. launch at most one fresh replacement with a qualifying different model;
4. keep the other completed blind report undisclosed to the replacement;
5. retain partial findings as provisional evidence for the accepting lead but do not disclose them to the replacement;
6. reject any late report as non-qualifying;
7. mark the gate `blocked` when the replacement also fails or times out.

## Durable review records

Record these facts separately:

1. `review_plan_declared` — coverage, rationale, evidence expectations, accepting lead, and source revision;
2. `review_plan_bound` — plan revision bound to the exact immutable deliverable revision;
3. `review_coverage_assigned` — reviewer run, Perspectives, Specialists, model ID, and claims;
4. `review_finding_recorded` — finding, Perspective, Specialist, severity, evidence, and affected invariant;
5. `review_report_completed` — report identity, coverage completed, evidence gaps, and pass/fail;
6. `review_run_timed_out` or `review_run_failed` — run, deadline, observed failure, and replacement disposition;
7. `review_moderation_recorded` — acceptance scope, author and reviewer model IDs, moderator kind and model ID when automated, pairwise diversity result, consensus, disagreements, dispositions, moderator decisions, residual risks, deadline, replacement disposition, and pass/fail;
8. `acceptance_decided` — accountable acceptance decision linked to the preceding records.

Report completion is not acceptance. Moderation is not acceptance unless the same accountable command explicitly records the decision.

## Moderate findings

Every accountable acceptance decision that consumes independent reports requires its own accepting-lead moderation record before acceptance. This applies to Task result, delivery-checkpoint, Feature, Workstream, and Milestone decisions, not only remote readiness.

Before moderation starts:

1. record the author or implementer model ID and both dispatch-pinned reviewer model IDs;
2. choose `qualifying_automated_model` or `direct_human`;
3. for automated moderation, pin a moderator model ID that differs from the author and both reviewers and record all pairwise comparisons;
4. when no qualifying automated model is available, require the accepting lead to moderate directly as a human;
5. when neither a qualifying automated moderator nor direct human moderation is available, record `blocked` and stop acceptance;
6. give an automated moderation run and its required Specialist support a 20-minute wall-clock deadline and one replacement budget; reject a late report even when it says `pass`.

The accepting lead then:

- reconciles consensus and disagreement;
- disposes every blocking and material non-blocking finding;
- records residual risks;
- decides whether coverage must expand;
- records the final acceptance decision when authorized.

The moderation packet records the accepting role, moderator kind, automated moderator dispatch and model ID when present, author and reviewer model IDs, pairwise comparison, immutable revision, review plan, report identities, Perspective and Specialist dispositions, evidence inputs, deadline, replacement disposition, and pass/fail. Missing identity or diversity evidence fails closed. A moderator is neither a foundational reviewer nor a required Specialist.

For final pre-push review, the Engineering Lead stops after dual review and validation and returns the evidence to the Project Steward.

The Project Steward unconditionally moderates remote readiness as an additional gate. For an automated PAW moderation run, configure ReviewContext with:

```text
Review Mode: society-of-thought
Review Specialists: all
Review Interaction Mode: parallel
```

Explicitly add separately attributable `type-safety` output when the discovered Specialist roster does not contain it. Invoke the installed `type-safety-reviewer` agent for that output when available. A PAW participant or external Specialist report remains evidence consumed by the moderator and never becomes the moderator or an independent foundational reviewer.

Apply the same accepting-lead moderator identity, diversity, fail-closed, deadline, and replacement rules above. When no qualifying moderator model is available, the Project Steward moderates directly as a human; do not relax the model-diversity rule with another automated run.

Do not poll in a loop. A second failure or timeout blocks remote readiness and returns the evidence to the Project Steward. A late `pass` does not qualify.

Any artifact revision or required-coverage change invalidates affected reports and the Society-of-Thought result. Content changes freeze a replacement artifact revision. A pure coverage change creates a replacement review-plan revision that may bind to the same immutable artifact bytes. Dispatch two fresh reviewers in either case.

A rebase, dependency resolution change, toolchain change, credential or mirror change, or execution-environment shift may leave the immutable artifact hash unchanged while invalidating its integration context. Refresh affected validation and integration evidence. Repeat every affected accepting-lead moderation because its evidence inputs changed, including the Project Steward pre-push moderation when applicable. Repeat both independent reviews only when artifact content, reviewed diff meaning, authoritative requirements, or required coverage changed.
