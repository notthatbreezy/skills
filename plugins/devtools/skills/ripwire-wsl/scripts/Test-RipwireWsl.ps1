[CmdletBinding()]
param([string] $ConfigPath, [string] $WorktreePath, [switch] $Json)
if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Console]::Error.WriteLine('RIPWIRE_WSL_UNSUPPORTED_RUNTIME')
    exit 78
}
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'RipwireWsl.Common.ps1')
. (Join-Path $PSScriptRoot 'RipwireWsl.Setup.ps1')
. (Join-Path $PSScriptRoot 'RipwireWsl.Diagnostics.ps1')
$report = Invoke-RipwireDiagnostics -ConfigPath $ConfigPath -WorktreePath $WorktreePath
if ($Json) { $report | ConvertTo-Json -Depth 10 }
else { $report.checks | Format-Table layer, status, code, message, remediation -Wrap }
if ($report.status -eq 'Failed') { exit 1 }
exit 0
