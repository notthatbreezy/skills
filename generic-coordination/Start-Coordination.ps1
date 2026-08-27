#!/usr/bin/env pwsh

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$ConfigPath,
    [switch]$ValidateOnly,
    [switch]$RenderOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "Coordination.Common.ps1")

$config = Read-CoordinationConfig $ConfigPath

foreach ($command in @($config.launch.executable, "git", "pwsh", "telex", "wt.exe")) {
    Get-Command $command -ErrorAction Stop | Out-Null
}

foreach ($worktree in @($config.worktrees)) {
    Initialize-CoordinationWorktree $worktree
}

if ($ValidateOnly) {
    Write-Output "Coordination config is valid: $($config._configPath)"
    Write-Output "Integration worktree: $($config._integrationWorktree.path)"
    Write-Output "Sessions: $(@($config.sessions).Count)"
    return
}

$paths = if ($RenderOnly) {
    $renderRoot = Join-Path $env:TEMP "copilot-coordination-render\$($config.name)-$([guid]::NewGuid())"
    @{
        Root = $renderRoot
        State = Join-Path $renderRoot "state.json"
        Sessions = Join-Path $renderRoot "sessions"
    }
}
else {
    Get-CoordinationStatePath $config
}

if (-not $RenderOnly -and (Test-Path -LiteralPath $paths.State)) {
    $existingState = Get-Content -Raw -LiteralPath $paths.State | ConvertFrom-Json -Depth 30
    if ($existingState.status -ne "stopped") {
        throw "Coordination '$($config.name)' has state '$($existingState.status)' at $($paths.State). Run Stop-Coordination.ps1 before launching another copy."
    }
}

New-Item -ItemType Directory -Path $paths.Sessions -Force | Out-Null

if (-not $RenderOnly) {
    foreach ($session in @($config.sessions)) {
        $status = Get-TelexAddressStatus $session.address
        if ($null -ne $status -and @($status.daemon_members | Where-Object station_health -eq "attended_push").Count -gt 0) {
            throw "Telex address '$($session.address)' is already attended. Stop or detach the existing session before launch."
        }
    }
}

$agencyPath = Resolve-CoordinationExecutable $config.launch.executable
$pwshPath = Resolve-CoordinationExecutable "pwsh"
$wtPath = Resolve-CoordinationExecutable "wt.exe"
$sessionStates = @()

foreach ($session in @($config.sessions)) {
    $worktree = $config._worktreeMap[$session.worktree]
    $sessionId = [guid]::NewGuid().ToString()
    $sessionDirectory = Join-Path $paths.Sessions $session.name
    $bootstrapPath = Join-Path $sessionDirectory "bootstrap.ps1"
    $processPath = Join-Path $sessionDirectory "process.json"
    New-Item -ItemType Directory -Path $sessionDirectory -Force | Out-Null

    $initialPrompt = @"
You are the $($session.role) session for coordination scope '$($config.telex.scope)'.

Read and follow this role prompt exactly:
$($session.prompt)

Use this assignment template:
$($config.assignmentTemplate)

Runtime identity:
- role: $($session.role)
- Telex address: $($session.address)
- Telex scope: $($config.telex.scope)
- repository/worktree: $($worktree.path)
- branch: $($worktree.branch)
- integration worktree: $($config._integrationWorktree.path)
- write authority: $($session.writeAuthority)
- configured model: $(if ($null -ne $session.PSObject.Properties["model"]) { $session.model } else { "default" })

Attach only the configured local Telex address and scope. Reject messages from any other scope or address prefix. Follow the prompt's bridge setup and readiness instructions before accepting work.
"@

    if ($session.role -eq "coordinator") {
        $initialPrompt += @"

Your primary job is orchestration: decompose the outcome, identify disjoint work, assign safe implementation lanes, prepare independent validation and review, track dependencies and claims, integrate accepted checkpoints, and keep ready workers productively assigned. Do not implement or wait passively.
"@
    }

    $agencyArguments = [System.Collections.Generic.List[string]]::new()
    $agencyArguments.Add("copilot")
    $agencyArguments.Add("--session-id")
    $agencyArguments.Add($sessionId)
    foreach ($argument in @($config.launch.arguments | Select-Object -Skip 1)) {
        $agencyArguments.Add([string]$argument)
    }

    $modelProperty = $session.PSObject.Properties["model"]
    if ($null -ne $modelProperty) {
        $agencyArguments.Add("--model")
        $agencyArguments.Add([string]$modelProperty.Value)
    }

    $agencyArguments.Add("-C")
    $agencyArguments.Add($worktree.path)
    $agencyArguments.Add("-n")
    $agencyArguments.Add($session.name)
    $agencyArguments.Add("-i")
    $agencyArguments.Add($initialPrompt)

    $argumentLiterals = @($agencyArguments | ForEach-Object { ConvertTo-PowerShellLiteral $_ }) -join ",`r`n    "
    $environmentScriptProperty = $worktree.PSObject.Properties["environmentScript"]
    $environmentBlock = if ($null -ne $environmentScriptProperty -and -not [string]::IsNullOrWhiteSpace([string]$environmentScriptProperty.Value)) {
@"
`$environmentLines = & $(ConvertTo-PowerShellLiteral $worktree.environmentScript)
if (-not `$?) { throw "Failed to load worktree environment." }
Invoke-Expression (`$environmentLines -join [Environment]::NewLine)
& $(ConvertTo-PowerShellLiteral $worktree.environmentScript) -Doctor
if (-not `$?) { throw "Worktree environment doctor failed." }
"@
    }
    else {
        ""
    }

    $bootstrap = @"
Set-StrictMode -Version Latest
`$ErrorActionPreference = "Stop"
Set-Location $(ConvertTo-PowerShellLiteral $worktree.path)
$environmentBlock
`$processPath = $(ConvertTo-PowerShellLiteral $processPath)
`$record = [ordered]@{
    sessionName = $(ConvertTo-PowerShellLiteral $session.name)
    sessionId = $(ConvertTo-PowerShellLiteral $sessionId)
    role = $(ConvertTo-PowerShellLiteral $session.role)
    address = $(ConvertTo-PowerShellLiteral $session.address)
    bootstrapPid = `$PID
    bootstrapStartedAtUtc = [DateTime]::UtcNow.ToString("O")
    agencyPid = `$null
    agencyStartedAtUtc = `$null
    exitCode = `$null
    endedAtUtc = `$null
}
`$record | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath `$processPath -Encoding UTF8

`$arguments = @(
    $argumentLiterals
)
`$startInfo = [System.Diagnostics.ProcessStartInfo]::new()
`$startInfo.FileName = $(ConvertTo-PowerShellLiteral $agencyPath)
`$startInfo.UseShellExecute = `$false
foreach (`$argument in `$arguments) { `$startInfo.ArgumentList.Add(`$argument) }
`$process = [System.Diagnostics.Process]::Start(`$startInfo)
`$record.agencyPid = `$process.Id
`$record.agencyStartedAtUtc = `$process.StartTime.ToUniversalTime().ToString("O")
`$record | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath `$processPath -Encoding UTF8
`$process.WaitForExit()
`$record.exitCode = `$process.ExitCode
`$record.endedAtUtc = [DateTime]::UtcNow.ToString("O")
`$record | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath `$processPath -Encoding UTF8
"@

    Set-Content -LiteralPath $bootstrapPath -Value $bootstrap -Encoding UTF8

    $sessionStates += [ordered]@{
        name = $session.name
        role = $session.role
        address = $session.address
        telexScope = $config.telex.scope
        sessionId = $sessionId
        worktree = $worktree.path
        branch = $worktree.branch
        prompt = $session.prompt
        bootstrap = $bootstrapPath
        process = $processPath
        launched = $false
    }
}

$state = [ordered]@{
    version = 1
    name = $config.name
    config = $config._configPath
    scope = $config.telex.scope
    integrationWorktree = $config._integrationWorktree.path
    terminalWindow = $config.terminal.window
    status = "starting"
    startedAtUtc = [DateTime]::UtcNow.ToString("O")
    sessions = $sessionStates
}

if ($RenderOnly) {
    foreach ($sessionState in @($state.sessions)) {
        $tokens = $null
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile(
            $sessionState.bootstrap,
            [ref]$tokens,
            [ref]$errors) | Out-Null
        if ($errors.Count -gt 0) {
            $messages = $errors | ForEach-Object Message
            throw "Generated bootstrap failed to parse for '$($sessionState.name)': $($messages -join '; ')"
        }

        $content = Get-Content -Raw -LiteralPath $sessionState.bootstrap
        if ($content -notmatch [regex]::Escape("`$startInfo.FileName = $(ConvertTo-PowerShellLiteral ([string]$agencyPath))")) {
            throw "Generated bootstrap for '$($sessionState.name)' does not contain the resolved Agency executable path."
        }
    }

    Write-Output "Coordination render is valid: $($config._configPath)"
    Write-Output "Resolved Agency executable: $agencyPath"
    Write-Output "Generated bootstraps: $($paths.Sessions)"
    Write-Output "No terminal or agent sessions were launched."
    return
}

$state | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $paths.State -Encoding UTF8

function Start-ConfiguredSession {
    param($SessionState)

    & $wtPath -w $config.terminal.window new-tab --title $SessionState.name --startingDirectory $SessionState.worktree $pwshPath -NoLogo -NoExit -File $SessionState.bootstrap
    if (-not $?) {
        throw "Windows Terminal failed to launch session '$($SessionState.name)'."
    }

    $SessionState.launched = $true
    $state | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $paths.State -Encoding UTF8
}

$coordinator = @($state.sessions | Where-Object role -eq "coordinator")[0]
Start-ConfiguredSession $coordinator

$timeoutProperty = $config.telex.PSObject.Properties["coordinatorReadyTimeoutSeconds"]
$timeoutSeconds = if ($null -ne $timeoutProperty) {
    [int]$timeoutProperty.Value
}
else {
    180
}

$deadline = [DateTime]::UtcNow.AddSeconds($timeoutSeconds)
while ([DateTime]::UtcNow -lt $deadline) {
    if (Test-TelexSessionReady $coordinator.address $coordinator.sessionId) {
        break
    }

    Start-Sleep -Seconds 2
}

if (-not (Test-TelexSessionReady $coordinator.address $coordinator.sessionId)) {
    $state.status = "coordinator-not-ready"
    $state | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $paths.State -Encoding UTF8
    throw "Coordinator did not reach attended_push within $timeoutSeconds seconds. Workers were not launched."
}

foreach ($sessionState in @($state.sessions | Where-Object role -ne "coordinator")) {
    Start-ConfiguredSession $sessionState
}

$state.status = "running"
$state["readyAtUtc"] = [DateTime]::UtcNow.ToString("O")
$state | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $paths.State -Encoding UTF8

Write-Output "Started coordination '$($config.name)'."
Write-Output "State: $($paths.State)"
Write-Output "Scope: $($config.telex.scope)"
Write-Output "Sessions: $(@($state.sessions).Count)"
