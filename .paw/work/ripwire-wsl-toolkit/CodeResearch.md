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

No user-intent questions remain. `Spec.md` defines the exact V1 option language; implementation must
encode that approved table beside the release pin and verify its spellings against `v0.5.0`
`src/cli.h` without broadening it.
