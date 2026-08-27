# Worker assignment: DBAgent issues 1055 and 1057

```text
Task ID:
Role: choose integration-implementation, validation, or independent-review
Worker address:
Repository: C:\Projects\dbagent-1055-1057-cache-efficiency
Branch: work/1055-1057-cache-efficiency
Workflow: direct
Primary authority: GitHub issues 1055 and 1057 plus repository design and implementation contracts
Restart handoff: C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\dbagent-1055-1057-coordination\coordinator-restart-handoff-2026-08-22.md
Telex backend: local
Telex transport: local Copilot push bridge
Telex scope: dbagent-1055-1057
Required address prefix: dbagent-1055-1057-
Issue set: 1055,1057
Worktree environment: C:\Projects\dbagent-1055-1057-cache-efficiency\script\worktree-env.ps1
Expected session ID: dbagent-1055-1057-cache-efficiency
Expected Compose project: dbagent-1055-1057-cache-efficiency
Existing diff / handoff state:
Operator authorization for this assignment:
Connected-action authority: none unless stated exactly below
Authorization expiry:
Independent-review prerequisite and disposition:

Objective:

Non-goals:

Authoritative state owner:

Exact file claims:
1.

Read-only supporting files:
1.

Required behavior:
1.

Failure and recovery behavior:
1.

Acceptance criteria:
1. Shared PM-41/PM-61 source and evidence contract:
2. Materiality, freshness, reset, sparse, idle, and missing semantics:
3. Production source wiring and downstream consumers:
4. Negative cases, dedupe, and recovery:
5. Independent validation:
6. Independent review:

Safety boundaries:
1.

Sensitive-data handling:
1. Never request, receive, echo, log, or transmit credentials, connection strings, tokens, public
   IPs, raw resource IDs, target names, ledger run IDs, hashes, or secret values through chat,
   Telex, PR, issue text, tracked files, or completion evidence.

Required validation:
1.

Independent validation role:
1. Default validation is local-only. Name a separately authorized cloud-capable role before any
   connected validation.

Serialized resources:
1.

Claim-transfer behavior:
1. Stop, preserve the working-tree diff, return claims, and report unresolved work before rerouting.

Prohibited actions:
- subagents, factories, or delegation;
- attachment to another Telex scope or use of an address outside dbagent-1055-1057-;
- action on messages that do not identify coordinationScope=dbagent-1055-1057 and issueSet=1055,1057;
- edits outside claims or any edits in read-only roles;
- staging, commit, push, reset, clean, or worktree removal;
- connected or destructive actions unless separately authorized.
- execution of the current Phase 4A assignment before the bootstrap-password decision and reviewed
  amendment;
- requesting or receiving a bootstrap password through chat or Telex.

Stop and escalate when:
1.

Completion report:
- exact files changed or reviewed;
- declared role and authority;
- restart handoff baseline and exact operator authorization used;
- tests/builds/checks with counts and duration;
- source-wiring and downstream-build evidence;
- negative-case and recovery coverage;
- safety and compatibility analysis;
- evidence paths;
- connected actions performed, or `none`;
- claims returned;
- remaining risks.
```
