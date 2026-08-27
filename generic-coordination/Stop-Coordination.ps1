#!/usr/bin/env pwsh

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$ConfigPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "Coordination.Common.ps1")

$config = Read-CoordinationConfig $ConfigPath
$paths = Get-CoordinationStatePath $config
if (-not (Test-Path -LiteralPath $paths.State -PathType Leaf)) {
    throw "No coordination state exists at $($paths.State)."
}

$state = Get-Content -Raw -LiteralPath $paths.State | ConvertFrom-Json -Depth 30
foreach ($session in @($state.sessions | Sort-Object { if ($_.role -eq "coordinator") { 1 } else { 0 } })) {
    if (-not $PSCmdlet.ShouldProcess($session.name, "detach Telex session and stop exact recorded processes")) {
        continue
    }

    & telex copilot detach --session $session.sessionId --address $session.address --text 2>$null
    if (-not $?) {
        Write-Warning "Telex detach did not succeed for '$($session.address)'. The process stop will continue."
    }

    $process = Get-CoordinationProcessInfo $session.process
    if ($null -eq $process) {
        continue
    }

    foreach ($pidValue in @($process.agencyPid, $process.bootstrapPid)) {
        if ($null -eq $pidValue) {
            continue
        }

        $running = Get-Process -Id ([int]$pidValue) -ErrorAction SilentlyContinue
        if ($null -ne $running) {
            Stop-Process -Id ([int]$pidValue)
        }
    }
}

$stopTime = [DateTime]::UtcNow.ToString("O")
$state.status = "stopped"
$state | Add-Member -NotePropertyName stoppedAtUtc -NotePropertyValue $stopTime -Force
$state | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $paths.State -Encoding UTF8
Write-Output "Stopped coordination '$($state.name)'."
