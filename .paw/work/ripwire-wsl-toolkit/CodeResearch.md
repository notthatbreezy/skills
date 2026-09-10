---
date: 2026-09-09T16:18:00-04:00
git_commit: 1badf7e0eff84968844e0049a436d5289c1dc1f9
branch: brownch-microsoft-ripwire-wsl-toolkit
repository: notthatbreezy/skills
topic: "Ripwire WSL toolkit integration points"
tags: [research, codebase, copilot-plugin, powershell, skills]
status: complete
last_updated: 2026-09-09
---

# Research: Ripwire WSL Toolkit Integration Points

## Research Question

Where and how does a portable Ripwire-through-WSL toolkit fit into this repository's existing
Copilot plugin packaging, PowerShell, test, and documentation conventions?

## Summary

The repository distributes one versioned `brownch-devtools` Copilot plugin. Installable skills live
in one directory per skill under `plugins/devtools/skills/`, and each skill is explicitly listed in
the plugin manifest. A skill may colocate scripts, references, and evaluation fixtures. Repository
tests are standalone PowerShell scripts with local assertion helpers and disposable fixtures rather
than a Pester suite.

Adding a skill affects the skill package, `plugins/devtools/plugin.json`, the root and plugin
documentation, the plugin changelog, and both version fields in the marketplace catalog when the
change is released.

## Documentation System

- **Framework**: Plain Markdown; no documentation generator is declared.
- **Docs Directory**: N/A. Documentation is colocated at repository, plugin, skill, agent, and
  reference levels.
- **Navigation Config**: N/A.
- **Style Conventions**: Repository-relative links and paths; short skill entrypoints may disclose
  detailed guidance through a `references/` file (`README.md:174-179`,
  `plugins/devtools/skills/offscreen-windows-ui-automation/SKILL.md:1-8`).
- **Build Command**: N/A.
- **Standard Files**: `README.md`, `plugins/devtools/README.md`, and
  `plugins/devtools/CHANGELOG.md` (`README.md:162-179`).

## Verification Commands

- **Test Command**: `.\Tests\Install-DevTools.Tests.ps1`, run in PowerShell 7 and Windows
  PowerShell 5.1 (`README.md:172-179`).
- **Lint Command**: No dedicated command is documented.
- **Build Command**: No build command is documented for repository assets.
- **Type Check**: No dedicated command is documented.
- **Release Validation**: Validate PowerShell, JSON, plugin loading, skill discovery, and agent
  discovery (`README.md:172-180`).

## Detailed Findings

### Plugin package and marketplace

- The repository is a private marketplace containing one native Copilot plugin
  (`README.md:1-3`).
- Installable assets are kept under `plugins/devtools/`; skills and agents have separate
  subdirectories (`README.md:162-179`).
- `plugins/devtools/plugin.json` explicitly enumerates every packaged skill and agent, while its
  `include` array adds package-level Markdown files (`plugins/devtools/plugin.json:21-47`).
- `.github/plugin/marketplace.json` points the marketplace entry to `plugins/devtools` and carries
  a marketplace metadata version plus the plugin entry version
  (`.github/plugin/marketplace.json:2-15`).
- The plugin manifest and both marketplace version fields are currently `1.4.0`
  (`plugins/devtools/plugin.json:2-4`, `.github/plugin/marketplace.json:6-15`).
- Release entries record the capability change and synchronized manifest bump
  (`plugins/devtools/CHANGELOG.md:1-9`).

### Skill package conventions

- Skills use a directory containing a frontmatter-bearing `SKILL.md`; the frontmatter supplies a
  stable name and a model-facing trigger description
  (`plugins/devtools/skills/offscreen-windows-ui-automation/SKILL.md:1-5`).
- A short entrypoint can require an agent to load a colocated reference before acting
  (`plugins/devtools/skills/offscreen-windows-ui-automation/SKILL.md:6-8`).
- Skills may contain executable scripts and evaluation cases. The public-IP sampler includes
  `scripts/Test-StablePublicIp.ps1` and `evals/evals.json`
  (`plugins/devtools/skills/stable-public-ip-sampler/SKILL.md:8-9`,
  `plugins/devtools/skills/stable-public-ip-sampler/evals/evals.json:1-23`).
- Skill instructions invoke bundled scripts relative to the skill directory and distinguish normal,
  self-test, and explicitly authorized modes
  (`plugins/devtools/skills/stable-public-ip-sampler/SKILL.md:21-46`,
  `plugins/devtools/skills/stable-public-ip-sampler/SKILL.md:70-78`).
- The sampler's deterministic `-SelfTest` branch constructs fixtures, throws on failed assertions,
  reports structured JSON, and performs no network calls
  (`plugins/devtools/skills/stable-public-ip-sampler/scripts/Test-StablePublicIp.ps1:139-194`).

### PowerShell and repository tests

- Repository scripts use `[CmdletBinding()]`, parameter validation, `$ErrorActionPreference =
  'Stop'`, explicit external-command exit checks, and terminating errors
  (`Install-DevTools.ps1:1-17`, `Install-DevTools.ps1:20-64`).
- `Tests/Install-DevTools.Tests.ps1` is a standalone script with local assertion helpers and a
  disposable temporary directory (`Tests/Install-DevTools.Tests.ps1:1-30`).
- The test replaces the external `copilot` command with a logging function and verifies exact
  command sequences, exit codes, failure propagation, and parameter validation
  (`Tests/Install-DevTools.Tests.ps1:32-93`, `Tests/Install-DevTools.Tests.ps1:95-193`).
- Test cleanup restores prior functions and removes only its exact temporary directory
  (`Tests/Install-DevTools.Tests.ps1:180-193`).

### Repository installer boundary

- `Install-DevTools.ps1` installs or updates the Copilot marketplace and plugin; it is not a
  per-skill dependency installer (`Install-DevTools.ps1:20-64`).
- The plugin package declares no hooks, MCP servers, LSP servers, or post-install scripts
  (`plugins/devtools/README.md:3-7`).

## Code References

- `README.md:162-180` - Repository layout, maintenance, test, and release conventions.
- `plugins/devtools/plugin.json:21-47` - Explicit packaged asset lists.
- `.github/plugin/marketplace.json:2-15` - Marketplace source and synchronized versions.
- `plugins/devtools/skills/offscreen-windows-ui-automation/SKILL.md:1-8` - Compact skill entrypoint
  and progressive disclosure.
- `plugins/devtools/skills/stable-public-ip-sampler/SKILL.md:21-46` - Relative bundled-script usage
  and self-test command.
- `plugins/devtools/skills/stable-public-ip-sampler/scripts/Test-StablePublicIp.ps1:139-194` -
  Deterministic script self-test pattern.
- `Tests/Install-DevTools.Tests.ps1:32-193` - Standalone test harness, mocks, assertions, and cleanup.

## Architecture Documentation

The plugin manifest is the package index. `SKILL.md` is the agent entrypoint; branch-specific detail
can live in `references/`, executable behavior in `scripts/`, and invocation examples in `evals/`.
The root installer remains responsible only for installing the plugin as a unit.

## Public Runtime Research

### Release and runtime contract

- Ripwire `v0.5.0` resolves to source commit
  `bacfa3b7b3ad13648ce3892de06af05b6b55a2ac`. Its release publishes
  `ripwire-0.5.0-linux-x64.tar.gz` and `ripwire-0.5.0-linux-arm64.tar.gz` with the SHA-256 values
  recorded in `Spec.md` ([release](https://github.com/redhat-et/ripwire/releases/tag/v0.5.0)).
- The release workflow builds Linux assets in manylinux 2.28 containers and states compatibility
  with Ubuntu 20.04+ for x86-64
  ([release.yml](https://github.com/redhat-et/ripwire/blob/v0.5.0/.github/workflows/release.yml)).
- The upstream installer maps `x86_64|amd64` to `x64` and `arm64|aarch64` to `arm64`, installs by
  default below the user's `~/.local`, and requires `tar`
  ([install.sh](https://github.com/redhat-et/ripwire/blob/v0.5.0/scripts/install.sh)).
- Release archives have one top-level directory matching the asset basename and contain an
  executable `ripwire`. Upstream lists the archive before extraction, rejects absolute/traversal or
  unexpected entries, verifies the staged binary version, and uses an in-directory rename for the
  final binary ([install.sh](https://github.com/redhat-et/ripwire/blob/v0.5.0/scripts/install.sh)).

### CLI root, write, and output behavior

- Ripwire's parser treats the first non-flag positional argument as the root and supports multiple
  positional roots
  ([cli.h](https://github.com/redhat-et/ripwire/blob/v0.5.0/src/cli.h)).
- The same parser exposes MCP/listen controls, cache/index outputs, baseline generation, edit
  payloads, and symbol-edit operations. A Windows analysis launcher therefore needs a closed
  V1 option policy rather than treating every upstream argument as analysis
  ([cli.h](https://github.com/redhat-et/ripwire/blob/v0.5.0/src/cli.h)).
- Repo-reading verbs emit an `at` attribute containing a nine-character commit prefix and optional
  `+dirty` and `+shallow` suffixes. The default map deliberately does not emit this stamp
  ([gitstamp.h](https://github.com/redhat-et/ripwire/blob/v0.5.0/src/gitstamp.h)).
- Ripwire uses Git subprocesses for repo-aware behavior. A Windows-linked-worktree integration test
  must select a stamped Git-backed verb and cannot infer the common Git directory from ordinary
  Ripwire output
  ([gitstamp.h](https://github.com/redhat-et/ripwire/blob/v0.5.0/src/gitstamp.h)).

### Windows/WSL transport

- `wsl.exe --distribution <name>` explicitly selects a distribution, and `--cd` selects its working
  directory ([Microsoft WSL commands](https://learn.microsoft.com/windows/wsl/basic-commands)).
- `WSLENV` is the documented bridge for additional environment variables. A launcher must preserve
  the caller's value and add only child-process entries; assigning Win32 child environment
  variables alone does not define their Linux visibility
  ([Microsoft WSL filesystems](https://learn.microsoft.com/windows/wsl/filesystems)).
- Windows paths passed to Linux commands must be translated to WSL form. Mounted Windows files are
  expected to be slower than files stored inside WSL
  ([Microsoft WSL filesystems](https://learn.microsoft.com/windows/wsl/filesystems)).

## Open Questions

The cache-policy decision is resolved: the user approved persistent toolkit-managed Linux caching
outside the target, with V1 still focused on exploration. `Spec.md` and `Plan.md` now allow owned
cache/lock changes and retain project/Git/configuration non-mutation. This supersedes the former
zero-cache-write requirement; the live evidence below describes that earlier contract.

The revised cache-enabled probe now passes all 18 feasibility groups; see the follow-up evidence
below. The user accepted Phase 0 and authorized remaining implementation on 2026-09-10. Production cache
ownership/locking/maintenance, full option coverage, and other hosts remain implementation obligations.

`Spec.md` still defines the exact V1 option language. This finding does not authorize removing
`--for`, changing the pin, or silently broadening the launcher's accepted language.

## Live Phase 0 Evidence

### Scope and reproduction

Executed on 2026-09-10 with explicit user permission for download and disposable staging.
Environment: Windows with PowerShell 7.6.5, Ubuntu 26.04 on WSL 2,
Linux x86-64, Git 2.53.0, and test-only Python 3.14.4. The binary reported
`ripwire 0.5.0 (Release, GNU 14.2.1, built_from=unknown)`. Its provenance is the pinned archive
SHA-256, not the binary's unknown build label.

Run the deterministic probe contracts without WSL:
`pwsh -NoProfile -File .\Tests\Ripwire-Wsl-Toolkit.Tests.ps1`.

The current opt-in reproduction is
`pwsh -NoProfile -File .\Tests\Ripwire-Wsl-Toolkit.Tests.ps1 -Mode Feasibility -Distribution <installed-Ubuntu-name> -AllowDownload -AllowInstall -LinuxCacheRoot <fresh-Linux-test-cache-root> -ResultPath <absolute-report-path>`.
Generate the fresh Linux test cache root as
`'/tmp/ripwire-cache-feasibility.' + [Guid]::NewGuid().ToString('N')` in PowerShell.
Use an existing parent directory for the report. The test creates fresh disposable Windows and
Linux fixture directories and deletes them in `finally`; JSON reports may contain those local
paths and must not be committed. This minimal probe currently supports approved download/staging
only, not reuse of the operator's installed binary. It does not execute upstream installation or
agent-activation scripts.

`Tests/fixtures/ripwire-wsl/ProbeProcess.ps1` owns the test-only native process boundary;
`bootstrap.sh` appends the Git safety override; `probe.py` provides independent argument,
environment, byte, and Linux filesystem observations. These are feasibility assets, not the
finished public launcher. The source fixture contains `base_value`, its caller, a committed
linked-worktree-only function, and an uncommitted function calling it. The main checkout and linked
worktree have different commits, so reading the wrong checkout cannot satisfy the assertions.

### Original zero-cache-contract results

| Obligation | Result |
|---|---|
| Root, Git directory, common directory, HEAD | Match independent Windows Git plus `wslpath` for both fixture roots |
| Actual Ripwire orientation and targeted analysis | Correct root; expected nine-character commit stamp; `+dirty` only on linked fixture |
| Dirty source, not just a dirty flag | Returned function body equals the uncommitted Windows source line; absent from main fixture map |
| Caller and history queries | Known caller row present; `--pr-context=main` reports the changed file and correct base/current commit identities |
| Real WSL argument boundary | Empty, quoted, spaced, Unicode, backslash, equals-sign, and path-like values preserved |
| Streams and exit | Byte-identical stdout/stderr, including invalid UTF-8 and no final newline; more than 1 MiB on each stream; partial-output exit 23 preserved; empty output preserved |
| Git overrides and fsmonitor | Existing note and `core.fsmonitor=true` retained, final false wins; hook sentinel fires only in the unprotected positive control |
| Windows non-mutation | Fixture source, `.git`, configuration, workspace contents/status, and parent environment unchanged |
| Linux non-mutation | **Fail:** each `--for` creates a history-cache blob and directories below the dedicated temporary prefix despite `--no-cache` |
| Cleanup | All created Windows fixture/download and Linux staging/cache directories removed |

The first smoke run lacked the Linux prefix snapshot and appeared to pass. The strengthened run
supersedes it: the recorded gate was **Fail under the former contract**, not partial approval to
implement. Per-command snapshots
isolate the Linux changes to `--for`; rerunning with fresh fixtures reproduces the failure.

### Root cause and implications

The pinned release's
[`quality::gitCoChangeAndChurnCached`](https://github.com/redhat-et/ripwire/blob/v0.5.0/src/quality.h#L2890-L2928)
constructs a `qchurn` cache path and calls `atomicWriteFile` after a cold Git-history walk.
[`main.cpp`](https://github.com/redhat-et/ripwire/blob/v0.5.0/src/main.cpp) gates the default
ingestion cache on `cfg.noCache` but still calls the history-cache function for rich analysis.
[`quality::cacheDirLadder`](https://github.com/redhat-et/ripwire/blob/v0.5.0/src/quality.h)
uses `TMPDIR/ripwire` when `TMPDIR` is set. The probe observed two regular history-cache blobs,
one for each root, there; the staged executable and monitored Linux home configuration/cache
locations did not change.

Thus `--no-cache` is not a universal no-write guarantee. The same-worktree architecture and
transport were not disproved, but the then-current zero-cache-write acceptance criterion was unmet.
No attempt was made to patch upstream, force cache writes to fail, remove core analysis, or weaken
the requirement during that run. The subsequent user-approved design instead retains managed
cache namespaces across invocations for reuse; see the current specification. Disposable test
namespaces still get cleaned at the end of a test, not between warm queries.

Additional implementation findings:

- The release archive contains bundled skills/hooks as well as the executable. Validate paths and
  entry types, then extract only the exact binary for this probe; do not activate bundled assets.
- Set child-only `GIT_OPTIONAL_LOCKS=0` for observational Git calls to avoid optional index refresh
  writes ([Git environment reference](https://git-scm.com/docs/git#Documentation/git.txt-GITOPTIONALLOCKS)).
  The probe also isolates Git global/system configuration to fixture settings.
- Some upstream XML legend comments contain XML-invalid double hyphens. The test removes comments
  before parsing elements; assertions inspect actual rows, roots, stamps, and source bodies rather
  than matching words echoed in query text or legends.
- This evidence covers the recorded x86-64 host and commands, not ARM64, every allowed option,
  fresh-machine setup, full inherited-environment compatibility, or the eventual public launcher.

### Cache-enabled follow-up: Pass

The revised probe passed all 18 feasibility groups on 2026-09-10 using the same pinned release
and recorded host. Three deterministic groups also pass without invoking live WSL. This new run
supersedes the original gate outcome under the user-approved cache policy; it does not erase
the original `--no-cache` finding.

`cache-fixture.py` creates a new owner-private Linux-native test cache, namespaced by release,
architecture, and a SHA-256 of canonical worktree/Git/common-directory identities. Independent
PowerShell and Python implementations agree on the namespace key. HEAD is deliberately excluded
from this identity. Child-only `TMPDIR` and `XDG_CACHE_HOME` point into the namespace, retained
between Ripwire processes until test cleanup.

| Obligation | Observed result |
|---|---|
| Actual source-cache reuse | Test-only `RIPWIRE_CACHE_STATS=1` reports `reparsed=1 reused=0` cold and `reparsed=0 reused=1` warm for both fixture roots and both lean-map/rich-query caches |
| Output equivalence | Cold, warm, and independent empty-cache reference queries return identical stdout |
| Dirty-source freshness | An edited uncommitted function returns its new body and reparses the source |
| Same size and modification time | A second body edit preserving both size and mtime still reparses and returns the new body |
| HEAD freshness | A Windows commit retains the cache namespace, reuses unchanged source, and returns the new clean commit stamp; output agrees with an empty-cache reference |
| Missing/corrupt cache recovery | Both source and history cache families rebuild inside their namespace; output remains correct and the rebuilt source cache is reusable |
| Worktree isolation | Queries, cache faults, and linked-worktree source/HEAD changes leave the other worktree's cache unchanged |
| Non-mutation | Target source/Git/configuration remain unchanged during each analysis interval; staged binaries and monitored Linux home paths remain unchanged; only managed cache storage changes |
| Cleanup | Disposable Windows fixtures/downloads, Linux binary staging, and test cache all removed; cleanup failure would make the report fail |

The source-cache counters come from pinned
[`ingest_parsepool.h`](https://github.com/redhat-et/ripwire/blob/v0.5.0/src/ingest_parsepool.h).
They directly establish source-record reuse, not a separate history-cache hit counter. History
cache files persist between calls; fault recovery and fresh-reference output comparisons exercise
their correctness. The production launcher need not enable this test-only diagnostic.

For the small one-file fixture, observed main-checkout map times were 558 ms cold / 330 ms warm;
rich-query times were 1271 ms / 949 ms. Linked-worktree times were 399 ms / 291 ms and
1349 ms / 1045 ms respectively. These include process/WSL overhead and are observations, not
a benchmark, speed guarantee, or acceptance threshold.

A rebuilt source-cache blob can have a different binary hash while returning identical results
and demonstrating warm reuse. The recovery oracle therefore permits changed bytes only for
explicitly faulted derived files; it still requires regular rebuilt files, replaced corruption,
preserved modes, unchanged unrelated cache entries, correct output, and subsequent reuse.

This is a bounded feasibility result, not a filesystem sandbox or universal non-mutation proof.
Snapshots cover the declared fixture and monitored locations. No production installer, public
launcher, cache-clear interface, concurrent access coordination, ARM64 validation, or full V1
option qualification is delivered by this probe. The user subsequently accepted the evidence and
authorized Phase 1 and the remaining implementation/review work.
