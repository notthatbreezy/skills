Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function ConvertTo-CoordinationPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$ConfigDirectory
    )

    $expandedPath = [Environment]::ExpandEnvironmentVariables($Path)
    if ([System.IO.Path]::IsPathRooted($expandedPath)) {
        return [System.IO.Path]::GetFullPath($expandedPath)
    }

    return [System.IO.Path]::GetFullPath((Join-Path $ConfigDirectory $expandedPath))
}

function Resolve-CoordinationExecutable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $command = Get-Command $Name -CommandType Application -All -ErrorAction Stop |
        Select-Object -First 1
    foreach ($propertyName in @("Path", "Source", "Definition")) {
        $property = $command.PSObject.Properties[$propertyName]
        if ($null -ne $property -and -not [string]::IsNullOrWhiteSpace([string]$property.Value)) {
            return [string]$property.Value
        }
    }

    throw "Could not resolve an executable path for '$Name'."
}

function Read-CoordinationConfig {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    $resolvedConfig = (Resolve-Path -LiteralPath $ConfigPath -ErrorAction Stop).Path
    $configDirectory = Split-Path -Parent $resolvedConfig
    $config = Get-Content -Raw -LiteralPath $resolvedConfig | ConvertFrom-Json -Depth 50

    if ($config.version -ne 1) {
        throw "Unsupported coordination config version '$($config.version)'. Expected 1."
    }

    foreach ($property in @("name", "telex", "terminal", "launch", "assignmentTemplate", "worktrees", "sessions")) {
        if ($null -eq $config.$property) {
            throw "Missing required config property '$property'."
        }
    }

    $config.assignmentTemplate = ConvertTo-CoordinationPath $config.assignmentTemplate $configDirectory
    if (-not (Test-Path -LiteralPath $config.assignmentTemplate -PathType Leaf)) {
        throw "Assignment template does not exist: $($config.assignmentTemplate)"
    }

    if ([string]::IsNullOrWhiteSpace($config.name)) {
        throw "Config name cannot be empty."
    }

    if ([string]::IsNullOrWhiteSpace($config.telex.scope)) {
        throw "Telex scope cannot be empty."
    }

    if ([string]::IsNullOrWhiteSpace($config.terminal.window)) {
        throw "Terminal window name cannot be empty."
    }

    if ([string]::IsNullOrWhiteSpace($config.launch.executable)) {
        throw "Launch executable cannot be empty."
    }

    $launchArguments = @($config.launch.arguments)
    if ($launchArguments.Count -eq 0 -or $launchArguments[0] -ne "copilot") {
        throw "launch.arguments must begin with 'copilot'."
    }

    $worktreeMap = @{}
    foreach ($worktree in @($config.worktrees)) {
        if ([string]::IsNullOrWhiteSpace($worktree.name)) {
            throw "Every worktree requires a name."
        }

        if ($worktreeMap.ContainsKey($worktree.name)) {
            throw "Duplicate worktree name '$($worktree.name)'."
        }

        $worktree.path = ConvertTo-CoordinationPath $worktree.path $configDirectory
        $environmentScriptProperty = $worktree.PSObject.Properties["environmentScript"]
        if ($null -ne $environmentScriptProperty -and -not [string]::IsNullOrWhiteSpace([string]$environmentScriptProperty.Value)) {
            $worktree.environmentScript = ConvertTo-CoordinationPath $worktree.environmentScript $configDirectory
        }

        $creatorProperty = $worktree.PSObject.Properties["creator"]
        if ($null -ne $creatorProperty -and $null -ne $creatorProperty.Value) {
            $worktree.creator.executable = ConvertTo-CoordinationPath $worktree.creator.executable $configDirectory
        }

        $worktreeMap[$worktree.name] = $worktree
    }

    $integrationWorktrees = @($config.worktrees | Where-Object { $_.integration -eq $true })
    if ($integrationWorktrees.Count -ne 1) {
        throw "Exactly one worktree must set integration=true."
    }

    $allowedRoles = @("coordinator", "implementer", "validator", "reviewer")
    $sessionNames = @{}
    $addresses = @{}
    foreach ($session in @($config.sessions)) {
        if ($allowedRoles -notcontains $session.role) {
            throw "Session '$($session.name)' has unsupported role '$($session.role)'."
        }

        if ([string]::IsNullOrWhiteSpace($session.name) -or $sessionNames.ContainsKey($session.name)) {
            throw "Session names must be non-empty and unique. Invalid name '$($session.name)'."
        }

        if ([string]::IsNullOrWhiteSpace($session.address) -or $addresses.ContainsKey($session.address)) {
            throw "Telex addresses must be non-empty and unique. Invalid address '$($session.address)'."
        }

        if (-not $session.address.StartsWith("$($config.telex.scope)-", [StringComparison]::OrdinalIgnoreCase)) {
            throw "Address '$($session.address)' must begin with '$($config.telex.scope)-'."
        }

        if (-not $worktreeMap.ContainsKey($session.worktree)) {
            throw "Session '$($session.name)' references unknown worktree '$($session.worktree)'."
        }

        $modelProperty = $session.PSObject.Properties["model"]
        if ($null -ne $modelProperty -and [string]::IsNullOrWhiteSpace([string]$modelProperty.Value)) {
            throw "Session '$($session.name)' has an empty model value."
        }

        $session.prompt = ConvertTo-CoordinationPath $session.prompt $configDirectory
        if (-not (Test-Path -LiteralPath $session.prompt -PathType Leaf)) {
            throw "Prompt does not exist for session '$($session.name)': $($session.prompt)"
        }

        $sessionNames[$session.name] = $true
        $addresses[$session.address] = $true
    }

    $coordinators = @($config.sessions | Where-Object role -eq "coordinator")
    $implementers = @($config.sessions | Where-Object role -eq "implementer")
    $validators = @($config.sessions | Where-Object role -eq "validator")
    $reviewers = @($config.sessions | Where-Object role -eq "reviewer")

    if ($coordinators.Count -ne 1) {
        throw "Exactly one coordinator session is required."
    }

    if ($implementers.Count -lt 1 -or $validators.Count -lt 1 -or $reviewers.Count -lt 1) {
        throw "At least one implementer, validator, and reviewer session is required."
    }

    $integrationName = $integrationWorktrees[0].name
    foreach ($session in @($coordinators + $validators + $reviewers)) {
        if ($session.worktree -ne $integrationName) {
            throw "Session '$($session.name)' with role '$($session.role)' must use integration worktree '$integrationName'."
        }
    }

    $integrationImplementers = @($implementers | Where-Object worktree -eq $integrationName)
    if ($integrationImplementers.Count -ne 1) {
        throw "Exactly one implementer must own integration worktree '$integrationName'."
    }

    $implementationWorktrees = @{}
    foreach ($session in $implementers) {
        if ($implementationWorktrees.ContainsKey($session.worktree)) {
            throw "Implementation worktree '$($session.worktree)' is assigned to multiple implementers."
        }

        $implementationWorktrees[$session.worktree] = $true
    }

    $consoleProperty = $config.PSObject.Properties["console"]
    if ($null -ne $consoleProperty -and $null -ne $consoleProperty.Value) {
        $console = $consoleProperty.Value
        foreach ($propertyName in @("name")) {
            $property = $console.PSObject.Properties[$propertyName]
            if ($null -eq $property -or [string]::IsNullOrWhiteSpace([string]$property.Value)) {
                throw "Console configuration requires '$propertyName'."
            }
        }

        $databaseProperty = $console.PSObject.Properties["db"]
        if ($null -ne $databaseProperty -and -not [string]::IsNullOrWhiteSpace([string]$databaseProperty.Value)) {
            $console.db = ConvertTo-CoordinationPath ([string]$databaseProperty.Value) $configDirectory
        }

        $pollProperty = $console.PSObject.Properties["pollSeconds"]
        if ($null -ne $pollProperty -and [int]$pollProperty.Value -lt 1) {
            throw "Console pollSeconds must be at least 1."
        }

        $backfillProperty = $console.PSObject.Properties["backfill"]
        if ($null -ne $backfillProperty -and [string]::IsNullOrWhiteSpace([string]$backfillProperty.Value)) {
            throw "Console backfill cannot be empty."
        }
    }

    $config | Add-Member -NotePropertyName "_configPath" -NotePropertyValue $resolvedConfig
    $config | Add-Member -NotePropertyName "_configDirectory" -NotePropertyValue $configDirectory
    $config | Add-Member -NotePropertyName "_integrationWorktree" -NotePropertyValue $integrationWorktrees[0]
    $config | Add-Member -NotePropertyName "_worktreeMap" -NotePropertyValue $worktreeMap
    return $config
}

function Initialize-CoordinationWorktree {
    param(
        [Parameter(Mandatory = $true)]
        $Worktree
    )

    if (-not (Test-Path -LiteralPath $Worktree.path -PathType Container)) {
        $createProperty = $Worktree.PSObject.Properties["createIfMissing"]
        if ($null -eq $createProperty -or $createProperty.Value -ne $true) {
            throw "Worktree does not exist and createIfMissing is false: $($Worktree.path)"
        }

        $creatorProperty = $Worktree.PSObject.Properties["creator"]
        if ($null -eq $creatorProperty -or $null -eq $creatorProperty.Value) {
            throw "Worktree '$($Worktree.name)' requires a creator configuration."
        }

        if (-not (Test-Path -LiteralPath $Worktree.creator.executable -PathType Leaf)) {
            throw "Worktree creator does not exist: $($Worktree.creator.executable)"
        }

        & $Worktree.creator.executable @($Worktree.creator.arguments)
        if (-not $?) {
            throw "Worktree creator failed for '$($Worktree.name)'."
        }
    }

    $inside = (& git -C $Worktree.path rev-parse --is-inside-work-tree 2>$null | Select-Object -First 1)
    $insideSucceeded = $?
    if (-not $insideSucceeded -or $inside -ne "true") {
        throw "Path is not a Git worktree: $($Worktree.path)"
    }

    $actualBranch = (& git -C $Worktree.path branch --show-current | Select-Object -First 1).Trim()
    $branchSucceeded = $?
    if (-not $branchSucceeded -or $actualBranch -ne $Worktree.branch) {
        throw "Worktree '$($Worktree.path)' is on '$actualBranch'; expected '$($Worktree.branch)'."
    }

    $environmentScriptProperty = $Worktree.PSObject.Properties["environmentScript"]
    if ($null -ne $environmentScriptProperty -and -not [string]::IsNullOrWhiteSpace([string]$environmentScriptProperty.Value)) {
        if (-not (Test-Path -LiteralPath $Worktree.environmentScript -PathType Leaf)) {
            throw "Worktree environment script does not exist: $($Worktree.environmentScript)"
        }

        Push-Location $Worktree.path
        try {
            & $Worktree.environmentScript -Doctor
            if (-not $?) {
                throw "Worktree environment doctor failed for '$($Worktree.path)'."
            }
        }
        finally {
            Pop-Location
        }
    }
}

function Get-CoordinationStatePath {
    param(
        [Parameter(Mandatory = $true)]
        $Config
    )

    $runtimeProperty = $Config.PSObject.Properties["runtimeDirectory"]
    $root = if ($null -ne $runtimeProperty -and -not [string]::IsNullOrWhiteSpace([string]$runtimeProperty.Value)) {
        ConvertTo-CoordinationPath ([string]$runtimeProperty.Value) $Config._configDirectory
    }
    else {
        Join-Path $env:LOCALAPPDATA "copilot-coordination\$($Config.name)"
    }

    return @{
        Root = $root
        State = Join-Path $root "state.json"
        Sessions = Join-Path $root "sessions"
    }
}

function Get-TelexAddressStatus {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Address
    )

    $output = & telex address show --address $Address --json 2>$null
    $succeeded = $?
    if (-not $succeeded -or [string]::IsNullOrWhiteSpace(($output -join [Environment]::NewLine))) {
        return $null
    }

    return (($output -join [Environment]::NewLine) | ConvertFrom-Json -Depth 30)
}

function Test-TelexSessionReady {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Address,
        [Parameter(Mandatory = $true)]
        [string]$SessionId
    )

    $status = Get-TelexAddressStatus $Address
    if ($null -eq $status) {
        return $false
    }

    return @($status.daemon_members | Where-Object {
        $_.session_id -eq $SessionId -and
        $_.station_health -eq "attended_push" -and
        $_.push_registered -eq $true
    }).Count -gt 0
}

function ConvertTo-PowerShellLiteral {
    param([AllowNull()][string]$Value)
    if ($null -eq $Value) {
        return '$null'
    }

    return "'" + $Value.Replace("'", "''") + "'"
}

function Get-CoordinationProcessInfo {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }

    return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json -Depth 20
}
