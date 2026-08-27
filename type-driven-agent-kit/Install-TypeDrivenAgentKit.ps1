[CmdletBinding()]
param(
    [Parameter(DontShow)]
    [string]$TargetHome = $HOME,

    [Parameter(DontShow)]
    [string]$TargetCopilotHome
)

$ErrorActionPreference = 'Stop'

$kitRoot = $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($TargetCopilotHome)) {
    $isCurrentUserHome = [StringComparer]::OrdinalIgnoreCase.Equals(
        [IO.Path]::GetFullPath($TargetHome).TrimEnd('\'),
        [IO.Path]::GetFullPath($HOME).TrimEnd('\')
    )

    if ($isCurrentUserHome -and -not [string]::IsNullOrWhiteSpace($env:COPILOT_HOME)) {
        $copilotRoot = $env:COPILOT_HOME
    } else {
        $copilotRoot = Join-Path $TargetHome '.copilot'
    }
} else {
    $copilotRoot = $TargetCopilotHome
}

$pawRoot = Join-Path $TargetHome '.paw'
$instructionsPath = Join-Path $copilotRoot 'copilot-instructions.md'
$skillDirectory = Join-Path $copilotRoot 'skills\type-driven-development'
$agentDirectory = Join-Path $copilotRoot 'agents'
$personaDirectory = Join-Path $pawRoot 'personas'
$backupRoot = Join-Path $TargetHome ('.type-driven-agent-kit-backup\' + (Get-Date -Format 'yyyyMMdd-HHmmss'))

$managedFiles = @(
    @{
        Source = Join-Path $kitRoot 'skill\SKILL.md'
        Destination = Join-Path $skillDirectory 'SKILL.md'
    },
    @{
        Source = Join-Path $kitRoot 'agent\type-safety-reviewer.agent.md'
        Destination = Join-Path $agentDirectory 'type-safety-reviewer.agent.md'
    },
    @{
        Source = Join-Path $kitRoot 'paw\type-safety.md'
        Destination = Join-Path $personaDirectory 'type-safety.md'
    }
)

foreach ($entry in $managedFiles) {
    if (-not (Test-Path -LiteralPath $entry.Source -PathType Leaf)) {
        throw "Package is incomplete. Missing: $($entry.Source)"
    }
}

New-Item -ItemType Directory -Force -Path $skillDirectory, $agentDirectory, $personaDirectory | Out-Null

$existingDestinations = $managedFiles |
    Where-Object { Test-Path -LiteralPath $_.Destination -PathType Leaf }

if ($existingDestinations -or (Test-Path -LiteralPath $instructionsPath -PathType Leaf)) {
    New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
}

if (Test-Path -LiteralPath $instructionsPath -PathType Leaf) {
    Copy-Item -LiteralPath $instructionsPath -Destination (Join-Path $backupRoot 'copilot-instructions.md')
}

foreach ($entry in $existingDestinations) {
    $relativeName = $entry.Destination.Substring($TargetHome.Length).TrimStart('\') -replace '[\\:]', '_'
    Copy-Item -LiteralPath $entry.Destination -Destination (Join-Path $backupRoot $relativeName)
}

$instructionBlockPath = Join-Path $kitRoot 'instructions\type-driven-development.instructions.md'
$instructionBlock = (Get-Content -LiteralPath $instructionBlockPath -Raw).Trim()
$startMarker = '<!-- type-driven-development start -->'
$endMarker = '<!-- type-driven-development end -->'

if (Test-Path -LiteralPath $instructionsPath -PathType Leaf) {
    $instructions = Get-Content -LiteralPath $instructionsPath -Raw
} else {
    New-Item -ItemType Directory -Force -Path $copilotRoot | Out-Null
    $instructions = ''
}

$startIndex = $instructions.IndexOf($startMarker, [StringComparison]::Ordinal)
$endIndex = $instructions.IndexOf($endMarker, [StringComparison]::Ordinal)

if (($startIndex -ge 0) -xor ($endIndex -ge 0)) {
    throw "Existing Copilot instructions contain only one type-driven marker. Restore the pair or remove the orphan marker before installing."
}

if ($startIndex -ge 0) {
    if ($endIndex -lt $startIndex) {
        throw 'Existing type-driven instruction markers are out of order.'
    }

    $endIndex += $endMarker.Length
    $instructions = $instructions.Substring(0, $startIndex) +
        $instructionBlock +
        $instructions.Substring($endIndex)
} elseif ([string]::IsNullOrWhiteSpace($instructions)) {
    $instructions = $instructionBlock + [Environment]::NewLine
} else {
    $instructions = $instructions.TrimEnd() +
        [Environment]::NewLine +
        [Environment]::NewLine +
        $instructionBlock +
        [Environment]::NewLine
}

Set-Content -LiteralPath $instructionsPath -Value $instructions -Encoding utf8

foreach ($entry in $managedFiles) {
    Copy-Item -LiteralPath $entry.Source -Destination $entry.Destination -Force
}

Write-Host 'Type-driven agent kit installed.' -ForegroundColor Green
Write-Host "Copilot instructions: $instructionsPath"
Write-Host "Skill: $(Join-Path $skillDirectory 'SKILL.md')"
Write-Host "Reviewer agent: $(Join-Path $agentDirectory 'type-safety-reviewer.agent.md')"
Write-Host "PAW persona: $(Join-Path $personaDirectory 'type-safety.md')"

if (Test-Path -LiteralPath $backupRoot -PathType Container) {
    Write-Host "Backup: $backupRoot"
}

Write-Host 'Restart Copilot CLI to reload personal skills and agents.' -ForegroundColor Yellow
