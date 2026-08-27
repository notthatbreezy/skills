# Phase 7 worker assignment

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
Integration owner: recover-failed-investigations-phase7-worker-sol-integration-1
Workflow: paw-prs
Primary authority: C:\Projects\dbagent-recover-phase7\.paw\work\recover-failed-investigations\ImplementationPlan.md, Phase 7
Workflow context: C:\Projects\dbagent-recover-phase7\.paw\work\recover-failed-investigations\WorkflowContext.md
Telex backend: local
Telex transport: local Copilot push bridge
Telex scope: recover-failed-investigations-phase7
Required address prefix: recover-failed-investigations-phase7-
Existing diff / handoff state:
Checkpoint transfer path:

Objective:

Non-goals:

Authoritative state owner:

Frozen Phase 6 contracts:
1.

Domain invariants:
1.

Exact file claims:
1.

Read-only supporting files:
1.

Required behavior:
1.

Failure, cancellation, restart, and recovery behavior:
1.

Acceptance criteria:
1. Exact crash/restart boundaries and negative cases:
2. Stable identity, one Run, one allowance, no overlap:
3. Audit-before-projection and deterministic convergence:
4. Frozen Phase 6 API/MCP contract consumption:
5. Production source wiring and normal downstream builds:
6. Infrastructure cleanup and teardown:
7. Independent validation:
8. Independent review:

Safety boundaries:
1. Local source edits and local validation only.
2. No deployment, migration, production access, credentials, connected measurements, or promotion.
3. Preserve durable 202, closed recovery models, authoritative stageNumber, and exact Phase 6 contracts.

Required validation:
1.

Serialized resources:
1.

Claim-transfer behavior:
1. Stop, preserve the working-tree diff, return claims, and report unresolved work before rerouting.

Prohibited actions:
- subagents, factories, fleets, or delegation;
- attachment to another Telex scope or use of an address outside recover-failed-investigations-phase7-;
- edits outside claims or edits in read-only roles;
- staging, commit, push, reset, clean, checkout, or worktree removal;
- connected or destructive actions unless separately authorized;
- assertion weakening, skipped required tests, success-shaped partial evidence, or silent fallback.

Stop and escalate when:
1. The assigned model is below the worker type's minimum capability.
2. The root cause crosses an unclaimed state owner or file.
3. Stored-schema evolution lacks D-150 classification.
4. A durable accepted command could return a post-acceptance 503.
5. Shared infrastructure cannot be isolated or teardown cannot be proved.

Completion report:
- exact files changed or reviewed;
- worker type, minimum model, assigned model, and independence where applicable;
- behavior and invariants implemented or reviewed;
- tests/builds/checks with counts and duration;
- normal downstream consumer results;
- crash, restart, cancellation, negative-case, and recovery coverage;
- API/MCP, lifecycle, compatibility, safety, and type analysis;
- evidence paths and hashes;
- cleanup and residue state;
- claims returned;
- remaining risks;
- staging, commit, push, connected actions, and subagents: none.
```
