# Worker assignment: DBAgent issues 1059 and 1061

```text
Task ID:
Role: choose integration-implementation, validation, or independent-review
Worker address:
Repository: C:\Projects\dbagent-1059-1061-replication-risk
Branch: work/1059-1061-replication-risk
Workflow: direct
Primary authority: GitHub issues 1059 and 1061 plus repository design and implementation contracts
Telex backend: local
Telex transport: local Copilot push bridge
Telex scope: dbagent-1059-1061
Required address prefix: dbagent-1059-1061-
Issue set: 1059,1061
Worktree environment: C:\Projects\dbagent-1059-1061-replication-risk\script\worktree-env.ps1
Expected session ID: dbagent-1059-1061-replication-risk
Expected Compose project: dbagent-1059-1061-replication-risk
Existing diff / handoff state:
Current handoff: C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\dbagent-1059-1061-coordination\handoff-2026-08-22.md
Resume authorization: identify the operator instruction that resumed this paused scope
Prior blocking findings and required corrections: include full text, not message IDs alone
Frozen target manifest: required before validation or independent review
Expected immutable hashes: required before validation or independent review

Connected-action authorization:
- public endpoint or live source observation:
- Azure authentication/preflight and read-only subscription checks:
- one Azure provisioning/deployment attempt:
- physical replication interruption, slot mutation, or topology change:

Objective:

Non-goals:

Authoritative state owner:

Exact file claims:
1.

Read-only supporting files:
1.

Required behavior:
1.

Failure, topology-change, and recovery behavior:
1.

Acceptance criteria:
1. Kusto topology/identity/WAL authority and Geneva transient-activity boundary:
2. Freshness, invalid-value, reset, disappearance, and dedupe semantics:
3. PM-96 inactive-slot policy:
4. PM-98 Kusto-only lag policy:
5. Privacy/cardinality and production source wiring:
6. Negative cases and recovery:
7. Independent validation:
8. Independent review:
9. Typed deployment parameter-file/template binding:

Safety boundaries:
1.
2. The handoff pause remains authoritative unless this assignment identifies explicit operator resume authorization.

Required validation:
1.
2. For Bicep changes, compare emitted parameter keys against template declarations; compilation alone is insufficient.
3. For frozen reviews, verify hashes before and after and abort on drift.

Serialized resources:
1.

Claim-transfer behavior:
1. Stop, preserve the working-tree diff, return claims, and report unresolved work before rerouting.
2. Implementation completion requires all writes stopped, all claims returned, and two identical full-scope manifests separated by a quiescence interval.

Prohibited actions:
- subagents, factories, or delegation;
- attachment to another Telex scope or use of an address outside dbagent-1059-1061-;
- action on messages that do not identify coordinationScope=dbagent-1059-1061 and issueSet=1059,1061;
- edits outside claims or any edits in read-only roles;
- staging, commit, push, reset, clean, or worktree removal;
- replication-slot mutation or topology changes;
- connected or destructive actions unless separately authorized.

Stop and escalate when:
1.

Completion report:
- exact files changed or reviewed;
- declared role and authority;
- tests/builds/checks with counts and duration;
- source-wiring and downstream-build evidence;
- lifecycle, topology, negative-case, and recovery coverage;
- privacy, safety, and compatibility analysis;
- evidence paths;
- immutable manifest and before/after hash result when applicable;
- claims returned;
- remaining risks.
```
