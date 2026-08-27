#!/usr/bin/env pwsh

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
param(
    [string[]]$DestinationRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$skillNames = @(
    "coordinator",
    "validator",
    "reviewer"
)

function Test-SameFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,
        [Parameter(Mandatory = $true)]
        [string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Destination -PathType Leaf)) {
        return $false
    }

    $sourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $Source).Hash
    $destinationHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $Destination).Hash
    return $sourceHash -eq $destinationHash
}

$sourceRoot = $PSScriptRoot

foreach ($skillName in $skillNames) {
    $sourceSkill = Join-Path $sourceRoot $skillName
    $sourceEntryPoint = Join-Path $sourceSkill "SKILL.md"
    if (-not (Test-Path -LiteralPath $sourceEntryPoint -PathType Leaf)) {
        throw "Skill '$skillName' is missing its source entry point: $sourceEntryPoint"
    }
}

$requestedRoots = if ($PSBoundParameters.ContainsKey("DestinationRoot")) {
    @($DestinationRoot)
}
else {
    @(
        Join-Path $HOME ".agents\skills"
        if (-not [string]::IsNullOrWhiteSpace($env:COPILOT_HOME)) {
            Join-Path $env:COPILOT_HOME "skills"
        }
    )
}

$destinationRootPaths = [System.Collections.Generic.List[string]]::new()
$seenRoots = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase)

foreach ($requestedRoot in $requestedRoots) {
    if ([string]::IsNullOrWhiteSpace($requestedRoot)) {
        throw "DestinationRoot cannot contain an empty path."
    }

    $resolvedRoot = [System.IO.Path]::GetFullPath(
        [Environment]::ExpandEnvironmentVariables($requestedRoot))
    if ($seenRoots.Add($resolvedRoot)) {
        $destinationRootPaths.Add($resolvedRoot)
    }
}

if ($destinationRootPaths.Count -eq 0) {
    throw "At least one destination root is required."
}

foreach ($destinationRootPath in $destinationRootPaths) {
    if (-not (Test-Path -LiteralPath $destinationRootPath -PathType Container)) {
        if ($PSCmdlet.ShouldProcess($destinationRootPath, "create Copilot skills directory")) {
            New-Item -ItemType Directory -Path $destinationRootPath -Force | Out-Null
        }
    }
}

$results = foreach ($destinationRootPath in $destinationRootPaths) {
    foreach ($skillName in $skillNames) {
        $sourceSkill = Join-Path $sourceRoot $skillName
        $destinationSkill = Join-Path $destinationRootPath $skillName
        $copied = 0
        $unchanged = 0
        $removed = 0

        $sourceFiles = @(Get-ChildItem -LiteralPath $sourceSkill -Recurse -File)
        $sourceRelativePaths = [System.Collections.Generic.HashSet[string]]::new(
            [System.StringComparer]::OrdinalIgnoreCase)

        foreach ($sourceFile in $sourceFiles) {
            $relativePath = [System.IO.Path]::GetRelativePath($sourceSkill, $sourceFile.FullName)
            $null = $sourceRelativePaths.Add($relativePath)
            $destinationFile = Join-Path $destinationSkill $relativePath

            if (Test-SameFile -Source $sourceFile.FullName -Destination $destinationFile) {
                $unchanged++
                continue
            }

            if ($PSCmdlet.ShouldProcess($destinationFile, "install or update skill file")) {
                $destinationDirectory = Split-Path -Parent $destinationFile
                New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
                Copy-Item -LiteralPath $sourceFile.FullName -Destination $destinationFile -Force
                $copied++
            }
        }

        if (Test-Path -LiteralPath $destinationSkill -PathType Container) {
            $destinationFiles = @(Get-ChildItem -LiteralPath $destinationSkill -Recurse -File)
            foreach ($destinationFile in $destinationFiles) {
                $relativePath = [System.IO.Path]::GetRelativePath(
                    $destinationSkill,
                    $destinationFile.FullName)

                if ($sourceRelativePaths.Contains($relativePath)) {
                    continue
                }

                if ($PSCmdlet.ShouldProcess($destinationFile.FullName, "remove stale installed skill file")) {
                    Remove-Item -LiteralPath $destinationFile.FullName -Force
                    $removed++
                }
            }

            $emptyDirectories = @(
                Get-ChildItem -LiteralPath $destinationSkill -Recurse -Directory |
                    Sort-Object { $_.FullName.Length } -Descending
            )
            foreach ($directory in $emptyDirectories) {
                if (@(Get-ChildItem -LiteralPath $directory.FullName -Force).Count -eq 0 -and
                    $PSCmdlet.ShouldProcess($directory.FullName, "remove empty installed skill directory")) {
                    Remove-Item -LiteralPath $directory.FullName
                }
            }
        }

        [pscustomobject]@{
            Skill = $skillName
            CopiedOrUpdated = $copied
            Unchanged = $unchanged
            Removed = $removed
            Destination = $destinationSkill
        }
    }
}

$results | Format-Table -AutoSize
