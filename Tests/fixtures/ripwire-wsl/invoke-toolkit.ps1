[CmdletBinding()]
param(
    [Parameter(Mandatory)][string] $Launcher,
    [Parameter(Mandatory)][string] $WorktreePath,
    [Parameter(Mandatory)][string] $ConfigPath,
    [string] $ArgumentsJson = '[]'
)
$ErrorActionPreference = 'Stop'
$arguments = ConvertFrom-Json -InputObject $ArgumentsJson -NoEnumerate
if ($arguments -isnot [array] -or @($arguments | Where-Object { $_ -isnot [string] }).Count) {
    throw 'Invalid test invocation arguments'
}
& $Launcher -WorktreePath $WorktreePath -ConfigPath $ConfigPath -RipwireArguments ([string[]] $arguments)
exit $LASTEXITCODE
