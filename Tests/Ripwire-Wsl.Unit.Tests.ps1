[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Console]::Error.WriteLine('RIPWIRE_WSL_UNSUPPORTED_RUNTIME')
    exit 78
}

$root = Split-Path -Parent $PSScriptRoot
$package = Join-Path $root 'plugins\devtools\skills\ripwire-wsl'
$common = Join-Path $package 'scripts\RipwireWsl.Common.ps1'
$manifestPath = Join-Path $package 'references\release.json'
. $common

$passed = [Collections.Generic.List[string]]::new()
function Assert-True([bool] $Condition, [string] $Message) {
    if (-not $Condition) { throw "ASSERTION_FAILED: $Message" }
}
function Assert-Equal($Expected, $Actual, [string] $Message) {
    $left = $Expected | ConvertTo-Json -Depth 30 -Compress
    $right = $Actual | ConvertTo-Json -Depth 30 -Compress
    Assert-True ($left -ceq $right) "$Message`nExpected: $left`nActual:   $right"
}
function Add-Pass([string] $Name) { $passed.Add($Name) }

function Copy-JsonValue($Value) {
    return ($Value | ConvertTo-Json -Depth 30 | ConvertFrom-Json -AsHashtable -Depth 30)
}
function Invoke-ManifestMutation([scriptblock] $Mutation) {
    $data = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json -AsHashtable -Depth 30
    & $Mutation $data
    $path = Join-Path $testRoot ("manifest-{0}.json" -f [Guid]::NewGuid().ToString('N'))
    $data | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path -Encoding utf8
    return Read-RipwireReleaseManifest $path
}

$testRoot = Join-Path $root ("ripwire-unit-{0}" -f [Guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $testRoot
try {
    $parsed = Read-RipwireReleaseManifest $manifestPath
    Assert-Equal 'Valid' ([string] $parsed.State) 'Pinned manifest parses'
    $manifest = $parsed.Manifest
    Assert-Equal 'v0.5.0' $manifest.releaseVersion 'Pinned version'
    Assert-Equal 'bacfa3b7b3ad13648ce3892de06af05b6b55a2ac' $manifest.releaseCommit 'Pinned commit'
    Assert-Equal 'x64' (Resolve-RipwireArchitecture $manifest 'x86_64').Architecture 'x86_64 mapping'
    Assert-Equal 'x64' (Resolve-RipwireArchitecture $manifest 'amd64').Architecture 'amd64 mapping'
    Assert-Equal 'arm64' (Resolve-RipwireArchitecture $manifest 'aarch64').Architecture 'aarch64 mapping'
    Assert-Equal 'arm64' (Resolve-RipwireArchitecture $manifest 'arm64').Architecture 'arm64 mapping'
    Assert-Equal 'Unsupported' ([string] (Resolve-RipwireArchitecture $manifest 'riscv64').State) 'Unknown architecture'
    foreach ($asset in $manifest.assets) {
        Assert-Equal @('ripwire', 'README.md', 'LICENSE') @($asset.archiveFiles) `
            "Pinned archive files for $($asset.architecture)"
        Assert-Equal @('skills', 'hooks') @($asset.archiveDirectories) `
            "Pinned archive directories for $($asset.architecture)"
    }
    $expectedAllowed = @('--for', '--pack-task', '--callers', '--callees', '--uses', '--impact', '--situ',
        '--pr-context', '--from-trace', '--whereis', '--grep', '--regex', '--expand', '--outline',
        '--doctor', '--top-k', '--max-tokens', '--detail', '--adaptive', '--signatures-only', '--json')
    Assert-Equal $expectedAllowed @($manifest.options |
        Where-Object kind -CNE 'rejected' | ForEach-Object name) 'Exact V1 allowed option table'
    $expectedOptionMetadata = [ordered] @{
        '--for' = 'primary:non-empty-text'; '--pack-task' = 'primary:non-empty-text'
        '--callers' = 'primary:symbol'; '--callees' = 'primary:symbol'; '--uses' = 'primary:symbol'
        '--impact' = 'primary:symbol'; '--situ' = 'primary:none'; '--pr-context' = 'primary:non-empty-text'
        '--from-trace' = 'primary:windows-path'; '--whereis' = 'primary:symbol'
        '--grep' = 'primary:non-empty-text'; '--regex' = 'primary:non-empty-text'
        '--expand' = 'primary:symbol-list'; '--outline' = 'primary:symbol-list'; '--doctor' = 'primary:none'
        '--top-k' = 'numeric-modifier:non-negative-int'; '--max-tokens' = 'numeric-modifier:positive-int'
        '--detail' = 'numeric-modifier:non-negative-int'; '--adaptive' = 'boolean-modifier:none'
        '--signatures-only' = 'boolean-modifier:none'; '--json' = 'boolean-modifier:none'
    }
    $actualOptionMetadata = [ordered] @{}
    $expectedDependencies = @{
        '--adaptive' = @('--for')
        '--signatures-only' = @('--for')
    }
    foreach ($option in $manifest.options | Where-Object kind -CNE 'rejected') {
        $actualOptionMetadata[$option.name] = "$($option.kind):$($option.valueGrammar)"
        $dependencies = if ($expectedDependencies.ContainsKey($option.name)) {
            $expectedDependencies[$option.name]
        } else { @() }
        Assert-Equal @($dependencies) @($option.dependencies) "Pinned dependencies for $($option.name)"
    }
    Assert-Equal $expectedOptionMetadata $actualOptionMetadata 'Exact V1 kinds and grammars from Spec'
    Assert-Equal @(
        [ordered] @{
            option = '--detail'; condition = 'positive'; requiresAny = @('--for', '--whereis')
        },
        [ordered] @{
            option = '--top-k'; condition = 'zero'; requiresAny = @('--expand', '--outline')
        }
    ) @($manifest.compatibility.conditionalRequires) 'Pinned conditional requirements'
    Assert-Equal @(
        [ordered] @{
            option = '--signatures-only'; condition = 'present'
            excludedOption = '--detail'; excludedCondition = 'positive'
        }
        [ordered] @{
            option = '--json'; condition = 'present'
            excludedOption = '--detail'; excludedCondition = 'positive'
        }
    ) @($manifest.compatibility.exclusions) 'Pinned exclusions'
    $pagingSelectors = @('--callers', '--callees', '--whereis', '--grep', '--regex', '--impact', '--uses')
    $nonJsonSelectors = @('--uses', '--situ', '--pr-context', '--from-trace', '--whereis',
        '--grep', '--regex', '--expand', '--outline', '--doctor')
    Assert-Equal @(
        [ordered] @{ option = '--top-k'; selectors = $pagingSelectors },
        [ordered] @{ option = '--max-tokens'; selectors = $pagingSelectors }
        [ordered] @{ option = '--json'; selectors = $nonJsonSelectors }
    ) @($manifest.compatibility.selectorRejections) 'Pinned selector rejections'
    Assert-Equal 'MissingField' ([string] (Invoke-ManifestMutation { param($m) $m.Remove('releaseCommit') }).State) 'Missing field'
    Assert-Equal 'UnknownField' ([string] (Invoke-ManifestMutation { param($m) $m.extra = 1 }).State) 'Unknown field'
    Assert-Equal 'UnsupportedSchema' ([string] (Invoke-ManifestMutation {
        param($m) $m.schemaVersion = '1'
    }).State) 'String schema version is not coerced'
    Assert-Equal 'UnsupportedSchema' ([string] (Invoke-ManifestMutation {
        param($m) $m.schemaVersion = 1.5
    }).State) 'Floating-point schema version is rejected'
    Assert-Equal 'MissingField' ([string] (Invoke-ManifestMutation {
        param($m) $m.assets = 1
    }).State) 'Numeric assets collection is rejected'
    Assert-Equal 'MissingField' ([string] (Invoke-ManifestMutation {
        param($m) $m.releaseVersion = $null
    }).State) 'Null release identity is rejected without throwing'
    Assert-Equal 'MissingField' ([string] (Invoke-ManifestMutation {
        param($m) $m.releaseVersion = @('v0.5.0')
    }).State) 'Array release identity is not coerced to text'
    Assert-Equal 'InvalidDigest' ([string] (Invoke-ManifestMutation { param($m) $m.assets[0].sha256 = 'bad' }).State) 'Invalid digest'
    Assert-Equal 'DuplicateArchitecture' ([string] (Invoke-ManifestMutation {
        param($m) $m.assets[1].acceptedMachineArchitectures[0] = 'x86_64'
    }).State) 'Duplicate architecture alias'
    Assert-Equal 'InconsistentAsset' ([string] (Invoke-ManifestMutation {
        param($m) $m.assets[0].assetName = 'ripwire-latest.tar.gz'
    }).State) 'Version/asset mismatch'
    Assert-Equal 'InconsistentAsset' ([string] (Invoke-ManifestMutation {
        param($m) $m.assets[0].acceptedMachineArchitectures[0] = 'arbitrary-alias'
    }).State) 'Architecture aliases are fixed by normalized architecture'
    Assert-Equal 'InconsistentAsset' ([string] (Invoke-ManifestMutation {
        param($m) $m.assets = @($m.assets | Where-Object architecture -CEQ 'x64')
    }).State) 'Both supported asset entries are required'
    Assert-Equal 'MissingField' ([string] (Invoke-ManifestMutation {
        param($m) $m.assets[0].Remove('archiveFiles')
    }).State) 'Archive file allowlist is required'
    Assert-Equal 'MissingField' ([string] (Invoke-ManifestMutation {
        param($m) $m.assets[0].Remove('archiveDirectories')
    }).State) 'Archive directory allowlist is required'
    Assert-Equal 'InconsistentAsset' ([string] (Invoke-ManifestMutation {
        param($m) $m.assets[0].archiveFiles = 'ripwire'
    }).State) 'Archive files must be an array'
    Assert-Equal 'InconsistentAsset' ([string] (Invoke-ManifestMutation {
        param($m) $m.assets[0].archiveDirectories = 1
    }).State) 'Archive directories must be an array'
    Assert-Equal 'InconsistentAsset' ([string] (Invoke-ManifestMutation {
        param($m) $m.assets[0].archiveFiles = @('ripwire', 7)
    }).State) 'Archive file entries must be strings'
    Assert-Equal 'InconsistentAsset' ([string] (Invoke-ManifestMutation {
        param($m) $m.assets[0].archiveDirectories = @('skills', 7)
    }).State) 'Archive directory entries must be strings'
    foreach ($invalidEntry in @('', '.', '..', 'nested/file', 'nested\file', 'space name', "line`n", "tab`tname", 'name:part')) {
        Assert-Equal 'InconsistentAsset' ([string] (Invoke-ManifestMutation {
            param($m) $m.assets[0].archiveDirectories = @($invalidEntry)
        }).State) "Invalid archive component '$invalidEntry'"
    }
    Assert-Equal 'InconsistentAsset' ([string] (Invoke-ManifestMutation {
        param($m) $m.assets[0].archiveFiles = @('ripwire', 'ripwire')
    }).State) 'Duplicate archive files are rejected'
    Assert-Equal 'InconsistentAsset' ([string] (Invoke-ManifestMutation {
        param($m) $m.assets[0].archiveDirectories = @('skills', 'skills')
    }).State) 'Duplicate archive directories are rejected'
    Assert-Equal 'InconsistentAsset' ([string] (Invoke-ManifestMutation {
        param($m) $m.assets[0].archiveDirectories = @('ripwire')
    }).State) 'A top-level name cannot be both a file and directory'
    Assert-Equal 'InconsistentAsset' ([string] (Invoke-ManifestMutation {
        param($m) $m.assets[0].archiveFiles = @('README.md', 'LICENSE')
    }).State) 'Payload must be declared as an archive file'
    Assert-Equal 'Valid' ([string] (Invoke-ManifestMutation {
        param($m)
        foreach ($asset in $m.assets) {
            $asset.archiveFiles = @('ripwire')
            $asset.archiveDirectories = @()
        }
    }).State) 'Binary-only archive layout is valid'
    Assert-Equal 'InconsistentAsset' ([string] (Invoke-ManifestMutation {
        param($m) $option = @($m.options | Where-Object name -CEQ '--top-k')[0]; $option.valueGrammar = 'non-empty-text'
    }).State) 'Numeric modifiers require numeric grammar'
    Assert-Equal 'InconsistentAsset' ([string] (Invoke-ManifestMutation {
        param($m) $option = @($m.options | Where-Object name -CEQ '--json')[0]; $option.valueGrammar = 'non-empty-text'
    }).State) 'Boolean modifiers must be valueless'
    Assert-Equal 'InconsistentAsset' ([string] (Invoke-ManifestMutation {
        param($m) $option = @($m.options | Where-Object kind -CEQ 'rejected')[0]; $option.valueGrammar = 'none'
    }).State) 'Rejected options use the opaque any grammar'
    Assert-Equal 'InconsistentAsset' ([string] (Invoke-ManifestMutation {
        param($m) $option = @($m.options | Where-Object name -CEQ '--json')[0]; $option.dependencies = @('--missing')
    }).State) 'Dependencies must name declared available options'
    Assert-Equal 'InconsistentAsset' ([string] (Invoke-ManifestMutation {
        param($m) $option = @($m.options | Where-Object name -CEQ '--json')[0]
        $option.dependencies = @('--for', '--for')
    }).State) 'Duplicate dependencies are malformed metadata'
    Assert-Equal 'InconsistentAsset' ([string] (Invoke-ManifestMutation {
        param($m) $option = @($m.options | Where-Object kind -CEQ 'rejected')[0]
        $option.dependencies = @('--for')
    }).State) 'Rejected options cannot carry unenforceable dependencies'
    Assert-Equal 'InconsistentAsset' ([string] (Invoke-ManifestMutation {
        param($m) $m.options[0].repeatable = 0
    }).State) 'Numeric booleans are not coerced'
    Assert-Equal 'InconsistentAsset' ([string] (Invoke-ManifestMutation {
        param($m) $m.options[0].dependencies = 7
    }).State) 'Numeric dependency collections are rejected'
    Assert-Equal 'MissingField' ([string] (Invoke-ManifestMutation {
        param($m) $m.Remove('compatibility')
    }).State) 'Compatibility table is required'
    Assert-Equal 'UnknownField' ([string] (Invoke-ManifestMutation {
        param($m) $m.compatibility.extra = @()
    }).State) 'Compatibility table is closed'
    Assert-Equal 'InconsistentAsset' ([string] (Invoke-ManifestMutation {
        param($m) $m.compatibility.conditionalRequires = 1
    }).State) 'Conditional requirements must be an array'
    Assert-Equal 'UnknownField' ([string] (Invoke-ManifestMutation {
        param($m) $m.compatibility.conditionalRequires[0].extra = 'bad'
    }).State) 'Conditional requirement fields are closed'
    Assert-Equal 'InconsistentAsset' ([string] (Invoke-ManifestMutation {
        param($m) $m.compatibility.conditionalRequires[0].condition = 'present'
    }).State) 'Conditional requirement conditions are numeric and closed'
    Assert-Equal 'InconsistentAsset' ([string] (Invoke-ManifestMutation {
        param($m) $m.compatibility.conditionalRequires[0].requiresAny = @('--for', '--for')
    }).State) 'Conditional requirement alternatives are unique'
    Assert-Equal 'UnknownField' ([string] (Invoke-ManifestMutation {
        param($m) $m.compatibility.exclusions[0].extra = 'bad'
    }).State) 'Exclusion fields are closed'
    Assert-Equal 'InconsistentAsset' ([string] (Invoke-ManifestMutation {
        param($m) $m.compatibility.exclusions[0].excludedOption = '--missing'
    }).State) 'Exclusions name available options'
    Assert-Equal 'UnknownField' ([string] (Invoke-ManifestMutation {
        param($m) $m.compatibility.selectorRejections[0].extra = 'bad'
    }).State) 'Selector rejection fields are closed'
    Assert-Equal 'InconsistentAsset' ([string] (Invoke-ManifestMutation {
        param($m) $m.compatibility.selectorRejections[0].selectors = @('--json')
    }).State) 'Selector rejection targets are primary selectors'
    $duplicateManifestPath = Join-Path $testRoot 'duplicate-manifest.json'
    $duplicateManifest = [IO.File]::ReadAllText($manifestPath).Replace(
        '"schemaVersion": 1,', '"schemaVersion": 1, "schemaVersion": 1,')
    [IO.File]::WriteAllText($duplicateManifestPath, $duplicateManifest)
    $duplicateManifestResult = Read-RipwireReleaseManifest $duplicateManifestPath
    Assert-Equal 'MalformedJson' ([string] $duplicateManifestResult.State) 'Duplicate manifest property'
    Assert-Equal 'RIPWIRE_WSL_DUPLICATE_JSON_PROPERTY' $duplicateManifestResult.Code `
        'Duplicate manifest property has structured code'
    $nestedDuplicate = [IO.File]::ReadAllText($manifestPath).Replace(
        '"architecture": "x64",', '"architecture": "x64", "architecture": "x64",')
    [IO.File]::WriteAllText($duplicateManifestPath, $nestedDuplicate)
    Assert-Equal 'MalformedJson' ([string] (Read-RipwireReleaseManifest $duplicateManifestPath).State) `
        'Nested duplicate manifest property is rejected recursively'
    Add-Pass 'strict pinned release manifest and architecture mapping'

    $validConfig = [ordered] @{
        schemaVersion = 1
        distribution = 'Ubuntu'
        architecture = 'x64'
        releaseVersion = $manifest.releaseVersion
        releaseCommit = $manifest.releaseCommit
        archiveSha256 = $manifest.assets[0].sha256
        binaryPath = '/home/test/.local/share/brownch-devtools/ripwire-wsl/v0.5.0/bin/ripwire'
        cacheRoot = '/home/test/.cache/brownch-devtools/ripwire-wsl'
    }
    $configPath = Join-Path $testRoot 'config.json'
    $validConfig | ConvertTo-Json | Set-Content -LiteralPath $configPath -Encoding utf8
    Assert-Equal 'Valid' ([string] (Read-RipwireConfiguration $configPath $manifest).State) 'Valid configuration'
    $stale = Copy-JsonValue $validConfig
    $stale.releaseCommit = '0000000000000000000000000000000000000000'
    $stale | ConvertTo-Json | Set-Content -LiteralPath $configPath -Encoding utf8
    Assert-Equal 'ValidButStale' ([string] (Read-RipwireConfiguration $configPath $manifest).State) 'Stale configuration'
    $invalid = Copy-JsonValue $validConfig
    $invalid.extra = 'not allowed'
    $invalid | ConvertTo-Json | Set-Content -LiteralPath $configPath -Encoding utf8
    Assert-Equal 'Malformed' ([string] (Read-RipwireConfiguration $configPath $manifest).State) 'Unknown config field'
    $invalid = Copy-JsonValue $validConfig
    $invalid.schemaVersion = '1'
    $invalid | ConvertTo-Json | Set-Content -LiteralPath $configPath -Encoding utf8
    Assert-Equal 'UnsupportedVersion' ([string] (Read-RipwireConfiguration $configPath $manifest).State) `
        'String configuration schema version is not coerced'
    $invalid = Copy-JsonValue $validConfig
    $invalid.architecture = @('x64')
    $invalid | ConvertTo-Json | Set-Content -LiteralPath $configPath -Encoding utf8
    Assert-Equal 'Malformed' ([string] (Read-RipwireConfiguration $configPath $manifest).State) `
        'Array configuration scalar is rejected'
    $invalid = Copy-JsonValue $validConfig
    $invalid.binaryPath = $null
    $invalid | ConvertTo-Json | Set-Content -LiteralPath $configPath -Encoding utf8
    Assert-Equal 'Malformed' ([string] (Read-RipwireConfiguration $configPath $manifest).State) `
        'Null configuration scalar is rejected without throwing'
    $duplicateConfig = ($validConfig | ConvertTo-Json).Replace(
        '"schemaVersion": 1,', '"schemaVersion": 1, "schemaVersion": 1,')
    [IO.File]::WriteAllText($configPath, $duplicateConfig)
    $duplicateConfigResult = Read-RipwireConfiguration $configPath $manifest
    Assert-Equal 'Malformed' ([string] $duplicateConfigResult.State) 'Duplicate configuration property'
    Assert-Equal 'RIPWIRE_WSL_DUPLICATE_JSON_PROPERTY' $duplicateConfigResult.Code `
        'Duplicate configuration property has structured code'
    Assert-Equal 'Missing' ([string] (Read-RipwireConfiguration (Join-Path $testRoot 'missing.json') $manifest).State) 'Missing config'
    Add-Pass 'closed configuration states'

    $allowedValues = @{
        '--for' = 'thing'; '--pack-task' = 'task'; '--callers' = 'symbol'; '--callees' = 'symbol'
        '--uses' = 'symbol'; '--impact' = 'symbol'; '--pr-context' = 'main'
        '--from-trace' = 'C:\trace file.txt'; '--whereis' = 'symbol'; '--grep' = 'text'
        '--regex' = 'a.*b'; '--expand' = 'a,b'; '--outline' = 'a,b'
        '--top-k' = '1'; '--max-tokens' = '1'; '--detail' = '0'
    }
    $allowedCompanions = @{
        '--adaptive' = @('--for=thing')
        '--signatures-only' = @('--for=thing')
    }
    foreach ($option in $manifest.options) {
        if ($option.kind -eq 'rejected') {
            $classified = Classify-RipwireInvocation @($option.name) $manifest
            $expected = switch ($option.rejectionCategory) {
                mutation { 'RejectedMutation' }; mcp { 'RejectedMcp' }; output { 'RejectedOutput' }
            }
            Assert-Equal $expected ([string] $classified.State) "Rejected option $($option.name)"
            continue
        }
        $token = if ($option.valueGrammar -eq 'none') { $option.name } else {
            "$($option.name)=$($allowedValues[$option.name])"
        }
        $companions = if ($allowedCompanions.ContainsKey($option.name)) {
            $allowedCompanions[$option.name]
        } else { @() }
        $invocation = @($token) + @($companions)
        Assert-Equal 'AllowedAnalysis' ([string] (Classify-RipwireInvocation $invocation $manifest).State) `
            "Allowed option $token with required companions"
    }
    Assert-Equal 'AllowedDefaultMap' ([string] (Classify-RipwireInvocation @() $manifest).State) 'Default map'
    foreach ($case in @(
        @{ Args = @('C:\other'); State = 'RejectedAdditionalRoot' },
        @{ Args = @('--unknown'); State = 'RejectedUnknown' },
        @{ Args = @('--FOR=thing'); State = 'RejectedUnknown' },
        @{ Args = @('--JSON'); State = 'RejectedUnknown' },
        @{ Args = @('--for'); State = 'InvalidSyntax' },
        @{ Args = @('--for='); State = 'InvalidSyntax' },
        @{ Args = @('--situ=yes'); State = 'InvalidSyntax' },
        @{ Args = @('--max-tokens=0'); State = 'InvalidSyntax' },
        @{ Args = @('--max-tokens=1000000000'); State = 'AllowedAnalysis' },
        @{ Args = @('--max-tokens=1000000001'); State = 'InvalidSyntax' },
        @{ Args = @('--max-tokens=999999999999999999999999'); State = 'InvalidSyntax' },
        @{ Args = @('--top-k=1000000000'); State = 'AllowedAnalysis' },
        @{ Args = @('--top-k=1000000001'); State = 'InvalidSyntax' },
        @{ Args = @('--top-k=-1'); State = 'InvalidSyntax' },
        @{ Args = @('--detail=1000000000', '--for=thing'); State = 'AllowedAnalysis' },
        @{ Args = @('--detail=1000000001', '--for=thing'); State = 'InvalidSyntax' },
        @{ Args = @('--detail=1'); State = 'InvalidSyntax' },
        @{ Args = @('--detail=1', '--callers=symbol'); State = 'InvalidSyntax' },
        @{ Args = @('--detail=1', '--for=thing'); State = 'AllowedAnalysis' },
        @{ Args = @('--detail=1', '--for=thing', '--json'); State = 'InvalidSyntax' },
        @{ Args = @('--detail=0', '--for=thing', '--json'); State = 'AllowedAnalysis' },
        @{ Args = @('--signatures-only', '--for=thing', '--json'); State = 'AllowedAnalysis' },
        @{ Args = @('--detail=1', '--whereis=symbol'); State = 'AllowedAnalysis' },
        @{ Args = @('--adaptive'); State = 'InvalidSyntax' },
        @{ Args = @('--adaptive', '--for=thing'); State = 'AllowedAnalysis' },
        @{ Args = @('--signatures-only'); State = 'InvalidSyntax' },
        @{ Args = @('--signatures-only', '--for=thing'); State = 'AllowedAnalysis' },
        @{ Args = @('--signatures-only', '--detail=0', '--for=thing'); State = 'AllowedAnalysis' },
        @{ Args = @('--signatures-only', '--detail=1', '--for=thing'); State = 'InvalidSyntax' },
        @{ Args = @('--top-k=0'); State = 'InvalidSyntax' },
        @{ Args = @('--top-k=0', '--expand=symbol'); State = 'AllowedAnalysis' },
        @{ Args = @('--top-k=0', '--outline=symbol'); State = 'AllowedAnalysis' },
        @{ Args = @('--top-k=0', '--for=thing'); State = 'InvalidSyntax' },
        @{ Args = @('--top-k=1', '--pr-context=main'); State = 'AllowedAnalysis' },
        @{ Args = @('--max-tokens=1000', '--pr-context=main'); State = 'AllowedAnalysis' },
        @{
            Args = @('--for=base_value', '--top-k=1', '--max-tokens=1000', '--detail=1',
                '--adaptive', '--signatures-only', '--json')
            State = 'InvalidSyntax'
        },
        @{ Args = @('--for=a', '--for=b'); State = 'InvalidSyntax' },
        @{ Args = @('--for=a', '--callers=b'); State = 'InvalidSyntax' },
        @{ Args = @('--json', '--json'); State = 'InvalidSyntax' }
    )) {
        Assert-Equal $case.State ([string] (Classify-RipwireInvocation $case.Args $manifest).State) "Invocation $($case.Args -join ' ')"
    }
    foreach ($selector in $pagingSelectors) {
        $selectorValue = $allowedValues[$selector]
        $selectorToken = if ($null -eq $selectorValue) { $selector } else { "$selector=$selectorValue" }
        foreach ($modifier in @('--top-k=1', '--max-tokens=1000')) {
            $classified = Classify-RipwireInvocation @($selectorToken, $modifier) $manifest
            Assert-Equal 'InvalidSyntax' ([string] $classified.State) "Paging selector $selectorToken rejects $modifier"
            Assert-Equal 69 $classified.ExitCode "Paging selector rejection exits 69"
        }
        foreach ($option in $manifest.options | Where-Object kind -CEQ 'primary') {
            $token = if ($option.valueGrammar -ceq 'none') { $option.name } else {
                "$($option.name)=$($allowedValues[$option.name])"
            }
            $expected = if ($option.name -cin $nonJsonSelectors) { 'InvalidSyntax' } else { 'AllowedAnalysis' }
            Assert-Equal $expected ([string](Classify-RipwireInvocation @($token, '--json') $manifest).State) `
                "JSON capability for $($option.name)"
        }
    }
    $dependencyManifest = Copy-JsonValue $manifest
    $dependentOption = @($dependencyManifest.options | Where-Object name -CEQ '--json')[0]
    $dependentOption.dependencies = @('--for')
    Assert-Equal 'InvalidSyntax' ([string] (Classify-RipwireInvocation @('--json') $dependencyManifest).State) `
        'Missing declared dependency is rejected'
    Assert-Equal 'AllowedAnalysis' ([string] (Classify-RipwireInvocation @('--json', '--for=thing') $dependencyManifest).State) `
        'Declared dependency is evaluated independently of argument order'
    Add-Pass 'closed invocation grammar and rejection classes'

    $parent = @{
        WSLENV = 'KEEP/u:PATHS/lp'
        KEEP = 'unchanged'
        PATHS = 'a;b'
        GIT_CONFIG_COUNT = '2'
        GIT_CONFIG_KEY_0 = 'probe.note'
        GIT_CONFIG_VALUE_0 = "unicode-$([char] 0x00e9)"
        GIT_CONFIG_KEY_1 = 'core.fsmonitor'
        GIT_CONFIG_VALUE_1 = 'true'
        TMPDIR = 'parent-tmp'
        XDG_CACHE_HOME = 'parent-xdg'
    }
    $before = $parent | ConvertTo-Json -Compress
    $child = New-RipwireChildEnvironment $parent @{
        GIT_DIR = '/git/worktrees/a'
        GIT_WORK_TREE = '/mnt/c/work'
        GIT_COMMON_DIR = '/git'
        RIPWIRE_BIN = '/home/test/bin/ripwire'
        RIPWIRE_WSL_DIAGNOSTIC = '0'
        GIT_OPTIONAL_LOCKS = '0'
        TMPDIR = '/home/test/cache/releases/v/x64/key/tmp'
        XDG_CACHE_HOME = '/home/test/cache/releases/v/x64/key/xdg'
    }
    Assert-Equal $before ($parent | ConvertTo-Json -Compress) 'Parent environment byte-equivalent JSON'
    Assert-Equal 'parent-tmp' $parent.TMPDIR 'Parent TMPDIR preserved'
    Assert-Equal '/home/test/cache/releases/v/x64/key/tmp' $child.TMPDIR 'Child TMPDIR'
    Assert-True $child.WSLENV.StartsWith('KEEP/u:PATHS/lp:') 'Existing WSLENV order and flags preserved'
    Assert-True (($child.WSLENV -split ':') -ccontains 'GIT_CONFIG_COUNT/u') `
        'Validated Git configuration count is always transported'
    Assert-Equal "unicode-$([char] 0x00e9)" $child.GIT_CONFIG_VALUE_0 'Unicode inherited override'
    foreach ($bad in @(
        @{ WSLENV = 'X/u:X/u' },
        @{ WSLENV = 'X/uu' },
        @{ WSLENV = 'X/uw' },
        @{ WSLENV = 'GIT_DIR/p' },
        @{ WSLENV = 'GIT_CONFIG_COUNT/p' },
        @{ WSLENV = 'X/u:' },
        @{ GIT_CONFIG_COUNT = 'x' },
        @{ GIT_CONFIG_COUNT = '-1' },
        @{ GIT_CONFIG_COUNT = '999999999999999999999999999999999999' },
        @{ GIT_CONFIG_COUNT = '1'; GIT_CONFIG_KEY_0 = 'x' },
        @{ GIT_CONFIG_COUNT = '1'; GIT_CONFIG_KEY_0 = 'x'; GIT_CONFIG_VALUE_0 = 'y'; GIT_CONFIG_KEY_1 = 'extra'; GIT_CONFIG_VALUE_1 = 'extra' },
        @{ GIT_CONFIG_COUNT = '2'; GIT_CONFIG_KEY_0 = 'x'; GIT_CONFIG_VALUE_0 = 'y'; GIT_CONFIG_KEY_2 = 'hole'; GIT_CONFIG_VALUE_2 = 'hole' },
        @{ GIT_CONFIG_COUNT = '1'; GIT_CONFIG_KEY_0 = ''; GIT_CONFIG_VALUE_0 = 'y' },
        [ordered] @{ GIT_CONFIG_COUNT = '1'; git_config_key_0 = 'x'; GIT_CONFIG_VALUE_0 = 'y' },
        [ordered] @{ git_config_count = '0' }
    )) {
        $failed = $false
        try { $null = New-RipwireChildEnvironment $bad @{ GIT_DIR = '/git' } } catch { $failed = $true }
        Assert-True $failed "Reject malformed inherited environment: $($bad | ConvertTo-Json -Compress)"
    }
    try {
        $null = New-RipwireChildEnvironment @{
            GIT_CONFIG_COUNT = '999999999999999999999999999999999999'
        } @{ GIT_DIR = '/git' }
        throw 'ASSERTION_FAILED: overflowing Git count was accepted'
    } catch {
        Assert-Equal 'RIPWIRE_WSL_INVALID_GIT_CONFIG_COUNT' $_.Exception.Message `
            'Overflowing count has a stable pre-process error'
    }
    try {
        $null = New-RipwireChildEnvironment ([ordered] @{
            GIT_CONFIG_COUNT = '1'; git_config_key_0 = 'x'; GIT_CONFIG_VALUE_0 = 'y'
        }) @{ GIT_DIR = '/git' }
        throw 'ASSERTION_FAILED: noncanonical Git key was accepted'
    } catch {
        Assert-Equal 'RIPWIRE_WSL_NONCANONICAL_GIT_CONFIG_ENTRY: git_config_key_0' $_.Exception.Message `
            'Case aliases have a stable pre-process error'
    }
    $empty = New-RipwireChildEnvironment @{} @{ GIT_DIR = '/git' }
    Assert-Equal '0' $empty.GIT_CONFIG_COUNT 'Absent Git override becomes explicit empty block'
    Assert-True (($empty.WSLENV -split ':') -ccontains 'GIT_CONFIG_COUNT/u') `
        'Explicit empty Git override count is transported'
    $pretransportedCount = New-RipwireChildEnvironment @{
        WSLENV = 'GIT_CONFIG_COUNT/u'; GIT_CONFIG_COUNT = '0'
    } @{ GIT_DIR = '/git' }
    Assert-Equal 1 @($pretransportedCount.WSLENV -split ':' |
        Where-Object { $_ -ceq 'GIT_CONFIG_COUNT/u' }).Count 'Valid count transport is not duplicated'
    Add-Pass 'child-only WSLENV and indexed Git override validation'

    $cacheA = New-RipwireCacheContext '/home/u/cache' 'v0.5.0' x64 '/mnt/c/a' '/mnt/c/repo/.git/worktrees/a' '/mnt/c/repo/.git' '/home/u/install/ripwire'
    $cacheB = New-RipwireCacheContext '/home/u/cache' 'v0.5.0' x64 '/mnt/c/b' '/mnt/c/repo/.git/worktrees/b' '/mnt/c/repo/.git' '/home/u/install/ripwire'
    $cacheHeadSame = New-RipwireCacheContext '/home/u/cache' 'v0.5.0' x64 '/mnt/c/a' '/mnt/c/repo/.git/worktrees/a' '/mnt/c/repo/.git' '/home/u/install/ripwire'
    $cacheVersion = New-RipwireCacheContext '/home/u/cache' 'v0.6.0' x64 '/mnt/c/a' '/mnt/c/repo/.git/worktrees/a' '/mnt/c/repo/.git' '/home/u/install/ripwire'
    $cacheArch = New-RipwireCacheContext '/home/u/cache' 'v0.5.0' arm64 '/mnt/c/a' '/mnt/c/repo/.git/worktrees/a' '/mnt/c/repo/.git' '/home/u/install/ripwire'
    Assert-Equal 'Valid' ([string] $cacheA.State) 'Valid cache context'
    Assert-True ($cacheA.Namespace -cne $cacheB.Namespace) 'Linked worktrees separated'
    Assert-Equal $cacheA.Namespace $cacheHeadSame.Namespace 'HEAD is excluded from identity'
    Assert-True ($cacheA.Namespace -cne $cacheVersion.Namespace) 'Release separates namespace'
    Assert-True ($cacheA.Namespace -cne $cacheArch.Namespace) 'Architecture separates namespace'
    Assert-True (-not $cacheA.LockPath.StartsWith("$($cacheA.Namespace)/", [StringComparison]::Ordinal)) `
        'Stable lock inode is outside the deletable namespace'
    Assert-True ($cacheA.LockPath.EndsWith("$($cacheA.NamespaceKey).lock", [StringComparison]::Ordinal)) `
        'Lock identity matches the namespace key'
    Assert-Equal 'WindowsBacked' ([string] (New-RipwireCacheContext '/mnt/c/cache' 'v0.5.0' x64 '/mnt/c/a' '/mnt/c/a/.git' '/mnt/c/a/.git' '/home/u/bin/ripwire').State) 'Windows cache rejected'
    Assert-Equal 'Overlap' ([string] (New-RipwireCacheContext '/home/u/install/cache' 'v0.5.0' x64 '/mnt/c/a' '/mnt/c/a/.git' '/mnt/c/a/.git' '/home/u/install/ripwire').State) 'Install overlap rejected'
    Add-Pass 'stable isolated managed-cache identity and path policy'

    $worktree = Resolve-RipwireWindowsWorktree $root
    Assert-Equal 'Valid' ([string] $worktree.State) 'Current exact worktree resolves through Windows Git'
    Assert-Equal ([IO.Path]::TrimEndingDirectorySeparator([IO.Path]::GetFullPath($root))) `
        $worktree.WindowsRoot 'Canonical root'
    Assert-True ([IO.Path]::IsPathFullyQualified($worktree.WindowsGitDirectory)) 'Canonical Git directory'
    Assert-True ([IO.Path]::IsPathFullyQualified($worktree.WindowsCommonDirectory)) 'Canonical common directory'
    $nestedPath = Join-Path $root 'Tests'
    Assert-Equal 'MismatchedRoot' ([string] (Resolve-RipwireWindowsWorktree $nestedPath).State) `
        'A subdirectory cannot silently stand in for the exact worktree root'
    $lowerDrive = $root.Substring(0, 1).ToLowerInvariant() + $root.Substring(1)
    Assert-Equal 'Valid' ([string] (Resolve-RipwireWindowsWorktree $lowerDrive).State) `
        'Drive-letter casing does not change exact worktree identity'
    $translationFailure = ConvertTo-RipwireLinuxPath 'C:\path' 'No-Such-Distro' (Join-Path $testRoot 'missing-wsl.exe')
    Assert-Equal 'Failed' ([string] $translationFailure.State) 'Translation failure remains structured'
    $bootstrapWindows = Join-Path $package 'scripts\invoke-ripwire-wsl.sh'
    $poisonedEnvironment = Get-RipwireCurrentEnvironment
    foreach ($name in @($poisonedEnvironment.Keys)) {
        if ($name -cmatch '^GIT_CONFIG_(?:COUNT|PARAMETERS|KEY_[0-9]+|VALUE_[0-9]+)$') {
            $poisonedEnvironment.Remove($name)
        }
    }
    $poisonedEnvironment.GIT_DIR = 'C:\definitely-not-the-requested-repository'
    $poisonedEnvironment.GIT_WORK_TREE = 'C:\definitely-not-the-requested-worktree'
    $poisonedEnvironment.GIT_COMMON_DIR = 'C:\definitely-not-the-requested-common-directory'
    $poisonedEnvironment.GIT_CONFIG_COUNT = '1'
    $poisonedEnvironment.GIT_CONFIG_KEY_0 = 'core.worktree'
    $poisonedEnvironment.GIT_CONFIG_VALUE_0 = 'C:\also-not-the-requested-worktree'
    $poisonedEnvironment.RIPWIRE_WSL_OPERATION = 'clear'
    Assert-Equal 'Valid' ([string] (Resolve-RipwireWindowsWorktree $root git $poisonedEnvironment).State) `
        'Inherited Git identity and process-local config cannot redirect discovery'
    $context = New-RipwireWorktreeLaunchContext $root @('--from-trace=C:\trace file.txt', '--max-tokens=1000') `
        $validConfig $manifest $bootstrapWindows $poisonedEnvironment -PathTranslator {
            param($path)
            if ($path -ceq 'C:\trace file.txt') { return '/mnt/c/trace file.txt' }
            return '/mnt/c/' + ([IO.Path]::GetFileName($path) -replace ' ', '-')
        }
    Assert-Equal 'Valid' ([string] $context.State) 'Complete launch context'
    Assert-Equal '/bin/bash' $context.WslArguments[5] 'WSL uses explicit Bash'
    Assert-Equal '--' $context.WslArguments[6] 'WSL executable separator'
    Assert-Equal '--from-trace=/mnt/c/trace file.txt' $context.WslArguments[-2] 'Only trace path is translated'
    Assert-Equal '--max-tokens=1000' $context.WslArguments[-1] 'Non-path option remains unchanged'
    Assert-Equal '0' $context.ChildEnvironment.GIT_OPTIONAL_LOCKS 'Child-only optional locks'
    Assert-Equal '0' $context.ChildEnvironment.RIPWIRE_WSL_DIAGNOSTIC 'Analysis context mode'
    Assert-Equal 'analysis' $context.Operation 'Default operation is analysis'
    Assert-Equal 'analysis' $context.ChildEnvironment.RIPWIRE_WSL_OPERATION `
        'Inherited operation cannot select clear'
    Assert-True ($context.ChildEnvironment.GIT_DIR -cne $poisonedEnvironment.GIT_DIR) `
        'Translated exact worktree Git directory replaces inherited identity in the child only'
    $diagnosticContext = New-RipwireWorktreeLaunchContext $root @() $validConfig $manifest `
        $bootstrapWindows $poisonedEnvironment -Diagnostic -PathTranslator {
            param($path) '/mnt/c/' + ([IO.Path]::GetFileName($path) -replace ' ', '-')
        }
    Assert-Equal 'diagnostic' $diagnosticContext.Operation '-Diagnostic maps to diagnostic operation'
    Assert-Equal 'diagnostic' $diagnosticContext.ChildEnvironment.RIPWIRE_WSL_OPERATION `
        'Diagnostic operation is explicit in child'
    Assert-Equal '1' $diagnosticContext.ChildEnvironment.RIPWIRE_WSL_DIAGNOSTIC `
        'Diagnostic compatibility variable follows resolved operation'
    $clearContext = New-RipwireWorktreeLaunchContext $root @() $validConfig $manifest `
        $bootstrapWindows $poisonedEnvironment -Operation clear -PathTranslator {
            param($path) '/mnt/c/' + ([IO.Path]::GetFileName($path) -replace ' ', '-')
        }
    Assert-Equal 'clear' $clearContext.Operation 'Clear operation is explicit'
    Assert-Equal 'clear' $clearContext.ChildEnvironment.RIPWIRE_WSL_OPERATION 'Clear reaches child explicitly'
    Assert-Equal '0' $clearContext.ChildEnvironment.RIPWIRE_WSL_DIAGNOSTIC `
        'Clear is not mislabeled as diagnostic'
    Add-Pass 'canonical worktree discovery and complete WSL launch context'

    $runtime = (Get-Process -Id $PID).Path
    $raw = Invoke-RipwireNativeCommand $runtime @(
        '-NoProfile', '-Command',
        '[Console]::OpenStandardOutput().Write([byte[]](0,255,13,10)); [Console]::OpenStandardError().Write([byte[]](254,1)); exit 23')
    Assert-Equal 'NonZero' ([string] $raw.State) 'Non-zero command result variant'
    Assert-Equal 23 $raw.ExitCode 'Exact exit code'
    Assert-Equal 'AP8NCg==' ([Convert]::ToBase64String($raw.Stdout)) 'Raw stdout'
    Assert-Equal '/gE=' ([Convert]::ToBase64String($raw.Stderr)) 'Raw stderr'
    $large = Invoke-RipwireNativeCommand $runtime @(
        '-NoProfile', '-Command',
        '$o=[Console]::OpenStandardOutput();$e=[Console]::OpenStandardError();$b=[byte[]]::new(262144);$o.Write($b);$e.Write($b)')
    Assert-Equal 'Success' ([string] $large.State) 'Concurrent large-stream result'
    Assert-Equal 262144 $large.Stdout.Length 'Large stdout drained'
    Assert-Equal 262144 $large.Stderr.Length 'Large stderr drained'
    $timeout = Invoke-RipwireNativeCommand $runtime @('-NoProfile', '-Command', 'Start-Sleep 5') -TimeoutSeconds 1
    Assert-Equal 'TimedOut' ([string] $timeout.State) 'Timeout result variant'
    Assert-Equal 'RIPWIRE_WSL_COMMAND_TIMED_OUT' $timeout.Code 'Timeout has stable structured code'
    Assert-Equal @() @($timeout.CleanupErrors) 'Successful timeout cleanup has no hidden errors'
    $missing = Invoke-RipwireNativeCommand (Join-Path $testRoot 'missing.exe')
    Assert-Equal 'Unavailable' ([string] $missing.State) 'Unavailable result variant'
    Add-Pass 'raw concurrent native process results'

    $bootstrap = Join-Path $package 'scripts\invoke-ripwire-wsl.sh'
    Assert-True (-not ([IO.File]::ReadAllBytes($bootstrap) -contains [byte] 13)) 'Bootstrap is LF-only'
    $commonText = [IO.File]::ReadAllText($common)
    Assert-True ($commonText -match "'--exec', 'wslpath'") 'Path translation explicitly invokes wslpath'
    $bootstrapText = [IO.File]::ReadAllText($bootstrap)
    Assert-True ($bootstrapText -match 'exec "\$RIPWIRE_BIN" "\$root" "\$@"') 'Bootstrap execs binary with sole root'
    Assert-True ($bootstrapText -match 'RIPWIRE_WSL_DIAGNOSTIC == 1') 'Diagnostic branch is explicit'
    Assert-True ($bootstrapText -match 'flock -x -w') 'Bounded same-namespace lock'
    $diagnosticOffset = $bootstrapText.IndexOf('if [[ $RIPWIRE_WSL_DIAGNOSTIC == 1 ]]')
    Assert-True ($diagnosticOffset -ge 0 -and
        $diagnosticOffset -lt $bootstrapText.IndexOf('mkdir -p --') -and
        $diagnosticOffset -lt $bootstrapText.IndexOf('exec 9>')) `
        'Diagnostic exits before cache directories or lock files can be created'
    Assert-True ($bootstrapText -match 'lock_path="\$cache_root/locks/\$namespace_identity\.lock"') `
        'Bootstrap lock inode is stable outside the deletable namespace'
    Assert-True ($bootstrapText -notmatch '(?i)\bpython(?:3)?\b' -and
        $commonText -notmatch '(?i)\bpython(?:3)?\b') 'Production helpers do not require Python'
    Add-Pass 'bootstrap LF, diagnostic, execution, and lock contracts'
} finally {
    if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force }
}

Write-Output "Passed $($passed.Count) Ripwire WSL Phase 1 unit groups:"
$passed | ForEach-Object { Write-Output " - $_" }
