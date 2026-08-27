#!/usr/bin/env pwsh

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [AllowNull()]
    [object[]]$LauncherArguments
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$sourceWorktree = "C:\Projects\dbagent-recover-phase6"
$sourceBranch = "feature/recover-failed-investigations_phase6"
$sourceCommit = "336e7c3970ac0f88740a97a923e18c2cd97dcd24"
$targetWorktree = "C:\Projects\dbagent-recover-phase7"
$targetBranch = "feature/recover-failed-investigations_phase7"

if (Test-Path -LiteralPath $targetWorktree) {
    throw "Target worktree already exists: $targetWorktree"
}

if ((git -C $sourceWorktree rev-parse --is-inside-work-tree) -ne "true") {
    throw "Phase 6 source path is not a Git worktree: $sourceWorktree"
}

$actualBranch = (git -C $sourceWorktree branch --show-current).Trim()
$actualCommit = (git -C $sourceWorktree rev-parse HEAD).Trim()
$sourceStatus = @(git -C $sourceWorktree status --porcelain=v1)

if ($actualBranch -ne $sourceBranch) {
    throw "Phase 6 source branch is '$actualBranch'; expected '$sourceBranch'."
}

if ($actualCommit -ne $sourceCommit) {
    throw "Phase 6 source HEAD is '$actualCommit'; expected '$sourceCommit'."
}

if ($sourceStatus.Count -ne 0) {
    throw "Phase 6 source worktree is not clean."
}

git -C $sourceWorktree show-ref --verify --quiet "refs/heads/$targetBranch"
if ($LASTEXITCODE -eq 0) {
    throw "Target branch already exists without its configured worktree: $targetBranch"
}

git -C $sourceWorktree worktree add $targetWorktree -b $targetBranch $sourceBranch
if ($LASTEXITCODE -ne 0) {
    throw "Failed to create Phase 7 worktree."
}

Push-Location $targetWorktree
try {
    & "$targetWorktree\script\worktree-env.ps1" -Write
    if (-not $?) {
        throw "Phase 7 worktree was created, but environment initialization failed."
    }
}
finally {
    Pop-Location
}

$createdBranch = (git -C $targetWorktree branch --show-current).Trim()
$createdCommit = (git -C $targetWorktree rev-parse HEAD).Trim()
if ($createdBranch -ne $targetBranch -or $createdCommit -ne $sourceCommit) {
    throw "Created worktree identity does not match the configured Phase 7 branch and base commit."
}

Write-Output "Created Phase 7 worktree: $targetWorktree"
Write-Output "Branch: $targetBranch"
Write-Output "Base commit: $sourceCommit"
