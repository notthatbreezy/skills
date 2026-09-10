[CmdletBinding()]
param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string] $Distribution)

if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Console]::Error.WriteLine('RIPWIRE_WSL_UNSUPPORTED_RUNTIME')
    exit 78
}

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = Split-Path -Parent $PSScriptRoot
$package = Join-Path $repo 'plugins\devtools\skills\ripwire-wsl'
$fixtures = Join-Path $PSScriptRoot 'fixtures\ripwire-wsl'
. (Join-Path $package 'scripts\RipwireWsl.Common.ps1')

function Invoke-Wsl([string[]]$Arguments, [int]$TimeoutSeconds = 60) {
    $normalizedArguments = @($Arguments | ForEach-Object { $_.Replace("`r`n", "`n") })
    Invoke-RipwireNativeCommand 'wsl.exe' (@('--distribution',$Distribution,'--exec') + $normalizedArguments) `
        -TimeoutSeconds $TimeoutSeconds
}
function Text($Result, [string]$Operation) {
    if ($Result.State -ne 'Success') {
        $errorBytes = [byte[]]@($Result.Stderr)
        $errorText = if ($errorBytes.Count) { [Text.Encoding]::UTF8.GetString($errorBytes) } else { $Result.Message }
        throw "${Operation}: $errorText"
    }
    $bytes = [byte[]]@($Result.Stdout)
    if ($bytes.Count -eq 0) { return '' }
    [Text.Encoding]::UTF8.GetString($bytes).Trim()
}
function LinuxPath([string]$WindowsPath) {
    Text (Invoke-Wsl @('wslpath','-a','-u','--',$WindowsPath)) 'wslpath'
}
function Assert-Equal($Expected, $Actual, [string]$Message) {
    $left = $Expected | ConvertTo-Json -Compress -Depth 10
    $right = $Actual | ConvertTo-Json -Compress -Depth 10
    if ($left -cne $right) { throw "ASSERTION_FAILED: $Message ($left != $right)" }
}
function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "ASSERTION_FAILED: $Message" }
}

$windowsRoot = Join-Path ([IO.Path]::GetTempPath()) "ripwire-transaction-$([Guid]::NewGuid().ToString('N'))"
[IO.Directory]::CreateDirectory($windowsRoot) | Out-Null
$linuxRoot = $null
try {
    $linuxHome = Text (Invoke-Wsl @('/bin/bash','-c','printf "%s" "$HOME"')) 'Linux HOME'
    Assert-True ($linuxHome -match '^/') 'Linux HOME is absolute'
    $linuxRoot = "$linuxHome/.cache/brownch-devtools/ripwire-wsl-transaction-tests/$([Guid]::NewGuid().ToString('N'))"
    $helper = LinuxPath (Join-Path $package 'scripts\install-ripwire-wsl.sh')
    $fixtureBinary = LinuxPath (Join-Path $fixtures 'transaction-ripwire.sh')
    $fixtureMv = LinuxPath (Join-Path $fixtures 'transaction-mv.sh')
    $fixtureRm = LinuxPath (Join-Path $fixtures 'transaction-rm.sh')
    $archiveRoot = 'ripwire-0.5.0-linux-x64'
    $archive = "$linuxRoot/archive.tar.gz"
    $unexpectedArchive = "$linuxRoot/archive-unexpected.tar.gz"
    $invalidTypeArchive = "$linuxRoot/archive-invalid-type.tar.gz"
    $missingLayoutArchive = "$linuxRoot/archive-missing-layout.tar.gz"
    $shim = "$linuxRoot/shim"
    $null = Text (Invoke-Wsl @('/bin/bash','-c',@'
set -e
umask 077
mkdir -p -- "$1/source/$2/skills" "$1/source/$2/hooks" "$1/shim"
cp -- "$3" "$1/source/$2/ripwire"
printf 'fixture readme\n' >"$1/source/$2/README.md"
printf 'fixture license\n' >"$1/source/$2/LICENSE"
printf 'skill\n' >"$1/source/$2/skills/example.md"
printf 'hook\n' >"$1/source/$2/hooks/example.sh"
cp -- "$4" "$1/shim/mv"
cp -- "$5" "$1/shim/rm"
chmod 755 -- "$1/source/$2/ripwire" "$1/shim/mv" "$1/shim/rm"
tar -czf "$1/archive.tar.gz" -C "$1/source" -- "$2"
cp -a -- "$1/source" "$1/source-unexpected"
printf 'unexpected\n' >"$1/source-unexpected/$2/README"
tar -czf "$1/archive-unexpected.tar.gz" -C "$1/source-unexpected" -- "$2"
cp -a -- "$1/source" "$1/source-invalid-type"
rm -- "$1/source-invalid-type/$2/README.md"
mkdir -- "$1/source-invalid-type/$2/README.md"
tar -czf "$1/archive-invalid-type.tar.gz" -C "$1/source-invalid-type" -- "$2"
cp -a -- "$1/source" "$1/source-missing-layout"
rm -rf -- "$1/source-missing-layout/$2/hooks"
tar -czf "$1/archive-missing-layout.tar.gz" -C "$1/source-missing-layout" -- "$2"
'@,'_',$linuxRoot,$archiveRoot,$fixtureBinary,$fixtureMv,$fixtureRm)) 'fixture creation'

    function Invoke-TransactionCase {
        param(
            [string]$Name,
            [string]$FailAt = '',
            [switch]$WrongStageVersion,
            [switch]$PostHealthFailure,
            [switch]$ExpectSuccess,
            [switch]$ExpectCleanupError,
            [switch]$NoExisting,
            [switch]$Repeat,
            [ValidateSet('Valid','Unexpected','InvalidType','MissingLayout')][string]$ArchiveKind = 'Valid',
            [switch]$ExpectRollbackFailure,
            [switch]$ExpectRestoredDespiteRollbackError,
            [string]$ExpectedCleanupToken = '',
            [string]$ExpectedRollbackToken = ''
        )
        $caseRoot = "$linuxRoot/cases/$Name"
        $installRoot = "$caseRoot/install"
        $cacheRoot = "$caseRoot/cache"
        $binary = "$installRoot/v0.5.0/bin/ripwire"
        $config = Join-Path $windowsRoot "$Name.config.json"
        $configStage = Join-Path $windowsRoot ".$Name.config.json.stage.$('a' * 32)"
        $configBackup = Join-Path $windowsRoot ".$Name.config.json.backup.$('a' * 32)"
        if (-not $NoExisting) {
            [IO.File]::WriteAllBytes($config, [Text.Encoding]::UTF8.GetBytes("old-$Name`n"))
        }
        [IO.File]::WriteAllBytes($configStage, [Text.Encoding]::UTF8.GetBytes("new-$Name`n"))
        $linuxConfig = LinuxPath $config
        $linuxConfigStage = LinuxPath $configStage
        $linuxConfigBackup = LinuxPath $configBackup
        $null = Text (Invoke-Wsl @('/bin/bash','-c',@'
set -e
umask 077
mkdir -p -- "$1/v0.5.0/bin" "$2"
if [[ "$5" == 0 ]]; then
    cp -- "$3" "$1/v0.5.0/bin/ripwire"
    printf '\n# old-%s\n' "$4" >>"$1/v0.5.0/bin/ripwire"
    chmod 711 -- "$1/v0.5.0/bin/ripwire"
fi
'@,'_',$installRoot,$cacheRoot,$fixtureBinary,$Name,[int][bool]$NoExisting)) "prepare $Name"
        $beforeBinary = if ($NoExisting) { $null } else {
            Text (Invoke-Wsl @('sha256sum',$binary)) "binary hash $Name"
        }
        $beforeMode = if ($NoExisting) { $null } else {
            Text (Invoke-Wsl @('stat','-c','%a',$binary)) "binary mode $Name"
        }
        $beforeConfig = if ($NoExisting) { $null } else {
            [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([IO.File]::ReadAllBytes($config)))
        }
        $selectedArchive = switch ($ArchiveKind) {
            Valid { $archive }
            Unexpected { $unexpectedArchive }
            InvalidType { $invalidTypeArchive }
            MissingLayout { $missingLayoutArchive }
        }
        $environmentArguments = @('/usr/bin/env',"PATH=$shim`:/usr/bin:/bin",
            "TRANSACTION_FAIL_AT=$FailAt",
            "TRANSACTION_FAKE_VERSION=$(if ($WrongStageVersion) { '0x5x0' } else { '0.5.0' })",
            "TRANSACTION_POST_HEALTH_FAIL=$(if ($PostHealthFailure) { '1' } else { '0' })",
            '/bin/bash','--',$helper,'transaction',
            '--archive',$selectedArchive,'--archive-root',$archiveRoot,'--payload',"$archiveRoot/ripwire",
            '--archive-file','ripwire','--archive-file','README.md','--archive-file','LICENSE',
            '--archive-directory','skills','--archive-directory','hooks',
            '--version','v0.5.0','--install-root',$installRoot,'--cache-root',$cacheRoot,
            '--config',$linuxConfig,'--config-stage',$linuxConfigStage,'--config-backup',$linuxConfigBackup,
            '--transaction-id',('a' * 32))
        $result = Invoke-Wsl $environmentArguments
        if ($Repeat -and $result.State -eq 'Success') {
            [IO.File]::WriteAllBytes($configStage, [Text.Encoding]::UTF8.GetBytes("new-$Name`n"))
            $result = Invoke-Wsl $environmentArguments
        }
        $stdout = if (@($result.Stdout).Count) { [Text.Encoding]::UTF8.GetString($result.Stdout) } else { '' }
        if ($ExpectSuccess) {
            Assert-Equal 'Success' ([string]$result.State) "$Name succeeds"
            Assert-Equal "new-$Name`n" ([Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes($config))) `
                "$Name commits config"
            Assert-Equal '700' (Text (Invoke-Wsl @('stat','-c','%a',$binary)) "installed mode $Name") `
                "$Name installs restrictive executable mode"
            $ancillary = Invoke-Wsl @('/bin/bash','-c',
                'test ! -e "$1/README.md" -a ! -e "$1/LICENSE" -a ! -e "$1/skills" -a ! -e "$1/hooks"',
                '_',$installRoot)
            Assert-Equal 'Success' ([string]$ancillary.State) "$Name extracts only the binary payload"
            if ($ExpectCleanupError) {
                Assert-True ($stdout -match 'CLEANUP_ERRORS=.+') "$Name reports cleanup failure"
            } else {
                Assert-True ($stdout -match 'CLEANUP_ERRORS=\r?\n') "$Name has clean transaction cleanup"
            }
        } else {
            Assert-True ([string]$result.State -ne 'Success') "$Name fails"
            if (-not $ExpectRollbackFailure -or $ExpectRestoredDespiteRollbackError) {
                $afterBinary = Text (Invoke-Wsl @('sha256sum',$binary)) "restored binary hash $Name"
                $afterMode = Text (Invoke-Wsl @('stat','-c','%a',$binary)) "restored binary mode $Name"
                $afterConfig = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData(
                    [IO.File]::ReadAllBytes($config)))
                Assert-Equal $beforeBinary $afterBinary "$Name restores binary bytes"
                Assert-Equal $beforeMode $afterMode "$Name restores binary mode"
                Assert-Equal $beforeConfig $afterConfig "$Name restores config bytes"
                if (-not $ExpectRollbackFailure -and $ArchiveKind -eq 'Valid') {
                    Assert-True ($stdout -match 'ROLLBACK=(NotRequired|Succeeded)') "$Name reports rollback result"
                }
            }
            if ($ExpectRollbackFailure) {
                Assert-True ($stdout -match 'ROLLBACK=Failed') "$Name reports rollback failure separately"
            }
        }
        if ($ExpectedCleanupToken) {
            Assert-True ($stdout.Contains("CLEANUP_ERRORS=$ExpectedCleanupToken")) `
                "$Name reports exact cleanup transition '$ExpectedCleanupToken'"
        }
        if ($ExpectedRollbackToken) {
            Assert-True ($stdout.Contains($ExpectedRollbackToken)) `
                "$Name reports exact rollback transition '$ExpectedRollbackToken'"
        }
        [pscustomobject]@{ Result=$result; Output=$stdout; Binary=$binary; Config=$config }
    }

    $null = Invoke-TransactionCase clean -ExpectSuccess -NoExisting
    $null = Invoke-TransactionCase repeat -ExpectSuccess -NoExisting -Repeat
    $null = Invoke-TransactionCase wrong-stage -WrongStageVersion
    $null = Invoke-TransactionCase unexpected-entry -ArchiveKind Unexpected
    $null = Invoke-TransactionCase invalid-expected-type -ArchiveKind InvalidType
    $null = Invoke-TransactionCase missing-expected-layout -ArchiveKind MissingLayout
    $null = Invoke-TransactionCase post-swap -PostHealthFailure
    foreach ($failure in @('binary-backup','binary-swap','config-backup','config-commit')) {
        $null = Invoke-TransactionCase $failure -FailAt $failure
    }
    $null = Invoke-TransactionCase rollback-displace -FailAt 'rollback-displace' -PostHealthFailure `
        -ExpectRollbackFailure -ExpectRestoredDespiteRollbackError -ExpectedRollbackToken 'new-binary-displace'
    $null = Invoke-TransactionCase rollback-binary -FailAt 'rollback-binary-restore' -PostHealthFailure `
        -ExpectRollbackFailure -ExpectedRollbackToken 'binary-backup-restore'
    $null = Invoke-TransactionCase swap-and-restore -FailAt 'binary-swap,rollback-binary-restore' `
        -ExpectRollbackFailure -ExpectedRollbackToken 'binary-backup-restore-after-swap'
    $null = Invoke-TransactionCase rollback-config -FailAt 'config-commit,rollback-config-restore' `
        -ExpectRollbackFailure -ExpectedRollbackToken 'config-backup-restore'
    $null = Invoke-TransactionCase cleanup-binary -FailAt 'cleanup-binary-backup' -ExpectSuccess `
        -ExpectCleanupError -ExpectedCleanupToken 'binary-backup-cleanup'
    $null = Invoke-TransactionCase cleanup-config -FailAt 'cleanup-config-backup' -ExpectSuccess `
        -ExpectCleanupError -ExpectedCleanupToken 'config-backup-cleanup'
    $null = Invoke-TransactionCase cleanup-artifacts -FailAt 'cleanup-transaction-artifacts' `
        -ExpectSuccess -ExpectCleanupError -ExpectedCleanupToken 'transaction-artifact-cleanup'
    $null = Invoke-TransactionCase cleanup-stage -FailAt 'cleanup-stage' -WrongStageVersion `
        -ExpectedCleanupToken 'stage-cleanup'
    $null = Invoke-TransactionCase rollback-cleanup -FailAt 'cleanup-failed-binary' -PostHealthFailure `
        -ExpectedCleanupToken 'failed-binary-cleanup'

    Write-Output 'Passed live disposable Bash transaction swap, rollback, configuration, mode, and cleanup cases.'
} finally {
    if ($null -ne $linuxRoot) {
        $cleanup = Invoke-Wsl @('/bin/bash','-c','rm -rf -- "$1"','_',$linuxRoot)
        if ($cleanup.State -ne 'Success') {
            [Console]::Error.WriteLine('TRANSACTION_TEST_LINUX_CLEANUP_FAILED')
        }
    }
    if ([IO.Directory]::Exists($windowsRoot)) { [IO.Directory]::Delete($windowsRoot, $true) }
}
