# Assignment packet

Use this shape for every worker. Include only fields that materially constrain the task.

```text
Task:
Lease ID:
Worker surface: background | child session
Lease horizon: one assignment | named milestone role
Lease expiry:
Mode: research | implement | integrate | validate | review
Outcome:
Checkpoint:
Repository and worktree:
Branch or immutable source:
Authoritative workflow artifact:
Delivery target and supported golden path:
Explicit unsupported paths:
Assigned model and reasoning:
Context tier: default (long/high context prohibited)
Required skills and exact fallback paths:

Owned state or behavior:
Exact write claims:
Read-only scope:
Dependencies:
Integration owner and checkpoint transfer path:
Non-goals:

Required behavior and invariants:
Failure, cancellation, and compatibility behavior:
Validation or review evidence required:
Validation ladder and minimum nonzero signals:
Serialized resources:
Safety boundaries:

Stop and return when:
Completion criteria:
```

Every worker returns:

```text
Status: PASS | FAIL | BLOCKED
Checkpoint:
Source identity:
Files changed or reviewed:
Evidence:
Findings or unresolved risks:
POC blockers:
Pre-1.0 defect candidates:
Claims returned:
Lease state: completed | paused | blocked
Working tree and active-process state:
Known next assignment or archive recommendation:
Recommended next mode:
```

Keep the report under 300 words unless failure evidence requires exact output. Link or cite artifacts instead of pasting long transcripts.
