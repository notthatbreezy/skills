#!/usr/bin/env pwsh

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$ConfigPath,
    [switch]$RenderOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "Coordination.Common.ps1")

$config = Read-CoordinationConfig $ConfigPath
$consoleProperty = $config.PSObject.Properties["console"]
if ($null -eq $consoleProperty -or $null -eq $consoleProperty.Value) {
    throw "The coordination config does not define a console section."
}

$console = $consoleProperty.Value
$worktree = $config._integrationWorktree
Initialize-CoordinationWorktree $worktree

$consolePath = Resolve-CoordinationExecutable "telex-console"
$wtPath = Resolve-CoordinationExecutable "wt.exe"
$arguments = [System.Collections.Generic.List[string]]::new()

$backendProperty = $console.PSObject.Properties["backend"]
if ($null -ne $backendProperty -and -not [string]::IsNullOrWhiteSpace([string]$backendProperty.Value)) {
    $arguments.Add("--backend")
    $arguments.Add([string]$backendProperty.Value)
}

$databaseProperty = $console.PSObject.Properties["db"]
if ($null -ne $databaseProperty -and -not [string]::IsNullOrWhiteSpace([string]$databaseProperty.Value)) {
    $arguments.Add("--db")
    $arguments.Add([string]$databaseProperty.Value)
}

$addressProperty = $console.PSObject.Properties["addressFilter"]
if ($null -ne $addressProperty -and -not [string]::IsNullOrWhiteSpace([string]$addressProperty.Value)) {
    $arguments.Add("--address")
    $arguments.Add([string]$addressProperty.Value)
}

$pollProperty = $console.PSObject.Properties["pollSeconds"]
if ($null -ne $pollProperty) {
    $arguments.Add("--poll-secs")
    $arguments.Add(([int]$pollProperty.Value).ToString())
}

$backfillProperty = $console.PSObject.Properties["backfill"]
if ($null -ne $backfillProperty -and -not [string]::IsNullOrWhiteSpace([string]$backfillProperty.Value)) {
    $arguments.Add("--backfill")
    $arguments.Add([string]$backfillProperty.Value)
}

$utcProperty = $console.PSObject.Properties["utc"]
if ($null -ne $utcProperty -and $utcProperty.Value -eq $true) {
    $arguments.Add("--utc")
}

if ($RenderOnly) {
    Write-Output "Telex console configuration is valid."
    Write-Output "Executable: $consolePath"
    Write-Output "Terminal window: $($config.terminal.window)"
    Write-Output "Starting directory: $($worktree.path)"
    Write-Output "Arguments: $($arguments -join ' ')"
    Write-Output "No terminal tab was opened."
    return
}

& $wtPath -w $config.terminal.window new-tab --title $console.name --startingDirectory $worktree.path $consolePath @arguments
if (-not $?) {
    throw "Windows Terminal failed to open telex-console '$($console.name)'."
}

Write-Output "Opened telex-console '$($console.name)' in terminal window '$($config.terminal.window)'."

