[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$package = Join-Path (Split-Path -Parent $PSScriptRoot) 'plugins\devtools\skills\ripwire-wsl'
. (Join-Path $package 'scripts\RipwireWsl.Common.ps1')
. (Join-Path $package 'scripts\RipwireWsl.Diagnostics.ps1')
$temporary = Join-Path ([IO.Path]::GetTempPath()) ('ripwire-doctor-' + [Guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $temporary
$calls = [Collections.Generic.List[string]]::new()
$scenario = 'ready'
function Equal($Expected, $Actual, [string] $Label) {
    if ($Expected -cne $Actual) { throw "ASSERTION_FAILED: $Label ($Expected != $Actual)" }
}
function Invoke-RipwireNativeCommand {
    param($FilePath, $Arguments, $Environment)
    $calls.Add("$FilePath $($Arguments -join ' ')")
    $text = switch ($FilePath) {
        git { 'git version fixture' }
        wsl.exe {
            if ($script:scenario -eq 'inspection-failure') {
                return [pscustomobject]@{ State=[RipwireCommandResultKind]::NonZero; Stdout=[byte[]]@()
                    Stderr=[Text.Encoding]::UTF8.GetBytes('RIPWIRE_WSL_CACHE_OWNER_OR_PERMISSIONS'); ExitCode=70 }
            }
            if ('diagnostic-fixture' -cin $Arguments) {
                if ($script:scenario -eq 'bad-identity') { '{"root":"/wrong","gitDirectory":"/git","commonDirectory":"/git","cacheReady":false}' }
                else { '{"root":"/project","gitDirectory":"/git","commonDirectory":"/git","cacheReady":false,"cacheNamespace":"/cache/releases/v0.5.0/x64/key"}' }
            } else { '{"binaryReady":true,"cacheRootReady":true,"cacheBytes":4096}' }
        }
        default { throw "Unexpected doctor process: $FilePath" }
    }
    [pscustomobject]@{ State=[RipwireCommandResultKind]::Success; Stdout=[Text.Encoding]::UTF8.GetBytes($text)
        Stderr=[byte[]]@(); ExitCode=0 }
}
function Get-RipwireCurrentEnvironment { @{ WSLENV='' } }
function Get-RipwireSetupPrerequisites {
    param($Distribution, $Manifest, $LinuxInstallRoot, $LinuxCacheRoot)
    Equal '/install' $LinuxInstallRoot 'Doctor validates configured install root, not default'
    Equal '/cache' $LinuxCacheRoot 'Doctor validates configured cache root, not default'
    if ($script:scenario -eq 'missing-host') {
        return [pscustomobject]@{ State='Failed'; Checks=@((New-RipwireDiagnostic wsl RIPWIRE_WSL_MISSING Failed 'Missing WSL' 'Install separately.')) }
    }
    [pscustomobject]@{ State='Valid'; Architecture='x64'; Checks=@((New-RipwireDiagnostic wsl RIPWIRE_WSL_READY Ready 'WSL ready')) }
}
function ConvertTo-RipwireLinuxPath { param($WindowsPath, $Distribution)
    [pscustomobject]@{ State='Valid'; LinuxPath='/package/inspect.sh' }
}
function New-RipwireWorktreeLaunchContext {
    param($WorktreePath, $Configuration, $Manifest, $BootstrapWindowsPath, $ParentEnvironment, $Operation)
    Equal diagnostic $Operation 'Doctor only requests diagnostic operation'
    [pscustomobject]@{ State='Valid'; LinuxRoot='/project'; LinuxGitDirectory='/git'; LinuxCommonDirectory='/git'
        WslFilePath='wsl.exe'; WslArguments=@('diagnostic-fixture'); ChildEnvironment=@{} }
}
try {
    $manifest = (Read-RipwireReleaseManifest (Join-Path $package 'references\release.json')).Manifest
    $config = [ordered]@{
        schemaVersion=1; distribution='Ubuntu'; architecture='x64'; releaseVersion=$manifest.releaseVersion
        releaseCommit=$manifest.releaseCommit; archiveSha256=$manifest.assets[0].sha256
        binaryPath='/install/v0.5.0/bin/ripwire'; cacheRoot='/cache'
    }
    $path = Join-Path $temporary 'config.json'
    $config | ConvertTo-Json | Set-Content -LiteralPath $path -Encoding utf8
    $baseline = (Get-FileHash -LiteralPath $path).Hash
    $report = Invoke-RipwireDiagnostics -ConfigPath $path
    Equal Ready $report.status 'Complete setup without worktree'
    Equal Skipped ($report.checks | Where-Object layer -EQ binaryDigest).status 'Archive and executable digests are distinct'
    Equal 4096 $report.details.cacheBytes 'Cache usage surfaced'
    $report = Invoke-RipwireDiagnostics -ConfigPath $path -WorktreePath $temporary
    Equal Warning $report.status 'Missing first-use namespace is warning'
    Equal RIPWIRE_WSL_CACHE_FIRST_USE ($report.checks | Where-Object layer -EQ cacheNamespace).code 'No doctor cache creation'
    foreach ($scenario in @('inspection-failure', 'missing-host', 'bad-identity')) {
        $report = Invoke-RipwireDiagnostics -ConfigPath $path -WorktreePath $temporary
        Equal Failed $report.status "Explicit failure: $scenario"
    }
    $calls.Clear()
    $report = Invoke-RipwireDiagnostics -ConfigPath (Join-Path $temporary 'absent.json')
    Equal Failed $report.status 'Missing configuration'
    Equal 0 $calls.Count 'Missing config never starts a process'
    Equal $baseline (Get-FileHash -LiteralPath $path).Hash 'Doctor never changes config'
    Equal 1 @(Get-ChildItem -LiteralPath $temporary -Force).Count 'Doctor creates no files'
    Write-Output 'Passed deterministic doctor readiness, first-use, failure, identity, and non-mutation cases.'
} finally {
    Remove-Item -LiteralPath $temporary -Recurse -Force
}
