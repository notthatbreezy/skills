# Ripwire WSL Toolkit Plan

## Overview

Add a model-invoked `ripwire-wsl` skill to the existing `brownch-devtools` plugin. The skill will
present a small analysis interface to agents while colocated scripts own installation, diagnostics,
Windows Git discovery, WSL path conversion, child-environment construction, and Ripwire process
execution.

The implementation will consume pinned upstream `v0.5.0` Linux release assets for x86-64 and ARM64.
It will be independently authored; the unlicensed public launcher gist remains research evidence,
not source material.

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
   architecture, release, and Linux binary path at
   `%LOCALAPPDATA%\brownch-devtools\ripwire-wsl\config.json`. Every script accepts `-ConfigPath`;
   installation also accepts `-LinuxInstallRoot`; tests always use disposable overrides for both.
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
   baseline, cache/index/output, and other write-capable controls before starting WSL.
7. **Independent implementation**: No code is copied from the public gist because no reuse license
   is declared.
8. **Transactional installation**: Download and extract to staging, validate archive and executable,
   preserve prior binary/config bytes through swap and post-swap health, roll back on failure, and
   commit configuration last.
9. **Raw stream contract**: Pump stdout/stderr base streams as bytes; launcher diagnostics use
   stderr separately. Runtime requires PowerShell 7.
10. **CLI-only V1**: MCP configuration and JSON protocol path adaptation remain a separate feature.

## What We're NOT Doing

- Porting Ripwire to Windows or modifying upstream.
- Installing, enabling, unregistering, or replacing WSL host components automatically.
- Cloning the target project inside WSL.
- Editing user-global MCP configuration.
- Building an MCP protocol adapter.
- Supporting arbitrary cross-root operations from one Ripwire process.
- Forwarding arbitrary upstream Ripwire options.
- Adding Pester or another test framework.
- Testing against the user's primary target project.
- Publishing, pushing, or opening the final PR during implementation unless separately authorized.

## Phase Status

- [ ] **Phase 1: Package contracts and deterministic core** - Add the skill package, release
  manifest, configuration model, and pure validation/conversion helpers with self-tests.
- [ ] **Phase 2: Installer and doctor** - Implement repeatable pinned installation and read-only
  diagnostics with mocked contract coverage.
- [ ] **Phase 3: Worktree-aware launcher** - Implement Windows Git discovery, WSL translation,
  environment preservation, stream fidelity, and exit propagation.
- [ ] **Phase 4: Isolated live integration** - Prove real WSL/Ripwire behavior against disposable
  standalone and linked-worktree fixtures.
- [ ] **Phase 5: Plugin integration and documentation** - Register the skill, update package
  versions and docs, and record the as-built artifact.

## Phase Candidates

No optional candidates are approved for V1. MCP support requires a new specification and gate.

---

## Phase 1: Package Contracts and Deterministic Core

### Changes Required

- **`plugins/devtools/skills/ripwire-wsl/SKILL.md`**: Add a model-invoked skill with triggers for
  Windows-session Ripwire analysis. Keep the agent path short: confirm the current worktree, invoke
  the bundled launcher, keep mutations and verification on Windows, and surface unsupported states.
- **`plugins/devtools/skills/ripwire-wsl/references/guide.md`**: Document human setup, supported
  boundaries, local configuration, release pin, troubleshooting, mounted-filesystem performance,
  and the CLI-only/single-worktree contract.
- **`plugins/devtools/skills/ripwire-wsl/references/release.json`**: Declare `v0.5.0`, source commit
  `bacfa3b7b3ad13648ce3892de06af05b6b55a2ac`, accepted probe values
  (`x86_64|amd64`, `aarch64|arm64`), normalized assets (`x64`, `arm64`), URLs, archive SHA-256,
  expected archive root/payload, and the exact selector/modifier table in `Spec.md`. Store option
  spelling, kind, attached-value grammar, repeatability, dependencies, and rejection category.
- **`plugins/devtools/skills/ripwire-wsl/scripts/RipwireWsl.Common.ps1`**: Centralize typed/structured
  configuration and launch-context construction, manifest/config parsing, canonical worktree
  normalization, invocation classification, architecture mapping, child-only WSLENV composition,
  and command-result handling. Use closed states from `Spec.md` and exhaustive switches; do not use
  boolean bags or success-shaped fallbacks.
- **`plugins/devtools/skills/ripwire-wsl/scripts/invoke-ripwire-wsl.sh`**: Add the Linux bootstrap
  contract for validating imported worktree/Git variables and `GIT_CONFIG_COUNT`, preserving every
  indexed pair, appending `core.fsmonitor=false`, printing JSON only in diagnostic mode, and running
  `exec "$RIPWIRE_BIN" "$@"`.
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

- [ ] `pwsh -NoProfile -File .\Tests\Ripwire-Wsl-Toolkit.Tests.ps1 -Mode Unit`
- [ ] Manifest tests reject unknown architectures, missing fields, duplicate mappings, invalid
  SHA-256 values, and version/asset-name mismatches.
- [ ] Git/WSLENV tests cover absent and empty blocks, valid populated blocks, duplicate names,
  path/list flags, indexed variables beyond the declared count, non-numeric counts, missing indexed
  keys/values, conflicting partial blocks, Unicode values, and byte-identical parent environment.
- [ ] Invocation tests classify every pinned option as allowed analysis or rejected control and
  reject unknown flags and all non-flag user arguments. Attached `--name=value` is the only
  value-bearing form; tests cover missing, empty, duplicate, incompatible, and repeated selectors.
- [ ] Bootstrap bytes are LF-only, its Windows path is translated explicitly, and the WSL command
  invokes `/bin/bash` rather than relying on NTFS executable bits or a shebang.
- [ ] Static package tests find no username, absolute checkout path, session branch, Git metadata
  path, or host MCP configuration.

#### Manual Verification

- [ ] `SKILL.md` uses a concise trigger pointer and discloses setup detail through `guide.md`.
- [ ] The common module exposes closed result variants for external command and configuration
  outcomes; no `any`-equivalent loose object or success-shaped fallback obscures failure origin.

---

## Phase 2: Installer and Doctor

### Changes Required

- **`plugins/devtools/skills/ripwire-wsl/scripts/Install-RipwireWsl.ps1`**: Read the release manifest;
  require PowerShell 7; validate `/etc/os-release` as Ubuntu 20.04+, WSL generation, Linux
  architecture, Git, and `tar`; download the declared asset; verify archive SHA-256; list and reject
  unsafe or unexpected archive entries; extract into a new staging directory; verify a regular
  executable payload and staged `--version`; swap within the user-owned
  `$HOME/.local/share/brownch-devtools/ripwire-wsl/<version>/bin` directory; run post-swap health;
  roll back binary/config after any failure; and atomically commit the versioned config last.
  `-LinuxInstallRoot` replaces the default root for isolated tests.
  Binary staging and backup are sibling paths under the destination parent; the config temporary
  and backup are sibling paths under the config parent. Every commit/rollback transition uses a
  same-filesystem rename, and cleanup failure is reported separately from rollback success/failure.
- **`plugins/devtools/skills/ripwire-wsl/scripts/Test-RipwireWsl.ps1`**: Implement read-only named
  checks for Windows Git, WSL, selected distribution, WSL version, Linux Git, archive support,
  release manifest, local configuration, installed binary, version, recorded release/archive
  identity, path translation, and required worktree readiness when `-WorktreePath` is supplied.
  Never compare installed-binary bytes to the archive digest; emit Skipped when no binary digest is
  declared.
  Emit the stable diagnostic schema from `Spec.md`, with `-Json` for automation.
- **`Tests/Ripwire-Wsl-Toolkit.Tests.ps1`**: Mock download, hashing, WSL, Linux architecture, archive,
  and version calls. Cover clean install, repeat install, stale install, checksum mismatch,
  unsupported architecture, partial install, missing prerequisite, and failed atomic replacement.

### Success Criteria

#### Automated Verification

- [ ] `pwsh -NoProfile -File .\Tests\Ripwire-Wsl-Toolkit.Tests.ps1 -Mode Setup`
- [ ] Wrong checksum, unsafe archive, unexpected layout, link payload, wrong version, unrunnable
  staged binary, failed swap, failed post-swap health, and failed config commit preserve or restore
  binary bytes/mode and config bytes.
- [ ] Failure injection covers every sibling rename, post-swap health, rollback rename, config
  commit, and cleanup transition.
- [ ] Missing WSL, distribution, Windows Git, Linux Git, or archive tooling produces distinct
  actionable failures and zero installation commands.
- [ ] Repeating a matching install produces one configured installation and no duplicate path or
  config entries.
- [ ] Doctor fixtures report ready, warning, and failed states deterministically and perform no
  writes.

#### Manual Verification

- [ ] Host prerequisite messaging asks for separate human action; no path enables Windows features
  or installs/unregisters/replaces a distribution.
- [ ] Machine-local configuration contains no repository-specific branch or Git metadata path.

---

## Phase 3: Worktree-Aware Launcher

### Changes Required

- **`plugins/devtools/skills/ripwire-wsl/scripts/Invoke-RipwireWsl.ps1`**: Require
  `-WorktreePath`; require PowerShell 7; load validated local configuration; canonicalize the
  worktree including trailing separators and drive-letter casing; use Windows Git to resolve the
  exact worktree, Git directory, and common directory; translate known filesystem fields through
  the configured distribution; parse all user tokens as pinned analysis flags only; construct the
  sole positional Linux root; preserve and extend `WSLENV` in one child environment; invoke WSL
  exactly as `wsl.exe --distribution <name> --cd <linux-root> --exec /bin/bash -- <translated-linux-bootstrap> -- <linux-root> <allowed-args> --no-cache`;
  set `RIPWIRE_BIN` and internal diagnostic mode through the child environment; pump raw
  stdout/stderr streams concurrently; and return the child exit code.
- **`plugins/devtools/skills/ripwire-wsl/scripts/RipwireWsl.Common.ps1`**: Add ProcessStartInfo-based
  native argument handling that preserves empty, quoted, spaced, Unicode, trailing-backslash,
  equals-sign, and path-like values without converting arbitrary arguments based on filesystem
  existence. Tests use PATH-prepended executable shims or an injectable runner that
  ProcessStartInfo actually invokes; PowerShell function mocks are not the process boundary.
- **`Tests/Ripwire-Wsl-Toolkit.Tests.ps1`**: Use fake Windows Git, `wsl.exe`, Linux bootstrap, and
  Ripwire executables to assert exact commands, environment, streams, and exit behavior.

### Success Criteria

#### Automated Verification

- [ ] `pwsh -NoProfile -File .\Tests\Ripwire-Wsl-Toolkit.Tests.ps1 -Mode Launcher`
- [ ] Standalone and linked-worktree fixtures produce exact resolved launch contexts without
  changing `.git`, local config, or global config.
- [ ] Invalid directories, deleted worktrees, mismatched roots, and failed path translation stop
  before Ripwire starts.
- [ ] Alternate roots, unknown options, MCP/listen, edit, baseline, cache/index/output, and every
  excluded pinned option stop before `wsl.exe` starts with a stable error code.
- [ ] Empty, quoted, spaced, Unicode, backslash, equals-sign, and path-like non-path arguments reach
  the fake child with exact boundaries.
- [ ] Empty output, UTF-8, CRLF, no-final-newline, invalid byte sequences, and partial output before
  non-zero exit are copied byte-for-byte; launcher diagnostics are on stderr; exit codes are
  unchanged.
- [ ] Independent asynchronous pumps drain stdout and stderr concurrently and are both awaited.
  A bounded-time shim writes more than pipe capacity to both streams and proves no deadlock.
- [ ] The child receives existing valid Git override entries followed by
  `core.fsmonitor=false`; the parent environment remains unchanged.

#### Manual Verification

- [ ] Agent-facing usage requires only the current worktree and analysis arguments.
- [ ] No fallback or search logic can select the main checkout.

---

## Phase 4: Isolated Live Integration

### Changes Required

- **`Tests/Ripwire-Wsl-Toolkit.Tests.ps1`**: Add an explicit `-Mode Integration` path that creates a
  temporary Windows repository plus a Windows-created linked worktree containing spaces and Unicode.
  Integration never uses the operator's normal installation. It requires disposable
  `-ConfigPath` and `-LinuxInstallRoot`; download/install additionally require both
  `-AllowDownload` and `-AllowInstall`. Without both capabilities, Integration requires an
  already-staged test binary and performs no network or install mutation.
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
  before launcher/doctor execution. With injected `--no-cache`, no target, Git, config, prefix,
  cache, or sidecar delta is permitted during analysis scenarios.
- Add a synthetic `core.fsmonitor` hook sentinel in the fixture and prove that Ripwire's Git calls
  do not execute it under the launcher override. A positive-control arm runs the same Git operation
  without the appended override and must create the sentinel; the launcher arm must not.
- Snapshot fixture content, Git status/config, and primary repository status before and after
  non-editing scenarios.

### Success Criteria

#### Automated Verification

- [ ] `pwsh -NoProfile -File .\Tests\Ripwire-Wsl-Toolkit.Tests.ps1 -Mode Integration`
- [ ] Doctor/bootstrap diagnostic output reports the same canonical root, translated Git directory,
  and translated common directory as independent Windows Git plus `wslpath`.
- [ ] A stamped `--for` result reports the expected nine-character `HEAD` prefix and dirty/shallow
  suffix.
- [ ] Dirty-file and Git-backed queries observe fixture changes.
- [ ] Spaces and Unicode survive the real Windows-to-WSL boundary.
- [ ] The fsmonitor sentinel is not created, the stamped result proves Git executed, and bootstrap
  diagnostic output proves preexisting valid override entries remain visible to the child.
- [ ] Failure cases preserve exact non-zero exit codes and actionable stderr.
- [ ] Before/after snapshots cover fixture source, `.git`, Windows local/global config, disposable
  toolkit config, disposable Linux prefix, cache/sidecar paths, and primary repository; documented
  test setup/cleanup paths are the only allowed differences.

#### Manual Verification

- [ ] Review output for truthful limitations: mounted-drive performance, raw `.git` parser
  limitations, CLI-only support, and one-worktree-per-process.
- [ ] Confirm Integration mode was explicitly selected with disposable config and Linux prefix and
  any real download or WSL install had explicit human approval.
- [ ] Integration without `-AllowDownload` and `-AllowInstall` logs zero network, extraction,
  config-write, and install commands.

---

## Phase 5: Plugin Integration and Documentation

### Changes Required

- **`plugins/devtools/plugin.json`**: Register `skills/ripwire-wsl` and update package description,
  keywords if warranted, and plugin version.
- **`.github/plugin/marketplace.json`**: Synchronize marketplace metadata and plugin entry versions.
- **`plugins/devtools/README.md`**: Add the skill to included capabilities and state its runtime
  prerequisites and non-MCP boundary.
- **`README.md`**: Add the capability to the repository catalog and document its verification
  command.
- **`plugins/devtools/CHANGELOG.md`**: Record the new skill, pinned upstream release, launcher,
  installer, doctor, tests, and version bump.
- **`.paw/work/ripwire-wsl-toolkit/Docs.md`**: Record the as-built interfaces, configuration
  location contract, release identity, diagnostics, verification commands, and known limitations
  using `paw-docs-guidance`.

### Success Criteria

#### Automated Verification

- [ ] `pwsh -NoProfile -File .\Tests\Install-DevTools.Tests.ps1`
- [ ] `pwsh -NoProfile -File .\Tests\Ripwire-Wsl-Toolkit.Tests.ps1 -Mode Unit`
- [ ] `pwsh -NoProfile -File .\Tests\Ripwire-Wsl-Toolkit.Tests.ps1 -Mode Setup`
- [ ] `pwsh -NoProfile -File .\Tests\Ripwire-Wsl-Toolkit.Tests.ps1 -Mode Launcher`
- [ ] `powershell.exe -NoProfile -File .\Tests\Ripwire-Wsl-Toolkit.Tests.ps1 -Mode Unit`
- [ ] JSON parsing succeeds for plugin, marketplace, release, and eval manifests.
- [ ] Plugin and marketplace versions are identical.
- [ ] A package-level discovery test loads the staged `plugin.json`, resolves every listed skill
  directory, validates `ripwire-wsl/SKILL.md` frontmatter, and proves the result comes from the
  package under test without touching the user's Copilot configuration.
- [ ] Manifest/static tests pass under Windows PowerShell 5.1; runtime scripts return the documented
  unsupported-runtime code before side effects.

#### Manual Verification

- [ ] Documentation distinguishes plugin installation, Ripwire runtime installation, doctor, and
  agent invocation.
- [ ] Documentation contains no internal scratch paths, private session names, machine-specific
  settings, or unsupported MCP/read-only claims.
- [ ] Every public technical claim links to upstream Ripwire, Git, or Microsoft WSL documentation.

---

## Fleet Coordination

Implementation can use at most two bounded workers when phases expose independent surfaces:

- Package instructions/references/evals can proceed in parallel with deterministic test-harness
  scaffolding after Phase 1 contracts are fixed.
- Installer/doctor implementation and launcher implementation remain separate work items but both
  depend on the Phase 1 common contracts.
- Live integration depends on completed installer, doctor, and launcher work.
- The coordinating agent integrates all work and independently accepts each checkpoint.

## Planning Review Gate

Before implementation, run independent reviews of `WorkflowContext.md`, `WorkShaping.md`, `Spec.md`,
`CodeResearch.md`, and `Plan.md` with:

- `gpt-5.6-sol-fast`
- `gemini-3.8-flash`
- `grok-4.6`

Review for feasibility, specification coverage, fixture/oracle quality, scope control, and type/state
model gaps. Synthesize findings, revise artifacts for confirmed issues, and present the final plan
for human approval. Approval authorizes implementation planning only; real WSL installation and
other host-affecting validation still require the explicit phase gate described above.

## Acceptance Coverage Matrix

| Obligation | Phase | Fixture/action | Oracle | Failure control |
|---|---:|---|---|---|
| SC-001 root/commit/dirty | 4 | Disposable standalone and linked worktree; doctor JSON plus stamped `--for` | Canonical path equality; 9-char Windows HEAD with dirty/shallow suffix | Fail if stamp absent or bootstrap diagnostic lacks Git fields |
| SC-002 non-mutation | 3-4 | Snapshot target, Git config, toolkit config/prefix, caches, primary repo | Exact before/after set and byte comparison excluding declared setup paths | Fail on any undeclared delta |
| SC-003 args/streams/exit | 3 | Executable shim emits binary fixtures, over-pipe-capacity concurrent output, and chosen exit codes | Exact argv records and byte-array equality | Assert one child start, bounded completion, and exact exit |
| SC-004 Git overrides | 1,3-4 | Empty, populated, malformed, duplicate, extra-index, Unicode WSLENV/GIT blocks plus fsmonitor positive/negative control arms | Ordered child diagnostic entries; parent bytes unchanged; sentinel fires only without override | WSL not started for malformed state or failed positive control |
| SC-005 install outcomes | 2 | Clean, repeated, stale, bad hash, unsupported arch/runtime, partial install, every same-filesystem rename failure | Transaction state, command log, binary/config snapshots | No commit before staged health; rollback after later failure; ARM64 qualified by staged health |
| SC-006 doctor | 2 | One fixture per Windows/WSL/Linux/config/install/worktree layer | Stable diagnostic code/status/remediation JSON | Zero writes and exact probe count |
| SC-007 portability/policy | 1,5 | Package scan and option-policy fixtures | No machine identities; CLI-only/single-root text; closed allowlist | Reject unknown/write/control options |
| SC-008 runner compatibility | 1-5 | Default deterministic mode; explicit Integration | Expected mode list and exit 0 | Default never invokes live WSL; 5.1 runtime exits before effects |
| SC-009 plugin discovery | 5 | Staged package manifest/frontmatter validation | Skill resolves from package path/version under test | No user Copilot config access |
| SC-010 analysis boundary | 1,3 | Exact Spec option table; every other known/unknown flag and non-flag token | Invocation variant and stable rejection code; zero WSL starts; injected `--no-cache` | Target, cache paths, and parent environment snapshots unchanged |
| SC-011 transaction | 2 | Every pre/post-swap failure point | Prior bytes/mode/config preserved or restored | Inject one failure at each state transition |

The deterministic test script defaults to `AllDeterministic` and runs Unit, Setup, Launcher,
manifest, and package checks. `Integration` is opt-in and additionally requires disposable
`-ConfigPath` and Linux install prefix values.

## References

- `.paw/work/ripwire-wsl-toolkit/WorkflowContext.md`
- `.paw/work/ripwire-wsl-toolkit/WorkShaping.md`
- `.paw/work/ripwire-wsl-toolkit/Spec.md`
- `.paw/work/ripwire-wsl-toolkit/CodeResearch.md`
- [Ripwire v0.5.0 release](https://github.com/redhat-et/ripwire/releases/tag/v0.5.0)
- [Ripwire v0.5.0 source](https://github.com/redhat-et/ripwire/tree/bacfa3b7b3ad13648ce3892de06af05b6b55a2ac)
- [Microsoft WSL filesystem guidance](https://learn.microsoft.com/windows/wsl/filesystems)
- [Microsoft WSL commands](https://learn.microsoft.com/windows/wsl/basic-commands)
