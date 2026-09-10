[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string] $Distribution,
    [string] $ConfigPath,
    [string] $LinuxInstallRoot,
    [string] $LinuxCacheRoot
)

if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Console]::Error.WriteLine('RIPWIRE_WSL_UNSUPPORTED_RUNTIME')
    exit 78
}

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'RipwireWsl.Common.ps1')
. (Join-Path $PSScriptRoot 'RipwireWsl.Setup.ps1')

try {
    $result = Invoke-RipwireWslInstall -Distribution $Distribution -ConfigPath $ConfigPath `
        -LinuxInstallRoot $LinuxInstallRoot -LinuxCacheRoot $LinuxCacheRoot
    Write-Output ("Installed Ripwire {0} for {1} ({2}) at {3}" -f
        $result.ReleaseVersion, $result.Distribution, $result.Architecture, $result.BinaryPath)
    if ($result.CleanupErrors.Count -gt 0) {
        foreach ($cleanupError in $result.CleanupErrors) {
            [Console]::Error.WriteLine("RIPWIRE_WSL_INSTALL_CLEANUP: $cleanupError")
        }
        exit 74
    }
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit $(if ($_.Exception.Data.Contains('ExitCode')) { [int] $_.Exception.Data['ExitCode'] } else { 1 })
}
