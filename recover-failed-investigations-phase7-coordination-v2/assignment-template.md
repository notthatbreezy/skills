# Phase 7 v2 worker assignment

```text
Task ID:
Worker type:
Worker address:
Minimum model:
Assigned model:
Repository: C:\Projects\dbagent-recover-phase7
Branch: feature/recover-failed-investigations_phase7
Worktree: C:\Projects\dbagent-recover-phase7
Worktree role: integration
Integration owner: recover-failed-investigations-phase7-v2-worker-sol-integration-1
Workflow: paw-prs
Primary authority: C:\Projects\dbagent-recover-phase7\.paw\work\recover-failed-investigations\ImplementationPlan.md
Telex backend: local
Telex transport: local Copilot push bridge
Telex scope: recover-failed-investigations-phase7-v2
Source checkpoint or required file hashes:
Existing diff / handoff state:
Checkpoint transfer path: shared integrated worktree; validation and review begin only after claims release and source freeze

Objective:

Non-goals:

Authoritative state owner:

Exact file claims:
1.

Read-only supporting files:
1.

Required behavior:
1.

Failure, cancellation, crash, and restart behavior:
1.

Compatibility and D-150 classification:
1.

Acceptance criteria:
1. Exact invariants and negative cases:
2. Normal downstream consumer builds:
3. Generated artifacts and production source wiring:
4. Independent validation required:
5. Independent review required:
6. Substantive plans, design docs, workflow artifacts, and safety analysis reviewed independently:

Validation artifact provenance:
1. New checkpoint directory:
2. Pre-run UTC note, command, source hashes, and process identity:
3. Freshness checks for timestamps, run IDs, delivery IDs, PDB mapping, and hashes:
4. Teardown evidence:

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
- staging or commit by workers;
- push, PR, merge, reset, clean, or worktree removal;
- connected or destructive actions unless separately authorized.

Stop and escalate when:
1. The assigned model is below the worker type's capability floor.
2. A required file is unclaimed.
3. Source identity changes during a validation or review window.
4. Fresh artifact provenance cannot be proved.

Completion report:
- exact files changed or reviewed;
- worker type, minimum model, and assigned model;
- tests, builds, and checks with counts and duration;
- normal downstream consumer result;
- negative-case, compatibility, and source-wiring coverage;
- evidence paths, timestamps, run IDs, and hashes;
- cleanup and residue state;
- claims returned;
- remaining risks;
- staging, commit, push, connected mutations, and subagents: none.
```
