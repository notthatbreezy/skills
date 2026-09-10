[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Console]::Error.WriteLine('RIPWIRE_WSL_UNSUPPORTED_RUNTIME')
    exit 78
}

$repo = Split-Path -Parent $PSScriptRoot
$assets = Join-Path $PSScriptRoot 'fixtures\ripwire-wsl'
$launcher = Join-Path $repo 'plugins\devtools\skills\ripwire-wsl\scripts\Invoke-RipwireWsl.ps1'
$invokeFixture = Join-Path $assets 'launcher-invoke.ps1'
. (Join-Path $assets 'ProbeProcess.ps1')

$passed = [Collections.Generic.List[string]]::new()
function Assert-True([bool] $Condition, [string] $Label) {
    if (-not $Condition) { throw "ASSERTION_FAILED: $Label" }
}
function Assert-Equal($Expected, $Actual, [string] $Label) {
    $left = $Expected | ConvertTo-Json -Depth 20 -Compress
    $right = $Actual | ConvertTo-Json -Depth 20 -Compress
    Assert-True ($left -ceq $right) "$Label`nExpected: $left`nActual:   $right"
}
function Add-Pass([string] $Label) { $passed.Add($Label) }
function To-LinuxFixturePath([string] $Path) {
    $bytes = [Text.Encoding]::UTF8.GetBytes($Path)
    return '/translated/' + [Convert]::ToHexString($bytes).ToLowerInvariant()
}
function Read-StartCount([string] $Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return 0 }
    return @([IO.File]::ReadAllLines($Path)).Count
}
function Get-EnvironmentSnapshot {
    $lines = [Collections.Generic.List[string]]::new()
    foreach ($entry in [Environment]::GetEnvironmentVariables().GetEnumerator() |
        Sort-Object { [string] $_.Key }) {
        $name = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes([string] $entry.Key))
        $value = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes([string] $entry.Value))
        $lines.Add("$name=$value")
    }
    return [Text.Encoding]::UTF8.GetBytes($lines -join "`n")
}
function Invoke-Git([string[]] $Arguments, [hashtable] $Environment) {
    $result = Invoke-ProbeProcess 'git.exe' $Arguments $Environment
    if ($result.ExitCode -ne 0) { throw "Git failed: $($result.ErrorText())" }
    return $result.OutputText().Trim()
}
function Invoke-Launcher([string] $Root, [string] $Config, [string[]] $Arguments, [hashtable] $Environment) {
    $json = ConvertTo-Json -InputObject ([object[]] $Arguments) -Compress
    Invoke-ProbeProcess 'pwsh.exe' @(
        '-NoProfile', '-File', $invokeFixture, '-Launcher', $launcher,
        '-WorktreePath', $Root, '-ConfigPath', $Config, '-ArgumentsJson', $json
    ) $Environment
}

$testRoot = Join-Path $repo ("launcher-tests-{0}" -f [Guid]::NewGuid().ToString('N'))
$shimRoot = Join-Path $testRoot 'shim'
$main = Join-Path $testRoot 'main repository'
$linked = Join-Path $testRoot 'linked worktree Ω'
$configPath = Join-Path $testRoot 'launcher-config.json'
$recordPath = Join-Path $testRoot 'launcher-record.json'
$endpointRecordPath = Join-Path $testRoot 'launcher-endpoint-record.json'
$countPath = Join-Path $testRoot 'launcher-count.txt'
$null = New-Item -ItemType Directory -Path $shimRoot

try {
    $compiler = "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
    Assert-True (Test-Path -LiteralPath $compiler) 'Windows Framework C# compiler is available'
    $compile = Invoke-ProbeProcess $compiler @(
        '/nologo', '/target:exe', "/out:$(Join-Path $shimRoot 'wsl.exe')",
        '/reference:System.Web.Extensions.dll', (Join-Path $assets 'launcher-wsl-shim.cs')
    )
    Assert-Equal 0 $compile.ExitCode "Launcher WSL shim compiles: $($compile.ErrorText())"
    Copy-Item -LiteralPath (Join-Path $shimRoot 'wsl.exe') `
        -Destination (Join-Path $shimRoot 'fake-bootstrap.exe')
    Copy-Item -LiteralPath (Join-Path $shimRoot 'wsl.exe') `
        -Destination (Join-Path $shimRoot 'fake-ripwire.exe')

    $gitEnvironment = @{
        GIT_CONFIG_NOSYSTEM = '1'; GIT_CONFIG_GLOBAL = (Join-Path $testRoot 'empty-global.gitconfig')
        GIT_OPTIONAL_LOCKS = '0'; GIT_DIR = $null; GIT_WORK_TREE = $null
        GIT_COMMON_DIR = $null; GIT_CONFIG = $null; GIT_CONFIG_COUNT = $null
    }
    [IO.File]::WriteAllText($gitEnvironment.GIT_CONFIG_GLOBAL, '')
    $null = Invoke-Git @('init', '-b', 'main', $main) $gitEnvironment
    $null = Invoke-Git @('-C', $main, 'config', 'user.name', 'Launcher Fixture') $gitEnvironment
    $null = Invoke-Git @('-C', $main, 'config', 'user.email', 'launcher@example.invalid') $gitEnvironment
    [IO.File]::WriteAllText((Join-Path $main 'fixture.txt'), "fixture`n")
    $null = Invoke-Git @('-C', $main, 'add', 'fixture.txt') $gitEnvironment
    $null = Invoke-Git @('-C', $main, 'commit', '-m', 'fixture') $gitEnvironment
    $null = Invoke-Git @('-C', $main, 'worktree', 'add', '-b', 'linked', $linked) $gitEnvironment

    $manifest = Get-Content (Join-Path $repo 'plugins\devtools\skills\ripwire-wsl\references\release.json') -Raw |
        ConvertFrom-Json
    $asset = $manifest.assets | Where-Object architecture -CEQ 'x64'
    [ordered]@{
        schemaVersion = 1; distribution = 'Launcher Fixture Distribution'; architecture = 'x64'
        releaseVersion = $manifest.releaseVersion; releaseCommit = $manifest.releaseCommit
        archiveSha256 = $asset.sha256; binaryPath = '/opt/ripwire fixture/bin/ripwire'
        cacheRoot = '/home/fixture/.cache/ripwire launcher'
    } | ConvertTo-Json | Set-Content -LiteralPath $configPath -Encoding utf8

    $baseEnvironment = @{
        PATH = "$shimRoot;$env:PATH"; WSLENV = ''; GIT_CONFIG_COUNT = '1'
        GIT_CONFIG_KEY_0 = 'fixture.launcher'; GIT_CONFIG_VALUE_0 = 'quoted Ω value\'
        LAUNCHER_PARENT_SENTINEL = 'parent value Ω'; LAUNCHER_SHIM_COUNT = $countPath
        LAUNCHER_SHIM_RECORD = $recordPath; LAUNCHER_SHIM_STDOUT_BASE64 = ''
        LAUNCHER_SHIM_STDERR_BASE64 = ''; LAUNCHER_SHIM_EXIT = '0'
        LAUNCHER_SHIM_CONCURRENT = '0'; LAUNCHER_SHIM_WSLPATH_MODE = ''
        LAUNCHER_CHAIN_ENABLED = '1'; LAUNCHER_CHAIN_BIN_ROOT = $shimRoot
        LAUNCHER_CHAIN_ENDPOINT_RECORD = $endpointRecordPath
    }
    foreach ($entry in [Environment]::GetEnvironmentVariables().GetEnumerator()) {
        if ([string] $entry.Key -match '^GIT_CONFIG_(?:KEY|VALUE)_[0-9]+$') {
            $baseEnvironment[[string] $entry.Key] = $null
        }
    }
    $baseEnvironment.GIT_CONFIG_KEY_0 = 'fixture.launcher'
    $baseEnvironment.GIT_CONFIG_VALUE_0 = 'quoted Ω value\'

    $missingConfig = Join-Path $testRoot 'missing-config.json'
    $rejections = [ordered]@{
        additionalRoot = @{ Arguments = @('another root'); Exit = 64; Code = 'RIPWIRE_WSL_REJECTED_ROOT' }
        emptyLiteralRoot = @{ Arguments = @(''); Exit = 64; Code = 'RIPWIRE_WSL_REJECTED_ROOT' }
        unknown = @{ Arguments = @('--future-mode'); Exit = 68; Code = 'RIPWIRE_WSL_REJECTED_UNKNOWN' }
        invalidSyntax = @{ Arguments = @('--for='); Exit = 69; Code = 'RIPWIRE_WSL_INVALID_ARGUMENT' }
        contradictoryBodies = @{ Arguments = @('--for=fixture', '--detail=1', '--signatures-only'); Exit = 69; Code = 'RIPWIRE_WSL_INVALID_ARGUMENT' }
        contradictoryJson = @{ Arguments = @('--for=fixture', '--detail=1', '--json'); Exit = 69; Code = 'RIPWIRE_WSL_INVALID_ARGUMENT' }
        unsupportedJson = @{ Arguments = @('--situ', '--json'); Exit = 69; Code = 'RIPWIRE_WSL_INVALID_ARGUMENT' }
        missingAdaptiveSelector = @{ Arguments = @('--adaptive'); Exit = 69; Code = 'RIPWIRE_WSL_INVALID_ARGUMENT' }
        missingSignatureSelector = @{ Arguments = @('--signatures-only'); Exit = 69; Code = 'RIPWIRE_WSL_INVALID_ARGUMENT' }
        missingDetailSelector = @{ Arguments = @('--detail=1'); Exit = 69; Code = 'RIPWIRE_WSL_INVALID_ARGUMENT' }
        missingPayload = @{ Arguments = @('--top-k=0'); Exit = 69; Code = 'RIPWIRE_WSL_INVALID_ARGUMENT' }
    }
    foreach ($case in $rejections.GetEnumerator()) {
        Remove-Item $countPath -Force -ErrorAction SilentlyContinue
        $result = Invoke-Launcher $linked $missingConfig $case.Value.Arguments $baseEnvironment
        Assert-Equal $case.Value.Exit $result.ExitCode "$($case.Key) has the exact classification exit code"
        Assert-Equal 0 (Read-StartCount $countPath) "$($case.Key) rejects before any WSL process"
        Assert-True ($result.ErrorText().StartsWith("$($case.Value.Code):",
            [StringComparison]::Ordinal)) "$($case.Key) emits the exact stable stderr diagnostic"
    }
    foreach ($option in $manifest.options | Where-Object kind -CEQ 'rejected') {
        Remove-Item $countPath -Force -ErrorAction SilentlyContinue
        $category = switch ($option.rejectionCategory) {
            mutation { @{ Exit = 65; Code = 'RIPWIRE_WSL_REJECTED_MUTATION' } }
            mcp { @{ Exit = 66; Code = 'RIPWIRE_WSL_REJECTED_MCP' } }
            output { @{ Exit = 67; Code = 'RIPWIRE_WSL_REJECTED_OUTPUT' } }
        }
        $result = Invoke-Launcher $linked $missingConfig @("$($option.name)=fixture") $baseEnvironment
        Assert-Equal $category.Exit $result.ExitCode "$($option.name) exact rejection exit"
        Assert-True ($result.ErrorText().StartsWith("$($category.Code):",
            [StringComparison]::Ordinal)) "$($option.name) exact rejection code"
        Assert-Equal 0 (Read-StartCount $countPath) "$($option.name) rejects before any WSL process"
    }
    Add-Pass 'all pinned denied options and closed rejection classes fail with exact codes before WSL'

    Remove-Item $countPath -Force -ErrorAction SilentlyContinue
    $nested = Join-Path $linked 'nested'
    $null = New-Item -ItemType Directory -Path $nested
    $mismatch = Invoke-Launcher $nested $configPath @() $baseEnvironment
    Assert-Equal 78 $mismatch.ExitCode 'Nested path is not accepted as the repository root'
    Assert-Equal 0 (Read-StartCount $countPath) 'Mismatched root does not fall back or start WSL'
    $absent = Invoke-Launcher (Join-Path $testRoot 'absent') $configPath @() $baseEnvironment
    Assert-Equal 78 $absent.ExitCode 'Missing worktree fails'
    Assert-Equal 0 (Read-StartCount $countPath) 'Missing worktree does not start WSL'
    $deleted = Join-Path $testRoot 'deleted linked worktree'
    $null = Invoke-Git @('-C', $main, 'worktree', 'add', '-b', 'deleted-linked', $deleted) $gitEnvironment
    Remove-Item -LiteralPath $deleted -Recurse -Force
    $deletedResult = Invoke-Launcher $deleted $configPath @() $baseEnvironment
    Assert-Equal 78 $deletedResult.ExitCode 'Deleted linked worktree fails'
    Assert-Equal 0 (Read-StartCount $countPath) 'Deleted linked worktree does not start WSL'
    Add-Pass 'exact worktree root is required with no fallback'

    foreach ($mode in @('fail', 'invalid')) {
        Remove-Item $countPath,$recordPath,$endpointRecordPath -Force -ErrorAction SilentlyContinue
        $environment = $baseEnvironment.Clone()
        $environment.LAUNCHER_SHIM_WSLPATH_MODE = $mode
        $translation = Invoke-Launcher $linked $configPath @('--situ') $environment
        Assert-Equal 78 $translation.ExitCode "Configured wslpath $mode fails preflight"
        Assert-Equal 1 (Read-StartCount $countPath) "Configured wslpath $mode stops at first translation"
        Assert-True (-not (Test-Path -LiteralPath $recordPath)) `
            "Configured wslpath $mode never reaches the bootstrap launch"
        Assert-True (-not (Test-Path -LiteralPath $endpointRecordPath)) `
            "Configured wslpath $mode never reaches the Ripwire endpoint"
        $expectedCode = if ($mode -eq 'fail') {
            'RIPWIRE_WSL_PATH_TRANSLATION_FAILED'
        } else {
            'RIPWIRE_WSL_INVALID_LINUX_PATH'
        }
        Assert-True ($translation.ErrorText().Contains($expectedCode, [StringComparison]::Ordinal)) `
            "Configured wslpath $mode reports $expectedCode"
    }
    Add-Pass 'wslpath failure and invalid output stop before bootstrap'

    Remove-Item $countPath,$recordPath,$endpointRecordPath -Force -ErrorAction SilentlyContinue
    $malformedEnvironment = $baseEnvironment.Clone()
    $malformedEnvironment.GIT_CONFIG_COUNT = '2'
    $malformed = Invoke-Launcher $linked $configPath @('--situ') $malformedEnvironment
    Assert-Equal 78 $malformed.ExitCode 'Malformed inherited Git block fails preflight'
    Assert-Equal 0 (Read-StartCount $countPath) 'Malformed inherited Git block starts no WSL process'
    Assert-True (-not (Test-Path -LiteralPath $recordPath)) `
        'Malformed inherited Git block creates no native launch record'
    Assert-True (-not (Test-Path -LiteralPath $endpointRecordPath)) `
        'Malformed inherited Git block creates no endpoint record'
    Assert-True ($malformed.ErrorText().Contains('RIPWIRE_WSL_INVALID_ENVIRONMENT',
        [StringComparison]::Ordinal)) 'Malformed inherited Git block reports exact environment code'
    Add-Pass 'malformed inherited Git overrides fail before WSL'

    Remove-Item $countPath,$recordPath,$endpointRecordPath -Force -ErrorAction SilentlyContinue
    $exactArguments = @('--for=space "quote" Ω trailing\ and=equals')
    $result = Invoke-Launcher ($linked + [IO.Path]::DirectorySeparatorChar) $configPath `
        $exactArguments $baseEnvironment
    Assert-Equal 0 $result.ExitCode "Valid launcher invocation exits successfully: $($result.ErrorText())"
    Assert-Equal 5 (Read-StartCount $countPath) 'Four path translations and one launch occur'
    $record = Get-Content -LiteralPath $recordPath -Raw | ConvertFrom-Json
    $root = (Get-Item -LiteralPath $linked).FullName.TrimEnd('\')
    $gitDirectory = Invoke-Git @('-C', $root, 'rev-parse', '--absolute-git-dir') $gitEnvironment
    $commonDirectory = Invoke-Git @('-C', $root, 'rev-parse', '--git-common-dir') $gitEnvironment
    if (-not [IO.Path]::IsPathFullyQualified($commonDirectory)) {
        $commonDirectory = [IO.Path]::GetFullPath((Join-Path $root $commonDirectory))
    }
    $gitDirectory = (Get-Item -LiteralPath $gitDirectory -Force).FullName
    $commonDirectory = (Get-Item -LiteralPath $commonDirectory -Force).FullName
    $linuxRoot = To-LinuxFixturePath $root
    $linuxGit = To-LinuxFixturePath ([IO.Path]::TrimEndingDirectorySeparator($gitDirectory))
    $linuxCommon = To-LinuxFixturePath ([IO.Path]::TrimEndingDirectorySeparator($commonDirectory))
    $linuxBootstrap = To-LinuxFixturePath (
        Join-Path $repo 'plugins\devtools\skills\ripwire-wsl\scripts\invoke-ripwire-wsl.sh')
    Assert-Equal (@(
        '--distribution', 'Launcher Fixture Distribution', '--cd', $linuxRoot, '--exec',
        '/bin/bash', '--', $linuxBootstrap, '--', $linuxRoot
    ) + $exactArguments) @($record.Arguments) 'Native WSL argv preserves exact boundaries'
    Assert-Equal $linuxRoot $record.Environment.GIT_WORK_TREE 'Child root metadata is exact'
    Assert-Equal $linuxGit $record.Environment.GIT_DIR 'Child Git directory metadata is exact'
    Assert-Equal $linuxCommon $record.Environment.GIT_COMMON_DIR 'Child common directory metadata is exact'
    Assert-Equal 'parent value Ω' $record.Environment.LAUNCHER_PARENT_SENTINEL 'Parent variable is preserved'
    Assert-Equal '1' $record.Environment.GIT_CONFIG_COUNT 'Git override count is preserved'
    Assert-Equal 'fixture.launcher' $record.Environment.GIT_CONFIG_KEY_0 'Git override key is preserved'
    Assert-Equal 'quoted Ω value\' $record.Environment.GIT_CONFIG_VALUE_0 'Git override value is preserved'
    Assert-True ($record.Environment.WSLENV -match 'GIT_CONFIG_COUNT/u') 'Git count is transported'
    Assert-True ($record.Environment.WSLENV -match 'GIT_CONFIG_KEY_0/u') 'Git key is transported'
    Assert-True ($record.Environment.WSLENV -match 'GIT_CONFIG_VALUE_0/u') 'Git value is transported'
    Assert-True ($record.Environment.WSLENV -match 'GIT_WORK_TREE/u') 'Worktree is transported'
    $endpoint = Get-Content -LiteralPath $endpointRecordPath -Raw | ConvertFrom-Json
    Assert-Equal (@($linuxRoot) + $exactArguments) @($endpoint.Arguments) `
        'Fake Ripwire endpoint receives the sole root followed by exact allowed arguments'
    Assert-Equal '3' $endpoint.Environment.GIT_CONFIG_COUNT `
        'Fake bootstrap appends exactly two Git overrides'
    Assert-Equal 'fixture.launcher' $endpoint.Environment.GIT_CONFIG_KEY_0 `
        'Fake bootstrap preserves the original Git override key'
    Assert-Equal 'quoted Ω value\' $endpoint.Environment.GIT_CONFIG_VALUE_0 `
        'Fake bootstrap preserves the original Git override value'
    Assert-Equal 'diff.autoRefreshIndex' $endpoint.Environment.GIT_CONFIG_KEY_1 `
        'Fake bootstrap disables index refresh'
    Assert-Equal 'false' $endpoint.Environment.GIT_CONFIG_VALUE_1 `
        'Fake bootstrap preserves Git index bytes'
    Assert-Equal 'core.fsmonitor' $endpoint.Environment.GIT_CONFIG_KEY_2 `
        'Fake bootstrap appends core.fsmonitor last'
    Assert-Equal 'false' $endpoint.Environment.GIT_CONFIG_VALUE_2 `
        'Fake bootstrap disables fsmonitor at the final endpoint'
    Add-Pass 'native WSL-bootstrap-Ripwire chain preserves root arguments and final Git override'

    $tracePath = Join-Path $linked 'trace file Ω.json'
    [IO.File]::WriteAllText($tracePath, '{}')
    Remove-Item $recordPath,$endpointRecordPath -Force -ErrorAction SilentlyContinue
    $traceResult = Invoke-Launcher $linked $configPath @("--from-trace=$tracePath") $baseEnvironment
    Assert-Equal 0 $traceResult.ExitCode 'Known from-trace path launches'
    $traceRecord = Get-Content -LiteralPath $recordPath -Raw | ConvertFrom-Json
    Assert-Equal "--from-trace=$(To-LinuxFixturePath $tracePath)" `
        $traceRecord.Arguments[-1] 'Known from-trace filesystem value is translated exactly'
    $traceEndpoint = Get-Content -LiteralPath $endpointRecordPath -Raw | ConvertFrom-Json
    Assert-Equal @($linuxRoot, "--from-trace=$(To-LinuxFixturePath $tracePath)") `
        @($traceEndpoint.Arguments) 'Translated trace reaches the fake Ripwire endpoint'
    $pathLikeSymbol = 'C:\not-a-filesystem-probe\symbol Ω\'
    Remove-Item $recordPath,$endpointRecordPath -Force -ErrorAction SilentlyContinue
    $symbolResult = Invoke-Launcher $linked $configPath @("--for=$pathLikeSymbol") $baseEnvironment
    Assert-Equal 0 $symbolResult.ExitCode 'Path-like symbol launches'
    $symbolRecord = Get-Content -LiteralPath $recordPath -Raw | ConvertFrom-Json
    Assert-Equal "--for=$pathLikeSymbol" $symbolRecord.Arguments[-1] `
        'Path-like non-path argument remains byte-for-byte text'
    $symbolEndpoint = Get-Content -LiteralPath $endpointRecordPath -Raw | ConvertFrom-Json
    Assert-Equal @($linuxRoot, "--for=$pathLikeSymbol") @($symbolEndpoint.Arguments) `
        'Untranslated path-like symbol reaches the fake Ripwire endpoint'
    Add-Pass 'only declared filesystem option values are translated'

    function Read-Namespace([string] $Worktree) {
        Remove-Item $recordPath,$endpointRecordPath -Force -ErrorAction SilentlyContinue
        $namespaceResult = Invoke-Launcher $Worktree $configPath @('--situ') $baseEnvironment
        Assert-Equal 0 $namespaceResult.ExitCode "Namespace launch succeeds for $Worktree"
        $namespaceRecord = Get-Content -LiteralPath $recordPath -Raw | ConvertFrom-Json
        return [pscustomobject]@{
            Tmp = $namespaceRecord.Environment.TMPDIR
            Xdg = $namespaceRecord.Environment.XDG_CACHE_HOME
        }
    }
    $linkedNamespaceOne = Read-Namespace $linked
    $linkedNamespaceTwo = Read-Namespace $linked
    $mainNamespace = Read-Namespace $main
    Assert-Equal $linkedNamespaceOne $linkedNamespaceTwo `
        'Repeated calls for one root select the same managed namespace'
    Assert-True ($linkedNamespaceOne.Tmp -cne $mainNamespace.Tmp -and
        $linkedNamespaceOne.Xdg -cne $mainNamespace.Xdg) `
        'Different worktrees select different managed namespaces'
    Add-Pass 'managed cache namespace is stable per root and isolated across roots'

    Remove-Item $countPath,$recordPath -Force -ErrorAction SilentlyContinue
    $emptyArguments = Invoke-Launcher $linked $configPath @() $baseEnvironment
    Assert-Equal 0 $emptyArguments.ExitCode 'Empty Ripwire argv is valid'
    $emptyRecord = Get-Content -LiteralPath $recordPath -Raw | ConvertFrom-Json
    Assert-Equal 10 @($emptyRecord.Arguments).Count 'Empty Ripwire argv adds no synthetic analysis option'
    Assert-True ('--no-cache' -cnotin @($emptyRecord.Arguments)) 'Launcher does not inject --no-cache'
    Add-Pass 'empty argv preserves the default analysis contract'

    $parentEnvironmentBefore = Get-EnvironmentSnapshot
    $streamCases = @(
        @{ Name = 'empty output'; Out = [byte[]]@(); Err = [byte[]]@(); Exit = 0; Concurrent = '0' }
        @{ Name = 'invalid bytes'; Out = [byte[]](0,255,254,13,10); Err = [byte[]](128,1); Exit = 0; Concurrent = '0' }
        @{ Name = 'partial nonzero'; Out = [Text.Encoding]::UTF8.GetBytes("partial Ω`r`nno-final"); Err = [byte[]](9,8,7); Exit = 37; Concurrent = '0' }
        @{ Name = 'over pipe capacity'; Out = [byte[]]::new(393216); Err = [byte[]]::new(327680); Exit = 0; Concurrent = '1' }
    )
    for ($index = 0; $index -lt $streamCases.Count; $index++) {
        $case = $streamCases[$index]
        if ($case.Name -eq 'over pipe capacity') {
            for ($offset = 0; $offset -lt $case.Out.Length; $offset++) { $case.Out[$offset] = $offset % 251 }
            for ($offset = 0; $offset -lt $case.Err.Length; $offset++) { $case.Err[$offset] = 255 - ($offset % 251) }
        }
        $environment = $baseEnvironment.Clone()
        $environment.LAUNCHER_SHIM_STDOUT_BASE64 = [Convert]::ToBase64String($case.Out)
        $environment.LAUNCHER_SHIM_STDERR_BASE64 = [Convert]::ToBase64String($case.Err)
        $environment.LAUNCHER_SHIM_EXIT = [string] $case.Exit
        $environment.LAUNCHER_SHIM_CONCURRENT = $case.Concurrent
        $streamResult = Invoke-Launcher $linked $configPath @('--situ') $environment
        Assert-Equal $case.Exit $streamResult.ExitCode "$($case.Name) exit code"
        Assert-Equal ([Convert]::ToBase64String($case.Out)) `
            ([Convert]::ToBase64String($streamResult.Stdout)) "$($case.Name) stdout bytes"
        Assert-Equal ([Convert]::ToBase64String($case.Err)) `
            ([Convert]::ToBase64String($streamResult.Stderr)) "$($case.Name) stderr bytes"
    }
    $parentEnvironmentAfter = Get-EnvironmentSnapshot
    Assert-Equal ([Convert]::ToBase64String($parentEnvironmentBefore)) `
        ([Convert]::ToBase64String($parentEnvironmentAfter)) `
        'Launcher calls leave the parent environment byte-equivalent'
    Add-Pass 'raw streams drain concurrently and preserve empty invalid partial and large output'

    Remove-Item $countPath -Force -ErrorAction SilentlyContinue
    $legacy = Invoke-ProbeProcess 'powershell.exe' @(
        '-NoProfile', '-File', $launcher, '-WorktreePath', $linked, '-ConfigPath', $missingConfig)
    Assert-Equal 78 $legacy.ExitCode 'Windows PowerShell 5.1 is rejected'
    Assert-Equal 'RIPWIRE_WSL_UNSUPPORTED_RUNTIME' $legacy.ErrorText().Trim() `
        'Windows PowerShell 5.1 emits only the runtime guard'
    Assert-Equal 0 (Read-StartCount $countPath) 'Windows PowerShell guard runs before process creation'
    $launcherSource = [IO.File]::ReadAllText($launcher)
    $guardIndex = $launcherSource.IndexOf('$PSVersionTable.PSVersion.Major -lt 7',
        [StringComparison]::Ordinal)
    $commonImportIndex = $launcherSource.IndexOf("RipwireWsl.Common.ps1",
        [StringComparison]::Ordinal)
    $entryImportIndex = $launcherSource.IndexOf("RipwireWsl.Entry.ps1",
        [StringComparison]::Ordinal)
    Assert-True ($guardIndex -ge 0 -and $guardIndex -lt $commonImportIndex -and
        $guardIndex -lt $entryImportIndex) 'Static runtime guard precedes Common and Entry imports'
    Add-Pass 'PowerShell 5.1 guard exits before imports and side effects'

    Write-Output "PASS: Ripwire WSL launcher ($($passed.Count) groups)"
    foreach ($case in $passed) { Write-Output "  - $case" }
} finally {
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
