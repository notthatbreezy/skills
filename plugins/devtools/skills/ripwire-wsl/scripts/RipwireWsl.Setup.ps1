Set-StrictMode -Version Latest

function ConvertFrom-RipwireSetupOutput {
    param([Parameter(Mandatory)] $Result, [Parameter(Mandatory)][string] $Operation)
    if ([string] $Result.State -ne 'Success') {
        $stderr = ConvertFrom-RipwireUtf8 ([byte[]] @($Result.Stderr))
        $detail = if ($stderr.State -eq 'Valid') {
            $stderr.Text.Trim()
        } else { $Result.Message }
        throw "RIPWIRE_WSL_SETUP_COMMAND_FAILED: $Operation failed$(if ($detail) { ": $detail" })."
    }
    $text = ConvertFrom-RipwireUtf8 ([byte[]] @($Result.Stdout))
    if ($text.State -ne 'Valid') { throw "RIPWIRE_WSL_SETUP_INVALID_OUTPUT: $Operation returned invalid UTF-8." }
    return $text.Text
}

function ConvertFrom-RipwireWslListOutput {
    param([Parameter(Mandatory)] $Result)
    if ([string]$Result.State -ne 'Success') {
        return ConvertFrom-RipwireSetupOutput $Result 'WSL distribution list'
    }
    $bytes = [byte[]] @($Result.Stdout)
    if ($bytes.Count -eq 0) { return '' }
    try {
        if ($bytes.Count -ge 2 -and $bytes[0] -eq 0xff -and $bytes[1] -eq 0xfe) {
            return [Text.UnicodeEncoding]::new($false, $true, $true).GetString($bytes, 2, $bytes.Count - 2)
        }
        if ($bytes.Count -ge 2 -and $bytes[0] -eq 0xfe -and $bytes[1] -eq 0xff) {
            return [Text.UnicodeEncoding]::new($true, $true, $true).GetString($bytes, 2, $bytes.Count - 2)
        }
        if ($bytes.Count -ge 3 -and $bytes[0] -eq 0xef -and $bytes[1] -eq 0xbb -and $bytes[2] -eq 0xbf) {
            return [Text.UTF8Encoding]::new($false, $true).GetString($bytes, 3, $bytes.Count - 3)
        }
        $oddNulls = 0
        for ($index = 1; $index -lt $bytes.Count; $index += 2) {
            if ($bytes[$index] -eq 0) { $oddNulls++ }
        }
        if ($bytes.Count -ge 4 -and $oddNulls -ge [Math]::Max(1, [Math]::Floor($bytes.Count / 8))) {
            return [Text.UnicodeEncoding]::new($false, $false, $true).GetString($bytes)
        }
        return [Text.UTF8Encoding]::new($false, $true).GetString($bytes)
    } catch {
        throw "RIPWIRE_WSL_SETUP_INVALID_OUTPUT: WSL distribution list has an unsupported encoding: $($_.Exception.Message)"
    }
}

function Invoke-RipwireSetupProcess {
    param(
        [Parameter(Mandatory)][string] $FilePath,
        [Parameter(Mandatory)][AllowEmptyCollection()][AllowEmptyString()][string[]] $Arguments,
        [scriptblock] $CommandRunner
    )
    if ($null -ne $CommandRunner) { return & $CommandRunner $FilePath $Arguments }
    return Invoke-RipwireNativeCommand $FilePath $Arguments -TimeoutSeconds 120
}

function ConvertTo-RipwireSetupLinuxPath {
    param(
        [Parameter(Mandatory)][string] $WindowsPath,
        [Parameter(Mandatory)][string] $Distribution,
        [scriptblock] $CommandRunner
    )
    $result = Invoke-RipwireSetupProcess 'wsl.exe' @(
        '--distribution', $Distribution, '--exec', 'wslpath', '-a', '-u', '--', $WindowsPath) $CommandRunner
    $path = (ConvertFrom-RipwireSetupOutput $result "wslpath for '$WindowsPath'").TrimEnd("`r", "`n")
    if ($path -cnotmatch '^/[^\r\n]+$') {
        throw (New-RipwireSetupException 'RIPWIRE_WSL_PATH_TRANSLATION_FAILED' `
            "wslpath did not return one absolute Linux path for '$WindowsPath'." 69)
    }
    return $path
}

function ConvertFrom-RipwireKeyValueOutput {
    param([Parameter(Mandatory)][string] $Text)
    $values = [ordered] @{}
    foreach ($line in $Text -split "`n") {
        $line = $line.TrimEnd("`r")
        if ($line -eq '') { continue }
        if ($line -cnotmatch '^([A-Z][A-Z0-9_]*)=(.*)$' -or $values.Contains($Matches[1])) {
            throw "RIPWIRE_WSL_SETUP_INVALID_OUTPUT: malformed helper output '$line'."
        }
        $values[$Matches[1]] = $Matches[2]
    }
    return $values
}

function New-RipwireSetupException {
    param(
        [Parameter(Mandatory)][string] $Code,
        [Parameter(Mandatory)][string] $Message,
        [int] $ExitCode = 69
    )
    $exception = [InvalidOperationException]::new("${Code}: $Message")
    $exception.Data['ExitCode'] = $ExitCode
    return $exception
}

function Get-RipwireSetupPrerequisites {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string] $Distribution,
        [System.Collections.IDictionary] $Manifest,
        [string] $ManifestPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'references\release.json'),
        [string] $LinuxInstallRoot,
        [string] $LinuxCacheRoot,
        [string] $LinuxHelperPath = (Join-Path $PSScriptRoot 'install-ripwire-wsl.sh'),
        [scriptblock] $CommandRunner
    )
    $checks = [Collections.Generic.List[object]]::new()
    function Add-Check([string] $Name, [bool] $Ready, [string] $Code, [string] $Message) {
        $layer = $Name.Substring(0, 1).ToLowerInvariant() + $Name.Substring(1)
        $readyCodeName = [regex]::Replace($Name, '([a-z0-9])([A-Z])', '$1_$2').ToUpperInvariant()
        $checks.Add([pscustomobject]@{
            layer = $layer
            code = if ($Ready) { "RIPWIRE_WSL_${readyCodeName}_READY" } else { $Code }
            status = if ($Ready) { 'Ready' } else { 'Failed' }
            message = if ($Ready) { "$Name prerequisite is ready." } else { $Message }
            remediation = if ($Ready) { '' } else { $Message }
        })
    }

    if ($null -eq $Manifest) {
        $manifestResult = Read-RipwireReleaseManifest $ManifestPath
        if ($manifestResult.State -ne 'Valid') {
            Add-Check 'ReleaseManifest' $false $manifestResult.Code $manifestResult.Message
            return [pscustomobject]@{
                PSTypeName='Ripwire.SetupPrerequisiteResult'; State='Failed'; Ready=$false
                Checks=$checks.ToArray(); Failure=$checks[0]; Values=$null; Architecture=$null
                Asset=$null; WslGeneration=$null; Manifest=$null
            }
        }
        $Manifest = $manifestResult.Manifest
    }
    Add-Check 'ReleaseManifest' $true 'RIPWIRE_WSL_MANIFEST_INVALID' 'The packaged release manifest must be valid.'

    $git = Invoke-RipwireSetupProcess 'git.exe' @('--version') $CommandRunner
    Add-Check 'WindowsGit' ([string]$git.State -eq 'Success') 'RIPWIRE_WSL_WINDOWS_GIT_MISSING' `
        'Install Git for Windows and ensure git.exe is available on PATH.'

    $status = Invoke-RipwireSetupProcess 'wsl.exe' @('--status') $CommandRunner
    Add-Check 'Wsl' ([string]$status.State -eq 'Success') 'RIPWIRE_WSL_WSL_MISSING' `
        'Install and configure WSL separately; setup never enables Windows features.'

    $listed = Invoke-RipwireSetupProcess 'wsl.exe' @('--list', '--verbose') $CommandRunner
    $listText = if ([string]$listed.State -eq 'Success') {
        ConvertFrom-RipwireWslListOutput $listed
    } else { '' }
    $escapedDistribution = [regex]::Escape($Distribution)
    $distributionMatch = [regex]::Match($listText, "(?m)^\s*\*?\s*$escapedDistribution\s+\S+\s+([12])\s*$")
    Add-Check 'Distribution' $distributionMatch.Success 'RIPWIRE_WSL_DISTRIBUTION_MISSING' `
        "Select an existing Ubuntu 20.04+ distribution named '$Distribution'; setup does not install distributions."
    Add-Check 'WslGeneration' $distributionMatch.Success 'RIPWIRE_WSL_GENERATION_UNKNOWN' `
        "The selected distribution must report its WSL generation in 'wsl.exe --list --verbose'."

    $helperResult = $null
    $helperValues = $null
    if ($distributionMatch.Success) {
        try {
            $translatedHelper = ConvertTo-RipwireSetupLinuxPath $LinuxHelperPath $Distribution $CommandRunner
        } catch {
            Add-Check 'LinuxTools' $false 'RIPWIRE_WSL_HELPER_PATH_TRANSLATION_FAILED' `
                'The packaged Linux setup helper could not be translated into the selected distribution.'
            $failed = @($checks | Where-Object status -CEQ 'Failed')
            return [pscustomobject]@{
                PSTypeName='Ripwire.SetupPrerequisiteResult'; State='Failed'; Ready=$false
                Checks=$checks.ToArray(); Failure=$failed[0]; Values=$null; Architecture=$null; Asset=$null
                WslGeneration=[int]$distributionMatch.Groups[1].Value; Manifest=$Manifest
            }
        }
        $helperArguments = @('--distribution', $Distribution, '--exec', '/bin/bash', '--', $LinuxHelperPath,
            'probe', '--install-root', [string]$LinuxInstallRoot, '--cache-root', [string]$LinuxCacheRoot,
            '--version', [string]$Manifest.releaseVersion)
        $helperArguments[5] = $translatedHelper
        $helperResult = Invoke-RipwireSetupProcess 'wsl.exe' $helperArguments $CommandRunner
        if ([string]$helperResult.State -eq 'Success') {
            $helperValues = ConvertFrom-RipwireKeyValueOutput (
                ConvertFrom-RipwireSetupOutput $helperResult 'Linux prerequisite probe')
            foreach ($required in @('DISTRO_ID','DISTRO_VERSION','MACHINE','HOME','INSTALL_ROOT','CACHE_ROOT','BINARY_PATH')) {
                if (-not $helperValues.Contains($required) -or [string]::IsNullOrWhiteSpace($helperValues[$required])) {
                    throw "RIPWIRE_WSL_SETUP_INVALID_OUTPUT: Linux probe omitted $required."
                }
            }
            $ubuntuVersion = [version]::new(0, 0)
            $ubuntuReady = $helperValues.DISTRO_ID -ceq 'ubuntu' -and
                [version]::TryParse($helperValues.DISTRO_VERSION, [ref]$ubuntuVersion) -and
                $ubuntuVersion -ge [version]'20.04'
            Add-Check 'Ubuntu' $ubuntuReady 'RIPWIRE_WSL_UNSUPPORTED_DISTRIBUTION' `
                'Use an existing Ubuntu 20.04 or newer distribution.'
            $architecture = Resolve-RipwireArchitecture $Manifest $helperValues.MACHINE
            Add-Check 'Architecture' ($architecture.State -eq 'Valid') 'RIPWIRE_WSL_UNSUPPORTED_ARCHITECTURE' `
                "The Linux machine architecture '$($helperValues.MACHINE)' has no declared release artifact."
            Add-Check 'LinuxTools' $true 'RIPWIRE_WSL_LINUX_TOOLS_MISSING' `
                'Install Linux git, bash, tar, coreutils, and util-linux flock separately.'
        } else {
            $decodedError = ConvertFrom-RipwireUtf8 ([byte[]] @($helperResult.Stderr))
            $errorText = if ($decodedError.State -eq 'Valid') {
                $decodedError.Text.Trim()
            } else { '' }
            $toolCode = if ($errorText -match 'RIPWIRE_WSL_LINUX_TOOL_MISSING: ([a-z0-9]+)') {
                "RIPWIRE_WSL_LINUX_TOOL_MISSING_$($Matches[1].ToUpperInvariant())"
            } else { 'RIPWIRE_WSL_LINUX_PREREQUISITE_FAILED' }
            Add-Check 'LinuxTools' $false $toolCode `
                'Install Linux git, bash, tar, coreutils, and util-linux flock separately.'
        }
    }
    $failed = @($checks | Where-Object status -CEQ 'Failed')
    $resolvedArchitecture = if ($null -ne $helperValues) {
        Resolve-RipwireArchitecture $Manifest $helperValues.MACHINE
    } else { $null }
    return [pscustomobject]@{
        PSTypeName = 'Ripwire.SetupPrerequisiteResult'
        State = if ($failed.Count -eq 0) { 'Valid' } else { 'Failed' }
        Ready = $failed.Count -eq 0
        Checks = $checks.ToArray()
        Failure = if ($failed.Count) { $failed[0] } else { $null }
        Values = $helperValues
        Architecture = if ($null -ne $resolvedArchitecture -and $resolvedArchitecture.State -eq 'Valid') {
            $resolvedArchitecture.Architecture
        } else { $null }
        Asset = if ($null -ne $resolvedArchitecture -and $resolvedArchitecture.State -eq 'Valid') {
            $resolvedArchitecture.Asset
        } else { $null }
        LinuxHelperPath = if ($distributionMatch.Success -and $null -ne $helperValues) {
            $translatedHelper
        } else { $null }
        WslGeneration = if ($distributionMatch.Success) { [int]$distributionMatch.Groups[1].Value } else { $null }
        Manifest = $Manifest
    }
}

function Invoke-RipwireConfigFileOperation {
    param(
        [Parameter(Mandatory)][ValidateSet('CreateDirectory','WriteNew','Delete')][string] $Operation,
        [Parameter(Mandatory)][string] $Path,
        [byte[]] $Bytes,
        [scriptblock] $FileOperation
    )
    if ($null -ne $FileOperation) { return & $FileOperation $Operation $Path $Bytes }
    switch ($Operation) {
        'CreateDirectory' { [IO.Directory]::CreateDirectory($Path) | Out-Null }
        'WriteNew' {
            $stream = $null
            try {
                $stream = [IO.FileStream]::new($Path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write,
                    [IO.FileShare]::None, 4096, [IO.FileOptions]::WriteThrough)
                $stream.Write($Bytes)
                $stream.Flush($true)
            } catch {
                if ($null -ne $stream) {
                    $stream.Dispose()
                    $stream = $null
                    try { [IO.File]::Delete($Path) }
                    catch {
                        $cleanupException = [IOException]::new(
                            "Write failed and partial file cleanup failed for '$Path': $($_.Exception.Message)")
                        $cleanupException.Data['PrimaryError'] = $PSItem.Exception.Message
                        throw $cleanupException
                    }
                }
                throw
            } finally {
                if ($null -ne $stream) { $stream.Dispose() }
            }
        }
        'Delete' { if ([IO.File]::Exists($Path)) { [IO.File]::Delete($Path) } }
    }
}

function Invoke-RipwireWslInstall {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string] $Distribution,
        [string] $ConfigPath,
        [string] $LinuxInstallRoot,
        [string] $LinuxCacheRoot,
        [string] $ManifestPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'references\release.json'),
        [string] $LinuxHelperPath = (Join-Path $PSScriptRoot 'install-ripwire-wsl.sh'),
        [scriptblock] $CommandRunner,
        [scriptblock] $DownloadAction,
        [scriptblock] $HashAction,
        [scriptblock] $FileOperation
    )
    $manifestResult = Read-RipwireReleaseManifest $ManifestPath
    if ($manifestResult.State -ne 'Valid') {
        throw (New-RipwireSetupException $manifestResult.Code $manifestResult.Message 65)
    }
    $manifest = $manifestResult.Manifest
    if ([string]::IsNullOrWhiteSpace($ConfigPath)) { $ConfigPath = Get-RipwireDefaultConfigPath }
    $ConfigPath = [IO.Path]::GetFullPath($ConfigPath)
    $prerequisites = Get-RipwireSetupPrerequisites -Distribution $Distribution -Manifest $manifest `
        -LinuxInstallRoot $LinuxInstallRoot -LinuxCacheRoot $LinuxCacheRoot `
        -LinuxHelperPath $LinuxHelperPath -CommandRunner $CommandRunner
    if (-not $prerequisites.Ready) {
        throw (New-RipwireSetupException $prerequisites.Failure.Code $prerequisites.Failure.Message 69)
    }
    $asset = $prerequisites.Asset
    $transactionId = [Guid]::NewGuid().ToString('N')
    $downloadPath = Join-Path ([IO.Path]::GetTempPath()) ("ripwire-$transactionId.tar.gz")
    $configParent = Split-Path -Parent $ConfigPath
    $configLeaf = Split-Path -Leaf $ConfigPath
    $configTemp = Join-Path $configParent ".$configLeaf.stage.$transactionId"
    $configBackup = Join-Path $configParent ".$configLeaf.backup.$transactionId"
    $downloaded = $false
    $tempWritten = $false
    $installResult = $null
    $primaryError = $null
    $cleanupErrors = [Collections.Generic.List[string]]::new()
    try {
        $downloaded = $true
        if ($null -ne $DownloadAction) { & $DownloadAction $asset.url $downloadPath }
        else { Invoke-WebRequest -Uri $asset.url -OutFile $downloadPath -UseBasicParsing }
        $actualHash = if ($null -ne $HashAction) { & $HashAction $downloadPath } else {
            (Get-FileHash -LiteralPath $downloadPath -Algorithm SHA256).Hash
        }
        if ([string]$actualHash -cne $asset.sha256.ToUpperInvariant() -and
            [string]$actualHash -cne $asset.sha256) {
            throw (New-RipwireSetupException 'RIPWIRE_WSL_ARCHIVE_CHECKSUM_MISMATCH' `
                "Downloaded archive SHA-256 does not match $($asset.assetName)." 65)
        }
        $translated = [Collections.Generic.List[string]]::new()
        foreach ($windowsPath in @($downloadPath, $ConfigPath, $configTemp, $configBackup)) {
            $translated.Add((ConvertTo-RipwireSetupLinuxPath $windowsPath $Distribution $CommandRunner))
        }
        $configuration = [ordered]@{
            schemaVersion = 1
            distribution = $Distribution
            architecture = $prerequisites.Architecture
            releaseVersion = $manifest.releaseVersion
            releaseCommit = $manifest.releaseCommit
            archiveSha256 = $asset.sha256
            binaryPath = $prerequisites.Values.BINARY_PATH
            cacheRoot = $prerequisites.Values.CACHE_ROOT
        }
        $configBytes = [Text.UTF8Encoding]::new($false).GetBytes(
            (($configuration | ConvertTo-Json -Depth 4) + "`n"))
        Invoke-RipwireConfigFileOperation CreateDirectory $configParent -FileOperation $FileOperation
        Invoke-RipwireConfigFileOperation WriteNew $configTemp $configBytes $FileOperation
        $tempWritten = $true

        $transactionArguments = @('--distribution', $Distribution, '--exec', '/bin/bash', '--',
            $prerequisites.LinuxHelperPath, 'transaction',
            '--archive', $translated[0], '--archive-root', $asset.archiveRoot,
            '--payload', $asset.payload)
        foreach ($archiveFile in $asset.archiveFiles) {
            $transactionArguments += @('--archive-file', [string]$archiveFile)
        }
        foreach ($archiveDirectory in $asset.archiveDirectories) {
            $transactionArguments += @('--archive-directory', [string]$archiveDirectory)
        }
        $transactionArguments += @('--version', $manifest.releaseVersion,
            '--install-root', $prerequisites.Values.INSTALL_ROOT,
            '--cache-root', $prerequisites.Values.CACHE_ROOT,
            '--config', $translated[1], '--config-stage', $translated[2],
            '--config-backup', $translated[3], '--transaction-id', $transactionId)
        $transaction = Invoke-RipwireSetupProcess 'wsl.exe' $transactionArguments $CommandRunner
        $transactionText = ConvertFrom-RipwireUtf8 ([byte[]] @($transaction.Stdout))
        $details = if ($transactionText.State -eq 'Valid') {
            ConvertFrom-RipwireKeyValueOutput $transactionText.Text
        } else { [ordered]@{} }
        if ([string]$transaction.State -ne 'Success') {
            $stderr = ConvertFrom-RipwireUtf8 ([byte[]] @($transaction.Stderr))
            $message = if ($stderr.State -eq 'Valid') {
                $stderr.Text.Trim()
            } else { $transaction.Message }
            $rollback = if ($details.Contains('ROLLBACK')) { $details.ROLLBACK } else { 'Unknown' }
            $rollbackErrors = if ($details.Contains('ROLLBACK_ERRORS')) { $details.ROLLBACK_ERRORS } else { '' }
            $cleanup = if ($details.Contains('CLEANUP_ERRORS')) { $details.CLEANUP_ERRORS } else { '' }
            throw (New-RipwireSetupException 'RIPWIRE_WSL_INSTALL_TRANSACTION_FAILED' `
                "Installation failed: $message Rollback=$rollback RollbackErrors=$rollbackErrors Cleanup=$cleanup" 70)
        }
        $tempWritten = $false
        $transactionCleanupErrors = [string[]] @(if ($details.Contains('CLEANUP_ERRORS') -and $details.CLEANUP_ERRORS) {
            $details.CLEANUP_ERRORS -split '\|'
        })
        $installResult = [pscustomobject]@{
            PSTypeName = 'Ripwire.InstallResult'
            Distribution = $Distribution
            Architecture = $prerequisites.Architecture
            ReleaseVersion = $manifest.releaseVersion
            BinaryPath = $prerequisites.Values.BINARY_PATH
            CacheRoot = $prerequisites.Values.CACHE_ROOT
            ConfigPath = $ConfigPath
            WslGeneration = $prerequisites.WslGeneration
            CleanupErrors = $transactionCleanupErrors
        }
    } catch {
        $primaryError = $_
    } finally {
        if ($tempWritten) {
            try { Invoke-RipwireConfigFileOperation Delete $configTemp -FileOperation $FileOperation }
            catch { $cleanupErrors.Add("Config stage cleanup failed: $($_.Exception.Message)") }
        }
        if ($downloaded) {
            try { Invoke-RipwireConfigFileOperation Delete $downloadPath -FileOperation $FileOperation }
            catch { $cleanupErrors.Add("Download cleanup failed: $($_.Exception.Message)") }
        }
    }
    if ($null -ne $primaryError) {
        if ($cleanupErrors.Count -eq 0) { throw $primaryError }
        $exitCode = if ($primaryError.Exception.Data.Contains('ExitCode')) {
            [int]$primaryError.Exception.Data['ExitCode']
        } else { 1 }
        $combined = New-RipwireSetupException 'RIPWIRE_WSL_INSTALL_AND_CLEANUP_FAILED' `
            "$($primaryError.Exception.Message) Cleanup: $($cleanupErrors -join '; ')" $exitCode
        $combined.Data['PrimaryError'] = $primaryError.Exception.Message
        $combined.Data['CleanupErrors'] = [string[]]$cleanupErrors.ToArray()
        throw $combined
    }
    if ($cleanupErrors.Count -gt 0) {
        $cleanupFailure = New-RipwireSetupException 'RIPWIRE_WSL_INSTALL_CLEANUP_FAILED' `
            "Installation committed, but cleanup failed: $($cleanupErrors -join '; ')" 74
        $cleanupFailure.Data['InstallCommitted'] = $true
        $cleanupFailure.Data['CleanupErrors'] = [string[]]$cleanupErrors.ToArray()
        throw $cleanupFailure
    }
    return $installResult
}
