# Ripwire through WSL

This toolkit runs pinned Linux Ripwire against the same files used by a Windows coding session.
It does not clone the project into Linux or port Ripwire to Windows.

## Setup

Runtime scripts require Windows, PowerShell 7, Windows Git, and an existing Ubuntu 20.04+
distribution in WSL. Linux Git, Bash, GNU archive/core utilities, and `flock` must be available.
Missing host prerequisites require separate human action. The installer does not enable Windows
features, install or replace distributions, or activate upstream hooks/skills.

Run from the installed skill directory, substituting the name of an existing Ubuntu distribution:

```powershell
pwsh -NoProfile -File .\scripts\Install-RipwireWsl.ps1 -Distribution '<installed-Ubuntu-name>'
pwsh -NoProfile -File .\scripts\Test-RipwireWsl.ps1 -WorktreePath '<current-Windows-worktree>' -Json
```

The release identity, archive hashes, architecture aliases, and option policy are authoritative in
[`release.json`](release.json). The pin is Ripwire v0.5.0; only the executable is extracted from the
verified upstream archive. Upstream bundled agent assets are not installed. x86-64 feasibility was
demonstrated on Ubuntu 26.04 / WSL 2. The upstream x86-64 baseline is Ubuntu 20.04+; an ARM64 asset
is available but a successful staged health probe is required on that host. Do not infer broader
compatibility from one host's result.

Configuration defaults to `%LOCALAPPDATA%\brownch-devtools\ripwire-wsl\config.json`.
`-ConfigPath` selects a separate machine-local configuration for all public scripts.
The versioned configuration records the distro, normalized architecture, release/commit/archive
identity, Linux binary path, and cache root. Keep it outside source control. A stale configuration
requires explicit setup; analysis never updates it automatically.

`-LinuxInstallRoot` and `-LinuxCacheRoot` provide separate native-Linux setup locations for
isolated installations. Default binary storage is below
`$HOME/.local/share/brownch-devtools/ripwire-wsl`; cache storage is below
`$HOME/.cache/brownch-devtools/ripwire-wsl`. Cache data is not part of the binary transaction.
Installation validates staging before replacement, verifies the installed executable before
committing configuration, and reports rollback or cleanup failures separately.

## Analysis

From a PowerShell 7 session, invoke the script by its installed path:

```powershell
& '<skill-directory>\scripts\Invoke-RipwireWsl.ps1' -WorktreePath $PWD.Path
& '<skill-directory>\scripts\Invoke-RipwireWsl.ps1' -WorktreePath $PWD.Path `
    -RipwireArguments @('--for=SymbolName', '--max-tokens=2000')
```

`-WorktreePath` is required. The launcher supplies the only Ripwire positional root; arguments are
an array, not a shell command string. Value-bearing options use attached `--name=value` syntax.
Choose at most one primary selector. The complete accepted selector/modifier grammar lives in
[`release.json`](release.json); unknown flags fail before WSL starts.

The V1 contract focuses on orientation, symbol relationships, targeted context, and change
exploration. Extra quality/architecture commands and baseline workflows are not qualified. Rejected
commands are not necessarily mutating: rejection also means their behavior is outside this release's
supported contract. Raw pass-through, MCP/listen, output destinations, and caller-chosen cache paths
are deliberately unavailable.

Ripwire stdout and stderr are forwarded as bytes, with the child exit code preserved. Toolkit errors
go to stderr. Invocation rejection codes are 64 (additional root), 65 (mutation), 66 (MCP),
67 (output), 68 (unknown), and 69 (invalid syntax). Windows PowerShell 5.1 rejects runtime entrypoints
with `RIPWIRE_WSL_UNSUPPORTED_RUNTIME`, exit 78, before probing or changing anything.

## Paths and scope

Repository-relative result paths refer to the supplied Windows worktree. A Linux absolute result
path under the reported Linux root maps to the same relative suffix under the Windows root; use that
Windows path for edits and tools. Do not globally replace `/mnt/c` or assume every result belongs to
the root. Treat paths outside the reported root as unsupported for this single-worktree invocation.

Only known path fields are translated. `--from-trace=<windows-path>` is the sole caller-supplied
path option; symbol text, regular expressions, and path-like query text remain unchanged. Command-line
conversion does not translate paths inside a future MCP protocol.

Windows Git resolves linked-worktree metadata. The child receives translated process-local Git
paths and a final `core.fsmonitor=false` override, preserving valid inherited overrides without
rewriting `.git` or configuration. This scopes Git calls to one worktree: it is not a general adapter
for arbitrary other repositories opened inside the same process. Upstream raw `.git` readers can
bypass Git environment variables; do not claim every upstream feature is compatible.

## Cache retention and maintenance

Source-index and Git-history caches persist inside private Linux storage, separately for each
release, architecture, and worktree identity. A commit change keeps that namespace; current source
and HEAD still determine the result. Repeated processes can reuse parsed source. Missing or corrupt
cache entries are disposable and rebuildable; caches are not architecture or quality baselines.

Caches can contain source and repository-history information. There is no automatic expiry or disk
quota in V1. The read-only toolkit doctor reports cache location, readiness, and usage; a missing
namespace is a first-use state, not an instruction to create it during diagnosis.

Explicitly clear one worktree's configured release/architecture cache:

```powershell
& '<skill-directory>\scripts\Clear-RipwireWslCache.ps1' -WorktreePath '<current-Windows-worktree>'
```

Clear and analysis coordinate exclusive access to that namespace with a bounded wait; other
worktrees have independent namespaces. Invalid ownership, escaped links, Windows-mounted storage,
overlap with target/Git/binary paths, and lock failures are errors, not reasons to use a fallback
directory. Clear does not delete the root, other namespaces, source, Git metadata, or installation.
Older-release caches remain until explicitly maintained using that release's configuration.

## Safety and troubleshooting

WSL accesses Windows files directly: there is no synchronization barrier and no read-only sandbox.
The launcher restricts commands and cache placement; regression snapshots detect unexpected writes.
Managed cache and lock changes are the only allowed analysis writes. Windows remains responsible
for editing, builds, tests, and Git mutations.

| Symptom | Action |
|---|---|
| Unsupported runtime | Run the script with PowerShell 7 (`pwsh`), not Windows PowerShell |
| Missing/stale/malformed configuration | Run toolkit diagnostics, then explicitly rerun setup with the intended distro/configuration |
| Missing WSL, distro, Linux Git, or utilities | Have the operator satisfy that specific prerequisite; do not change host features automatically |
| Invalid inherited Git/WSLENV entries | Correct the named malformed entry in the caller; do not silently discard the environment |
| Invalid worktree or failed translation | Confirm the exact current checkout still exists; never fall back to the main checkout |
| Cache ownership/path/lock error | Inspect the configured Linux cache and active analysis; resolve permissions or contention rather than bypassing coordination |
| Analysis is slower on a mounted drive | Keep the same worktree for correctness; Linux-resident binary/cache reduce some overhead, not mounted-file costs |
| Unsupported option/MCP/baseline request | Use supported exploration or separately scope the missing integration |

## Public references

- [Pinned release and upstream license](https://github.com/redhat-et/ripwire/tree/v0.5.0)
- [Upstream Linux release baseline](https://github.com/redhat-et/ripwire/blob/v0.5.0/.github/workflows/release.yml)
- [WSL commands](https://learn.microsoft.com/windows/wsl/basic-commands)
- [WSL filesystems and environment transport](https://learn.microsoft.com/windows/wsl/filesystems)

The toolkit is independently authored. The public launcher gist discussed during design had no
declared reuse license and is not copied into this package.
