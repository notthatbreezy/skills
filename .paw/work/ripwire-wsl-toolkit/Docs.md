# Ripwire WSL Toolkit

## Overview

The `ripwire-wsl` skill packages Windows entrypoints and a Linux process bootstrap with the existing
`brownch-devtools` plugin. Its target is the current Windows worktree, not a second checkout.
Ripwire v0.5.0 runs inside an explicitly configured Ubuntu WSL distribution against those same files.

This reference describes the implementation interfaces. Delivery and live qualification status
remain in `Plan.md`; the presence of an interface here is not a claim that final review is complete.

## Architecture and Design

The Windows launcher parses the release-pinned option policy, reads versioned local configuration,
resolves the exact root and metadata using Windows Git, and translates known paths with the selected
distribution's `wslpath`. A native process boundary preserves argument arrays and copies stdout and
stderr concurrently as bytes. No shell command interpolation is used to carry Ripwire arguments.

The Linux bootstrap validates the root and cache boundary, appends `diff.autoRefreshIndex=false`
and then `core.fsmonitor=false` after
the caller's indexed Git overrides, acquires the worktree namespace lock, and starts Ripwire.
Git identity variables are child-local. Windows discovery excludes inherited redirection so an
unrelated `GIT_DIR` or `core.worktree` cannot silently choose another checkout.

### Cache and maintenance

The source index and Git-history cache are derived data, distinct from project baselines. The
namespace key hashes the canonical Linux root, Git directory, and common directory. Release and
architecture form separate path segments. HEAD is excluded so commits do not discard reusable
source records; upstream content/history freshness still determines results.

Namespace data lives below `cacheRoot/releases/<version>/<architecture>/<key>`. Stable lock files
live separately below `cacheRoot/locks/<version>/<architecture>/<key>.lock`; clearing data must not
delete the inode used by a concurrent locker. Analysis and clear use the same exclusive bounded
lock. Diagnosis exits before opening or creating a lock.

The cache must be owner-private native Linux storage, outside source, Git metadata, and the binary
installation. Unsafe permissions or paths produce errors instead of adopting or repairing them
during analysis. Namespace creation happens after lock acquisition. Explicit clear removes only
the selected namespace. No expiry or quota is implemented; parsed source/history may persist until
the operator clears it.

### Boundary choices

The JSON manifest is the authoritative option table. Runtime parsing rejects inconsistent metadata,
and independent tests pin the expected release policy rather than duplicating it inside the parser.
Configuration parsing rejects unknown fields and duplicate properties instead of silently accepting
an evolving schema.

The archive contract declares top-level files and allowed ancillary subtrees alongside the
executable payload. Setup validates names and entry types throughout the archive, then extracts
only the executable; it never runs the bundled installer, skills, or hooks. Windows configuration
staging stays beside its destination, and Linux binary staging stays beside its destination.
Those sibling paths permit same-filesystem rename and rollback without treating a copy as atomic.

`RIPWIRE_WSL_OPERATION` is an internal closed operation (`analysis`, `diagnostic`, or `clear`),
assigned by the Windows entrypoint. It is not a caller-supplied Ripwire option. Clear shares the
bootstrap's cache validation and lock rather than implementing a second deletion policy.

## User Guide

Read the portable [skill guide](../../../plugins/devtools/skills/ripwire-wsl/references/guide.md)
for setup, invocation syntax, paths, diagnostics, retention, and troubleshooting.

The public entrypoints are:

| Script | Purpose |
|---|---|
| `Install-RipwireWsl.ps1` | Explicit pinned/checksummed setup in an existing distribution |
| `Test-RipwireWsl.ps1` | Read-only prerequisite, installation, cache, and optional worktree diagnosis |
| `Invoke-RipwireWsl.ps1` | Analysis of the exact required `-WorktreePath` |
| `Clear-RipwireWslCache.ps1` | Explicit maintenance of that worktree's configured namespace |

All accept an optional machine-local `-ConfigPath`. Setup requires `-Distribution` and accepts
separate Linux install/cache roots. Analysis accepts a string array through `-RipwireArguments`;
callers do not provide a positional Ripwire root. Value-bearing flags use attached `--name=value`.
Only `--from-trace` contains a caller-supplied path; other query text is never translated by
filesystem-existence guessing.

## API and Configuration

Runtime entrypoints require PowerShell 7. Windows PowerShell 5.1 exits with code 78 before importing
runtime helpers; it can run static/package tests.

Default configuration is `%LOCALAPPDATA%\brownch-devtools\ripwire-wsl\config.json`. Schema version 1
contains exactly `schemaVersion`, `distribution`, `architecture`, `releaseVersion`, `releaseCommit`,
`archiveSha256`, `binaryPath`, and `cacheRoot`. No worktree, branch, Git metadata path, or host MCP
configuration is persisted.

Common helpers return tagged configuration, invocation, worktree, path, and native-command results.
Only validated configuration/invocation data reaches context construction. Unknown CLI arguments
fail before WSL starts. Raw command output is decoded strictly only where a structured text response
is expected; analysis streams are not decoded.

Doctor JSON contains `schemaVersion`, overall `status`, named `checks`, and `details`. Checks carry
`layer`, `code`, `status`, `message`, and `remediation`. A missing first-use namespace is a warning,
not a failed install. Archive and executable hashes are not interchangeable: the executable digest
check is explicitly skipped because no separate binary digest is declared.

## Testing

The repository retains standalone PowerShell tests. `-Mode Unit`, `-Mode Setup`, and
`-Mode Launcher` isolate deterministic groups; the default runs deterministic groups only.
Staged-package discovery copies the plugin into a temporary directory and resolves registered
skills/agents without consulting Copilot's installed configuration.

The native launcher shim is a compiled temporary Windows executable. It checks real
`ProcessStartInfo` argument/environment and byte-stream boundaries. Linux bootstrap tests are
separately opt-in and use disposable WSL fixtures; simulations are not labeled end-to-end proof.
Live Integration uses the public toolkit with isolated Windows repositories and linked worktrees,
independent Git/path oracles, filesystem snapshots, cache observations, and explicit setup approval.

`Tests\Ripwire-Wsl.Transaction.Tests.ps1 -Distribution <installed-Ubuntu-name>` separately exercises
the real Bash installer with disposable archives and native command-failure shims. It checks binary
bytes/mode and Windows configuration bytes across replacement, rollback, and cleanup failures.
`Tests\Ripwire-Wsl.Bootstrap.Tests.ps1 -Distribution <installed-Ubuntu-name>` exercises real cache
diagnosis, first use, ownership/link rejection, lock contention, and deletion failure. Neither suite
downloads Ripwire or operates on a user project.

## Limitations and Future Work

This is not an OS-level read-only sandbox: WSL accesses the Windows files directly. The launcher
restricts commands and cache placement, while regression snapshots detect unexpected writes.
Source edits, builds, tests, and Git mutation remain Windows responsibilities.

One process is scoped to one worktree. Upstream raw `.git` readers can bypass environment-based
Git translation, and arbitrary cross-root behavior is not supported. Mounted-drive analysis may
be slower than Linux-native disk; same-file correctness takes priority. ARM64 availability does
not replace a staged executable health check on that host.

MCP, quality/architecture baselines, additional quality commands, a native Windows port, automatic
host prerequisite changes, cache quotas/expiry, and upstream agent-hook activation are outside V1.
