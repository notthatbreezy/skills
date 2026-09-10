Set-StrictMode -Version Latest

enum RipwireManifestState {
    Valid
    Unreadable
    MalformedJson
    UnsupportedSchema
    MissingField
    UnknownField
    DuplicateArchitecture
    InvalidDigest
    InconsistentAsset
}

enum RipwireConfigurationState {
    Missing
    Unreadable
    Malformed
    UnsupportedVersion
    ValidButStale
    Valid
}

enum RipwireInvocationKind {
    AllowedDefaultMap
    AllowedAnalysis
    RejectedAdditionalRoot
    RejectedMutation
    RejectedMcp
    RejectedOutput
    RejectedUnknown
    InvalidSyntax
}

enum RipwireCommandResultKind {
    Success
    Unavailable
    NonZero
    InvalidOutput
    TimedOut
    TransportFailure
}

enum RipwireLaunchResultKind {
    RejectedPreflight
    StartFailed
    Started
    Completed
    PumpFailed
    TransportFailure
}

function New-RipwireTaggedResult {
    param(
        [Parameter(Mandatory)][string] $TypeName,
        [Parameter(Mandatory)] $State,
        [hashtable] $Values = @{}
    )
    $result = [ordered] @{ PSTypeName = $TypeName; State = $State }
    foreach ($name in $Values.Keys) { $result[$name] = $Values[$name] }
    [pscustomobject] $result
}

function Test-RipwireJsonInteger {
    param($Value)
    return $Value -is [int] -or $Value -is [long]
}

function Test-RipwireJsonString {
    param($Value)
    return $Value -is [string]
}

function Find-RipwireDuplicateJsonProperty {
    param(
        [Parameter(Mandatory)][Text.Json.JsonElement] $Element,
        [Parameter(Mandatory)][string] $Path
    )
    switch ($Element.ValueKind) {
        ([Text.Json.JsonValueKind]::Object) {
            $names = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
            foreach ($property in $Element.EnumerateObject()) {
                if (-not $names.Add($property.Name)) { return "$Path.$($property.Name)" }
                $duplicate = Find-RipwireDuplicateJsonProperty $property.Value "$Path.$($property.Name)"
                if ($null -ne $duplicate) { return $duplicate }
            }
        }
        ([Text.Json.JsonValueKind]::Array) {
            $index = 0
            foreach ($item in $Element.EnumerateArray()) {
                $duplicate = Find-RipwireDuplicateJsonProperty $item "$Path[$index]"
                if ($null -ne $duplicate) { return $duplicate }
                $index++
            }
        }
    }
    return $null
}

function Test-RipwireJsonStructure {
    param([Parameter(Mandatory)][string] $Raw)
    $document = $null
    try {
        $document = [Text.Json.JsonDocument]::Parse($Raw)
        $duplicate = Find-RipwireDuplicateJsonProperty $document.RootElement '$'
        if ($null -ne $duplicate) {
            return New-RipwireTaggedResult Ripwire.JsonStructure DuplicateProperty @{
                Code = 'RIPWIRE_WSL_DUPLICATE_JSON_PROPERTY'
                Message = "JSON contains duplicate property '$duplicate'."
            }
        }
        return New-RipwireTaggedResult Ripwire.JsonStructure Valid
    } catch {
        return New-RipwireTaggedResult Ripwire.JsonStructure MalformedJson @{
            Code = 'RIPWIRE_WSL_MALFORMED_JSON'; Message = $_.Exception.Message
        }
    } finally {
        if ($null -ne $document) { $document.Dispose() }
    }
}

function Test-RipwireExactFields {
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Object,
        [Parameter(Mandatory)][string[]] $Required,
        [Parameter(Mandatory)][string] $At
    )
    foreach ($name in $Required) {
        if (-not $Object.Contains($name)) {
            return New-RipwireTaggedResult Ripwire.FieldCheck MissingField @{
                Code = 'RIPWIRE_WSL_MISSING_FIELD'; Message = "$At is missing '$name'."
            }
        }
    }
    foreach ($name in $Object.Keys) {
        if ($name -cnotin $Required) {
            return New-RipwireTaggedResult Ripwire.FieldCheck UnknownField @{
                Code = 'RIPWIRE_WSL_UNKNOWN_FIELD'; Message = "$At contains unknown field '$name'."
            }
        }
    }
    return New-RipwireTaggedResult Ripwire.FieldCheck Valid
}

function Read-RipwireReleaseManifest {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string] $Path)
    try { $raw = [IO.File]::ReadAllText($Path) }
    catch {
        return New-RipwireTaggedResult Ripwire.ManifestParseResult ([RipwireManifestState]::Unreadable) @{
            Code = 'RIPWIRE_WSL_MANIFEST_UNREADABLE'; Message = $_.Exception.Message
        }
    }
    $structure = Test-RipwireJsonStructure $raw
    if ($structure.State -ne 'Valid') {
        return New-RipwireTaggedResult Ripwire.ManifestParseResult ([RipwireManifestState]::MalformedJson) @{
            Code = $structure.Code; Message = $structure.Message
        }
    }
    try { $manifest = $raw | ConvertFrom-Json -AsHashtable -Depth 30 }
    catch {
        return New-RipwireTaggedResult Ripwire.ManifestParseResult ([RipwireManifestState]::MalformedJson) @{
            Code = 'RIPWIRE_WSL_MANIFEST_MALFORMED_JSON'; Message = $_.Exception.Message
        }
    }
    if ($manifest -isnot [System.Collections.IDictionary]) {
        return New-RipwireTaggedResult Ripwire.ManifestParseResult ([RipwireManifestState]::MalformedJson) @{
            Code = 'RIPWIRE_WSL_MANIFEST_MALFORMED_JSON'; Message = 'Manifest root must be an object.'
        }
    }
    $top = Test-RipwireExactFields $manifest @('schemaVersion', 'releaseVersion', 'releaseCommit', 'assets', 'options') 'manifest'
    if ($top.State -ne 'Valid') {
        return New-RipwireTaggedResult Ripwire.ManifestParseResult ([RipwireManifestState]::$($top.State)) @{
            Code = $top.Code; Message = $top.Message
        }
    }
    if (-not (Test-RipwireJsonInteger $manifest.schemaVersion) -or $manifest.schemaVersion -ne 1) {
        return New-RipwireTaggedResult Ripwire.ManifestParseResult ([RipwireManifestState]::UnsupportedSchema) @{
            Code = 'RIPWIRE_WSL_MANIFEST_UNSUPPORTED_SCHEMA'; Message = "Unsupported manifest schema '$($manifest.schemaVersion)'."
        }
    }
    if (-not (Test-RipwireJsonString $manifest.releaseVersion) -or
        -not (Test-RipwireJsonString $manifest.releaseCommit) -or
        $manifest.releaseVersion -cnotmatch '^v[0-9]+\.[0-9]+\.[0-9]+$' -or
        $manifest.releaseCommit -cnotmatch '^[0-9a-f]{40}$' -or
        $manifest.assets -isnot [array] -or $manifest.assets.Count -eq 0 -or
        $manifest.options -isnot [array] -or $manifest.options.Count -eq 0) {
        return New-RipwireTaggedResult Ripwire.ManifestParseResult ([RipwireManifestState]::MissingField) @{
            Code = 'RIPWIRE_WSL_MANIFEST_INVALID_FIELD'; Message = 'Manifest identity, assets, or options are invalid.'
        }
    }
    $aliases = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $normalized = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $version = $manifest.releaseVersion.Substring(1)
    foreach ($asset in $manifest.assets) {
        if ($asset -isnot [System.Collections.IDictionary]) {
            return New-RipwireTaggedResult Ripwire.ManifestParseResult ([RipwireManifestState]::MalformedJson) @{
                Code = 'RIPWIRE_WSL_MANIFEST_INVALID_ASSET'; Message = 'Each asset must be an object.'
            }
        }
        $check = Test-RipwireExactFields $asset @(
            'architecture', 'acceptedMachineArchitectures', 'assetName', 'url', 'sha256', 'archiveRoot', 'payload') 'asset'
        if ($check.State -ne 'Valid') {
            return New-RipwireTaggedResult Ripwire.ManifestParseResult ([RipwireManifestState]::$($check.State)) @{
                Code = $check.Code; Message = $check.Message
            }
        }
        if (-not (Test-RipwireJsonString $asset.architecture) -or
            -not (Test-RipwireJsonString $asset.assetName) -or
            -not (Test-RipwireJsonString $asset.url) -or
            -not (Test-RipwireJsonString $asset.sha256) -or
            -not (Test-RipwireJsonString $asset.archiveRoot) -or
            -not (Test-RipwireJsonString $asset.payload)) {
            return New-RipwireTaggedResult Ripwire.ManifestParseResult ([RipwireManifestState]::InconsistentAsset) @{
                Code = 'RIPWIRE_WSL_MANIFEST_INVALID_ASSET'; Message = 'Asset scalar fields must be strings.'
            }
        }
        if ($asset.sha256 -cnotmatch '^[0-9a-f]{64}$') {
            return New-RipwireTaggedResult Ripwire.ManifestParseResult ([RipwireManifestState]::InvalidDigest) @{
                Code = 'RIPWIRE_WSL_MANIFEST_INVALID_DIGEST'; Message = "Invalid SHA-256 for '$($asset.architecture)'."
            }
        }
        if (-not $normalized.Add([string] $asset.architecture)) {
            return New-RipwireTaggedResult Ripwire.ManifestParseResult ([RipwireManifestState]::DuplicateArchitecture) @{
                Code = 'RIPWIRE_WSL_MANIFEST_DUPLICATE_ARCHITECTURE'; Message = "Duplicate architecture '$($asset.architecture)'."
            }
        }
        if ($asset.architecture -cnotin @('x64', 'arm64') -or
            $asset.assetName -cne "ripwire-$version-linux-$($asset.architecture).tar.gz" -or
            $asset.archiveRoot -cne "ripwire-$version-linux-$($asset.architecture)" -or
            $asset.payload -cne "$($asset.archiveRoot)/ripwire" -or
            $asset.url -cne "https://github.com/redhat-et/ripwire/releases/download/$($manifest.releaseVersion)/$($asset.assetName)") {
            return New-RipwireTaggedResult Ripwire.ManifestParseResult ([RipwireManifestState]::InconsistentAsset) @{
                Code = 'RIPWIRE_WSL_MANIFEST_INCONSISTENT_ASSET'; Message = "Asset '$($asset.architecture)' is inconsistent with the release."
            }
        }
        if ($asset.acceptedMachineArchitectures -isnot [array] -or $asset.acceptedMachineArchitectures.Count -eq 0) {
            return New-RipwireTaggedResult Ripwire.ManifestParseResult ([RipwireManifestState]::MissingField) @{
                Code = 'RIPWIRE_WSL_MANIFEST_INVALID_ALIASES'; Message = "Architecture '$($asset.architecture)' has no aliases."
            }
        }
        foreach ($alias in $asset.acceptedMachineArchitectures) {
            if (-not (Test-RipwireJsonString $alias) -or [string]::IsNullOrWhiteSpace($alias) -or
                -not $aliases.Add($alias)) {
                return New-RipwireTaggedResult Ripwire.ManifestParseResult ([RipwireManifestState]::DuplicateArchitecture) @{
                    Code = 'RIPWIRE_WSL_MANIFEST_DUPLICATE_ARCHITECTURE'; Message = "Duplicate architecture alias '$alias'."
                }
            }
        }
        $expectedAliases = switch ($asset.architecture) {
            'x64' { @('x86_64', 'amd64') }
            'arm64' { @('aarch64', 'arm64') }
            default { @() }
        }
        if ($expectedAliases.Count -ne $asset.acceptedMachineArchitectures.Count -or
            @($expectedAliases | Where-Object { $_ -cnotin $asset.acceptedMachineArchitectures }).Count -ne 0) {
            return New-RipwireTaggedResult Ripwire.ManifestParseResult ([RipwireManifestState]::InconsistentAsset) @{
                Code = 'RIPWIRE_WSL_MANIFEST_INCONSISTENT_ARCHITECTURE'
                Message = "Architecture '$($asset.architecture)' has an invalid alias mapping."
            }
        }
    }
    if ($normalized.Count -ne 2 -or -not $normalized.Contains('x64') -or -not $normalized.Contains('arm64')) {
        return New-RipwireTaggedResult Ripwire.ManifestParseResult ([RipwireManifestState]::InconsistentAsset) @{
            Code = 'RIPWIRE_WSL_MANIFEST_INCOMPLETE_ARCHITECTURES'
            Message = 'Manifest must declare exactly one x64 asset and one arm64 asset.'
        }
    }
    $optionNames = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($option in $manifest.options) {
        if ($option -isnot [System.Collections.IDictionary]) {
            return New-RipwireTaggedResult Ripwire.ManifestParseResult ([RipwireManifestState]::MalformedJson) @{
                Code = 'RIPWIRE_WSL_MANIFEST_INVALID_OPTION'; Message = 'Each option must be an object.'
            }
        }
        $check = Test-RipwireExactFields $option @(
            'name', 'kind', 'valueGrammar', 'repeatable', 'dependencies', 'rejectionCategory') 'option'
        if ($check.State -ne 'Valid') {
            return New-RipwireTaggedResult Ripwire.ManifestParseResult ([RipwireManifestState]::$($check.State)) @{
                Code = $check.Code; Message = $check.Message
            }
        }
        $kindGrammarValid = $false
        if ((Test-RipwireJsonString $option.kind) -and (Test-RipwireJsonString $option.valueGrammar)) {
            $kindGrammarValid = switch ($option.kind) {
                'primary' { $option.valueGrammar -cin @('none', 'non-empty-text', 'symbol', 'symbol-list', 'windows-path') }
                'numeric-modifier' { $option.valueGrammar -cin @('non-negative-int', 'positive-int') }
                'boolean-modifier' { $option.valueGrammar -ceq 'none' }
                'rejected' { $option.valueGrammar -ceq 'any' }
                default { $false }
            }
        }
        if (-not (Test-RipwireJsonString $option.name) -or
            -not (Test-RipwireJsonString $option.kind) -or
            -not (Test-RipwireJsonString $option.valueGrammar) -or
            $option.name -cnotmatch '^--[a-z][a-z0-9-]*$' -or -not $optionNames.Add($option.name) -or
            $option.kind -cnotin @('primary', 'numeric-modifier', 'boolean-modifier', 'rejected') -or
            $option.valueGrammar -cnotin @('none', 'non-empty-text', 'symbol', 'symbol-list', 'windows-path',
                'non-negative-int', 'positive-int', 'any') -or
            -not $kindGrammarValid -or
            $option.repeatable -isnot [bool] -or $option.dependencies -isnot [array] -or
            @($option.dependencies | Where-Object { $_ -isnot [string] }).Count -ne 0 -or
            ($option.kind -eq 'rejected' -and $option.rejectionCategory -cnotin @('mutation', 'mcp', 'output')) -or
            ($option.kind -eq 'rejected' -and $option.rejectionCategory -isnot [string]) -or
            ($option.kind -ne 'rejected' -and $null -ne $option.rejectionCategory)) {
            return New-RipwireTaggedResult Ripwire.ManifestParseResult ([RipwireManifestState]::InconsistentAsset) @{
                Code = 'RIPWIRE_WSL_MANIFEST_INVALID_OPTION'; Message = "Option '$($option.name)' is invalid."
            }
        }
    }
    foreach ($option in $manifest.options) {
        if ($option.kind -eq 'rejected' -and $option.dependencies.Count -ne 0) {
            return New-RipwireTaggedResult Ripwire.ManifestParseResult ([RipwireManifestState]::InconsistentAsset) @{
                Code = 'RIPWIRE_WSL_MANIFEST_INVALID_DEPENDENCY'
                Message = "Rejected option '$($option.name)' cannot declare dependencies."
            }
        }
        $dependencyNames = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        foreach ($dependency in $option.dependencies) {
            if (-not $dependencyNames.Add($dependency) -or
                $dependency -ceq $option.name -or -not $optionNames.Contains($dependency)) {
                return New-RipwireTaggedResult Ripwire.ManifestParseResult ([RipwireManifestState]::InconsistentAsset) @{
                    Code = 'RIPWIRE_WSL_MANIFEST_INVALID_DEPENDENCY'
                    Message = "Option '$($option.name)' has invalid dependency '$dependency'."
                }
            }
            $target = @($manifest.options | Where-Object name -CEQ $dependency)
            if ($target.Count -ne 1 -or $target[0].kind -eq 'rejected') {
                return New-RipwireTaggedResult Ripwire.ManifestParseResult ([RipwireManifestState]::InconsistentAsset) @{
                    Code = 'RIPWIRE_WSL_MANIFEST_INVALID_DEPENDENCY'
                    Message = "Option '$($option.name)' depends on unavailable option '$dependency'."
                }
            }
        }
    }
    return New-RipwireTaggedResult Ripwire.ManifestParseResult ([RipwireManifestState]::Valid) @{
        Manifest = $manifest
    }
}

function Resolve-RipwireArchitecture {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Manifest,
        [Parameter(Mandatory)][string] $MachineArchitecture
    )
    foreach ($asset in $Manifest.assets) {
        if ($MachineArchitecture -cin $asset.acceptedMachineArchitectures) {
            return New-RipwireTaggedResult Ripwire.ArchitectureResult Valid @{
                Architecture = $asset.architecture; Asset = $asset
            }
        }
    }
    return New-RipwireTaggedResult Ripwire.ArchitectureResult Unsupported @{
        Code = 'RIPWIRE_WSL_UNSUPPORTED_ARCHITECTURE'; Message = "Unsupported architecture '$MachineArchitecture'."
    }
}

function Read-RipwireConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $Path,
        [Parameter(Mandatory)][System.Collections.IDictionary] $Manifest
    )
    if (-not [IO.File]::Exists($Path)) {
        return New-RipwireTaggedResult Ripwire.ConfigurationResult ([RipwireConfigurationState]::Missing) @{
            Code = 'RIPWIRE_WSL_CONFIG_MISSING'; Message = "Configuration does not exist: $Path"
        }
    }
    try { $raw = [IO.File]::ReadAllText($Path) }
    catch {
        return New-RipwireTaggedResult Ripwire.ConfigurationResult ([RipwireConfigurationState]::Unreadable) @{
            Code = 'RIPWIRE_WSL_CONFIG_UNREADABLE'; Message = $_.Exception.Message
        }
    }
    $structure = Test-RipwireJsonStructure $raw
    if ($structure.State -ne 'Valid') {
        return New-RipwireTaggedResult Ripwire.ConfigurationResult ([RipwireConfigurationState]::Malformed) @{
            Code = $structure.Code; Message = $structure.Message
        }
    }
    try { $config = $raw | ConvertFrom-Json -AsHashtable -Depth 10 }
    catch {
        return New-RipwireTaggedResult Ripwire.ConfigurationResult ([RipwireConfigurationState]::Malformed) @{
            Code = 'RIPWIRE_WSL_CONFIG_MALFORMED'; Message = $_.Exception.Message
        }
    }
    if ($config -isnot [System.Collections.IDictionary]) {
        return New-RipwireTaggedResult Ripwire.ConfigurationResult ([RipwireConfigurationState]::Malformed) @{
            Code = 'RIPWIRE_WSL_CONFIG_MALFORMED'; Message = 'Configuration root must be an object.'
        }
    }
    $fields = @('schemaVersion', 'distribution', 'architecture', 'releaseVersion', 'releaseCommit',
        'archiveSha256', 'binaryPath', 'cacheRoot')
    $check = Test-RipwireExactFields $config $fields 'configuration'
    if ($check.State -ne 'Valid') {
        return New-RipwireTaggedResult Ripwire.ConfigurationResult ([RipwireConfigurationState]::Malformed) @{
            Code = $check.Code; Message = $check.Message
        }
    }
    if (-not (Test-RipwireJsonInteger $config.schemaVersion) -or $config.schemaVersion -ne 1) {
        return New-RipwireTaggedResult Ripwire.ConfigurationResult ([RipwireConfigurationState]::UnsupportedVersion) @{
            Code = 'RIPWIRE_WSL_CONFIG_UNSUPPORTED_VERSION'; Message = "Unsupported configuration schema '$($config.schemaVersion)'."
        }
    }
    if (-not (Test-RipwireJsonString $config.distribution) -or
        -not (Test-RipwireJsonString $config.architecture) -or
        -not (Test-RipwireJsonString $config.releaseVersion) -or
        -not (Test-RipwireJsonString $config.releaseCommit) -or
        -not (Test-RipwireJsonString $config.archiveSha256) -or
        -not (Test-RipwireJsonString $config.binaryPath) -or
        -not (Test-RipwireJsonString $config.cacheRoot)) {
        return New-RipwireTaggedResult Ripwire.ConfigurationResult ([RipwireConfigurationState]::Malformed) @{
            Code = 'RIPWIRE_WSL_CONFIG_MALFORMED'; Message = 'Configuration scalar fields must be strings.'
        }
    }
    $asset = @($Manifest.assets | Where-Object architecture -CEQ $config.architecture)
    if ([string]::IsNullOrWhiteSpace($config.distribution) -or $asset.Count -ne 1 -or
        $config.archiveSha256 -cnotmatch '^[0-9a-f]{64}$' -or
        $config.binaryPath -cnotmatch '^/[^\r\n]*$' -or $config.cacheRoot -cnotmatch '^/[^\r\n]*$') {
        return New-RipwireTaggedResult Ripwire.ConfigurationResult ([RipwireConfigurationState]::Malformed) @{
            Code = 'RIPWIRE_WSL_CONFIG_MALFORMED'; Message = 'Configuration values are invalid.'
        }
    }
    if ($config.releaseVersion -cne $Manifest.releaseVersion -or
        $config.releaseCommit -cne $Manifest.releaseCommit -or
        $config.archiveSha256 -cne $asset[0].sha256) {
        return New-RipwireTaggedResult Ripwire.ConfigurationResult ([RipwireConfigurationState]::ValidButStale) @{
            Code = 'RIPWIRE_WSL_CONFIG_STALE'; Message = 'Configuration does not match the packaged release.'
            Configuration = $config
        }
    }
    return New-RipwireTaggedResult Ripwire.ConfigurationResult ([RipwireConfigurationState]::Valid) @{
        Configuration = $config
    }
}

function Test-RipwireOptionValue {
    param([string] $Grammar, [AllowEmptyString()][string] $Value, [bool] $Attached)
    switch ($Grammar) {
        'none' { return -not $Attached }
        'non-empty-text' { return $Attached -and -not [string]::IsNullOrEmpty($Value) }
        'symbol' { return $Attached -and -not [string]::IsNullOrWhiteSpace($Value) }
        'symbol-list' { return $Attached -and $Value -cmatch '^[^,\s]+(?:,[^,\s]+)*$' }
        'windows-path' { return $Attached -and -not [string]::IsNullOrWhiteSpace($Value) -and [IO.Path]::IsPathFullyQualified($Value) }
        'non-negative-int' {
            if (-not $Attached -or $Value -cnotmatch '^(0|[1-9][0-9]*)$') { return $false }
            [long] $number = 0
            return [long]::TryParse($Value, [Globalization.NumberStyles]::None,
                [Globalization.CultureInfo]::InvariantCulture, [ref] $number) -and $number -le 1000000000
        }
        'positive-int' {
            if (-not $Attached -or $Value -cnotmatch '^[1-9][0-9]*$') { return $false }
            [long] $number = 0
            return [long]::TryParse($Value, [Globalization.NumberStyles]::None,
                [Globalization.CultureInfo]::InvariantCulture, [ref] $number) -and $number -le 1000000000
        }
        'any' { return $true }
        default { throw "RIPWIRE_WSL_INTERNAL_UNKNOWN_GRAMMAR: $Grammar" }
    }
}

function Classify-RipwireInvocation {
    [CmdletBinding()]
    param(
        [AllowEmptyCollection()][AllowEmptyString()][string[]] $Arguments = @(),
        [Parameter(Mandatory)][System.Collections.IDictionary] $Manifest
    )
    if ($Arguments.Count -eq 0) {
        return New-RipwireTaggedResult Ripwire.InvocationClassification ([RipwireInvocationKind]::AllowedDefaultMap) @{
            Arguments = [string[]] @(); PrimarySelector = $null
        }
    }
    $table = [Collections.Generic.Dictionary[string, object]]::new([StringComparer]::Ordinal)
    foreach ($option in $Manifest.options) { $table.Add($option.name, $option) }
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $primary = $null
    foreach ($argument in $Arguments) {
        if ($argument -cnotmatch '^--') {
            return New-RipwireTaggedResult Ripwire.InvocationClassification ([RipwireInvocationKind]::RejectedAdditionalRoot) @{
                Code = 'RIPWIRE_WSL_REJECTED_ROOT'; ExitCode = 64; Argument = $argument
            }
        }
        $equals = $argument.IndexOf('=')
        $name = if ($equals -ge 0) { $argument.Substring(0, $equals) } else { $argument }
        $value = if ($equals -ge 0) { $argument.Substring($equals + 1) } else { $null }
        if (-not $table.ContainsKey($name)) {
            return New-RipwireTaggedResult Ripwire.InvocationClassification ([RipwireInvocationKind]::RejectedUnknown) @{
                Code = 'RIPWIRE_WSL_REJECTED_UNKNOWN'; ExitCode = 68; Argument = $argument
            }
        }
        $definition = $table[$name]
        if ($definition.kind -eq 'rejected') {
            $state, $code, $exit = switch ($definition.rejectionCategory) {
                'mutation' { [RipwireInvocationKind]::RejectedMutation; 'RIPWIRE_WSL_REJECTED_MUTATION'; 65 }
                'mcp' { [RipwireInvocationKind]::RejectedMcp; 'RIPWIRE_WSL_REJECTED_MCP'; 66 }
                'output' { [RipwireInvocationKind]::RejectedOutput; 'RIPWIRE_WSL_REJECTED_OUTPUT'; 67 }
                default { throw 'RIPWIRE_WSL_INTERNAL_REJECTION_CATEGORY' }
            }
            return New-RipwireTaggedResult Ripwire.InvocationClassification $state @{
                Code = $code; ExitCode = $exit; Argument = $argument
            }
        }
        $alreadySeen = $seen.Contains($name)
        if (($alreadySeen -and -not $definition.repeatable) -or
            -not (Test-RipwireOptionValue $definition.valueGrammar $value ($equals -ge 0))) {
            return New-RipwireTaggedResult Ripwire.InvocationClassification ([RipwireInvocationKind]::InvalidSyntax) @{
                Code = 'RIPWIRE_WSL_INVALID_ARGUMENT'; ExitCode = 69; Argument = $argument
            }
        }
        $null = $seen.Add($name)
        if ($definition.kind -eq 'primary') {
            if ($null -ne $primary) {
                return New-RipwireTaggedResult Ripwire.InvocationClassification ([RipwireInvocationKind]::InvalidSyntax) @{
                    Code = 'RIPWIRE_WSL_INVALID_ARGUMENT'; ExitCode = 69; Argument = $argument
                    Message = 'At most one primary selector is allowed.'
                }
            }
            $primary = $name
        }
    }
    foreach ($name in $seen) {
        foreach ($dependency in $table[$name].dependencies) {
            if (-not $seen.Contains($dependency)) {
                return New-RipwireTaggedResult Ripwire.InvocationClassification ([RipwireInvocationKind]::InvalidSyntax) @{
                    Code = 'RIPWIRE_WSL_INVALID_ARGUMENT'; ExitCode = 69; Argument = $name
                    Message = "Option '$name' requires '$dependency'."
                }
            }
        }
    }
    return New-RipwireTaggedResult Ripwire.InvocationClassification ([RipwireInvocationKind]::AllowedAnalysis) @{
        Arguments = [string[]] $Arguments.Clone(); PrimarySelector = $primary
    }
}

function New-RipwireChildEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $ParentEnvironment,
        [Parameter(Mandatory)][System.Collections.IDictionary] $Variables
    )
    $result = @{}
    $environmentNames = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($name in $ParentEnvironment.Keys) {
        $textName = [string] $name
        if (-not $environmentNames.Add($textName)) {
            throw "RIPWIRE_WSL_DUPLICATE_ENVIRONMENT_VARIABLE: $textName"
        }
        $result[$textName] = $ParentEnvironment[$name]
    }
    foreach ($name in $result.Keys) {
        $textName = [string] $name
        if (($textName -ieq 'GIT_CONFIG_COUNT' -and $textName -cne 'GIT_CONFIG_COUNT') -or
            ($textName -imatch '^GIT_CONFIG_(?:KEY|VALUE)_[0-9]+$' -and
             $textName -cnotmatch '^GIT_CONFIG_(?:KEY|VALUE)_[0-9]+$')) {
            throw "RIPWIRE_WSL_NONCANONICAL_GIT_CONFIG_ENTRY: $textName"
        }
    }
    $wslenv = if ($result.ContainsKey('WSLENV') -and $null -ne $result.WSLENV) { [string] $result.WSLENV } else { '' }
    $tokens = [Collections.Generic.List[string]]::new()
    $transported = [Collections.Generic.Dictionary[string, string]]::new([StringComparer]::OrdinalIgnoreCase)
    if ($wslenv -ne '') {
        foreach ($token in $wslenv.Split([char] ':')) {
            if ($token -cnotmatch '^([A-Za-z_][A-Za-z0-9_]*)(?:/([pluw]+))?$') {
                throw "RIPWIRE_WSL_INVALID_WSLENV: $token"
            }
            $name = $Matches[1]
            $flags = $Matches[2]
            if ($transported.ContainsKey($name)) { throw "RIPWIRE_WSL_DUPLICATE_WSLENV: $name" }
            if ($flags) {
                $letters = $flags.ToCharArray()
                if (@($letters | Select-Object -Unique).Count -ne $letters.Count -or
                    ($flags.Contains('u') -and $flags.Contains('w'))) {
                    throw "RIPWIRE_WSL_INVALID_WSLENV_FLAGS: $token"
                }
            }
            $transported.Add($name, $flags)
            $tokens.Add($token)
        }
    }
    $countText = if ($result.ContainsKey('GIT_CONFIG_COUNT') -and $null -ne $result.GIT_CONFIG_COUNT) {
        [string] $result.GIT_CONFIG_COUNT
    } else { '' }
    $count = 0
    if ($countText -ne '' -and
        ($countText -cnotmatch '^(0|[1-9][0-9]*)$' -or -not [int]::TryParse($countText, [ref] $count))) {
        throw 'RIPWIRE_WSL_INVALID_GIT_CONFIG_COUNT'
    }
    $indexed = @{}
    foreach ($name in $result.Keys) {
        if ([string] $name -match '^GIT_CONFIG_(KEY|VALUE)_([0-9]+)$') {
            $indexed[[string] $name] = [int] $Matches[2]
        }
    }
    if ($indexed.Count -ne 2 * $count) { throw 'RIPWIRE_WSL_INVALID_GIT_CONFIG_ENTRIES' }
    for ($i = 0; $i -lt $count; $i++) {
        foreach ($part in @('KEY', 'VALUE')) {
            $name = "GIT_CONFIG_${part}_$i"
            if (-not $result.ContainsKey($name) -or $null -eq $result[$name]) {
                throw "RIPWIRE_WSL_MISSING_GIT_CONFIG_ENTRY: $name"
            }
            if ($part -eq 'KEY' -and [string]::IsNullOrWhiteSpace([string] $result[$name])) {
                throw "RIPWIRE_WSL_EMPTY_GIT_CONFIG_KEY: $name"
            }
            if ($transported.ContainsKey($name) -and $transported[$name] -cne 'u') {
                throw "RIPWIRE_WSL_CONFLICTING_WSLENV: $name"
            }
            if (-not $transported.ContainsKey($name)) {
                $transported.Add($name, 'u'); $tokens.Add("$name/u")
            }
        }
    }
    $result.GIT_CONFIG_COUNT = [string] $count
    if ($transported.ContainsKey('GIT_CONFIG_COUNT')) {
        if ($transported['GIT_CONFIG_COUNT'] -cne 'u') {
            throw 'RIPWIRE_WSL_CONFLICTING_WSLENV: GIT_CONFIG_COUNT'
        }
    } else {
        $transported.Add('GIT_CONFIG_COUNT', 'u')
        $tokens.Add('GIT_CONFIG_COUNT/u')
    }
    foreach ($name in $Variables.Keys) {
        if ($null -eq $Variables[$name]) { throw "RIPWIRE_WSL_NULL_CHILD_VARIABLE: $name" }
        $result[[string] $name] = [string] $Variables[$name]
        if ($transported.ContainsKey([string] $name)) {
            if ($transported[[string] $name] -cne 'u') { throw "RIPWIRE_WSL_CONFLICTING_WSLENV: $name" }
        } else {
            $transported.Add([string] $name, 'u'); $tokens.Add("$name/u")
        }
    }
    $result.WSLENV = $tokens -join ':'
    return $result
}

function Invoke-RipwireNativeCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $FilePath,
        [AllowEmptyCollection()][AllowEmptyString()][string[]] $Arguments = @(),
        [System.Collections.IDictionary] $Environment,
        [ValidateSet('Capture', 'Streaming')][string] $Mode = 'Capture',
        [ValidateRange(1, 3600)][int] $TimeoutSeconds = 60
    )
    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = $FilePath
    $start.UseShellExecute = $false
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    foreach ($argument in $Arguments) { $start.ArgumentList.Add($argument) }
    if ($null -ne $Environment) {
        $start.Environment.Clear()
        foreach ($name in $Environment.Keys) {
            if ($null -ne $Environment[$name]) { $start.Environment[[string] $name] = [string] $Environment[$name] }
        }
    }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $start
    $stdout = if ($Mode -eq 'Capture') { [IO.MemoryStream]::new() } else { [Console]::OpenStandardOutput() }
    $stderr = if ($Mode -eq 'Capture') { [IO.MemoryStream]::new() } else { [Console]::OpenStandardError() }
    $safeToDispose = $true
    try {
        try {
            if (-not $process.Start()) {
                return New-RipwireTaggedResult Ripwire.ExternalCommandResult ([RipwireCommandResultKind]::Unavailable) @{
                    ExitCode = $null; Stdout = [byte[]] @(); Stderr = [byte[]] @(); Message = 'Process did not start.'
                }
            }
        } catch [ComponentModel.Win32Exception] {
            return New-RipwireTaggedResult Ripwire.ExternalCommandResult ([RipwireCommandResultKind]::Unavailable) @{
                ExitCode = $null; Stdout = [byte[]] @(); Stderr = [byte[]] @(); Message = $_.Exception.Message
            }
        } catch {
            return New-RipwireTaggedResult Ripwire.ExternalCommandResult ([RipwireCommandResultKind]::TransportFailure) @{
                ExitCode = $null; Stdout = [byte[]] @(); Stderr = [byte[]] @(); Message = $_.Exception.Message
            }
        }
        $outPump = $process.StandardOutput.BaseStream.CopyToAsync($stdout)
        $errPump = $process.StandardError.BaseStream.CopyToAsync($stderr)
        $wait = $process.WaitForExitAsync()
        $completion = [Threading.Tasks.Task]::WhenAll([Threading.Tasks.Task[]] @($wait, $outPump, $errPump))
        if (-not $completion.Wait($TimeoutSeconds * 1000)) {
            $cleanupErrors = [Collections.Generic.List[string]]::new()
            try {
                if (-not $process.HasExited) { $process.Kill($true) }
            } catch {
                if (-not $process.HasExited) { $cleanupErrors.Add("Kill failed: $($_.Exception.Message)") }
            }
            $exited = $process.HasExited
            if (-not $exited) {
                try { $exited = $process.WaitForExit(5000) }
                catch { $cleanupErrors.Add("Exit wait failed: $($_.Exception.Message)") }
            }
            if (-not $exited) { $cleanupErrors.Add('Process did not exit within the cleanup deadline.') }
            $drained = $false
            try { $drained = $completion.Wait(5000) }
            catch { $cleanupErrors.Add("Stream pump failed during cleanup: $($_.Exception.Message)") }
            if (-not $drained) { $cleanupErrors.Add('Stream pumps did not drain within the cleanup deadline.') }
            $safeToDispose = $exited -and $outPump.IsCompleted -and $errPump.IsCompleted
            $kind = if ($cleanupErrors.Count -eq 0) {
                [RipwireCommandResultKind]::TimedOut
            } else {
                [RipwireCommandResultKind]::TransportFailure
            }
            return New-RipwireTaggedResult Ripwire.ExternalCommandResult $kind @{
                Code = if ($cleanupErrors.Count -eq 0) {
                    'RIPWIRE_WSL_COMMAND_TIMED_OUT'
                } else {
                    'RIPWIRE_WSL_TIMEOUT_CLEANUP_FAILED'
                }
                Cause = [RipwireCommandResultKind]::TimedOut
                ExitCode = $null
                Stdout = if ($Mode -eq 'Capture' -and $outPump.IsCompletedSuccessfully) {
                    $stdout.ToArray()
                } else { [byte[]] @() }
                Stderr = if ($Mode -eq 'Capture' -and $errPump.IsCompletedSuccessfully) {
                    $stderr.ToArray()
                } else { [byte[]] @() }
                Message = if ($cleanupErrors.Count -eq 0) {
                    "Process timed out after $TimeoutSeconds seconds."
                } else {
                    "Process timed out and cleanup failed: $($cleanupErrors -join '; ')"
                }
                CleanupErrors = [string[]] $cleanupErrors.ToArray()
            }
        }
        $kind = if ($process.ExitCode -eq 0) { [RipwireCommandResultKind]::Success } else { [RipwireCommandResultKind]::NonZero }
        return New-RipwireTaggedResult Ripwire.ExternalCommandResult $kind @{
            ExitCode = $process.ExitCode
            Stdout = if ($Mode -eq 'Capture') { $stdout.ToArray() } else { [byte[]] @() }
            Stderr = if ($Mode -eq 'Capture') { $stderr.ToArray() } else { [byte[]] @() }
            Message = $null
        }
    } catch {
        return New-RipwireTaggedResult Ripwire.ExternalCommandResult ([RipwireCommandResultKind]::TransportFailure) @{
            ExitCode = $null
            Stdout = if ($Mode -eq 'Capture') { $stdout.ToArray() } else { [byte[]] @() }
            Stderr = if ($Mode -eq 'Capture') { $stderr.ToArray() } else { [byte[]] @() }
            Message = $_.Exception.Message
        }
    } finally {
        if ($safeToDispose) {
            $process.Dispose()
            if ($Mode -eq 'Capture') { $stdout.Dispose(); $stderr.Dispose() }
        }
    }
}

function ConvertFrom-RipwireUtf8 {
    param([Parameter(Mandatory)][byte[]] $Bytes)
    try {
        $encoding = [Text.UTF8Encoding]::new($false, $true)
        return New-RipwireTaggedResult Ripwire.TextResult Valid @{ Text = $encoding.GetString($Bytes) }
    } catch {
        return New-RipwireTaggedResult Ripwire.TextResult InvalidOutput @{
            Code = 'RIPWIRE_WSL_INVALID_COMMAND_OUTPUT'; Message = $_.Exception.Message
        }
    }
}

function Get-RipwireCanonicalWindowsPath {
    param([Parameter(Mandatory)][string] $Path)
    $full = [IO.Path]::GetFullPath($Path)
    if ([IO.Directory]::Exists($full)) {
        $target = [IO.DirectoryInfo]::new($full).ResolveLinkTarget($true)
        if ($null -ne $target) { $full = $target.FullName }
    } elseif ([IO.File]::Exists($full)) {
        $target = [IO.FileInfo]::new($full).ResolveLinkTarget($true)
        if ($null -ne $target) { $full = $target.FullName }
    }
    return [IO.Path]::TrimEndingDirectorySeparator($full)
}

function Get-RipwireCurrentEnvironment {
    $environment = @{}
    foreach ($entry in [Environment]::GetEnvironmentVariables().GetEnumerator()) {
        $environment[[string] $entry.Key] = $entry.Value
    }
    return $environment
}

function Get-RipwireWindowsGitDiscoveryEnvironment {
    param([Parameter(Mandatory)][System.Collections.IDictionary] $SourceEnvironment)
    $blocked = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($name in @(
        'GIT_DIR', 'GIT_WORK_TREE', 'GIT_COMMON_DIR', 'GIT_INDEX_FILE', 'GIT_OBJECT_DIRECTORY',
        'GIT_ALTERNATE_OBJECT_DIRECTORIES', 'GIT_NAMESPACE', 'GIT_PREFIX',
        'GIT_CEILING_DIRECTORIES', 'GIT_DISCOVERY_ACROSS_FILESYSTEM', 'GIT_CONFIG',
        'GIT_CONFIG_COUNT', 'GIT_CONFIG_PARAMETERS', 'GIT_CONFIG_SYSTEM', 'GIT_CONFIG_GLOBAL',
        'GIT_CONFIG_NOSYSTEM'
    )) {
        $null = $blocked.Add($name)
    }
    $result = @{}
    foreach ($name in $SourceEnvironment.Keys) {
        $textName = [string] $name
        if ($blocked.Contains($textName) -or
            $textName -cmatch '^GIT_CONFIG_(?:KEY|VALUE)_[0-9]+$') {
            continue
        }
        $result[$textName] = $SourceEnvironment[$name]
    }
    $result.GIT_OPTIONAL_LOCKS = '0'
    return $result
}

function Resolve-RipwireWindowsWorktree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $WorktreePath,
        [string] $GitPath = 'git',
        [System.Collections.IDictionary] $Environment
    )
    try {
        if (-not [IO.Directory]::Exists($WorktreePath)) { throw "Directory does not exist: $WorktreePath" }
        $requested = Get-RipwireCanonicalWindowsPath $WorktreePath
    } catch {
        return New-RipwireTaggedResult Ripwire.WorktreeResult InvalidWorktree @{
            Code = 'RIPWIRE_WSL_INVALID_WORKTREE'; Message = $_.Exception.Message
        }
    }
    if ($null -eq $Environment) { $Environment = Get-RipwireCurrentEnvironment }
    $gitEnvironment = Get-RipwireWindowsGitDiscoveryEnvironment $Environment
    $values = @{}
    foreach ($probe in @(
        @{ Name = 'Root'; Args = @('-C', $requested, 'rev-parse', '--show-toplevel') },
        @{ Name = 'GitDirectory'; Args = @('-C', $requested, 'rev-parse', '--absolute-git-dir') },
        @{ Name = 'CommonDirectory'; Args = @('-C', $requested, 'rev-parse', '--git-common-dir') }
    )) {
        $result = Invoke-RipwireNativeCommand $GitPath $probe.Args $gitEnvironment
        if ($result.State -ne [RipwireCommandResultKind]::Success) {
            return New-RipwireTaggedResult Ripwire.WorktreeResult GitFailure @{
                Code = 'RIPWIRE_WSL_GIT_DISCOVERY_FAILED'; Message = "Git failed resolving $($probe.Name)."
                CommandResult = $result
            }
        }
        $text = ConvertFrom-RipwireUtf8 $result.Stdout
        if ($text.State -ne 'Valid') {
            return New-RipwireTaggedResult Ripwire.WorktreeResult InvalidOutput @{
                Code = $text.Code; Message = $text.Message
            }
        }
        $values[$probe.Name] = $text.Text.TrimEnd("`r", "`n")
    }
    try {
        $root = Get-RipwireCanonicalWindowsPath $values.Root
        if (-not [string]::Equals($requested, $root, [StringComparison]::OrdinalIgnoreCase)) {
            return New-RipwireTaggedResult Ripwire.WorktreeResult MismatchedRoot @{
                Code = 'RIPWIRE_WSL_MISMATCHED_WORKTREE'
                Message = "Requested path '$requested' is not the exact worktree root '$root'."
            }
        }
        $gitDirectory = Get-RipwireCanonicalWindowsPath $values.GitDirectory
        $commonDirectory = if ([IO.Path]::IsPathFullyQualified($values.CommonDirectory)) {
            Get-RipwireCanonicalWindowsPath $values.CommonDirectory
        } else {
            Get-RipwireCanonicalWindowsPath (Join-Path $root $values.CommonDirectory)
        }
    } catch {
        return New-RipwireTaggedResult Ripwire.WorktreeResult InvalidOutput @{
            Code = 'RIPWIRE_WSL_INVALID_GIT_PATH'; Message = $_.Exception.Message
        }
    }
    return New-RipwireTaggedResult Ripwire.WorktreeResult Valid @{
        WindowsRoot = $root; WindowsGitDirectory = $gitDirectory; WindowsCommonDirectory = $commonDirectory
    }
}

function ConvertTo-RipwireLinuxPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $WindowsPath,
        [Parameter(Mandatory)][string] $Distribution,
        [string] $WslPath = 'wsl.exe'
    )
    $result = Invoke-RipwireNativeCommand $WslPath @(
        '--distribution', $Distribution, '--exec', 'wslpath', '-a', '-u', '--', $WindowsPath)
    if ($result.State -ne [RipwireCommandResultKind]::Success) {
        return New-RipwireTaggedResult Ripwire.PathTranslationResult Failed @{
            Code = 'RIPWIRE_WSL_PATH_TRANSLATION_FAILED'; CommandResult = $result
        }
    }
    $text = ConvertFrom-RipwireUtf8 $result.Stdout
    if ($text.State -ne 'Valid') { return $text }
    $path = $text.Text.TrimEnd("`r", "`n")
    if ($path -cnotmatch '^/[^\r\n]+$') {
        return New-RipwireTaggedResult Ripwire.PathTranslationResult InvalidOutput @{
            Code = 'RIPWIRE_WSL_INVALID_LINUX_PATH'; Message = "wslpath returned '$path'."
        }
    }
    return New-RipwireTaggedResult Ripwire.PathTranslationResult Valid @{ LinuxPath = $path }
}

function Get-RipwireCacheNamespaceKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $LinuxRoot,
        [Parameter(Mandatory)][string] $LinuxGitDirectory,
        [Parameter(Mandatory)][string] $LinuxCommonDirectory
    )
    $identity = ConvertTo-Json -InputObject @($LinuxRoot, $LinuxGitDirectory, $LinuxCommonDirectory) `
        -Compress -EscapeHandling EscapeNonAscii
    [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData(
        [Text.Encoding]::UTF8.GetBytes($identity))).ToLowerInvariant()
}

function Test-RipwireLinuxPathOverlap {
    param([string] $Left, [string] $Right)
    $a = $Left.TrimEnd('/')
    $b = $Right.TrimEnd('/')
    return $a -ceq $b -or $a.StartsWith("$b/", [StringComparison]::Ordinal) -or
        $b.StartsWith("$a/", [StringComparison]::Ordinal)
}

function New-RipwireCacheContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $CacheRoot,
        [Parameter(Mandatory)][string] $ReleaseVersion,
        [Parameter(Mandatory)][ValidateSet('x64', 'arm64')][string] $Architecture,
        [Parameter(Mandatory)][string] $LinuxRoot,
        [Parameter(Mandatory)][string] $LinuxGitDirectory,
        [Parameter(Mandatory)][string] $LinuxCommonDirectory,
        [Parameter(Mandatory)][string] $BinaryPath
    )
    foreach ($path in @($CacheRoot, $LinuxRoot, $LinuxGitDirectory, $LinuxCommonDirectory, $BinaryPath)) {
        if ($path -cnotmatch '^/[^\r\n]*$') {
            return New-RipwireTaggedResult Ripwire.ManagedCacheContext InvalidPath @{
                Code = 'RIPWIRE_WSL_INVALID_CACHE_PATH'; Message = "Not an absolute Linux path: '$path'."
            }

        }
    }
    if ($CacheRoot -cmatch '^/(?:mnt|run/desktop/mnt/host)(?:/|$)') {
        return New-RipwireTaggedResult Ripwire.ManagedCacheContext WindowsBacked @{
            Code = 'RIPWIRE_WSL_WINDOWS_BACKED_CACHE'; Message = 'Cache root must be Linux-native.'
        }
    }
    foreach ($forbidden in @($LinuxRoot, $LinuxGitDirectory, $LinuxCommonDirectory, (Split-Path -Parent $BinaryPath).Replace('\', '/'))) {
        if (Test-RipwireLinuxPathOverlap $CacheRoot $forbidden) {
            return New-RipwireTaggedResult Ripwire.ManagedCacheContext Overlap @{
                Code = 'RIPWIRE_WSL_CACHE_OVERLAP'; Message = "Cache root overlaps '$forbidden'."
            }
        }
    }
    $key = Get-RipwireCacheNamespaceKey $LinuxRoot $LinuxGitDirectory $LinuxCommonDirectory
    $versionSegment = $ReleaseVersion -replace '[^A-Za-z0-9._-]', '_'
    $namespace = "$($CacheRoot.TrimEnd('/'))/releases/$versionSegment/$Architecture/$key"
    $lockDirectory = "$($CacheRoot.TrimEnd('/'))/locks/$versionSegment/$Architecture"
    return New-RipwireTaggedResult Ripwire.ManagedCacheContext Valid @{
        CacheRoot = $CacheRoot.TrimEnd('/'); NamespaceKey = $key; Namespace = $namespace
        TemporaryDirectory = "$namespace/tmp"; XdgCacheDirectory = "$namespace/xdg"
        LockDirectory = $lockDirectory; LockPath = "$lockDirectory/$key.lock"
    }
}

function New-RipwireWslLaunchArguments {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $Distribution,
        [Parameter(Mandatory)][string] $LinuxRoot,
        [Parameter(Mandatory)][string] $LinuxBootstrap,
        [AllowEmptyCollection()][AllowEmptyString()][string[]] $RipwireArguments = @()
    )
    return [string[]] (@('--distribution', $Distribution, '--cd', $LinuxRoot, '--exec',
        '/bin/bash', '--', $LinuxBootstrap, '--', $LinuxRoot) + $RipwireArguments)
}

function New-RipwireWorktreeLaunchContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $WorktreePath,
        [AllowEmptyCollection()][AllowEmptyString()][string[]] $RipwireArguments = @(),
        [Parameter(Mandatory)][System.Collections.IDictionary] $Configuration,
        [Parameter(Mandatory)][System.Collections.IDictionary] $Manifest,
        [Parameter(Mandatory)][string] $BootstrapWindowsPath,
        [Parameter(Mandatory)][System.Collections.IDictionary] $ParentEnvironment,
        [string] $GitPath = 'git',
        [string] $WslPath = 'wsl.exe',
        [ValidateSet('analysis', 'diagnostic', 'clear')][string] $Operation = 'analysis',
        [switch] $Diagnostic,
        [scriptblock] $PathTranslator
    )
    if ($Diagnostic) {
        if ($Operation -eq 'clear') {
            return New-RipwireTaggedResult Ripwire.WorktreeLaunchContext InvalidOperation @{
                Code = 'RIPWIRE_WSL_CONFLICTING_OPERATION'
                Message = '-Diagnostic cannot be combined with -Operation clear.'
            }
        }
        $Operation = 'diagnostic'
    }
    if ($Operation -eq 'clear' -and $RipwireArguments.Count -ne 0) {
        return New-RipwireTaggedResult Ripwire.WorktreeLaunchContext InvalidOperation @{
            Code = 'RIPWIRE_WSL_INVALID_CLEAR_ARGUMENT'
            Message = 'Clear does not accept Ripwire analysis arguments.'
        }
    }
    $invocation = Classify-RipwireInvocation $RipwireArguments $Manifest
    if ($invocation.State -notin @(
        [RipwireInvocationKind]::AllowedDefaultMap, [RipwireInvocationKind]::AllowedAnalysis)) {
        return New-RipwireTaggedResult Ripwire.WorktreeLaunchContext RejectedInvocation @{
            Code = $invocation.Code; Invocation = $invocation
        }
    }
    try {
        $validatedParentEnvironment = New-RipwireChildEnvironment $ParentEnvironment @{}
    } catch {
        return New-RipwireTaggedResult Ripwire.WorktreeLaunchContext InvalidEnvironment @{
            Code = 'RIPWIRE_WSL_INVALID_ENVIRONMENT'; Message = $_.Exception.Message
        }
    }
    $worktree = Resolve-RipwireWindowsWorktree $WorktreePath $GitPath $validatedParentEnvironment
    if ($worktree.State -ne 'Valid') {
        return New-RipwireTaggedResult Ripwire.WorktreeLaunchContext InvalidWorktree @{
            Code = $worktree.Code; Worktree = $worktree
        }
    }
    function Convert-KnownPath([string] $Path) {
        if ($null -ne $PathTranslator) {
            $translated = & $PathTranslator $Path
            if ($translated -isnot [string] -or $translated -cnotmatch '^/[^\r\n]+$') {
                return New-RipwireTaggedResult Ripwire.PathTranslationResult InvalidOutput @{
                    Code = 'RIPWIRE_WSL_INVALID_LINUX_PATH'; Message = "Translator returned '$translated'."
                }
            }
            return New-RipwireTaggedResult Ripwire.PathTranslationResult Valid @{ LinuxPath = $translated }
        }
        return ConvertTo-RipwireLinuxPath $Path $Configuration.distribution $WslPath
    }
    $translated = @{}
    foreach ($entry in @(
        @{ Name = 'Root'; Path = $worktree.WindowsRoot },
        @{ Name = 'GitDirectory'; Path = $worktree.WindowsGitDirectory },
        @{ Name = 'CommonDirectory'; Path = $worktree.WindowsCommonDirectory },
        @{ Name = 'Bootstrap'; Path = $BootstrapWindowsPath }
    )) {
        $result = Convert-KnownPath $entry.Path
        if ($result.State -ne 'Valid') {
            return New-RipwireTaggedResult Ripwire.WorktreeLaunchContext TranslationFailed @{
                Code = $result.Code; Field = $entry.Name; Translation = $result
            }
        }
        $translated[$entry.Name] = $result.LinuxPath
    }
    $childArguments = [Collections.Generic.List[string]]::new()
    foreach ($argument in $invocation.Arguments) {
        if ($argument.StartsWith('--from-trace=', [StringComparison]::Ordinal)) {
            $windowsTrace = $argument.Substring('--from-trace='.Length)
            $trace = Convert-KnownPath $windowsTrace
            if ($trace.State -ne 'Valid') {
                return New-RipwireTaggedResult Ripwire.WorktreeLaunchContext TranslationFailed @{
                    Code = $trace.Code; Field = 'FromTrace'; Translation = $trace
                }
            }
            $childArguments.Add("--from-trace=$($trace.LinuxPath)")
        } else {
            $childArguments.Add($argument)
        }
    }
    $cache = New-RipwireCacheContext $Configuration.cacheRoot $Configuration.releaseVersion `
        $Configuration.architecture $translated.Root $translated.GitDirectory `
        $translated.CommonDirectory $Configuration.binaryPath
    if ($cache.State -ne 'Valid') {
        return New-RipwireTaggedResult Ripwire.WorktreeLaunchContext InvalidCache @{
            Code = $cache.Code; Cache = $cache
        }
    }
    try {
        $environment = New-RipwireChildEnvironment $ParentEnvironment @{
            GIT_DIR = $translated.GitDirectory
            GIT_WORK_TREE = $translated.Root
            GIT_COMMON_DIR = $translated.CommonDirectory
            RIPWIRE_BIN = $Configuration.binaryPath
            RIPWIRE_WSL_OPERATION = $Operation
            RIPWIRE_WSL_DIAGNOSTIC = $(if ($Operation -eq 'diagnostic') { '1' } else { '0' })
            GIT_OPTIONAL_LOCKS = '0'
            TMPDIR = $cache.TemporaryDirectory
            XDG_CACHE_HOME = $cache.XdgCacheDirectory
        }
    } catch {
        return New-RipwireTaggedResult Ripwire.WorktreeLaunchContext InvalidEnvironment @{
            Code = 'RIPWIRE_WSL_INVALID_ENVIRONMENT'; Message = $_.Exception.Message
        }
    }
    $wslArguments = New-RipwireWslLaunchArguments $Configuration.distribution $translated.Root `
        $translated.Bootstrap $childArguments.ToArray()
    return New-RipwireTaggedResult Ripwire.WorktreeLaunchContext Valid @{
        Operation = $Operation; Invocation = $invocation; Worktree = $worktree
        LinuxRoot = $translated.Root; LinuxGitDirectory = $translated.GitDirectory
        LinuxCommonDirectory = $translated.CommonDirectory; LinuxBootstrap = $translated.Bootstrap
        Cache = $cache; ChildEnvironment = $environment
        WslFilePath = $WslPath; WslArguments = $wslArguments
    }
}
