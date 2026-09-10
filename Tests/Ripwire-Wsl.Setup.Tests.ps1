[CmdletBinding()]
param()

if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Console]::Error.WriteLine('RIPWIRE_WSL_UNSUPPORTED_RUNTIME')
    exit 78
}

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = Split-Path -Parent $PSScriptRoot
$scripts = Join-Path $repo 'plugins\devtools\skills\ripwire-wsl\scripts'
. (Join-Path $scripts 'RipwireWsl.Common.ps1')
. (Join-Path $scripts 'RipwireWsl.Setup.ps1')

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "ASSERTION_FAILED: $Message" }
}
function Assert-Equal($Expected, $Actual, [string]$Message) {
    $left = $Expected | ConvertTo-Json -Depth 20 -Compress
    $right = $Actual | ConvertTo-Json -Depth 20 -Compress
    if ($left -cne $right) { throw "ASSERTION_FAILED: $Message ($left != $right)" }
}
function Result([string]$State, [string]$Out = '', [string]$Err = '', [int]$ExitCode = 0) {
    [pscustomobject]@{
        State=$State; Stdout=[Text.Encoding]::UTF8.GetBytes($Out)
        Stderr=[Text.Encoding]::UTF8.GetBytes($Err); ExitCode=$ExitCode; Message=$Err
    }
}
function ByteResult([string]$State, [byte[]]$Out, [byte[]]$Err = [byte[]]@(), [int]$ExitCode = 0) {
    [pscustomobject]@{ State=$State; Stdout=$Out; Stderr=$Err; ExitCode=$ExitCode; Message='' }
}

$root = Join-Path ([IO.Path]::GetTempPath()) "ripwire-setup-tests-$([Guid]::NewGuid().ToString('N'))"
[IO.Directory]::CreateDirectory($root) | Out-Null
$manifestPath = Join-Path (Split-Path -Parent $scripts) 'references\release.json'
$manifest = (Read-RipwireReleaseManifest $manifestPath).Manifest
$oldConfig = [Text.Encoding]::UTF8.GetBytes("{`"old`":true}`n")
$oldBinary = [byte[]](7, 3, 9, 1)
$oldMode = '700'

function Invoke-Case {
    param(
        [string]$Name,
        [string]$Failure = '',
        [string]$PrerequisiteFailure = '',
        [string]$Hash = $manifest.assets[0].sha256,
        [bool]$Existing = $true,
        [bool]$FailDownloadCleanup = $false
    )
    $caseRoot = Join-Path $root $Name
    [IO.Directory]::CreateDirectory($caseRoot) | Out-Null
    $config = Join-Path $caseRoot 'config.json'
    if ($Existing) { [IO.File]::WriteAllBytes($config, $oldConfig) }
    $state = [ordered]@{
        binary = if ($Existing) { [byte[]]$oldBinary.Clone() } else { $null }
        mode = if ($Existing) { $oldMode } else { $null }
        calls = [Collections.Generic.List[string]]::new()
        downloadCalls = 0
        transactionCalls = 0
        transactionArguments = $null
        wslpathCalls = 0
        batchedWslpathCalls = 0
        configStage = $null
    }
    $fileOperation = {
        param($Operation, $Path, $Bytes)
        $state.calls.Add("file:$Operation")
        switch ($Operation) {
            CreateDirectory { [IO.Directory]::CreateDirectory($Path) | Out-Null }
            WriteNew {
                $state.configStage = $Path
                [IO.File]::WriteAllBytes($Path, $Bytes)
            }
            Delete {
                if ($FailDownloadCleanup -and $Path.EndsWith('.tar.gz', [StringComparison]::OrdinalIgnoreCase)) {
                    throw 'injected download cleanup failure'
                }
                if ([IO.File]::Exists($Path)) { [IO.File]::Delete($Path) }
            }
        }
    }
    $runner = {
        param($FilePath, [string[]]$Arguments)
        $joined = "$FilePath $($Arguments -join ' ')"
        $state.calls.Add($joined)
        if ($FilePath -eq 'git.exe') {
            if ($PrerequisiteFailure -eq 'WindowsGit') { return Result Unavailable '' 'missing git' 1 }
            return Result Success "git version 2.50.0`n"
        }
        if ($Arguments[0] -eq '--status') {
            if ($PrerequisiteFailure -eq 'Wsl') { return Result Unavailable '' 'missing wsl' 1 }
            return Result Success "Default Version: 2`n"
        }
        if ($Arguments[0] -eq '--list') {
            if ($PrerequisiteFailure -eq 'Distribution') { return Result Success "Other Running 2`n" }
            return Result Success "  Ubuntu-Test Running 2`n"
        }
        if ($Arguments -contains 'wslpath') {
            $separator = [Array]::IndexOf($Arguments, '--')
            $paths = @($Arguments[($separator + 1)..($Arguments.Count - 1)])
            $state.wslpathCalls++
            if ($paths.Count -ne 1) {
                $state.batchedWslpathCalls++
                return Result NonZero '' 'wslpath accepts one path operand' 1
            }
            $path = $paths[0]
            $linuxPath = if ($path.EndsWith('install-ripwire-wsl.sh', [StringComparison]::OrdinalIgnoreCase)) {
                '/package/install-ripwire-wsl.sh'
            } elseif ($path.EndsWith('.tar.gz', [StringComparison]::OrdinalIgnoreCase)) {
                '/archive'
            } elseif ($path -eq $config) {
                '/config'
            } elseif ($path -match '\.stage\.') {
                '/config-stage'
            } elseif ($path -match '\.backup\.') {
                '/config-backup'
            } else { throw "Unexpected wslpath operand: $path" }
            return Result Success "$linuxPath`n"
        }
        if ($Arguments -contains 'probe') {
            if ($PrerequisiteFailure -eq 'LinuxTools') {
                return Result NonZero '' 'RIPWIRE_WSL_LINUX_TOOL_MISSING: tar' 69
            }
            $machine = if ($PrerequisiteFailure -eq 'Architecture') { 'riscv64' } else { 'x86_64' }
            $distro = if ($PrerequisiteFailure -eq 'Ubuntu') { 'debian' } else { 'ubuntu' }
            return Result Success @"
DISTRO_ID=$distro
DISTRO_VERSION=22.04
MACHINE=$machine
HOME=/home/test
INSTALL_ROOT=/home/test/.local/share/brownch-devtools/ripwire-wsl
CACHE_ROOT=/home/test/.cache/brownch-devtools/ripwire-wsl
BINARY_PATH=/home/test/.local/share/brownch-devtools/ripwire-wsl/v0.5.0/bin/ripwire
"@
        }
        if ($Arguments -contains 'transaction') {
            $state.transactionCalls++
            $state.transactionArguments = [string[]]$Arguments.Clone()
            $newBinary = [byte[]](11, 22, 33, 44)
            if ($Failure -in @('UnsafeArchive','LinkPayload','WrongVersion','DottedWildcardVersion','StageHealth')) {
                return Result NonZero "ROLLBACK=NotRequired`nCLEANUP_ERRORS=`n" "RIPWIRE_WSL_$($Failure.ToUpperInvariant())" 70
            }
            $savedBinary = if ($null -eq $state.binary) { $null } else { [byte[]]$state.binary.Clone() }
            $savedMode = $state.mode
            if ($Failure -eq 'BinaryBackupRename') {
                return Result NonZero "ROLLBACK=NotRequired`nCLEANUP_ERRORS=`n" 'backup rename failed' 70
            }
            if ($Failure -eq 'BinarySwapRename') {
                return Result NonZero "ROLLBACK=Succeeded`nCLEANUP_ERRORS=`n" 'swap rename failed' 70
            }
            $state.binary = $newBinary; $state.mode = '700'
            if ($Failure -eq 'PostHealth') {
                $state.binary = $savedBinary; $state.mode = $savedMode
                return Result NonZero "ROLLBACK=Succeeded`nCLEANUP_ERRORS=`n" 'post health failed' 70
            }
            if ($Failure -eq 'RollbackDisplace') {
                return Result NonZero "ROLLBACK=Failed`nCLEANUP_ERRORS=`n" 'new binary displace failed' 70
            }
            if ($Failure -eq 'RollbackBinaryRestore') {
                return Result NonZero "ROLLBACK=Failed`nCLEANUP_ERRORS=failed-binary-cleanup`n" 'rollback restore failed' 70
            }
            if ($Failure -eq 'ConfigBackupRename') {
                $state.binary = $savedBinary; $state.mode = $savedMode
                return Result NonZero "ROLLBACK=Succeeded`nCLEANUP_ERRORS=`n" 'config backup failed' 70
            }
            if ($Failure -eq 'ConfigCommitRename') {
                $state.binary = $savedBinary; $state.mode = $savedMode
                return Result NonZero "ROLLBACK=Succeeded`nCLEANUP_ERRORS=`n" 'config commit failed' 70
            }
            if ($Failure -eq 'RollbackConfigRestore') {
                return Result NonZero "ROLLBACK=Failed`nCLEANUP_ERRORS=`n" 'config restore failed' 70
            }
            if ($Failure -eq 'RollbackCleanup') {
                $state.binary = $savedBinary; $state.mode = $savedMode
                return Result NonZero "ROLLBACK=Succeeded`nCLEANUP_ERRORS=failed-binary-cleanup`n" 'rollback cleanup failed' 70
            }
            if ([IO.File]::Exists($config)) { [IO.File]::Delete($config) }
            [IO.File]::Move($state.configStage, $config)
            $cleanup = if ($Failure -eq 'CleanupBinaryBackup') { 'binary-backup-cleanup' }
                elseif ($Failure -eq 'CleanupConfigBackup') { 'config-backup-cleanup' }
                elseif ($Failure -eq 'CleanupTransactionArtifact') { 'transaction-artifact-cleanup' }
                else { '' }
            return Result Success "ROLLBACK=NotRequired`nCLEANUP_ERRORS=$cleanup`nBINARY_PATH=/home/test/bin/ripwire`n"
        }
        throw "Unexpected mock command: $joined"
    }.GetNewClosure()
    $download = {
        param($Uri, $Path)
        $state.downloadCalls++
        [IO.File]::WriteAllBytes($Path, [byte[]](1,2,3))
    }.GetNewClosure()
    $thrown = $null
    $result = $null
    $prerequisiteResult = Get-RipwireSetupPrerequisites -Distribution Ubuntu-Test -Manifest $manifest `
        -CommandRunner $runner
    $state.wslpathCalls = 0
    $state.batchedWslpathCalls = 0
    try {
        $result = Invoke-RipwireWslInstall -Distribution Ubuntu-Test -ConfigPath $config `
            -ManifestPath $manifestPath -CommandRunner $runner -DownloadAction $download `
            -HashAction { param($Path) $Hash } -FileOperation $fileOperation
    } catch { $thrown = $_ }
    [pscustomobject]@{
        Result=$result; Error=$thrown; State=$state; Config=$config
        Prerequisites=$prerequisiteResult
        ConfigBytes=if ([IO.File]::Exists($config)) { [IO.File]::ReadAllBytes($config) } else { $null }
    }
}

try {
    Assert-Equal '' (ConvertFrom-RipwireSetupOutput (ByteResult Success ([byte[]]@())) 'empty success') `
        'Empty successful stdout does not bind to the strict UTF-8 decoder'
    $accentedDistribution = "Ubuntu-$([char]0x00e9)"
    $wslListText = "  $accentedDistribution Running 2`r`n"
    $utf16NoBom = [Text.UnicodeEncoding]::new($false, $false).GetBytes($wslListText)
    $utf16Bom = [byte[]](0xff,0xfe) + $utf16NoBom
    Assert-Equal $wslListText (ConvertFrom-RipwireWslListOutput (ByteResult Success $utf16NoBom)) `
        'Actual BOM-less WSL UTF-16LE output is decoded'
    Assert-Equal $wslListText (ConvertFrom-RipwireWslListOutput (ByteResult Success $utf16Bom)) `
        'BOM-marked WSL UTF-16LE output is decoded'
    Assert-Equal $wslListText (ConvertFrom-RipwireWslListOutput (
        ByteResult Success ([Text.UTF8Encoding]::new($false).GetBytes($wslListText)))) `
        'Deterministic UTF-8 WSL fixtures remain supported'
    $unicodeRunner = {
        param($FilePath, [string[]]$Arguments)
        if ($FilePath -eq 'git.exe') {
            return [pscustomobject]@{ State='Success'; Stdout=[Text.Encoding]::UTF8.GetBytes('git version fixture')
                Stderr=[byte[]]@(); ExitCode=0; Message='' }
        }
        if ($Arguments[0] -eq '--status') {
            return [pscustomobject]@{ State='Success'; Stdout=[byte[]]@(); Stderr=[byte[]]@(); ExitCode=0; Message='' }
        }
        if ($Arguments[0] -eq '--list') {
            return [pscustomobject]@{ State='Success'; Stdout=$utf16NoBom; Stderr=[byte[]]@(); ExitCode=0; Message='' }
        }
        if ($Arguments -contains 'wslpath') {
            return [pscustomobject]@{ State='Success'
                Stdout=[Text.Encoding]::UTF8.GetBytes("/package/install-ripwire-wsl.sh`n")
                Stderr=[byte[]]@(); ExitCode=0; Message='' }
        }
        if ($Arguments -contains 'probe') {
            $probeText = @"
DISTRO_ID=ubuntu
DISTRO_VERSION=22.04
MACHINE=x86_64
HOME=/home/test
INSTALL_ROOT=/home/test/.local/share/brownch-devtools/ripwire-wsl
CACHE_ROOT=/home/test/.cache/brownch-devtools/ripwire-wsl
BINARY_PATH=/home/test/.local/share/brownch-devtools/ripwire-wsl/v0.5.0/bin/ripwire
"@
            return [pscustomobject]@{ State='Success'; Stdout=[Text.Encoding]::UTF8.GetBytes($probeText)
                Stderr=[byte[]]@(); ExitCode=0; Message='' }
        }
        throw "Unexpected Unicode prerequisite command: $FilePath $($Arguments -join ' ')"
    }.GetNewClosure()
    $unicodePrerequisites = Get-RipwireSetupPrerequisites -Distribution $accentedDistribution `
        -Manifest $manifest -CommandRunner $unicodeRunner
    Assert-Equal 'Valid' $unicodePrerequisites.State 'Accented distribution matches decoded WSL listing'
    Assert-Equal 2 $unicodePrerequisites.WslGeneration 'Unicode distribution retains explicit generation'

    $success = Invoke-Case success
    Assert-True ($null -eq $success.Error) "Clean install succeeds: $($success.Error)"
    Assert-Equal 1 $success.State.transactionCalls 'Clean install uses one locked transaction'
    $archiveFileValues = for ($index = 0; $index -lt $success.State.transactionArguments.Count; $index++) {
        if ($success.State.transactionArguments[$index] -ceq '--archive-file') {
            $success.State.transactionArguments[$index + 1]
        }
    }
    $archiveDirectoryValues = for ($index = 0; $index -lt $success.State.transactionArguments.Count; $index++) {
        if ($success.State.transactionArguments[$index] -ceq '--archive-directory') {
            $success.State.transactionArguments[$index + 1]
        }
    }
    Assert-Equal @('ripwire','README.md','LICENSE') @($archiveFileValues) `
        'Setup passes every declared top-level archive file'
    Assert-Equal @('skills','hooks') @($archiveDirectoryValues) `
        'Setup passes every declared archive directory'
    Assert-Equal 5 $success.State.wslpathCalls 'Setup translates five known paths individually'
    Assert-Equal 0 $success.State.batchedWslpathCalls 'Setup never batches wslpath operands'
    Assert-Equal ([byte[]](11,22,33,44)) $success.State.binary 'Clean install swaps binary'
    Assert-Equal 'Valid' $success.Prerequisites.State 'Doctor adapter returns Valid'
    Assert-Equal 'x64' $success.Prerequisites.Architecture 'Doctor adapter returns normalized architecture'
    Assert-Equal 2 $success.Prerequisites.WslGeneration 'WSL generation comes from the explicit WSL listing'
    foreach ($check in $success.Prerequisites.Checks) {
        Assert-Equal @('code','layer','message','remediation','status') @($check.psobject.Properties.Name | Sort-Object) `
            "Prerequisite check '$($check.layer)' has the diagnostic contract"
        Assert-True ($check.status -in @('Ready','Warning','Failed','Skipped')) `
            "Prerequisite check '$($check.layer)' has a closed status"
    }
    $installed = Read-RipwireConfiguration $success.Config $manifest
    Assert-Equal 'Valid' ([string]$installed.State) 'Committed config has exact schema and provenance'
    Assert-Equal @() @($success.Result.CleanupErrors) 'Clean install has no cleanup errors'
    Assert-True ($success.Result.CleanupErrors -is [string[]]) 'Cleanup errors preserve their collection type when empty'
    Assert-Equal 0 $success.Result.CleanupErrors.Count 'Public installer can inspect empty cleanup collection'

    $repeat = Invoke-Case repeat
    Assert-True ($null -eq $repeat.Error) 'Repeat install succeeds'
    Assert-Equal 1 $repeat.State.transactionCalls 'Repeat install remains one transaction'

    foreach ($failure in @(
        'UnsafeArchive','LinkPayload','WrongVersion','DottedWildcardVersion','StageHealth',
        'BinaryBackupRename','BinarySwapRename','PostHealth',
        'ConfigBackupRename','ConfigCommitRename'
    )) {
        $case = Invoke-Case "failure-$failure" $failure
        Assert-True ($null -ne $case.Error) "$failure is reported"
        Assert-Equal $oldBinary $case.State.binary "$failure preserves binary bytes"
        Assert-Equal $oldMode $case.State.mode "$failure preserves executable mode"
        Assert-Equal $oldConfig $case.ConfigBytes "$failure preserves configuration bytes"
    }

    foreach ($failure in @('RollbackDisplace','RollbackBinaryRestore','RollbackConfigRestore')) {
        $case = Invoke-Case "failure-$failure" $failure
        Assert-True ($case.Error.Exception.Message -match 'Rollback=Failed') "$failure reports rollback separately"
    }
    $rollbackCleanup = Invoke-Case failure-RollbackCleanup RollbackCleanup
    Assert-True ($rollbackCleanup.Error.Exception.Message -match
        'Rollback=Succeeded RollbackErrors=.* Cleanup=failed-binary-cleanup') `
        'Rollback cleanup failure is separate from successful rollback'
    foreach ($failure in @('CleanupBinaryBackup','CleanupConfigBackup','CleanupTransactionArtifact')) {
        $case = Invoke-Case "failure-$failure" $failure
        Assert-True ($null -eq $case.Error) "$failure does not undo committed installation"
        Assert-Equal 1 @($case.Result.CleanupErrors).Count "$failure is returned separately"
    }

    $checksum = Invoke-Case checksum '' '' ('0' * 64)
    Assert-True ($checksum.Error.Exception.Message -match 'CHECKSUM_MISMATCH') 'Checksum mismatch is distinct'
    Assert-Equal 0 $checksum.State.transactionCalls 'Checksum mismatch stops before Linux transaction'
    Assert-Equal $oldConfig $checksum.ConfigBytes 'Checksum mismatch preserves config'
    $cleanupAfterSuccess = Invoke-Case cleanup-after-success '' '' $manifest.assets[0].sha256 $true $true
    Assert-True ($cleanupAfterSuccess.Error.Exception.Message -match 'INSTALL_CLEANUP_FAILED') `
        'Download cleanup failure cannot return success'
    Assert-Equal ([byte[]](11,22,33,44)) $cleanupAfterSuccess.State.binary `
        'Cleanup failure reports that the installation was already committed'
    Assert-Equal 'Valid' ([string](Read-RipwireConfiguration $cleanupAfterSuccess.Config $manifest).State) `
        'Cleanup failure does not misrepresent committed configuration'
    $cleanupAfterFailure = Invoke-Case cleanup-after-primary-failure '' '' ('0' * 64) $true $true
    Assert-True ($cleanupAfterFailure.Error.Exception.Message -match 'INSTALL_AND_CLEANUP_FAILED') `
        'Primary and cleanup failures are preserved together'
    Assert-True ($cleanupAfterFailure.Error.Exception.Message -match 'CHECKSUM_MISMATCH') `
        'Combined failure retains the original cause'

    $collisionPath = Join-Path $root 'create-new-collision'
    [IO.File]::WriteAllBytes($collisionPath, [byte[]](4,5,6))
    try {
        Invoke-RipwireConfigFileOperation WriteNew $collisionPath ([byte[]](9,9))
        throw 'Expected CreateNew collision'
    } catch {
        Assert-Equal ([byte[]](4,5,6)) ([IO.File]::ReadAllBytes($collisionPath)) `
            'CreateNew collision never deletes or truncates a preexisting path'
    }

    $malformedManifest = Join-Path $root 'malformed-release.json'
    $mutated = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json -AsHashtable
    $mutated.assets[0].payload = '../ripwire'
    [IO.File]::WriteAllText($malformedManifest, ($mutated | ConvertTo-Json -Depth 20))
    $malformedDownloadCalls = 0
    try {
        $null = Invoke-RipwireWslInstall -Distribution Ubuntu-Test -ConfigPath (Join-Path $root 'never.json') `
            -ManifestPath $malformedManifest -DownloadAction { $script:malformedDownloadCalls++ }
        throw 'Expected malformed manifest failure'
    } catch {
        Assert-True ($_.Exception.Message -match 'MANIFEST_INCONSISTENT') 'Malformed asset metadata is rejected'
    }
    Assert-Equal 0 $malformedDownloadCalls 'Malformed manifest stops before download'

    foreach ($prerequisite in @('WindowsGit','Wsl','Distribution','LinuxTools','Architecture','Ubuntu')) {
        $case = Invoke-Case "prereq-$prerequisite" '' $prerequisite
        Assert-True ($null -ne $case.Error) "$prerequisite failure is reported"
        Assert-Equal 0 $case.State.downloadCalls "$prerequisite stops before download"
        Assert-Equal 0 $case.State.transactionCalls "$prerequisite stops before installation"
        Assert-Equal $oldBinary $case.State.binary "$prerequisite preserves binary"
        Assert-Equal $oldConfig $case.ConfigBytes "$prerequisite preserves config"
    }

    $shellBytes = [IO.File]::ReadAllBytes((Join-Path $scripts 'install-ripwire-wsl.sh'))
    Assert-True (-not $shellBytes.Contains([byte]13)) 'Linux helper uses LF line endings'
    $shellText = [Text.Encoding]::UTF8.GetString($shellBytes)
    foreach ($required in @('flock -w 30','tar -xOzf','--quoting-style=escape',
        'RIPWIRE_WSL_ARCHIVE_UNSAFE_TYPE','RIPWIRE_WSL_CACHE_INSTALL_OVERLAP',
        'ext2/ext3|tmpfs|btrfs|xfs','sed du find')) {
        Assert-True $shellText.Contains($required) "Shell transaction contains $required"
    }
    Assert-True ($shellText.Contains('"ripwire $expected"|"ripwire $expected "*')) `
        'Version health requires the literal pinned version after the ripwire prefix'
    Assert-True (-not $shellText.Contains('(^|[^0-9])$expected')) `
        'Version health does not interpret dotted versions as regular expressions'
    Assert-True (-not $shellText.Contains('python')) 'Production installer has no Python dependency'
    Assert-True (-not $shellText.Contains('install.sh')) 'Production installer does not invoke upstream installer'

    $windowsPowerShell = Get-Command powershell.exe -ErrorAction SilentlyContinue
    if ($null -ne $windowsPowerShell) {
        $gate = Invoke-RipwireNativeCommand $windowsPowerShell.Source @(
            '-NoProfile','-File',(Join-Path $scripts 'Install-RipwireWsl.ps1'),'-Distribution','NeverRun')
        Assert-Equal 78 $gate.ExitCode 'Windows PowerShell runtime gate exit'
        Assert-Equal 0 @($gate.Stdout).Count 'Windows PowerShell gate emits no normal output'
        Assert-True (([Text.Encoding]::UTF8.GetString($gate.Stderr)) -match 'RIPWIRE_WSL_UNSUPPORTED_RUNTIME') `
            'Windows PowerShell gate is explicit'
    }

    Write-Output 'Passed deterministic Ripwire WSL setup transactions, failures, prerequisites, and archive contracts.'
} finally {
    if ([IO.Directory]::Exists($root)) { [IO.Directory]::Delete($root, $true) }
}
