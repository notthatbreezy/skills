---
name: paw-moderated-local-review
description: Run a local PAW Society-of-Thought pull-request review with plain-English human moderation, PAW feedback critique, editable pending GitHub comments, and authorization-only submission.
metadata:
  version: "0.1.0"
---

# PAW Moderated Local Review

Run this skill directly in the reviewer's main session. Do not launch the `PAW-Review` custom agent.
The operator moderates the findings and owns every disposition. GitHub receives an editable pending
review only after moderation and PAW comment critique finish.

## Required operating guides

Load these skills before their stages:

1. `reviewer`
2. `paw-review-workflow`
3. `paw-review-understanding`
4. `paw-review-baseline`
5. `paw-sot`
6. `paw-review-feedback`
7. `paw-review-critic`
8. `paw-review-github`

Load `writing-clearly-and-concisely` before drafting operator questions or external review text.
Load any repository-specific review or type-safety skill required by the change.

The main session runs discovery, fixed-point setup, understanding, baseline research, synthesis
verification, moderation, comment preparation, and GitHub lifecycle control. Delegate only the SoT
specialist reviews and any explicitly requested independent review.

## Inputs

Accept:

- pull-request URL or owner, repository, and number;
- reviewer identity;
- repository checkout or discovery location;
- specialist roster or selection rule;
- reviewer budget;
- specialist model assignments;
- review emphasis and scope exclusions;
- desired submission event, if known.

Defaults:

- review mode: local Society of Thought;
- interaction mode: parallel;
- human moderation: required;
- reviewer budget: at most three independent evaluators;
- perspectives: none unless requested;
- GitHub output: pending review;
- submission: forbidden until the operator explicitly authorizes it.

Count SoT specialists and additional independent reviewers against the reviewer budget. Do not count
the synthesis process as another reviewer. A practical three-reviewer roster is two relevant SoT
specialists plus one rubber-duck reviewer.

## Non-negotiable rules

1. Work in an isolated worktree. Leave the main checkout untouched.
2. Pin the exact base commit, head commit, repository, branch or pull-request ref, and diff.
3. Stop if the fixed point changes or the comparison base is ambiguous.
4. Run Understanding and Baseline Research in the main reviewer session.
5. Use the PAW artifact formats required by each activity skill.
6. Run SoT locally through `paw-sot`; do not delegate the entire PAW Review workflow.
7. Ground every finding in the current diff, surrounding code, authoritative requirements, and
   existing repository conventions.
8. Present one finding or tightly coupled finding cluster at a time.
9. Use plain English in operator dialogue and external review comments.
10. Never lead with shorthand finding IDs such as `SF1`, `C2`, or `M3`. Keep IDs only in local
    artifacts for traceability.
11. Create a pending GitHub review only after moderation, feedback generation, critique, critique
    response, and live anchor validation finish.
12. Never submit the pending review without a new, explicit operator authorization.

## Stage 1: Discovery and fixed point

Read repository instructions and the reviewer guide first.

If the implementation pull request is not available, enter Discovery mode and use the canonical
reviewer discovery loop from the active lifecycle guide. On Windows, use its bounded PowerShell wait
pattern. Do not busy-poll, invent a second loop, or begin against a moving branch.

When the pull request appears:

1. Fetch its head and generated merge ref when available.
2. Determine the authoritative base from the hosting service's merge relationship, not a possibly
   stale local default branch.
3. Create a detached worktree for the review.
4. Record the base and head commit hashes in `ReviewContext.md`.
5. Inspect the complete diff, including tests, generated files, manifests, lockfiles,
   documentation, migrations, and deletions.
6. Record included and excluded scope.

Do not edit reviewed source files. PAW review artifacts may live under
`.paw/reviews/<identifier>/`.

## Stage 2: Understanding and baseline research

Run these activities in the main session:

1. `paw-review-understanding` creates `ReviewContext.md` and `ResearchQuestions.md`.
2. `paw-review-baseline` creates `CodeResearch.md` against the pinned base.
3. Resume `paw-review-understanding` to create `DerivedSpec.md`.

Understanding and baseline artifacts document behavior. They do not evaluate quality or propose
fixes.

Before evaluation, verify that:

- `ReviewContext.md` names `society-of-thought` review mode;
- base and head commits match the worktree;
- `CodeResearch.md` describes the pre-change behavior;
- `DerivedSpec.md` states the intended change and scope boundaries.

## Stage 3: Local Society-of-Thought review

Load `paw-sot` in the main session and construct a diff review context:

| Field | Value |
|---|---|
| `type` | `diff` |
| `coordinates` | pinned base-to-head diff plus Understanding and Baseline artifact paths |
| `output_dir` | `.paw/reviews/<identifier>/` |
| `interaction_mode` | `parallel` unless the operator requested debate |
| `interactive` | `true` |
| `specialists` | explicit relevant roster within the reviewer budget |
| `specialist_models` | operator-specified assignments |
| `perspectives` | operator-specified value, otherwise `none` |

Each specialist prompt must:

- include the operator's review emphasis and scope exclusions;
- require current file and line evidence;
- distinguish a demonstrated defect from a risk, missing test, misleading claim, or maintenance
  concern;
- inspect repository conventions before proposing a new mechanism;
- use proportional severity and state rebuttal conditions;
- avoid shorthand in any prose intended for the operator or pull-request author.

Only pin models for the specialists the operator named. Do not silently apply the same model to an
independent rubber-duck reviewer.

After specialist work completes, synthesize it into `REVIEW-SYNTHESIS.md`. Synthesis may merge,
deduplicate, classify disagreement, and assess grounding. It must not invent findings.

## Stage 4: Verify before moderation

Before presenting a synthesized finding:

1. Read the originating specialist evidence.
2. Verify the relevant diff and surrounding code.
3. Check the authoritative specification, issue, plan, or acceptance criteria.
4. Search for the existing project pattern that handles the same concern.
5. Identify whether the pull request introduced the issue, exposed it, amplified it, merely omitted
   coverage, or is unrelated.
6. Identify evidence that would rebut or narrow the finding.

Reject unsupported findings before they reach the operator.

Apply any operator-provided scope rule exactly. For example, process labels such as wave, sprint,
phase, milestone, initiative, or ticket names warrant review only when they are embedded in durable
artifacts or when maintained design or operations guidance uses them as lasting architecture.

## Stage 5: Plain-English moderator loop

Moderate one finding or tightly coupled cluster at a time. Do not display a findings dump.

Present these sections in this order.

### Finding

State what the code or artifact does and what can go wrong in one or two plain-English sentences.
Say whether the issue is demonstrated or theoretical. Put any local trace ID at the end, if it must
appear at all.

### Context and practical impact

Explain:

- who or what encounters the behavior;
- prerequisites;
- likely frequency;
- blast radius;
- concrete effect;
- controls that reduce the risk.

Use proportional language. A missing assertion, misleading document, large artifact, or local tool
failure is not automatically a production defect or exploit.

### Provenance

State whether the pull request:

- introduced the problem;
- exposed or amplified a pre-existing problem;
- omitted coverage for existing behavior; or
- is unrelated and should be deferred.

Name the changed boundary.

### Existing project convention

Cite the files, helpers, schemas, validators, or documentation rules the repository already uses.
Prefer extending an established pattern. If none exists, say so.

### Options

Present only realistic options. For each option, assess:

| Dimension | Required information |
|---|---|
| Complexity | Small, moderate, or large; name affected boundaries |
| Success likelihood | Probability that it resolves the demonstrated problem |
| Residual risk | What remains afterward |
| Compatibility | Effect on callers, schemas, APIs, or saved artifacts |
| Validation | Exact evidence that proves the correction |
| Convention fit | Alignment with repository or established engineering practice |
| Delivery impact | Fix now, narrow now, or safe to defer |

Do not manufacture alternatives when one bounded correction is clearly required.

### Recommendation

Recommend one:

- **Fix now**
- **Narrow fix now**
- **Defer with explicit follow-up**
- **Reject the finding**

Explain why the recommendation fits the evidence and delivery target.

### Operator decision

Use `ask_user` for one focused decision. Put the recommended option first and label it
`(Recommended)`. Do not present the next finding until the operator decides.

Record each decision in `REVIEW-SYNTHESIS.md` without deleting the original finding:

```text
Finding:
Disposition:
Plain-English rationale:
Introduced by this change:
Existing project convention:
Chosen approach:
Complexity:
Expected success:
Tradeoffs:
Validation:
Owner/checkpoint:
```

When the operator accepts the finding but delegates the implementation choice, record the required
outcome, the named owner, and the acceptable solution envelope. Do not invent a design decision on
the owner's behalf.

Moderation ends only when every actionable finding has a durable disposition and every deferred
item has an owner or promotion condition.

## Stage 6: PAW feedback and critique

After moderation:

1. Load `paw-review-feedback` and generate `ReviewComments.md`.
2. Convert only accepted or explicitly retained findings into comments.
3. Batch comments by root cause.
4. Use inline comments for actionable issues with reliable changed-line anchors.
5. Use the review body for cross-cutting findings and findings without a reliable anchor.
6. Load `paw-review-critic` and assess usefulness, accuracy, alternatives, and tradeoffs.
7. Load `paw-review-feedback` again in Critique Response Mode.
8. Mark every comment ready or skipped and finalize the artifact.

External comments contain only author-facing feedback and suggestions. Never post:

- PAW artifact names;
- specialist or model names;
- internal finding IDs;
- rationale sections;
- critic assessments;
- moderation records;
- `Final` or `Posted` markers.

Write comments in direct, constructive prose. Explain the behavior and requested outcome before
implementation detail.

## Stage 7: Validate live anchors

Immediately before GitHub posting:

1. Fetch the live pull-request head.
2. Confirm it equals the reviewed head.
3. Validate every inline path, side, start line, and end line against the live diff.
4. Narrow ranges that include unchanged context.
5. Move an unanchorable finding to the review body.
6. Stop and re-review affected areas if the head changed.

Do not choose a body-only review merely because anchor validation has not been attempted.

## Stage 8: Create an editable pending review

Load `paw-review-github`.

Create one pending review on the reviewed commit:

- omit the submission event;
- add only comments marked ready;
- preserve skipped comments locally;
- include a concise review body;
- verify the review state is `PENDING`;
- verify every comment belongs to that pending review;
- record the review ID and comment IDs in `ReviewComments.md`.

If GitHub's global comment endpoint hides pending comments, verify through the review-specific
comments endpoint. GitHub may represent pending anchors by diff position and report line fields as
null until submission; confirm the diff hunk and commit instead.

Never create a second pending review merely because verification used the wrong endpoint. Inspect
the existing review first.

Create `GitHubReviewBody.md` beside the PAW artifacts when the operator wants to edit the main body
locally. Open that file in the requested editor. Explain that local edits do not update GitHub
automatically.

Stop after pending-review creation. Tell the operator:

- the pending review URL;
- the review ID;
- how many comments were posted;
- that the pull-request author cannot see the review until submission;
- that edits may be made directly on GitHub.

## Stage 9: Authorization-only submission

Treat submission as a separate action in a later operator turn.

Valid authorization names the existing pending review or makes it unambiguous and specifies the
event:

- `REQUEST_CHANGES`
- `COMMENT`
- `APPROVE`

If the event is unclear, ask one focused `ask_user` question. Never infer `APPROVE`.

Before submission:

1. Read the existing pending review.
2. Record its review ID, state, and comment ID set.
3. Confirm the state is `PENDING`.

Submit the existing review through its events endpoint. Send only the event:

```json
{"event":"REQUEST_CHANGES"}
```

Do not send the review body or any comment body during submission. This preserves edits the operator
made directly on GitHub.

After submission:

1. Read the same review again.
2. Confirm the expected final state.
3. Confirm the comment ID set and count are unchanged.
4. Update `ReviewComments.md` with the submitted state.

Never recreate the review, repost comments, or overwrite GitHub edits during submission.

## Completion states

### Pending

Report:

- artifact directory;
- pending review URL and ID;
- posted and skipped comment counts;
- live head commit;
- next human action: edit the pending review.

### Submitted

Report:

- review URL and ID;
- submitted event and resulting state;
- whether the existing comment records were preserved.

### Blocked

State the exact blocker:

- missing or changing pull request;
- ambiguous base;
- missing PAW artifact;
- reviewer budget violation;
- invalid anchor;
- GitHub permission failure;
- missing explicit submission authorization.

Do not claim completion while any required state remains unverified.
