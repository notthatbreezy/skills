# Phase 6 worker assignment

Pack: `C:\Users\brownch\OneDrive - Microsoft\DevTools\recover-failed-investigations-phase6-coordination`

The coordinator completes this template and sends the resulting assignment through Telex. Workers must not treat the unfilled template itself as work authorization.

```text
Task ID:
Worker type:
Worker address:
Minimum model:
Assigned model:
Repository: C:\Projects\dbagent-recover-phase6
Branch: feature/recover-failed-investigations_phase6
Workflow: paw-prs
Primary authority: C:\Projects\dbagent-recover-phase6\.paw\work\recover-failed-investigations\ImplementationPlan.md, Phase 6
Telex scope: recover-failed-investigations-phase6
Telex transport: verified Copilot plugin push bridge

Objective:

Non-goals:

Authoritative state owner:

Domain invariants:
1.

Exact file claims:
1.

Read-only supporting files:
1.

Required behavior:
1.

Failure and cancellation behavior:
1.

Safety boundaries:
1. No production deployment, migration, credentials, or connected actions.
2. No stack consolidation or merge to main.
3. Parse external values before domain use; preserve closed recovery ADTs.

Required validation:
1.

Serialized resources:
1.

Prohibited actions:
- subagents, factories, or delegation;
- edits outside claims;
- staging, commit, push, reset, clean, or worktree removal;
- connected or destructive actions;
- weakening tests, validation, or type guarantees.

Stop and escalate when:
1. The assigned model is below the worker type's minimum capability.
2. The root cause crosses an unclaimed state owner or file.
3. Stored-schema evolution lacks D-150 classification.
4. API and MCP contract behavior cannot remain aligned.
5. A durable accepted command could return a post-acceptance 503.

Completion report:
- exact files changed or reviewed;
- worker type, minimum model, and assigned model;
- behavior and invariants implemented;
- tests/builds/checks with counts and duration;
- safety, lifecycle, compatibility, and type analysis;
- evidence paths and hashes;
- claims returned;
- remaining risks;
- staging, commit, push, connected actions, and subagents: none.
```
