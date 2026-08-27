# Remote Mutation Protocol

Use this protocol for branch push, pull-request creation or update, and merge. The Project Steward is the default human approval interface.

## Read-only preflight

Before any remote preflight begins, verify that the exact final revision has:

- two passing qualifying independent reviewer reports;
- passing required validation;
- a passing Project-Steward-moderated Society-of-Thought report satisfying the ReviewContext, Specialist attribution, moderator diversity, and timeout rules in [`review-plans.md`](review-plans.md).

Then:

1. verify the authenticated GitHub identity and repository access;
2. identify the local repository, remote URL, current branch, exact local SHA, and intended base;
3. fetch or otherwise refresh the relevant remote refs without mutation;
4. compare local and remote ancestry and divergence;
5. identify unrelated or newer remote commits and remote-only files;
6. inspect existing pull requests, checks, reviews, and branch protections when relevant;
7. prove the proposed push is non-destructive;
8. determine the exact mutation set;
9. integrate remote history locally when required;
10. refresh affected validation and integration evidence after any rebase, dependency, toolchain, credential, mirror, or environment shift;
11. repeat every affected accepting-lead moderation whenever its evidence inputs changed;
12. repeat both independent reviews when the artifact, diff meaning, authoritative requirements, or required coverage changed.

Preflight failure blocks the approval request and returns a typed blocker.

## Exact approval packet

```text
Repository and authenticated identity:
Remote:
Local branch:
Exact local SHA:
Target remote branch:
Target base branch:
Observed remote branch SHA or absence:
Ancestry and divergence:
Existing pull request:
Checks, reviews, and protections:
Allowed mutations:
Excluded mutations:
Validation at exact SHA:
Validation environment and dependency identity:
Reviewer A and Reviewer B reports:
Review plan identity and revision:
Moderated Society-of-Thought report:
Approval expiry or invalidation conditions:
```

Allowed mutations use a closed set:

- `push_branch`
- `create_draft_pull_request`
- `update_pull_request`
- `merge_pull_request`

Every allowed mutation is a parameterized command:

```text
push_branch:
  local_sha:
  remote_ref:
  expected_remote_sha_or_absent:
  force_mode: none | force_with_lease

create_draft_pull_request:
  head_ref:
  base_ref:
  title_digest:
  body_digest:

update_pull_request:
  pull_request_number:
  expected_updated_at:
  allowed_field_changes:

merge_pull_request:
  pull_request_number:
  expected_head_sha:
  method: merge | squash | rebase
  delete_branch: true | false
```

`force_with_lease` requires the exact expected remote SHA. Push or pull-request approval excludes merge unless the fully parameterized `merge_pull_request` command is present.

Approval is invalidated by a changed local SHA, validation environment, dependency resolution, required review coverage, remote ancestry, base, authentication identity, newly blocking check or protection, mutation outside the packet, or invalidated review, validation, or Society-of-Thought evidence.

## Execute and record

After approval:

1. recheck the invalidation conditions;
2. apply only the approved mutation set;
3. capture resulting remote branch SHA, pull request identity/state, or merge commit;
4. compare the observed result with the packet;
5. record success, partial completion, or mismatch;
6. stop before any additional mutation.

Any mismatch returns to read-only preflight and a new approval packet.

These gates apply to unaccepted work and future remote mutations. Already accepted or merged work is not reopened solely for retroactive compliance; a concrete new defect or revised planning outcome starts new governed work.
