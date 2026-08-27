# Central Execution-Boundary Policies

Assignments reference a version of this policy instead of restating it. A policy change that affects correctness or authority is material and requires fencing plus a replacement assignment and run.

## Repository lifecycle

Use the repository's canonical Scripts to Rule Them All entry points:

- `scripts/setup`
- `scripts/update`
- `scripts/server`
- `scripts/test`

Use specialized adjacent scripts only when the assignment names them or the canonical script delegates to them. Evidence records the exact command and selected tests or behaviors.

## Dependency mirrors

Python and npm dependencies resolve only through the approved Microsoft-operated mirrors.

The execution boundary must:

- explicitly configure the approved mirror for every dependency operation;
- disable or neutralize user and machine configuration that can override the mirror;
- preserve absent-versus-present environment-variable semantics during cleanup;
- verify default and scoped npm registries before resolution;
- reject public PyPI or npm registry URLs in manifests and lockfiles;
- reject external direct URLs, Git or VCS references, archives, local-file substitutions, and alternate registries unless the versioned boundary policy explicitly allowlists the immutable source and digest;
- include hostile-configuration tests with nonzero cases for user and machine overrides, scoped registries, manifest and lockfile URLs, and direct-source bypasses.

Workers invoke the centralized mechanism. They do not replace it with local environment defaults or prompt-only promises.

A rebase, dependency resolution, toolchain, credential, mirror, or execution-environment change invalidates affected validation and integration evidence even when artifact bytes are unchanged. Refresh that evidence and repeat every accepting-lead moderation that consumed it, including Project Steward pre-push moderation when applicable. Repeat artifact reviews only when content, diff meaning, authoritative requirements, or required coverage changed.

## Remote mutation

Push, pull-request mutation, and merge require the protocol in [`remote-actions.md`](remote-actions.md). Local commits do not imply remote approval.

## User interface boundary

Tennex v0 supports a desktop-class browser UI:

- dense, wide, multi-pane engineering surfaces are allowed;
- accessibility is required within the desktop target;
- mobile, tablet, touch-first, and responsive-layout behavior are not acceptance obligations.

## Runtime and schema boundary

- Python 3.13, strict Pyright, strict Pydantic v2 boundary models, and no untyped public APIs;
- TypeScript strict mode and runtime parsing from `unknown`;
- released event schemas are immutable and versioned;
- Microsoft Agent Framework workflow checkpoints are JSON execution snapshots, not business history;
- GitHub Copilot provider sessions are caches, not authority;
- raw external data is parsed before domain use.

## Effects and recovery

- record intent before connected or destructive effects;
- use idempotency keys where an effect can be retried;
- preserve exact process, workspace, branch, and artifact identity;
- hard stop revokes authority and preserves the worktree for recovery;
- recovery resumes only through current authority after effect reconciliation.
