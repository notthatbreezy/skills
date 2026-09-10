function Invoke-RipwireConfiguredOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $WorktreePath,
        [string] $ConfigPath,
        [AllowEmptyCollection()][AllowEmptyString()][string[]] $RipwireArguments = @(),
        [ValidateSet('analysis', 'clear')][string] $Operation = 'analysis'
    )
    try {
        $manifestResult = Read-RipwireReleaseManifest (Join-Path $PSScriptRoot '..\references\release.json')
        if ($manifestResult.State -ne [RipwireManifestState]::Valid) {
            [Console]::Error.WriteLine("$($manifestResult.Code): $($manifestResult.Message)")
            return 78
        }
        # Reject unsupported requests before reading configuration or invoking discovery/WSL.
        $invocation = Classify-RipwireInvocation $RipwireArguments $manifestResult.Manifest
        if ($invocation.State -notin @([RipwireInvocationKind]::AllowedDefaultMap, [RipwireInvocationKind]::AllowedAnalysis)) {
            [Console]::Error.WriteLine("$($invocation.Code): $($invocation.Argument)")
            return $invocation.ExitCode
        }
        if ([string]::IsNullOrEmpty($ConfigPath)) { $ConfigPath = Get-RipwireDefaultConfigPath }
        $config = Read-RipwireConfiguration $ConfigPath $manifestResult.Manifest
        if ($config.State -ne [RipwireConfigurationState]::Valid) {
            [Console]::Error.WriteLine("$($config.Code): $($config.Message) Run the toolkit doctor and explicit setup.")
            return 78
        }
        $context = New-RipwireWorktreeLaunchContext -WorktreePath $WorktreePath `
            -RipwireArguments $RipwireArguments -Configuration $config.Configuration `
            -Manifest $manifestResult.Manifest -BootstrapWindowsPath (Join-Path $PSScriptRoot 'invoke-ripwire-wsl.sh') `
            -ParentEnvironment (Get-RipwireCurrentEnvironment) -Operation $Operation
        if ($context.State -ne 'Valid') {
            [Console]::Error.WriteLine("$($context.Code): $($context | ConvertTo-Json -Depth 6 -Compress)")
            return 78
        }
        $result = Invoke-RipwireNativeCommand -FilePath $context.WslFilePath -Arguments $context.WslArguments `
            -Environment $context.ChildEnvironment -Mode Streaming -TimeoutSeconds 3600
        switch ($result.State) {
            ([RipwireCommandResultKind]::Success) { return $result.ExitCode }
            ([RipwireCommandResultKind]::NonZero) { return $result.ExitCode }
            ([RipwireCommandResultKind]::Unavailable) {
                [Console]::Error.WriteLine("RIPWIRE_WSL_START_FAILED: $($result.Message)")
                return 127
            }
            ([RipwireCommandResultKind]::TimedOut) {
                [Console]::Error.WriteLine("RIPWIRE_WSL_COMMAND_TIMED_OUT: $($result.Message)")
                return 124
            }
            default {
                [Console]::Error.WriteLine("RIPWIRE_WSL_TRANSPORT_FAILED: $($result.Message)")
                return 70
            }
        }
    } catch {
        [Console]::Error.WriteLine("RIPWIRE_WSL_PREFLIGHT_FAILED: $($_.Exception.Message)")
        return 78
    }
}
