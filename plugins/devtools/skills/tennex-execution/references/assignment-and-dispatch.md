# Assignment and Dispatch Protocol

Use this reference before authorizing, dispatching, revising, recovering, or transferring a Tennex assignment.

## Complete assignment

Every assignment revision contains:

```text
Assignment identity and revision:
Project, Milestone, Workstream, Feature, Task, and delivery checkpoint:
Assignee and supervisor:
Assigned model ID and dispatch provenance:
Outcome:
Delivery target and supported path:
Exact source state:
Writable claims:
Preserved resources and behavior:
Allowed tools and actions:
Required skills and exact fallback SKILL.md paths:
Execution-boundary policy revision:
Dependencies and ready condition:
Acceptance criteria:
Required evaluation and evidence:
Budget and lifetime:
Activation deadline, retry count, and backoff:
Stop conditions:
Approval boundaries:
Sub-delegation policy:
Expected result packet:
Review plan identity and required coverage:
First-turn activation handshake: before tool use or effects, return the Activation packet naming this assignment revision, policy revision, source identity, claims, and stop conditions.
```

The revision is complete on its own. A worker must not reconstruct authority from a base assignment plus queued corrections. Stop before dispatch when the activation deadline, retry count, or backoff is absent.

## Authorization and dispatch

1. Verify the supervisor possesses every delegated capability.
2. Verify claims do not overlap another active writer or state owner.
3. Persist the assignment revision and record `assignment_authorized`.
4. Create the worker surface.
5. Deliver the complete kickoff and record `dispatch_requested`.
6. Require the kickoff itself to tell the worker to reply, before tool use or effects, with:
   - worker and run identity;
   - assigned model ID echoed from the dispatch record;
   - assignment revision;
   - execution-boundary policy revision;
   - exact source state;
   - accepted claims and stop conditions;
   - first intended action or explicit blocker.
7. Record `activation_observed` only after observing that reply in an executing turn.
8. Record `work_observed` only after a concrete tool, source, artifact, or status signal shows work or a typed blocker.

## Dispatch watchdog

The supervisor starts a watchdog at `dispatch_requested`.

The watchdog tracks:

- activation deadline;
- most recent observed worker event;
- run and session/process identity;
- assignment and policy revisions expected;
- retry count and budget;
- current disposition.

Closed dispositions:

- `awaiting_activation`
- `activated`
- `activation_failed`
- `activation_expired`
- `cancelled`

On expiry or mismatch:

1. inspect the worker/session state;
2. fence any possibly issued authority;
3. stop or cancel the inactive or mismatched run;
4. retry with a complete assignment or escalate;
5. record watchdog disposition `activation_expired` or `activation_failed`, set delivery health to `blocked`, and leave the Task planning node `approved` unless an accountable planning decision changes it.

The early model includes dispatch and activation supervision. Broad post-activation health heuristics and automatic reboot remain deferred.

The dispatcher pins model identity from the session or agent creation configuration. The assignee echoes that value; it does not need to discover provider metadata in-band. The supervisor records model-diversity comparisons from dispatch records.

## Material revision

A change is material when it affects:

- outcome, scope, or acceptance criteria;
- writable claims or protected resources;
- allowed tools or remote effects;
- budget, lifetime, or stop conditions;
- approval or sub-delegation policy;
- package mirror, lifecycle script, credential, security, or other execution-boundary policy.

Revision procedure:

1. record the reason and affected invariants;
2. fence the current assignment and authority lease;
3. ask the worker to stop at the next safe boundary;
4. preserve the current worktree, processes, artifacts, and evidence;
5. record claims released or still requiring cleanup;
6. issue a complete replacement assignment with a new revision;
7. start a replacement run pinned to the new revision;
8. repeat dispatch and activation observation.

Message delivery, observation, or acknowledgment never reactivates fenced authority.

## Recovery and transfer

Recovery preserves:

- exact source state;
- partial files, commits, artifacts, and command output;
- observed external effects;
- open processes and cleanup needs;
- findings, blockers, and limitations.

Recovery does not preserve:

- an expired or fenced authority lease;
- assignment completion;
- evidence acceptance;
- planning-node acceptance.

A replacement assignee receives the original outcome, complete replacement assignment, preserved state, unresolved risks, and explicit claim transfer. It revalidates inherited work before use.

A reboot keeps the current assignment authority but creates a new run. The replacement run repeats the activation handshake and produces a new `activation_observed` event before authoritative work resumes.
