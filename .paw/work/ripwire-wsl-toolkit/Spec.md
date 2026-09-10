# Feature Specification: Ripwire WSL Toolkit

**Branch**: `brownch-microsoft-ripwire-wsl-toolkit` | **Created**: 2026-09-09 | **Status**: Draft
**Input Brief**: Make Linux Ripwire a portable, reproducible analysis tool for Windows Copilot
sessions using the active Windows worktree through Ubuntu WSL.

## Overview

Windows coding agents should be able to ask Ripwire for repository context without learning WSL
path rules, linked-worktree internals, or machine-specific installation details. The experience
should begin with the Windows worktree already active in the agent session and return Ripwire's
normal command-line result for that exact tree.

A human operator should be able to prepare a compatible machine repeatably from a versioned plugin
package. Setup must distinguish toolkit installation from host prerequisite changes: it may install
the pinned Ripwire artifact after explicit invocation, but it must report missing Windows or WSL
prerequisites rather than silently changing them.

The toolkit is exploration-focused and CLI-first. It accepts a reviewed, closed subset of the pinned
Ripwire release's analysis options, constructs the positional root itself, and rejects project-edit,
caller-directed output, alternate-root, and MCP controls before WSL starts. Persistent source-index
and Git-history caches are permitted only in toolkit-managed Linux storage outside the worktree.
Windows tools remain responsible for editing, building, testing, and Git mutation. MCP integration is not part of V1
because command-line path translation does not solve paths embedded later in JSON protocol
messages.

This is a command-policy and monitored non-mutation boundary, not a read-only filesystem sandbox.
WSL accesses the same Windows files; an unexpected write there would be immediately visible on
Windows. Cache support does not authorize project, Git metadata, baseline, or configuration writes.

## Objectives

- Give agents one stable way to run Ripwire against the current Windows worktree.
- Make installation repeatable with a pinned, checksummed upstream release.
- Diagnose missing prerequisites and unsupported states without destructive or implicit host
  changes.
- Preserve exact worktree identity, arguments, output streams, and exit status across Windows and
  WSL.
- Package usage guidance and regression coverage with the existing Copilot plugin.
- Reuse source parsing and Git-history work across invocations through managed persistent Linux
  caching, without confusing caches with project baselines or weakening worktree correctness.

## User Scenarios & Testing

### User Story P1 - Analyze the active worktree

Narrative: As a Windows coding agent, I can run Ripwire analysis against my current session
worktree without understanding WSL or linked-worktree metadata.

Independent Test: Run an analysis from an isolated Windows-created linked worktree and verify that
Ripwire reports that worktree's root and current commit while observing its dirty files.

Acceptance Scenarios:

1. Given a valid Windows Git worktree and configured Ubuntu WSL installation, when the agent
   requests a Ripwire CLI analysis, then the result comes from that exact worktree.
2. Given a Windows-created linked worktree, when analysis starts, then no `.git` file or Git
   configuration is rewritten.
3. Given no valid worktree, when analysis is requested, then the launcher fails clearly without
   using another checkout.
4. Given a prior successful analysis, when the same worktree is queried again, then its managed
   Linux cache is eligible for reuse; changes to source or HEAD must still be reflected.
5. Given a different linked worktree, when analysis runs, then it uses a separate cache namespace
   even when both worktrees share a common Git directory.

### User Story P2 - Prepare a machine repeatably

Narrative: As a toolkit user, I can install the declared Ripwire version and verify its integrity
without relying on an unpinned latest release or machine-specific repository settings.

Independent Test: Start from a clean toolkit installation location, install the declared artifact,
and verify the installed version and SHA-256 against the package manifest.

Acceptance Scenarios:

1. Given supported Windows and WSL prerequisites, when installation runs, then it selects the
   correct declared architecture artifact, verifies its checksum, and installs it inside the
   selected distribution.
2. Given a checksum mismatch, when installation runs, then it stops before replacing the installed
   binary.
3. Given a missing host prerequisite, when installation runs, then it reports the prerequisite and
   requires separate human action rather than enabling or replacing host components.
4. Given an existing matching install, when installation runs again, then the outcome is
   repeatable and does not create conflicting installations.

### User Story P3 - Diagnose failures

Narrative: As a human operator, I can determine whether WSL, distribution selection, Git discovery,
path translation, local configuration, and Ripwire installation are ready before asking an agent
to use the tool.

Independent Test: Run diagnostics across ready, missing, stale, and malformed fixtures and verify
that each check reports a distinct actionable result.

Acceptance Scenarios:

1. Given a complete setup, when diagnostics run, then every required layer is reported ready.
2. Given a missing or stale layer, when diagnostics run, then the failing layer and remediation are
   identified without modifying the system.
3. Given malformed inherited Git override state, when diagnostics or launch runs, then it stops
   instead of discarding or replacing the caller's state.

### User Story P4 - Invoke Ripwire safely and faithfully

Narrative: As an agent author, I can rely on arguments, streams, and failures reaching Ripwire and
returning to the caller without launcher-specific ambiguity.

Independent Test: Send spaced, Unicode, quoted, empty, and failing test arguments through a fake
Ripwire process and verify exact argument boundaries, stdout, stderr, and exit code.

Acceptance Scenarios:

1. Given valid arguments containing spaces or Unicode, when launch occurs, then each argument
   arrives unchanged as one argument.
2. Given Ripwire output, when launch occurs, then Ripwire stdout remains result-only and launcher
   diagnostics use stderr.
3. Given a non-zero Ripwire exit, when launch completes, then the caller receives the same exit
   code.
4. Given valid inherited Git configuration overrides, when launch occurs, then they are preserved
   and the required safety override is appended last for the child process only.
5. Given an alternate root, unknown option, MCP control, edit operation, baseline, or caller-chosen
   cache/index/output path, when launch is requested, then it is rejected before WSL starts.
   Toolkit-managed internal caching is not a caller-selected output operation.

### Edge Cases

- Paths with spaces, Unicode characters, trailing separators, and different drive-letter casing.
- Standalone repositories versus Windows-created linked worktrees.
- Unsupported non-Git directories and worktree paths that no longer exist.
- Missing `wsl.exe`, Windows Git, selected distribution, Linux Git, archive tooling, or Ripwire.
- WSL distributions with x86-64 or ARM64 architecture.
- Existing matching, outdated, partial, and checksum-invalid installations.
- Archives containing absolute paths, traversal entries, unexpected roots, links, missing payloads,
  or non-executable payloads.
- Empty arguments and arguments containing quotes, backslashes, equals signs, or path-like text.
- Valid empty Git override blocks, valid populated blocks, missing indexed entries, non-numeric
  counts, and conflicting inherited values.
- Ripwire failure before output, after partial output, and from an unavailable binary.
- Requests that imply another repository root, an MCP server, or an option outside the pinned
  analysis allowlist.
- Missing, corrupt, stale, or unwritable caches; simultaneous queries; cache maintenance during an
  active query; and unsafe cache paths that resolve into Windows storage or another user's files.

## Requirements

### Functional Requirements

- **FR-001**: The toolkit shall expose an agent-discoverable CLI analysis capability as part of the
  repository's existing Copilot plugin. (Stories: P1, P4)
- **FR-002**: The launcher shall require a current Windows worktree and shall not search for or fall
  back to another checkout. (Stories: P1)
- **FR-003**: The launcher shall use Windows Git to resolve the worktree and Git metadata needed by
  the WSL child without modifying repository metadata or Git configuration. (Stories: P1)
- **FR-004**: The launcher shall run Ripwire in one explicitly configured Ubuntu WSL distribution
  with both WSL working directory and the launcher-supplied Ripwire positional root set to the same
  translated current worktree. (Stories: P1)
- **FR-005**: The child process shall receive worktree-scoped Git metadata and a final
  `core.fsmonitor=false` override through a child-only launch contract: PowerShell transports the
  validated caller block and translated paths with `WSLENV`, and the Linux bootstrap appends the
  safety entry before Ripwire starts. The parent process remains unchanged. (Stories: P1, P4)
- **FR-006**: Malformed inherited Git override state shall produce an actionable failure rather
  than replacement, truncation, or silent defaulting. (Stories: P3, P4)
- **FR-007**: The launcher shall preserve argument boundaries, copy Ripwire stdout and stderr as raw
  bytes without text decoding/newline conversion, keep launcher diagnostics on stderr, and return
  the Ripwire exit code. (Stories: P4)
- **FR-008**: The installer shall select only artifacts declared in a versioned package manifest
  and verify the archive SHA-256, safe archive layout, regular executable payload, and staged
  binary version before installation. (Stories: P2)
- **FR-009**: The installer shall support the upstream Linux x86-64 and ARM64 artifacts declared by
  the selected release. x86-64 is supported on the documented Ubuntu 20.04+ baseline; ARM64 is an
  available artifact that becomes supported on a host only after the staged binary health probe
  succeeds. (Stories: P2)
- **FR-010**: Machine-local distribution and binary settings shall use a versioned JSON schema at
  `%LOCALAPPDATA%\brownch-devtools\ripwire-wsl\config.json` by default, support an explicit
  `-ConfigPath` override for isolation, remain outside version control, and not be embedded in agent
  instructions. (Stories: P1, P2)
- **FR-011**: Diagnostics shall check required Windows, WSL, Linux, Git, configuration, installation,
  and worktree layers without changing them. (Stories: P3)
- **FR-012**: Missing host prerequisites shall be reported for separate human approval and action;
  the toolkit shall not silently enable Windows features, install or unregister distributions, or
  replace a distribution. (Stories: P2, P3)
- **FR-013**: Agent instructions shall keep edits, builds, tests, and Git mutations on Windows and
  use Ripwire for analysis. (Stories: P1)
- **FR-014**: Regression coverage shall use isolated fixtures and shall not exercise the user's
  primary project as a test target. (Stories: P1, P2, P3, P4)
- **FR-015**: The toolkit shall identify single-worktree and CLI-only boundaries rather than
  claiming universal cross-root or MCP compatibility. (Stories: P1, P3)
- **FR-016**: The launcher shall parse arguments against a release-pinned closed analysis allowlist,
  construct the sole positional root itself, and reject unknown, project-mutating, caller-directed
  output/cache/index, baseline, MCP/listen, and additional-root controls before creating a WSL process.
  (Stories: P1, P4)
- **FR-017**: Installation shall be transactional: validate in staging, preserve prior binary and
  configuration bytes until post-swap health succeeds, restore both after any post-swap failure,
  and commit configuration last. (Stories: P2)
- **FR-018**: Caching shall be enabled by default for source ingestion and Git history, using a
  persistent, user-private Linux cache namespace scoped to the pinned release, architecture, and
  canonical worktree identity. No cache may be located in the target, Git metadata, Windows-mounted
  storage, or binary installation directory. Caches shall never override current source or HEAD
  identity and shall remain disposable derived data. (Stories: P1, P4)
- **FR-019**: The toolkit shall expose cache location/readiness through read-only diagnostics and
  an explicit, scoped cache-clear operation. Maintenance and analysis shall coordinate access;
  invalid locations, permission/lock failures, and failed cleanup shall be reported rather than
  silently falling back to a different directory. (Stories: P2, P3, P4)

### Key Entities

- **Release Manifest**: Versioned declaration of upstream release identity, source commit, accepted
  `uname -m` values, normalized architecture, asset name/URL, archive SHA-256, expected archive root
  and payload path, and the closed analysis-option policy. Missing, unknown, duplicate, or
  contradictory fields are parse errors.
- **Manifest Parse Result**: Valid or one of Unreadable, MalformedJson, UnsupportedSchema,
  MissingField, UnknownField, DuplicateArchitecture, InvalidDigest, or InconsistentAsset.
- **Local Toolkit Configuration**: Versioned machine-local JSON containing distribution identity,
  normalized architecture, release identity, and Linux absolute binary and cache-root paths.
  Its closed states are Missing, Unreadable, Malformed, UnsupportedVersion, ValidButStale, and Valid.
- **Worktree Launch Context**: Validated canonical Windows root, translated Linux root, Git
  directory, common directory, closed invocation classification, child-only `WSLENV`, and launch
  arguments used by one process.
- **Managed Cache Context**: Validated Linux-owned cache root, release/architecture/worktree key,
  derived temporary/cache directories, and exclusive per-namespace access. Raw caller paths do not
  reach cache creation or deletion without ownership and containment validation.
- **Invocation Classification**: AllowedDefaultMap, AllowedAnalysis, RejectedAdditionalRoot,
  RejectedMutation, RejectedMcp, RejectedOutput, RejectedUnknown, or InvalidSyntax. AllowedAnalysis
  carries one primary selector plus validated modifiers.
- **External Command Result**: Success with raw streams, Unavailable, NonZero, InvalidOutput,
  TimedOut, or TransportFailure.
- **Launch Result**: RejectedPreflight, StartFailed, Started, Completed, PumpFailed, or
  TransportFailure.
- **Diagnostic Result**: Named layer, stable code, Ready/Warning/Failed/Skipped status, message, and
  remediation. Worktree checks are required when a worktree is supplied.
- **Install Transaction**: Downloaded, HashVerified, LayoutVerified, StagedBinaryVerified,
  ReadyToSwap, Swapped, PostSwapVerified, ConfigCommitted, or RolledBack. Rollback result is
  NotRequired, Succeeded, or Failed and is never collapsed into the original installation error.

### V1 Analysis Option Contract

The launcher supplies the sole positional root and enables upstream default caching by omitting
`--no-cache`. It controls cache placement through the child environment, not a caller-supplied
`--cache` path. Callers may provide only these `v0.5.0` forms:

| Kind | Allowed forms |
|---|---|
| Primary selector, zero or one | `--for=<text>`, `--pack-task=<text>`, `--callers=<symbol>`, `--callees=<symbol>`, `--uses=<symbol>`, `--impact=<symbol>`, `--situ`, `--pr-context=<ref>`, `--from-trace=<windows-path>`, `--whereis=<symbol>`, `--grep=<text>`, `--regex=<pattern>`, `--expand=<symbol-list>`, `--outline=<symbol-list>`, `--doctor` |
| Numeric modifier | `--top-k=<non-negative-int>`, `--max-tokens=<positive-int>`, `--detail=<non-negative-int>` |
| Boolean modifier | `--adaptive`, `--signatures-only`, `--json` |

Value-bearing options use attached `--name=value` syntax only. `--from-trace` is the only
caller-supplied path option and its value is translated as a known path. Every other upstream or
unknown option is rejected; rejection is classified as additional-root, mutation, MCP, output, or
unknown. The release manifest records this table so changing the Ripwire pin cannot silently change
the accepted language.

The exploration selectors above are unchanged. Additional quality commands (including
`--metrics`, `--hotspots`, `--test-gate`, `--edit-check`, and `--quality-delta`), architecture/quality
baseline creation or updates, and acknowledgment commands remain deferred. They are not all
classified as mutating; they simply have not been included and qualified for V1.

### Managed Cache Contract

- Default root: `$HOME/.cache/brownch-devtools/ripwire-wsl` inside the selected distribution.
  Setup accepts `-LinuxCacheRoot` and records the resolved Linux path as `cacheRoot`. Tests use a
  disposable override. Configuration remains machine-local; agents need no cache-path arguments.
- Namespaces separate release identity, architecture, and a hash of canonical worktree root plus
  Git directory/common-directory identity. Sharing a Git common directory does not merge worktree
  caches. A HEAD change does not select a new toolkit namespace; upstream freshness handling must
  validate/rebuild its entries.
- Child-only `TMPDIR=<namespace>/tmp` and `XDG_CACHE_HOME=<namespace>/xdg` direct both default
  ingestion caching and history caches into owned storage. `TMPDIR` takes precedence for the
  observed history-cache family. Preserve the parent's values; do not edit shell startup files.
- Resolve and validate native Linux storage, ownership, restrictive permissions, and containment
  before use; reject links that escape the owned root and Windows-backed locations. Do not adopt
  another user's directory or fall back to a shared/default cache on failure.
- Reuse the namespace across successful and failed invocations; do not delete it after every
  query. Missing or invalid entries may be recomputed only within that same managed namespace.
  Cache data may contain parsed source and repository-history metadata; document this retention.
- Serialize operations within a namespace using an exclusive lock with a bounded wait. Different
  worktree namespaces may run independently. Explicit clear uses the same coordination and must
  not delete data beneath an active analysis.
- `Clear-RipwireWslCache.ps1 -WorktreePath <path> [-ConfigPath <path>]` removes only that validated
  worktree namespace for the configured release/architecture, never the overall cache root,
  installation, source, or Git directories. Surface clear failures with non-zero exit and stderr.
  V1 does not promise a disk quota or automatic expiry: report location/usage and document explicit
  clearing, including retention of older release namespaces until separately maintained.
- Creating/updating/rebuilding owned cache files and lock state is the only analysis-write
  exception. Setup, explicit maintenance, and disposable test cleanup have their own declared
  effects. Target/Git/configuration/binary changes remain forbidden during analysis.

### Invocation Rejection Codes

| Rejection result | Symbolic code | Exit code |
|---|---|---:|
| RejectedAdditionalRoot | `RIPWIRE_WSL_REJECTED_ROOT` | 64 |
| RejectedMutation | `RIPWIRE_WSL_REJECTED_MUTATION` | 65 |
| RejectedMcp | `RIPWIRE_WSL_REJECTED_MCP` | 66 |
| RejectedOutput | `RIPWIRE_WSL_REJECTED_OUTPUT` | 67 |
| RejectedUnknown | `RIPWIRE_WSL_REJECTED_UNKNOWN` | 68 |
| InvalidSyntax | `RIPWIRE_WSL_INVALID_ARGUMENT` | 69 |

### WSL Environment Contract

PowerShell resolves Windows paths and translates them with `wslpath` before launch. Already
translated Linux values use `/u`, never `/p`, in the child-only `WSLENV`:

| Linux variable | Source | `WSLENV` token |
|---|---|---|
| `GIT_DIR` | Translated Windows Git directory | `GIT_DIR/u` |
| `GIT_WORK_TREE` | Translated canonical worktree | `GIT_WORK_TREE/u` |
| `GIT_COMMON_DIR` | Translated Windows common directory | `GIT_COMMON_DIR/u` |
| `GIT_CONFIG_COUNT` | Validated caller block | `GIT_CONFIG_COUNT/u` |
| `GIT_CONFIG_KEY_<n>` / `GIT_CONFIG_VALUE_<n>` | Validated caller entries | `<name>/u` |
| `RIPWIRE_BIN` | Linux absolute path from valid local config | `RIPWIRE_BIN/u` |
| `RIPWIRE_WSL_DIAGNOSTIC` | Internal `0` or `1` | `RIPWIRE_WSL_DIAGNOSTIC/u` |
| `RIPWIRE_WSL_OPERATION` | Internal `analysis`, `diagnostic`, or explicit maintenance `clear`; always assigned by the Windows entrypoint | `RIPWIRE_WSL_OPERATION/u` |
| `GIT_OPTIONAL_LOCKS` | Internal `0` to avoid optional index refresh writes | `GIT_OPTIONAL_LOCKS/u` |
| `TMPDIR` | Validated namespace temporary directory | `TMPDIR/u` |
| `XDG_CACHE_HOME` | Validated namespace cache directory | `XDG_CACHE_HOME/u` |

Existing `WSLENV` entries are preserved in order. Duplicate names, conflicting flags, malformed
tokens, or a `/p` request for these pretranslated values fail before process creation.

The local configuration schema version is `1` and requires exactly
`schemaVersion`, `distribution`, `architecture`, `releaseVersion`, `releaseCommit`,
`archiveSha256`, `binaryPath`, and `cacheRoot`. This is a revision to the unpublished V1 schema.
Unknown fields are rejected so configuration evolution requires
an explicit schema version.

### Cross-Cutting / Non-Functional

- The package shall contain no username, absolute project path, session branch, Git metadata path,
  or host MCP configuration.
- Default diagnostic and test output shall not disclose unrelated environment data.
- A failed validation shall stop before starting Ripwire or changing an existing installation.
- Runtime scripts require PowerShell 7. Windows PowerShell 5.1 shall run manifest/static tests and
  otherwise write `RIPWIRE_WSL_UNSUPPORTED_RUNTIME` to stderr and exit `78` before importing common
  modules, reading configuration, probing commands, or creating processes.
- Supported distributions shall report `ID=ubuntu`, Ubuntu 20.04 or newer, a declared architecture,
  and a runnable staged binary. WSL generation is reported separately and is not inferred from the
  distribution name. ARM64 support is qualified by the staged health check rather than inferred
  from asset availability.

## Success Criteria

- **SC-001**: An isolated Windows-created linked-worktree fixture returns the same root and commit
  identity through the toolkit as Windows Git, and dirty-file analysis observes fixture changes.
  (FR-002, FR-003, FR-004)
- **SC-002**: Before and after snapshots show no change to fixture files, `.git` metadata, local
  config, global config, or the primary repository during non-editing Ripwire scenarios. (FR-003,
  FR-014)
- **SC-003**: All spaced, Unicode, quoted, empty, and path-like argument fixtures arrive at the test
  child with exact boundaries, and stdout, stderr, and exit code match expectations. (FR-007)
- **SC-004**: Valid preexisting Git override entries remain ordered and unchanged, the safety
  override is last, and malformed blocks fail with a specific diagnostic. (FR-005, FR-006)
- **SC-005**: Clean, repeated, wrong-checksum, missing-prerequisite, and architecture-selection
  installation fixtures produce the specified outcomes. (FR-008, FR-009, FR-012)
- **SC-006**: Diagnostics distinguish every required layer and perform zero host or repository
  mutations. (FR-011, FR-012)
- **SC-007**: Package inspection finds zero machine-specific paths or identities and finds explicit
  CLI-only, single-worktree, and Windows-authority guidance. (FR-010, FR-013, FR-015)
- **SC-008**: Existing repository tests and every deterministic toolkit mode pass under PowerShell
  7; manifest/static tests pass under Windows PowerShell 5.1, while runtime entrypoints fail before
  side effects with the documented unsupported-runtime code. (FR-014)
- **SC-009**: Package-level discovery resolves the new skill and valid frontmatter from the staged
  plugin manifest without reading or changing the user's Copilot configuration. (FR-001, FR-014)
- **SC-010**: Every disallowed or unknown invocation fixture exits before `wsl.exe` starts, identifies
  the option class, and leaves the parent environment and target unchanged. (FR-016)
- **SC-011**: Every install failure preserves or restores the prior binary bytes, executable mode,
  and configuration bytes; successful commit occurs only after staged and post-swap health checks.
  (FR-008, FR-017)
- **SC-012**: Repeated processes using one cache namespace demonstrate source-cache reuse with
  unchanged analysis results. Dirty-source and HEAD changes produce current results; distinct
  linked worktrees do not share toolkit namespaces. Warm/cold timings are recorded without an
  unmeasured speedup promise. (FR-018)
- **SC-013**: Snapshots permit only declared managed-cache/lock changes during analysis and detect
  any target, Git, configuration, binary, or out-of-namespace write. Missing/corrupt cache,
  permission, escaped-path, contention, and clear-failure cases preserve this boundary. Explicit
  clear removes only the selected namespace; the next analysis rebuilds it. (FR-018, FR-019)

## Assumptions

- Supported hosts meet Microsoft's documented requirements for a current WSL installation.
- Users can provide or select an installed Ubuntu 20.04+ distribution; exact local naming is
  machine configuration.
- Upstream release `v0.5.0` remains the V1 pin unless implementation research finds a release
  integrity or compatibility blocker.
- Release binaries remain governed by upstream Apache-2.0 terms.
- Mounted Windows filesystem analysis may be slower than native Linux storage; same-worktree
  correctness has priority.

## Scope

### In Scope

- One model-invoked Copilot plugin skill.
- Windows launcher, installer, doctor, Linux process bootstrap, release manifest, references, and
  eval fixtures colocated with the skill.
- Plugin manifest, version, changelog, and user-facing documentation updates.
- Deterministic unit/contract tests and explicit live WSL integration tests using disposable
  fixtures.
- Persistent Linux source/history caches, cache diagnostics, and scoped explicit maintenance.

### Out of Scope

- Native Windows Ripwire binaries or changes to upstream Ripwire.
- Automatic Windows feature enablement or distribution installation/replacement.
- A second source clone in WSL.
- User-global or repository MCP configuration.
- MCP JSON path translation or claims of read-only sandboxing.
- Multi-worktree or arbitrary cross-root requests in one process.
- Raw pass-through of arbitrary Ripwire options.
- Additional quality/architecture command families, baseline writes, and acknowledgments; cache
  support does not expand the exploration allowlist.
- Automatic cache expiry/quotas and a hard read-only filesystem sandbox.
- Publishing, pushing, opening a PR, or changing user-global configuration during planning.

## Dependencies

- GitHub Copilot CLI plugin support.
- Windows Git.
- Microsoft WSL with an installed Ubuntu distribution.
- Linux Git and archive support in that distribution.
- PowerShell 7 for runtime scripts.
- Network access to the pinned GitHub release during installation.
- Upstream Ripwire `v0.5.0` assets:
  - x86-64 SHA-256:
    `f06e9d7e55032e8e5c397405ed72a19d6e70767d28c8c617a925de4401779f50`
  - ARM64 SHA-256:
    `efe049b1645045e96751a51b1bc321b2d8653aa1f6ab5d7c2390eb3d49716bf0`

## Risks & Mitigations

- **WSL path and quoting differences**: Exact argument contract tests plus disposable live fixtures.
- **WSL environment transport**: Preserve and extend `WSLENV` only in the child process and prove
  the imported Linux environment through doctor output.
- **Linked-worktree Git discovery**: Resolve with Windows Git and verify identities against Windows
  Git before invoking Ripwire.
- **Inherited unsafe Git configuration**: Append a child-only final override and reject malformed
  override blocks.
- **Upstream Git behavior**: Verify the pinned release's root parsing and Git subprocess behavior
  against `cli.h` and `gitstamp.h`; avoid claims about files absent from the release.
- **Gist licensing ambiguity**: Independently implement the launcher; do not copy gist code.
- **Release drift**: Use one checked manifest and update it only through reviewed repository
  changes.
- **Unexpected host mutation**: Keep doctor read-only and require separate explicit action for host
  prerequisites.
- **Cache retention and stale reuse**: Use private scoped Linux storage; prove dirty/HEAD freshness,
  expose location/usage and explicit clear, and never equate a cache hit with current correctness.
- **Analysis is not filesystem enforcement**: Keep project-write exclusions and snapshots even
  with managed caching. An allowlist is not an OS-level write barrier.

## References

- [Ripwire v0.5.0](https://github.com/redhat-et/ripwire/releases/tag/v0.5.0)
- [Ripwire v0.5.0 source commit](https://github.com/redhat-et/ripwire/commit/bacfa3b7b3ad13648ce3892de06af05b6b55a2ac)
- [Ripwire license](https://github.com/redhat-et/ripwire/blob/v0.5.0/LICENSE)
- [Ripwire CLI parser](https://github.com/redhat-et/ripwire/blob/v0.5.0/src/cli.h)
- [Ripwire Git stamp](https://github.com/redhat-et/ripwire/blob/v0.5.0/src/gitstamp.h)
- [Ripwire installer](https://github.com/redhat-et/ripwire/blob/v0.5.0/scripts/install.sh)
- [Ripwire release workflow](https://github.com/redhat-et/ripwire/blob/v0.5.0/.github/workflows/release.yml)
- [Ripwire MCP index](https://github.com/redhat-et/ripwire/blob/v0.5.0/src/mcpindex.h)
- [Microsoft WSL filesystem guidance](https://learn.microsoft.com/windows/wsl/filesystems)
- [Microsoft WSL command reference](https://learn.microsoft.com/windows/wsl/basic-commands)
- `.paw/work/ripwire-wsl-toolkit/WorkShaping.md`
- `.paw/work/ripwire-wsl-toolkit/CodeResearch.md`
