#!/usr/bin/env pwsh

[CmdletBinding()]
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
$rows = foreach ($session in @($state.sessions)) {
    $process = Get-CoordinationProcessInfo $session.process
    $agencyRunning = $false
    $bootstrapRunning = $false
    if ($null -ne $process) {
        if ($null -ne $process.agencyPid) {
            $agencyRunning = $null -ne (Get-Process -Id ([int]$process.agencyPid) -ErrorAction SilentlyContinue)
        }

        if ($null -ne $process.bootstrapPid) {
            $bootstrapRunning = $null -ne (Get-Process -Id ([int]$process.bootstrapPid) -ErrorAction SilentlyContinue)
        }
    }

    $telex = Get-TelexAddressStatus $session.address
    $member = @(
        if ($null -ne $telex) {
            $telex.daemon_members | Where-Object session_id -eq $session.sessionId | Select-Object -First 1
        }
    )

    [pscustomobject]@{
        Name = $session.name
        Role = $session.role
        Branch = $session.branch
        Agency = if ($agencyRunning) { "running" } else { "stopped" }
        Terminal = if ($bootstrapRunning) { "open" } else { "closed" }
        Telex = if ($member.Count -gt 0) { $member[0].station_health } else { "not-attached" }
        Address = $session.address
    }
}

Write-Output "Coordination: $($state.name)"
Write-Output "State:        $($state.status)"
Write-Output "Scope:        $($state.scope)"
Write-Output "Started:      $($state.startedAtUtc)"
$rows | Format-Table -AutoSize
