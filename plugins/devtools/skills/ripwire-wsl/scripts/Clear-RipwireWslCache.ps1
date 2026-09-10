[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $WorktreePath,
    [string] $ConfigPath
)
if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Console]::Error.WriteLine('RIPWIRE_WSL_UNSUPPORTED_RUNTIME')
    exit 78
}
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'RipwireWsl.Common.ps1')
. (Join-Path $PSScriptRoot 'RipwireWsl.Entry.ps1')
exit (Invoke-RipwireConfiguredOperation -WorktreePath $WorktreePath -ConfigPath $ConfigPath -Operation clear)
