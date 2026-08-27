# Generic worker assignment template

```text
Task ID:
Worker type:
Worker address:
Minimum model:
Assigned model:
Repository:
Branch:
Worktree:
Worktree role: <integration|implementation-lane>
Integration owner:
Workflow:
Primary authority:
Telex backend:
Telex transport:
Telex scope:
Existing diff / handoff state:
Checkpoint transfer path:

Objective:

Non-goals:

Authoritative state owner:

Exact file claims:
1.

Read-only supporting files:
1.

Required behavior:
1.

Failure and cancellation behavior:
1.

Acceptance criteria:
1. Exact invariants and negative cases:
2. Normal downstream consumer builds:
3. Generated artifacts / source wiring:
4. Independent review required:
5. Substantive plans, specifications, design docs, workflow artifacts, and safety analysis reviewed independently:

Safety boundaries:
1.

Required validation:
1.

Serialized resources:
1.

Claim-transfer behavior:
1. Stop, preserve the working-tree diff, return claims, and report unresolved work before rerouting.

Prohibited actions:
- subagents, factories, or delegation;
- edits outside claims;
- staging, commit, push, reset, clean, or worktree removal;
- connected or destructive actions unless separately authorized.

Stop and escalate when:
1. The assigned model is below the worker type's minimum capability.
2.

Completion report:
- exact files changed or reviewed;
- worker type, minimum model, and assigned model;
- tests/builds/checks with counts and duration;
- normal consumer-level build result, not package-local checks alone;
- negative-case and source-wiring coverage;
- safety and compatibility analysis;
- evidence paths and hashes;
- claims returned;
- remaining risks.
```
