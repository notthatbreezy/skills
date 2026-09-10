enum RipwireDiagnosticStatus { Ready; Warning; Failed; Skipped }

function New-RipwireDiagnostic {
    param(
        [string] $Layer,
        [string] $Code,
        [RipwireDiagnosticStatus] $Status,
        [string] $Message,
        [string] $Remediation = ''
    )
    [pscustomobject]@{ layer = $Layer; code = $Code; status = $Status.ToString()
        message = $Message; remediation = $Remediation }
}

function Invoke-RipwireDiagnostics {
    [CmdletBinding()]
    param([string] $ConfigPath, [string] $WorktreePath)
    $checks = [Collections.Generic.List[object]]::new()
    $details = [ordered]@{}
    function Finish-Diagnostics {
        $state = if (@($checks | Where-Object status -EQ Failed).Count) { 'Failed' }
            elseif (@($checks | Where-Object status -EQ Warning).Count) { 'Warning' } else { 'Ready' }
        [pscustomobject]@{ schemaVersion = 1; status = $state; checks = $checks.ToArray(); details = $details }
    }
    try {
        $manifest = Read-RipwireReleaseManifest (Join-Path $PSScriptRoot '..\references\release.json')
        if ($manifest.State -ne [RipwireManifestState]::Valid) {
            $checks.Add((New-RipwireDiagnostic manifest $manifest.Code Failed $manifest.Message 'Restore the packaged release manifest.'))
            return Finish-Diagnostics
        }
        $checks.Add((New-RipwireDiagnostic manifest RIPWIRE_WSL_MANIFEST_READY Ready $manifest.Manifest.releaseVersion))
        if ([string]::IsNullOrEmpty($ConfigPath)) { $ConfigPath = Get-RipwireDefaultConfigPath }
        $configuration = Read-RipwireConfiguration $ConfigPath $manifest.Manifest
        if ($configuration.State -ne [RipwireConfigurationState]::Valid) {
            $checks.Add((New-RipwireDiagnostic configuration $configuration.Code Failed $configuration.Message 'Run explicit setup for the intended distribution.'))
            return Finish-Diagnostics
        }
        $config = $configuration.Configuration
        $checks.Add((New-RipwireDiagnostic configuration RIPWIRE_WSL_CONFIG_READY Ready 'Configuration matches the pinned release and archive identity.'))
        try { $null = New-RipwireChildEnvironment (Get-RipwireCurrentEnvironment) @{} }
        catch {
            $checks.Add((New-RipwireDiagnostic environment RIPWIRE_WSL_INVALID_ENVIRONMENT Failed $_.Exception.Message 'Correct the named inherited Git or WSLENV entry.'))
            return Finish-Diagnostics
        }
        $checks.Add((New-RipwireDiagnostic environment RIPWIRE_WSL_ENVIRONMENT_READY Ready 'Inherited indexed Git overrides and WSLENV are valid.'))
        $installRoot = $config.binaryPath -replace '/v[0-9]+\.[0-9]+\.[0-9]+/bin/ripwire$', ''
        if ($installRoot -ceq $config.binaryPath) {
            throw 'RIPWIRE_WSL_UNEXPECTED_BINARY_LAYOUT: rerun explicit setup using the packaged installation layout.'
        }
        $hostResult = Get-RipwireSetupPrerequisites -Distribution $config.distribution -Manifest $manifest.Manifest `
            -LinuxInstallRoot $installRoot -LinuxCacheRoot $config.cacheRoot
        # The setup prerequisite adapter returns named checks without performing installation.
        foreach ($check in $hostResult.Checks) { $checks.Add($check) }
        if ($hostResult.State -ne 'Valid') { return Finish-Diagnostics }
        if ($hostResult.Architecture -cne $config.architecture) {
            $checks.Add((New-RipwireDiagnostic architecture RIPWIRE_WSL_ARCHITECTURE_MISMATCH Failed 'Configured architecture differs from the selected distribution.' 'Rerun explicit setup.'))
            return Finish-Diagnostics
        }
        $script = ConvertTo-RipwireLinuxPath (Join-Path $PSScriptRoot 'inspect-ripwire-wsl.sh') $config.distribution
        if ($script.State -ne 'Valid') {
            $checks.Add((New-RipwireDiagnostic pathTranslation $script.Code Failed 'Could not translate the inspection script.' 'Check the selected distribution and the package path.'))
            return Finish-Diagnostics
        }
        $inspection = Invoke-RipwireNativeCommand wsl.exe @('--distribution', $config.distribution, '--exec',
            '/bin/bash', '--', $script.LinuxPath, $config.binaryPath, $config.cacheRoot, $config.releaseVersion)
        if ($inspection.State -ne [RipwireCommandResultKind]::Success) {
            $checks.Add((New-RipwireDiagnostic installation RIPWIRE_WSL_INSTALLATION_NOT_READY Failed `
                ([Text.Encoding]::UTF8.GetString($inspection.Stderr).Trim()) 'Inspect binary/cache paths, permissions, and version; rerun explicit setup if needed.'))
            return Finish-Diagnostics
        }
        $decoded = ConvertFrom-RipwireUtf8 $inspection.Stdout
        if ($decoded.State -ne 'Valid') { throw $decoded.Message }
        $observed = $decoded.Text | ConvertFrom-Json -AsHashtable
        if ($observed -isnot [Collections.IDictionary] -or $observed.binaryReady -cne $true -or
            $observed.cacheRootReady -cne $true -or $observed.cacheBytes -isnot [long] -or $observed.cacheBytes -lt 0) {
            throw 'RIPWIRE_WSL_INVALID_INSPECTION_OUTPUT'
        }
        $details.binaryPath = $config.binaryPath
        $details.cacheRoot = $config.cacheRoot
        $details.cacheBytes = $observed.cacheBytes
        $checks.Add((New-RipwireDiagnostic installation RIPWIRE_WSL_BINARY_READY Ready 'Installed executable reports the pinned version.'))
        $checks.Add((New-RipwireDiagnostic cache RIPWIRE_WSL_CACHE_ROOT_READY Ready 'Cache root is private, Linux-native, and separate from installation.'))
        $checks.Add((New-RipwireDiagnostic binaryDigest RIPWIRE_WSL_BINARY_DIGEST_UNDECLARED Skipped `
            'The manifest declares an archive digest, not a binary digest; binary bytes were not compared to the archive hash.'))
        if ($WorktreePath) {
            $context = New-RipwireWorktreeLaunchContext -WorktreePath $WorktreePath -Configuration $config `
                -Manifest $manifest.Manifest -BootstrapWindowsPath (Join-Path $PSScriptRoot 'invoke-ripwire-wsl.sh') `
                -ParentEnvironment (Get-RipwireCurrentEnvironment) -Operation diagnostic
            if ($context.State -ne 'Valid') {
                $checks.Add((New-RipwireDiagnostic worktree $context.Code Failed 'Worktree discovery, translation, or cache containment failed.' 'Confirm the exact Windows worktree root and configuration.'))
                return Finish-Diagnostics
            }
            $result = Invoke-RipwireNativeCommand $context.WslFilePath $context.WslArguments $context.ChildEnvironment
            if ($result.State -ne [RipwireCommandResultKind]::Success) {
                $checks.Add((New-RipwireDiagnostic worktree RIPWIRE_WSL_WORKTREE_DIAGNOSTIC_FAILED Failed `
                    ([Text.Encoding]::UTF8.GetString($result.Stderr).Trim()) 'Correct the reported cache or worktree boundary.'))
                return Finish-Diagnostics
            }
            $text = ConvertFrom-RipwireUtf8 $result.Stdout
            if ($text.State -ne 'Valid') { throw $text.Message }
            $rootReport = $text.Text | ConvertFrom-Json -AsHashtable
            if ($rootReport.root -cne $context.LinuxRoot -or $rootReport.gitDirectory -cne $context.LinuxGitDirectory -or
                $rootReport.commonDirectory -cne $context.LinuxCommonDirectory -or $rootReport.cacheReady -isnot [bool]) {
                throw 'RIPWIRE_WSL_DIAGNOSTIC_IDENTITY_MISMATCH'
            }
            $details.worktree = $rootReport
            $checks.Add((New-RipwireDiagnostic worktree RIPWIRE_WSL_WORKTREE_READY Ready 'Windows and Linux worktree/Git identities agree.'))
            if ($rootReport.cacheReady) {
                $checks.Add((New-RipwireDiagnostic cacheNamespace RIPWIRE_WSL_CACHE_NAMESPACE_READY Ready $rootReport.cacheNamespace))
            } else {
                $checks.Add((New-RipwireDiagnostic cacheNamespace RIPWIRE_WSL_CACHE_FIRST_USE Warning `
                    'The namespace does not exist yet; analysis creates it on first use.' 'No action required. Diagnostics did not create it.'))
            }
        } else {
            $checks.Add((New-RipwireDiagnostic worktree RIPWIRE_WSL_WORKTREE_NOT_REQUESTED Skipped 'Supply -WorktreePath to inspect worktree identity and its cache namespace.'))
        }
    } catch {
        $checks.Add((New-RipwireDiagnostic diagnostics RIPWIRE_WSL_DIAGNOSTICS_FAILED Failed $_.Exception.Message 'Resolve the reported failure and rerun the doctor.'))
    }
    Finish-Diagnostics
}
