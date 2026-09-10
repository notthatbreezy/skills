# Ripwire WSL Toolkit Plan

## Overview

Add a model-invoked `ripwire-wsl` skill to the existing `brownch-devtools` plugin. The skill will
present a small analysis interface to agents while colocated scripts own installation, diagnostics,
Windows Git discovery, WSL path conversion, child-environment construction, and Ripwire process
execution.

V1 includes persistent, toolkit-managed Linux source/history caching. Exploration remains the
feature scope; additional quality commands and baseline workflows are deferred. The safety
boundary is no project/Git/configuration mutation, not no filesystem writes anywhere.

The implementation will consume pinned upstream `v0.5.0` Linux release assets for x86-64 and ARM64.
It will be independently authored; the unlicensed public launcher gist remains research evidence,
not source material.

Start with **Phase 0: Live feasibility gate**, before installer or full toolkit implementation.
Prove both actual Ripwire linked-worktree behavior and the real Windows-to-WSL process boundary
with a minimal reusable test harness. A successful Git discovery probe alone is not sufficient.
This planning revision does not authorize executing the gate or downloading/installing Ripwire.

## Current State Analysis

- The plugin explicitly lists skills in `plugins/devtools/plugin.json`; new skills are not discovered
  from the directory alone (`CodeResearch.md`, Plugin package and marketplace).
- Existing skills colocate `SKILL.md`, scripts, references, and eval fixtures
  (`CodeResearch.md`, Skill package conventions).
- Repository regression tests are standalone PowerShell scripts with disposable fixtures and mocked
  external commands (`CodeResearch.md`, PowerShell and repository tests).
- The root installer manages only marketplace/plugin installation. Per-skill runtime setup belongs
  inside the skill package (`CodeResearch.md`, Repository installer boundary).
- Upstream publishes checksummed x86-64 and ARM64 Linux assets for `v0.5.0`.
- Windows-created linked worktrees require process-local translated Git metadata for Linux Git.

## Desired End State

An installed plugin exposes `ripwire-wsl` when an agent needs repository analysis from a Windows
session. After one explicit human setup, the agent supplies only the current Windows worktree and
Ripwire CLI intent. The launcher validates that exact worktree, starts the configured Ubuntu
distribution, preserves arguments and streams, appends child-only Git hardening, and returns
Ripwire's exit status.

The package includes read-only diagnostics and deterministic tests. Live tests create their own
standalone repository and Windows linked worktree, then prove identity, dirty-file behavior,
Git-backed queries, argument fidelity, failure propagation, and target non-mutation.

## Architecture Decisions

1. **Model-invoked skill**: `plugins/devtools/skills/ripwire-wsl/SKILL.md` carries concise trigger and
   analysis instructions. Detailed human setup and compatibility guidance is disclosed through
   `references/guide.md`.
2. **Machine-local configuration**: Installation records schema version, distribution, normalized
   architecture, release, Linux binary path, and Linux cache root at
   `%LOCALAPPDATA%\brownch-devtools\ripwire-wsl\config.json`. Every script accepts `-ConfigPath`;
   installation also accepts `-LinuxInstallRoot` and `-LinuxCacheRoot`; tests always use disposable
   configuration, binary, and cache locations.
3. **Pinned release manifest**: `references/release.json` is the single source for version, source
   commit, architecture mapping, asset URLs, SHA-256 values, expected archive layout, and the exact
   V1 option table from `Spec.md`.
4. **Child-only WSL transport**: PowerShell validates existing `WSLENV` and `GIT_CONFIG_COUNT`
   entries, creates a ProcessStartInfo environment without changing the parent, adds translated Git
   variables to child `WSLENV`, and invokes
   `wsl.exe --distribution <name> --cd <linux-root> --exec /bin/bash -- <linux-bootstrap> --`.
5. **Windows launcher plus Linux bootstrap**: PowerShell validates Windows state and launches WSL.
   The shell bootstrap verifies imported Git variables, appends `core.fsmonitor=false`, supports a
   read-only JSON launch-context diagnostic, and otherwise finishes with
   `exec "$RIPWIRE_BIN" "$@"`.
6. **Exact worktree and invocation contract**: The launcher requires `-WorktreePath`, resolves the
   root through Windows Git, constructs the only positional Ripwire root, and accepts only
   release-pinned analysis flags. It rejects non-flag roots, unknown flags, MCP/listen, edit,
   baseline, caller-directed cache/index/output, and other project-mutating controls before starting WSL.
7. **Independent implementation**: No code is copied from the public gist because no reuse license
   is declared.
8. **Transactional installation**: Download and extract to staging, validate archive and executable,
   preserve prior binary/config bytes through swap and post-swap health, roll back on failure, and
   commit configuration last.
9. **Raw stream contract**: Pump stdout/stderr base streams as bytes; launcher diagnostics use
   stderr separately. Runtime requires PowerShell 7.
10. **CLI-only V1**: MCP configuration and JSON protocol path adaptation remain a separate feature.
11. **Managed persistent cache**: Follow `Spec.md`'s cache contract. Keep default ingestion caching
    enabled; set child-only `TMPDIR` and `XDG_CACHE_HOME` beneath a private Linux namespace keyed by
    release, architecture, and canonical worktree identity. Reuse across calls; serialize same-key
    access and explicit clearing. Do not expose arbitrary cache destinations to analysis callers.
12. **Non-mutation, not sandboxing**: `GIT_OPTIONAL_LOCKS=0`, the final fsmonitor override, command
    exclusions, and before/after observations remain required. They do not prevent arbitrary WSL
    writes to the shared Windows mount at the filesystem level.

## What We're NOT Doing

- Porting Ripwire to Windows or modifying upstream.
- Installing, enabling, unregistering, or replacing WSL host components automatically.
- Cloning the target project inside WSL.
- Editing user-global MCP configuration.
- Building an MCP protocol adapter.
- Supporting arbitrary cross-root operations from one Ripwire process.
- Forwarding arbitrary upstream Ripwire options.
- Adding quality/architecture commands, baseline creation/update, or acknowledgments to V1.
- Disabling all caches, deleting useful cache state after every query, or promising cache quotas,
  automatic expiry, or a hard read-only filesystem sandbox.
- Adding Pester or another test framework.
- Testing against the user's primary target project.
- Publishing, pushing, or opening the final PR during implementation unless separately authorized.

## Phase Status

- [x] **Phase 0: Live feasibility gate** - Core worktree behavior, real transport, and managed
  warm-cache evidence passed and were accepted by the user on 2026-09-10.
- [x] **Phase 1: Package contracts and deterministic core** - Add the skill package, release
  manifest, configuration/cache model, and pure validation/conversion helpers with self-tests.
- [x] **Phase 2: Installer and doctor** - Implement repeatable pinned installation and read-only
  diagnostics and scoped cache maintenance with mocked contract coverage.
- [x] **Phase 3: Worktree-aware launcher** - Implement Windows Git discovery, WSL translation,
  environment preservation, stream fidelity, and exit propagation.
- [x] **Phase 4: Isolated live integration** - Prove real WSL/Ripwire behavior against disposable
  standalone and linked-worktree fixtures through the finished toolkit, reusing Phase 0 coverage.
- [x] **Phase 5: Plugin integration and documentation** - Register the skill, update package
  versions and docs, and record the as-built artifact.

## Phase Candidates

No optional candidates are approved for V1. MCP support requires a new specification and gate.

---

## Phase 0: Live Feasibility Gate

### Execution Status

**Cache-enabled rerun: Pass; user go/no-go acceptance received (2026-09-10).**
All 18 feasibility groups passed against pinned Ripwire v0.5.0 on the recorded Ubuntu x86-64
host, including new-process source-cache hits, cold/warm/fresh-result equality, dirty-source
and HEAD freshness, same-size/same-mtime edits, separate worktree namespaces, and recovery
from missing/corrupt source and history caches. Monitored writes stayed within managed cache
storage; cleanup succeeded. This is test-harness evidence, not a finished production launcher.

**Historical result: original run failed the former zero-cache-delta contract (2026-09-10).**
Live linked-worktree identity, dirty-source content, caller/history queries, and real WSL
argument/environment/raw-stream/exit transport passed. Target source, Git metadata/configuration,
and the skills workspace remained unchanged. However, `--for` creates a `ripwire-qchurn-*.bin`
history cache despite `--no-cache`, inside the probe's disposable Linux `TMPDIR`. Cleanup succeeded.
See `CodeResearch.md`, Live Phase 0 Evidence, for reproduction and public upstream source.

The user has approved managed persistent Linux caching and retained exploration as the V1 scope.
This supersedes the zero-cache-delta requirement, not the historical observation. The revised
probe enables caching and enforces the approved write boundary. The user accepted this evidence
and authorized all remaining phases without routine phase approvals. Production cache ownership,
locking, and maintenance are still future work.

### Changes Required

- **`Tests/Ripwire-Wsl-Toolkit.Tests.ps1`**: Add an explicit `-Mode Feasibility` using the existing
  standalone PowerShell test style. Create a disposable Windows Git repository with small C++
  source files containing a known function and caller, two commits, and a Windows-created linked
  worktree whose path contains spaces and Unicode. Give the linked worktree a different HEAD from
  the fixture's main checkout and add an uncommitted symbol/change only there. Neither the skills
  repository nor any operator project is the Ripwire target; all source/Git mutations use Windows.
- **`Tests/fixtures/ripwire-wsl/`**: Add only reusable probe assets: a minimal Windows
  ProcessStartInfo runner, Linux bootstrap, and Linux argument/environment/byte-output probe.
  Use the same explicit distribution, `wslpath`, child-only WSLENV, `/bin/bash`, raw stream pumps,
  and Git override contract planned for Phase 3. The probe is test infrastructure, not a second
  supported launcher. Read the pinned release/hash from `Spec.md` until Phase 1 supplies the
  manifest; consolidate that metadata into the manifest in Phase 1.
- Keep acquisition minimal: no production installer, doctor, plugin registration, or user
  configuration. Require explicit phase execution approval, an existing Ubuntu distribution,
  and a disposable Linux prefix. Use an already-staged test binary with provenance tying it to
  the pinned checksummed archive, or obtain separate approval and require both `-AllowDownload`
  and `-AllowInstall` for checksum-verified staging. Missing prerequisites mean **Blocked**, not
  permission to enable WSL or replace a distribution.
- Run the transport probe through **real `wsl.exe` and Bash**, not a fake WSL executable.
  Record exact argv boundaries and the Linux environment; compare against independent expected
  values. Test spaced/Unicode/quoted/empty/backslash/equals-sign/path-like values at this lower-level
  boundary even where the eventual public option grammar rejects those tokens.
- Run pinned Ripwire through that same transport against both fixture roots, with the sole
  positional root and default caching enabled (no injected `--no-cache`). Direct both cache families
  into separate private namespaces in a disposable `-LinuxCacheRoot`, retained between subprocess
  calls for the duration of the test. Prove default orientation, stamped `--for`, a known caller
  query, and a Git-backed `--pr-context` query against fixture history. Check that linked-worktree
  results reflect its distinct HEAD and uncommitted content, not the main checkout.
- Reuse Phase 4's independent Windows Git/`wslpath` identity oracles, baseline timing, and fsmonitor
  positive/negative controls. Capture source, metadata, configuration, and cache/sidecar snapshots
  after fixture/staging/cache-root setup. Only declared cache/lock subtrees may change; the rest
  of the Linux prefix, target/Git/configuration, and primary workspace must stay unchanged. Cleanup
  removes the explicitly created fixture, staging, and test cache at the end, not between warm runs.
- Repeat identical queries through new processes with the same namespace and demonstrate actual
  source-index reuse, using upstream cache-hit diagnostics or another independent reuse observable,
  not merely file existence or a faster elapsed time. Compare results with a fresh empty test
  namespace; then change an uncommitted body and advance HEAD using Windows Git and verify fresh
  results in the reused namespace. Record cold/warm timings as observations, not a pass threshold.
- Exercise missing/corrupt entries and namespace isolation across linked worktrees. Rebuilds must
  stay inside managed storage and preserve results; an out-of-namespace write or stale result fails
  the gate. The minimal probe need not implement the production maintenance interface yet.
- **`.paw/work/ripwire-wsl-toolkit/CodeResearch.md`**: Record reproducible commands, pinned binary
  provenance, host/runtime versions without personal identifiers, expected versus observed
  results, limitations, and a `Pass | Blocked | Fail` gate outcome. No fabricated pass from mocks,
  skipped live cases, Git discovery alone, or a successful binary `--version`.

### Success Criteria

#### Automated Verification

- [x] Explicit `pwsh -NoProfile -File .\Tests\Ripwire-Wsl-Toolkit.Tests.ps1 -Mode Feasibility`
  with disposable paths and approved staging inputs completes all live cases; default test modes
  never select Feasibility or invoke live WSL.
- [x] Standalone and linked-worktree root/Git metadata match independent oracles; stamped Ripwire
  output matches the linked worktree's own HEAD and dirty state, and analysis finds its uncommitted
  symbol/caller content. Results cannot also pass by reading the main checkout.
- [x] Real Windows-to-WSL transport preserves exact argument boundaries, imported Git override
  order, and byte-identical parent environment. Malformed inherited blocks fail before WSL starts.
- [x] Both output streams preserve UTF-8, invalid bytes, CRLF, empty output, and no final newline;
  concurrent output larger than pipe capacity finishes within a timeout, including partial output
  followed by a chosen non-zero exit whose code propagates exactly.
- [x] Fsmonitor sentinel fires in the positive control but not under the final override; analysis
  leaves source, Git metadata/configuration, binaries, and out-of-namespace paths unchanged.
- [x] Persistent source/history cache reuse across processes is observable; cached and fresh
  results agree, including after dirty-source/HEAD changes. Each worktree has its own namespace.
  Test cleanup removes all disposable cache data, and failures remain explicit.

#### Manual Verification and Go/No-Go

- [x] Present observed evidence and supported host scope to the user before starting Phase 1.
  Passing this gate reduces architectural uncertainty; it does not establish all option,
  architecture, installer, or production-launcher behavior.
- [x] Fix reproducible probe/transport defects within this bounded scope and rerun affected cases.
  If core worktree identity, dirty-file analysis, or faithful transport requires upstream changes
  or relaxing the same-worktree contract, mark **Fail** and stop the toolkit implementation.
- [x] Optional-command limitations require an explicit user-approved scope revision; do not count
  a reduced feature set as a pass against the current spec. Never substitute a main checkout,
  second clone, rewritten `.git`, or loss of dirty-worktree correctness.
- [x] Missing runtime/access/staging permission is **Blocked** with remediation, not a failed
  compatibility finding. Neither Blocked nor Fail permits downstream implementation.

---

## Phase 1: Package Contracts and Deterministic Core

### Execution Status

Completed: packaged skill/guide/evals, authoritative release policy, strict JSON/configuration
parsing, invocation/environment/native-process helpers, and shared Linux cache bootstrap.
PowerShell 7 deterministic tests and Windows PowerShell 5.1 static tests pass. Opt-in
`Tests/Ripwire-Wsl.Bootstrap.Tests.ps1 -Distribution <Ubuntu-name>` exercises the real bootstrap
with disposable Linux fixtures, including read-only diagnosis, escaped links, unsafe permissions,
linked lock files, a simulated foreign-owner observation, and scoped clear.

Implementation review found a missing-architecture case and missing cache rejection coverage;
both were addressed. The manifest remains the single option-policy source: runtime parsing
enforces metadata consistency and exact pinned-policy tests detect accidental grammar changes,
rather than duplicating the entire option table inside PowerShell. No production installer or
public launcher is claimed complete by this phase.

### Changes Required

- Begin only after Phase 0 passes and the user accepts the go/no-go evidence. Move the proven
  transport components into the planned shared helpers/bootstrap as appropriate; retain independent
  probe oracles and regression fixtures rather than maintaining two production implementations.
- **`plugins/devtools/skills/ripwire-wsl/SKILL.md`**: Add a model-invoked skill with triggers for
  Windows-session Ripwire analysis. Keep the agent path short: confirm the current worktree, invoke
  the bundled launcher, keep mutations and verification on Windows, and surface unsupported states.
- **`plugins/devtools/skills/ripwire-wsl/references/guide.md`**: Document human setup, supported
  boundaries, local configuration, release pin, troubleshooting, mounted-filesystem performance,
  the CLI-only/single-worktree contract, persistent cache retention/usage/clear, and the absence of
  an OS-level write barrier. Distinguish managed caches from project baselines.
- **`plugins/devtools/skills/ripwire-wsl/references/release.json`**: Declare `v0.5.0`, source commit
  `bacfa3b7b3ad13648ce3892de06af05b6b55a2ac`, accepted probe values
  (`x86_64|amd64`, `aarch64|arm64`), normalized assets (`x64`, `arm64`), URLs, archive SHA-256,
  expected archive root/payload, and the exact selector/modifier table in `Spec.md`. Store option
  spelling, kind, attached-value grammar, repeatability, dependencies, and rejection category.
- **`plugins/devtools/skills/ripwire-wsl/scripts/RipwireWsl.Common.ps1`**: Centralize typed/structured
  configuration and launch-context construction, manifest/config parsing, canonical worktree
  normalization, invocation classification, architecture mapping, child-only WSLENV composition,
  cache namespace/ownership/containment validation, and command-result handling. Use closed states
  from `Spec.md` and exhaustive switches; do not use
  boolean bags or success-shaped fallbacks.
- **`plugins/devtools/skills/ripwire-wsl/scripts/invoke-ripwire-wsl.sh`**: Add the Linux bootstrap
  contract for validating imported worktree/Git variables and `GIT_CONFIG_COUNT`, preserving every
  indexed pair, appending `core.fsmonitor=false`, printing JSON only in diagnostic mode, and running
  `exec "$RIPWIRE_BIN" "$@"`. Analysis acquires namespace access and prepares owned cache paths;
  internal diagnostics must neither create caches nor invoke a cache-writing Ripwire doctor.
- **`.gitattributes`**: Pin
  `plugins/devtools/skills/ripwire-wsl/scripts/*.sh text eol=lf` so the packaged bootstrap is
  runnable from Windows checkouts. Tests also verify LF bytes.
- **`plugins/devtools/skills/ripwire-wsl/evals/evals.json`**: Cover analysis invocation, missing
  setup, requests to install or alter WSL automatically, MCP requests, and edit requests.
- **`Tests/Ripwire-Wsl-Toolkit.Tests.ps1`**: Add deterministic manifest, configuration,
  architecture, worktree-validation, and Git-override tests using local assertions and disposable
  fixtures.

### Success Criteria

#### Automated Verification

- [x] `pwsh -NoProfile -File .\Tests\Ripwire-Wsl-Toolkit.Tests.ps1 -Mode Unit`
- [x] Manifest tests reject unknown architectures, missing fields, duplicate mappings, invalid
  SHA-256 values, and version/asset-name mismatches.
- [x] Git/WSLENV tests cover absent and empty blocks, valid populated blocks, duplicate names,
  path/list flags, indexed variables beyond the declared count, non-numeric counts, missing indexed
  keys/values, conflicting partial blocks, Unicode values, and byte-identical parent environment.
- [x] Invocation tests classify every pinned option as allowed analysis or rejected control and
  reject unknown flags and all non-flag user arguments. Attached `--name=value` is the only
  value-bearing form; tests cover missing, empty, duplicate, incompatible, and repeated selectors.
- [x] Bootstrap bytes are LF-only, its Windows path is translated explicitly, and the WSL command
  invokes `/bin/bash` rather than relying on NTFS executable bits or a shebang.
- [x] Static package tests find no username, absolute checkout path, session branch, Git metadata
  path, or host MCP configuration.
- [x] Cache-key tests separate linked worktrees and release/architecture versions while retaining a
  namespace across HEAD changes. Reject unsafe ownership, escaped links, Windows-backed paths,
  and installation/target/Git overlap. Environment tests preserve parent cache settings.

#### Manual Verification

- [x] `SKILL.md` uses a concise trigger pointer and discloses setup detail through `guide.md`.
- [x] The common module exposes closed result variants for external command and configuration
  outcomes; no `any`-equivalent loose object or success-shaped fallback obscures failure origin.

---

## Phase 2: Installer and Doctor

### Execution Status

Complete. The public installer and doctor passed deterministic coverage and disposable Ubuntu
installation. Real Bash transaction tests exercise sibling renames, staged/post-swap health,
rollback failures, cleanup failures, binary bytes/mode, and configuration restoration. Review
identified an open archive layout and missing real failure transitions; both are covered now.
The manifest declares expected top-level files/subtrees, all entries are validated, and only
the executable is extracted. Real bootstrap tests cover diagnosis, private cache paths,
ownership/link rejection, contention, and explicit clear failure.

### Changes Required

- **`plugins/devtools/skills/ripwire-wsl/scripts/Install-RipwireWsl.ps1`**: Read the release manifest;
  require PowerShell 7; validate `/etc/os-release` as Ubuntu 20.04+, WSL generation, Linux
  architecture, Git, and `tar`; download the declared asset; verify archive SHA-256; list and reject
  unsafe or unexpected archive entries; extract into a new staging directory; verify a regular
  executable payload and staged `--version`; swap within the user-owned
  `$HOME/.local/share/brownch-devtools/ripwire-wsl/<version>/bin` directory; run post-swap health;
  roll back binary/config after any failure; and atomically commit the versioned config last.
  `-LinuxInstallRoot` replaces the default root for isolated tests.
  `-LinuxCacheRoot` selects private Linux cache storage and is recorded in config separately from
  the transactional binary prefix. Create/validate only owned cache-root metadata during setup;
  do not purge existing valid cache namespaces on reinstall, rollback, or upgrade.
  Binary staging and backup are sibling paths under the destination parent; the config temporary
  and backup are sibling paths under the config parent. Every commit/rollback transition uses a
  same-filesystem rename, and cleanup failure is reported separately from rollback success/failure.
- **`plugins/devtools/skills/ripwire-wsl/scripts/Test-RipwireWsl.ps1`**: Implement read-only named
  checks for Windows Git, WSL, selected distribution, WSL version, Linux Git, archive support,
  release manifest, local configuration, installed binary, version, recorded release/archive
  identity, path translation, and required worktree readiness when `-WorktreePath` is supplied.
  Include resolved cache location, ownership/permissions, namespace readiness, and usage. If the
  namespace does not yet exist, report first-use creation without creating a probe file. Do not
  run upstream cache-writing diagnostics to implement the read-only toolkit doctor.
  Never compare installed-binary bytes to the archive digest; emit Skipped when no binary digest is
  declared.
  Emit the stable diagnostic schema from `Spec.md`, with `-Json` for automation.
- **`plugins/devtools/skills/ripwire-wsl/scripts/Clear-RipwireWslCache.ps1`**: Add explicit
  per-worktree maintenance using the configured release/architecture and `-ConfigPath`. Validate
  ownership/containment, coordinate with analysis using the same namespace lock, and delete only
  that namespace's derived cache data. Never remove the root, another worktree/version, installation,
  source, or Git metadata. Report failure; no silent success after failed deletion.
- **`Tests/Ripwire-Wsl-Toolkit.Tests.ps1`**: Mock download, hashing, WSL, Linux architecture, archive,
  and version calls. Cover clean install, repeat install, stale install, checksum mismatch,
  unsupported architecture, partial install, missing prerequisite, and failed atomic replacement.

### Success Criteria

#### Automated Verification

- [x] `pwsh -NoProfile -File .\Tests\Ripwire-Wsl-Toolkit.Tests.ps1 -Mode Setup`
- [x] Wrong checksum, unsafe archive, unexpected layout, link payload, wrong version, unrunnable
  staged binary, failed swap, failed post-swap health, and failed config commit preserve or restore
  binary bytes/mode and config bytes.
- [x] Failure injection covers every sibling rename, post-swap health, rollback rename, config
  commit, and cleanup transition.
- [x] Missing WSL, distribution, Windows Git, Linux Git, or archive tooling produces distinct
  actionable failures and zero installation commands.
- [x] Repeating a matching install produces one configured installation and no duplicate path or
  config entries.
- [x] Doctor fixtures report ready, warning, and failed states deterministically and perform no
  writes.
- [x] Cache maintenance tests cover selected-namespace deletion, absent cache, unsafe path/owner,
  active analysis contention, bounded lock failure, and cleanup failure. Other namespaces and
  binary/configuration bytes remain unchanged; installation rollback does not clear valid caches.

#### Manual Verification

- [x] Host prerequisite messaging asks for separate human action; no path enables Windows features
  or installs/unregisters/replaces a distribution.
- [x] Machine-local configuration contains no repository-specific branch or Git metadata path.

---

## Phase 3: Worktree-Aware Launcher

### Execution Status

Completed in parallel with Phase 2 after the shared Phase 1 contracts, matching the independent
setup/launcher todo dependencies. The public wrapper uses common configuration/context validation
and raw streaming. Ten deterministic groups exercise real Windows Git fixtures and a compiled
native WSL -> fake bootstrap -> fake Ripwire chain, including exact endpoint arguments, preserved
overrides plus final fsmonitor suppression, raw concurrent streams, failure codes, translation
failures, and namespace identity. Separate opt-in tests exercise the real Linux bootstrap.

Phase review initially identified that the native shim stopped at the WSL boundary; the fixture
now reaches the fake Ripwire endpoint. This remains transport-contract evidence, not a substitute
for Phase 4's real Ripwire run through the finished toolkit.

### Changes Required

- **`plugins/devtools/skills/ripwire-wsl/scripts/Invoke-RipwireWsl.ps1`**: Require
  `-WorktreePath`; require PowerShell 7; load validated local configuration; canonicalize the
  worktree including trailing separators and drive-letter casing; use Windows Git to resolve the
  exact worktree, Git directory, and common directory; translate known filesystem fields through
  the configured distribution; parse all user tokens as pinned analysis flags only; construct the
  sole positional Linux root; preserve and extend `WSLENV` in one child environment; invoke WSL
  exactly as `wsl.exe --distribution <name> --cd <linux-root> --exec /bin/bash -- <translated-linux-bootstrap> -- <linux-root> <allowed-args>`;
  set `RIPWIRE_BIN` and internal diagnostic mode through the child environment; pump raw
  stdout/stderr streams concurrently; and return the child exit code.
  Select the validated managed namespace, pass child-only `TMPDIR`, `XDG_CACHE_HOME`, and
  `GIT_OPTIONAL_LOCKS=0`, and coordinate exclusive same-namespace access for the process lifetime.
  Cache state survives normal invocation completion; do not add a per-query cache deletion.
- **`plugins/devtools/skills/ripwire-wsl/scripts/RipwireWsl.Common.ps1`**: Add ProcessStartInfo-based
  native argument handling that preserves empty, quoted, spaced, Unicode, trailing-backslash,
  equals-sign, and path-like values without converting arbitrary arguments based on filesystem
  existence. Tests use PATH-prepended executable shims or an injectable runner that
  ProcessStartInfo actually invokes; PowerShell function mocks are not the process boundary.
- **`Tests/Ripwire-Wsl-Toolkit.Tests.ps1`**: Use fake Windows Git, `wsl.exe`, Linux bootstrap, and
  Ripwire executables to assert exact commands, environment, streams, and exit behavior.

### Success Criteria

#### Automated Verification

- [x] `pwsh -NoProfile -File .\Tests\Ripwire-Wsl-Toolkit.Tests.ps1 -Mode Launcher`
- [x] Standalone and linked-worktree fixtures produce exact resolved launch contexts without
  changing `.git`, local config, or global config.
- [x] Invalid directories, deleted worktrees, mismatched roots, and failed path translation stop
  before Ripwire starts.
- [x] Alternate roots, unknown options, MCP/listen, edit, baseline, caller-directed cache/index/output, and every
  excluded pinned option stop before `wsl.exe` starts with a stable error code.
- [x] Empty, quoted, spaced, Unicode, backslash, equals-sign, and path-like non-path arguments reach
  the fake child with exact boundaries.
- [x] Empty output, UTF-8, CRLF, no-final-newline, invalid byte sequences, and partial output before
  non-zero exit are copied byte-for-byte; launcher diagnostics are on stderr; exit codes are
  unchanged.
- [x] Independent asynchronous pumps drain stdout and stderr concurrently and are both awaited.
  A bounded-time shim writes more than pipe capacity to both streams and proves no deadlock.
- [x] The child receives existing valid Git override entries followed by
  `core.fsmonitor=false`; the parent environment remains unchanged.
- [x] Repeated calls select the same managed namespace and different worktrees select different
  ones; neither `--no-cache` nor arbitrary output paths are injected. Cache path/permission/lock
  failures stop explicitly, with no fallback into the target or shared default directories.

#### Manual Verification

- [x] Agent-facing usage requires only the current worktree and analysis arguments.
- [x] No fallback or search logic can select the main checkout.

---

## Phase 4: Isolated Live Integration

### Execution Status

Complete: 20 groups passed through the public toolkit, both with approved disposable setup and
with a separately staged installation without download/install permissions. Both runs cleaned
their fixtures; the pre-staged run retained the supplied configuration and binary.

Live qualification found two gaps before passing. The modifier smoke test combined incompatible
upstream output shapes; the manifest now enforces the pinned companion, paging, and JSON rules.
More importantly, `--situ` caused Git diff to refresh `.git/index` stat data despite optional locks
being disabled. The bootstrap now appends `diff.autoRefreshIndex=false` before the final
`core.fsmonitor=false`; selector-by-selector snapshots and the complete live run confirm unchanged
source and Git metadata. This is not a filesystem sandbox.

Run live integration without concurrent tests or edits in this repository: its workspace snapshots
deliberately detect temporary launcher fixtures and other changes. Final SoT review and the
post-remediation verification are complete; see Final review decisions below.

### Changes Required

- Rerun Phase 0's live cases through the finished launcher and doctor, not just the feasibility
  runner. This is full integration/regression coverage, not the first architectural viability test.
- **`Tests/Ripwire-Wsl-Toolkit.Tests.ps1`**: Add an explicit `-Mode Integration` path that creates a
  temporary Windows repository plus a Windows-created linked worktree containing spaces and Unicode.
  Integration never uses the operator's normal installation. It requires disposable
  `-ConfigPath` and `-LinuxInstallRoot`; download/install additionally require both
  `-AllowDownload` and `-AllowInstall`. Without both capabilities, Integration requires an
  already-staged test binary and performs no network or install mutation.
  Require a separate disposable `-LinuxCacheRoot`; retain its namespaces between warm queries and
  remove them only during declared test cleanup. Cache writes do not require download/install
  permissions and do not authorize writes to the binary prefix or configuration.
- Exercise Ripwire root/orientation, targeted analysis, dirty-state analysis, and Git-backed history
  queries. Use doctor JSON plus bootstrap diagnostic mode to compare canonical Windows/Linux root,
  Git directory, common directory, and imported environment to independent Windows Git and
  `wslpath` results. Use a stamped Ripwire `--for` invocation and compare its `at` attribute to the
  first nine characters of Windows `HEAD` plus expected `+dirty`/`+shallow` suffixes.
- Independent oracles use:
  `git -C <root> rev-parse --show-toplevel`,
  `git -C <root> rev-parse --absolute-git-dir`,
  `git -C <root> rev-parse --git-common-dir`,
  `git -C <root> rev-parse HEAD`,
  `git -C <root> rev-parse --is-shallow-repository`,
  `git -C <root> status --porcelain`, and
  `wsl.exe --distribution <name> --exec wslpath -a -u -- <windows-path>`.
  Relative common-directory output is resolved against the canonical worktree before translation.
- Canonical comparison trims trailing separators, resolves full paths and links where the platform
  API exposes them, compares Windows paths case-insensitively, and compares Linux paths exactly.
  The non-mutation baseline is captured after fixture and optional test installation setup but
  before launcher/doctor execution. Only managed cache/lock subtrees may change during analysis;
  target, Git, config, binary prefix, and out-of-namespace sidecars must not. Toolkit doctor has
  no write exception. Declared source/HEAD/cache-corruption setup starts a new snapshot interval.
- Add a synthetic `core.fsmonitor` hook sentinel in the fixture and prove that Ripwire's Git calls
  do not execute it under the launcher override. A positive-control arm runs the same Git operation
  without the appended override and must create the sentinel; the launcher arm must not.
- Snapshot fixture content, Git status/config, and primary repository status before and after
  non-editing scenarios.

### Success Criteria

#### Automated Verification

- [x] `pwsh -NoProfile -File .\Tests\Ripwire-Wsl-Toolkit.Tests.ps1 -Mode Integration` with explicit disposable parameters
- [x] Doctor/bootstrap diagnostic output reports the same canonical root, translated Git directory,
  and translated common directory as independent Windows Git plus `wslpath`.
- [x] A stamped `--for` result reports the expected nine-character `HEAD` prefix and dirty/shallow
  suffix.
- [x] Dirty-file and Git-backed queries observe fixture changes.
- [x] Finished-toolkit cold/warm/fresh-namespace comparisons reproduce Phase 0 cache evidence;
  edits and HEAD changes remain fresh. Explicit clear followed by analysis rebuilds safely,
  concurrent same-namespace operations are coordinated, and other worktrees are unaffected.
- [x] Spaces and Unicode survive the real Windows-to-WSL boundary.
- [x] The fsmonitor sentinel is not created, the stamped result proves Git executed, and bootstrap
  diagnostic output proves preexisting valid override entries remain visible to the child.
- [x] Failure cases preserve exact non-zero exit codes and actionable stderr.
- [x] Before/after snapshots cover fixture source, `.git`, Windows local/global config, disposable
  toolkit config, disposable Linux prefix, cache/sidecar paths, and primary repository; documented
  cache/lock changes and documented test setup/maintenance/cleanup are the only allowed differences.

#### Manual Verification

- [x] Review output for truthful limitations: mounted-drive performance, raw `.git` parser
  limitations, CLI-only support, and one-worktree-per-process.
- [x] Confirm Integration mode was explicitly selected with disposable config and Linux prefix and
  any real download or WSL install had explicit human approval.
- [x] Integration without `-AllowDownload` and `-AllowInstall` records `PreStagedNoInstall`,
  takes no acquisition/install branch, and preserves configuration and binary snapshots.

---

## Phase 5: Plugin Integration and Documentation

### Execution Status

Complete. Plugin and marketplace versions are synchronized at 1.5.0, the staged package discovers
the new skill, and the existing plugin installer remains compatible. The guide and as-built
reference cover setup versus plugin installation, diagnostics, invocation, cache retention/clear,
supported modifier combinations, reproduction commands, and known platform boundaries.

### Changes Required

- **`plugins/devtools/plugin.json`**: Register `skills/ripwire-wsl` and update package description,
  keywords if warranted, and plugin version.
- **`.github/plugin/marketplace.json`**: Synchronize marketplace metadata and plugin entry versions.
- **`plugins/devtools/README.md`**: Add the skill to included capabilities and state its runtime
  prerequisites and non-MCP boundary.
- **`README.md`**: Add the capability to the repository catalog and document its verification
  command.
- **`plugins/devtools/CHANGELOG.md`**: Record the new skill, pinned upstream release, launcher,
  installer, doctor, persistent managed cache/clear, tests, and version bump.
- **`.paw/work/ripwire-wsl-toolkit/Docs.md`**: Record the as-built interfaces, configuration
  location contract, release identity, diagnostics, verification commands, and known limitations
  using `paw-docs-guidance`.

### Success Criteria

#### Automated Verification

- [x] `pwsh -NoProfile -File .\Tests\Install-DevTools.Tests.ps1`
- [x] `pwsh -NoProfile -File .\Tests\Ripwire-Wsl-Toolkit.Tests.ps1 -Mode Unit`
- [x] `pwsh -NoProfile -File .\Tests\Ripwire-Wsl-Toolkit.Tests.ps1 -Mode Setup`
- [x] `pwsh -NoProfile -File .\Tests\Ripwire-Wsl-Toolkit.Tests.ps1 -Mode Launcher`
- [x] `powershell.exe -NoProfile -File .\Tests\Ripwire-Wsl-Toolkit.Tests.ps1 -Mode Unit`
- [x] JSON parsing succeeds for plugin, marketplace, release, and eval manifests.
- [x] Plugin and marketplace versions are identical.
- [x] A package-level discovery test loads the staged `plugin.json`, resolves every listed skill
  directory, validates `ripwire-wsl/SKILL.md` frontmatter, and proves the result comes from the
  package under test without touching the user's Copilot configuration.
- [x] Manifest/static tests pass under Windows PowerShell 5.1; runtime scripts return the documented
  unsupported-runtime code before side effects.

#### Manual Verification

- [x] Documentation distinguishes plugin installation, Ripwire runtime installation, doctor, and
  agent invocation, plus persistent cache retention/maintenance versus deferred baseline workflows.
- [x] Documentation contains no internal scratch paths, private session names, machine-specific
  settings, or unsupported MCP/read-only claims.
- [x] Public technical references cover upstream Ripwire, Git, and Microsoft WSL behavior.

---

## Fleet Coordination

Phase 0 is the first blocking dependency. No Phase 1-5 worker starts before its evidence is accepted;
installer/doctor and full launcher development must not run speculatively alongside feasibility.

Implementation can use at most two bounded workers when phases expose independent surfaces:

- Package instructions/references/evals can proceed in parallel with deterministic test-harness
  scaffolding after Phase 1 contracts are fixed.
- Installer/doctor implementation and launcher implementation remain separate work items but both
  depend on the Phase 1 common contracts.
- Phase 4 full integration depends on completed installer, doctor, and launcher work; Phase 0
  feasibility deliberately does not.
- The coordinating agent integrates all work and independently accepts each checkpoint.

## Planning Review Gate

Before implementation, run independent reviews of `WorkflowContext.md`, `WorkShaping.md`, `Spec.md`,
`CodeResearch.md`, and `Plan.md` with:

- `gpt-5.6-sol-fast`
- `gemini-3.8-flash`
- `grok-4.6`

Review for feasibility, specification coverage, fixture/oracle quality, scope control, and type/state
model gaps. Synthesize findings, revise artifacts for confirmed issues, and present the final plan
for human approval. Approval to revise this plan is not execution approval. Explicit Phase 0
approval authorizes only the bounded feasibility work; real download/WSL staging additionally
requires the capabilities and permission described above. Present its outcome for acceptance
before Phase 1. Final review and PR gates remain unchanged.

The prior two-cycle review covered the earlier sequence. This user-directed revision adds a
blocking feasibility gate and managed caching; it does not claim those reviewers reviewed these revisions.

## Acceptance Coverage Matrix

| Obligation | Phase | Fixture/action | Oracle | Failure control |
|---|---:|---|---|---|
| SC-001 root/commit/dirty | 0,4 | Disposable roots with distinct HEADs; live probe then finished toolkit; stamped `--for` | Canonical path equality; 9-char Windows HEAD with dirty/shallow suffix and uncommitted content | Fail if stamp absent, main checkout substituted, or diagnostic lacks Git fields |
| SC-002 non-mutation | 0,3-4 | Snapshot target, Git config, toolkit config/prefix, caches, primary repo | Exact comparison outside declared managed cache/lock and setup paths | Fail on any undeclared delta |
| SC-003 args/streams/exit | 0,3-4 | Real WSL/Bash byte probe first; deterministic shims and finished-toolkit rerun; over-pipe-capacity output | Exact argv records and byte-array equality | Assert one child start, bounded completion, and exact exit |
| SC-004 Git overrides | 0-1,3-4 | Empty, populated, malformed, duplicate, extra-index, Unicode WSLENV/GIT blocks plus fsmonitor positive/negative control arms | Ordered child diagnostic entries; parent bytes unchanged; sentinel fires only without override | WSL not started for malformed state or failed positive control |
| SC-005 install outcomes | 2 | Clean, repeated, stale, bad hash, unsupported arch/runtime, partial install, every same-filesystem rename failure | Transaction state, command log, binary/config snapshots | No commit before staged health; rollback after later failure; ARM64 qualified by staged health |
| SC-006 doctor | 2 | One fixture per Windows/WSL/Linux/config/install/worktree layer | Stable diagnostic code/status/remediation JSON | Zero writes and exact probe count |
| SC-007 portability/policy | 1,5 | Package scan and option-policy fixtures | No machine identities; CLI-only/single-root text; closed allowlist | Reject unknown/write/control options |
| SC-008 runner compatibility | 0-5 | Default deterministic mode; explicit Feasibility and Integration | Expected mode list and exit 0 | Default never invokes live WSL; 5.1 runtime exits before effects |
| SC-009 plugin discovery | 5 | Staged package manifest/frontmatter validation | Skill resolves from package path/version under test | No user Copilot config access |
| SC-010 analysis boundary | 1,3 | Exact Spec option table; every other known/unknown flag and non-flag token | Invocation variant and stable rejection code; rejected invocations start no WSL | Rejected invocations leave target, caches, and parent environment unchanged |
| SC-011 transaction | 2 | Detected pre/post-swap command failures, serialized setup | Prior bytes/mode/config preserved or restored; rollback failures reported | Inject command failure at each transition; crash recovery and concurrent shared-config setup excluded |
| SC-012 cache reuse/freshness | 0,3-4 | Warm process, fresh namespace, dirty edit, HEAD change, second worktree | Observable source-cache reuse and equivalent current results; timings recorded | Stale results or shared worktree namespaces fail |
| SC-013 cache write boundary/maintenance | 0-4 | Missing/corrupt cache, unsafe paths, permission/lock failures, explicit clear | Only owned cache/lock changes; safe rebuild and scoped clear | No fallback, deletion outside namespace, or silent failure |

The deterministic test script defaults to `AllDeterministic` and runs Unit, Setup, Launcher,
manifest, and package checks as they are implemented. `Feasibility` and `Integration` are opt-in,
never included by the default mode, and require disposable Linux staging/install paths.
`Integration` additionally requires a disposable `-ConfigPath`. Neither live mode may download or
stage a binary without the separate approval and capability flags described in its phase.

## Final review decisions

The final SoT used the initial ten-specialist sweep plus two debate rounds, with OpenAI, Grok,
Gemini, and an explicit type-safety lens. The testing worker produced no second-round artifact;
the parent supplied explicitly attributed testing-lens responses in rounds 2 and 3. No factual
disputes remained after round 3. All 17 dispositions were settled before resuming remediation.

Only F03 authorizes a runtime change: reject unsupported inherited Git redirection before WSL
starts, preserving supported indexed overrides and unrelated environment state. F02/F04/F07/F08/F11
are documentation-only accepted limits: interruption recovery, trusted executable configuration,
orphan/old-release cache maintenance, transient lock-free diagnosis, and concurrent shared-config
setup. F06 is deferred; F12 and F15 preserve current diagnostics and coverage. F01/F05/F13/F17
were skipped or factually withdrawn; F09/F10/F16 await measurements; F14 preserves bounded locking.

Post-remediation verification is complete against the accepted contract. Nine specialist workers
returned no actionable findings; the parent covered the testing lens with explicit GPT-6 Astra
attribution. This was a focused verification pass, not a fourth global debate round.

F03 unit and native-launcher coverage passed, including rejection before any WSL start. An earlier
live run reached the primary-workspace snapshot assertion while review artifacts were changing.
The isolated fresh-install rerun passed all 20 groups with successful cleanup and unchanged primary
workspace, targets, Git metadata, configuration, and parent environment. The same strict snapshot
oracle remains; only differing-path diagnostics were improved. Raw reports and review scratch
artifacts remain local.

All implementation and review gates are complete. Update existing draft PR #3 with these outcomes
and preserve the planning documents in commit history under the configured commit-and-clean
lifecycle. The PR remains draft for the human handoff; no merge is authorized.

## References

- `.paw/work/ripwire-wsl-toolkit/WorkflowContext.md`
- `.paw/work/ripwire-wsl-toolkit/WorkShaping.md`
- `.paw/work/ripwire-wsl-toolkit/Spec.md`
- `.paw/work/ripwire-wsl-toolkit/CodeResearch.md`
- [Ripwire v0.5.0 release](https://github.com/redhat-et/ripwire/releases/tag/v0.5.0)
- [Ripwire v0.5.0 source](https://github.com/redhat-et/ripwire/tree/bacfa3b7b3ad13648ce3892de06af05b6b55a2ac)
- [Microsoft WSL filesystem guidance](https://learn.microsoft.com/windows/wsl/filesystems)
- [Microsoft WSL commands](https://learn.microsoft.com/windows/wsl/basic-commands)
