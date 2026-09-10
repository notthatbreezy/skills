[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repository = Split-Path -Parent $PSScriptRoot
$staging = Join-Path ([IO.Path]::GetTempPath()) ('ripwire-package-' + [Guid]::NewGuid().ToString('N'))
function Require([bool] $Condition, [string] $Message) { if (-not $Condition) { throw $Message } }
try {
    $null = New-Item -ItemType Directory -Path $staging
    Copy-Item -LiteralPath (Join-Path $repository 'plugins\devtools') -Destination $staging -Recurse
    $pluginRoot = Join-Path $staging 'devtools'
    $plugin = Get-Content -LiteralPath (Join-Path $pluginRoot 'plugin.json') -Raw | ConvertFrom-Json
    $marketplace = Get-Content -LiteralPath (Join-Path $repository '.github\plugin\marketplace.json') -Raw | ConvertFrom-Json
    Require ($plugin.version -ceq $marketplace.metadata.version -and
        $plugin.version -ceq $marketplace.plugins[0].version) 'Plugin and marketplace versions differ'
    Require (@($plugin.skills | Where-Object { $_ -ceq 'skills/ripwire-wsl' }).Count -eq 1) 'Skill must be registered exactly once'
    foreach ($skill in $plugin.skills) {
        $path = Join-Path $pluginRoot ($skill.Replace('/', '\') + '\SKILL.md')
        Require (Test-Path -LiteralPath $path -PathType Leaf) "Unresolvable staged skill: $skill"
        $text = Get-Content -LiteralPath $path -Raw
        Require ($text -match '(?s)\A---\r?\n.*?\r?\n---') "Missing staged skill frontmatter: $skill"
    }
    foreach ($agent in $plugin.agents) {
        Require (Test-Path -LiteralPath (Join-Path $pluginRoot $agent.Replace('/', '\')) -PathType Leaf) "Unresolvable staged agent: $agent"
    }
    $package = Join-Path $pluginRoot 'skills\ripwire-wsl'
    $skillText = Get-Content -LiteralPath (Join-Path $package 'SKILL.md') -Raw
    Require ($skillText -match '(?m)^name: ripwire-wsl\r?$' -and $skillText -match '(?m)^description: .+') 'Invalid Ripwire frontmatter'
    foreach ($file in @('Invoke-RipwireWsl.ps1','Install-RipwireWsl.ps1','Test-RipwireWsl.ps1','Clear-RipwireWslCache.ps1')) {
        Require (Test-Path -LiteralPath (Join-Path $package "scripts\$file") -PathType Leaf) "Missing public script: $file"
    }
    foreach ($file in @('references\release.json','evals\evals.json')) {
        $null = Get-Content -LiteralPath (Join-Path $package $file) -Raw | ConvertFrom-Json
    }
    Write-Output 'Passed staged plugin discovery and version checks without Copilot configuration access.'
} finally {
    if (Test-Path -LiteralPath $staging) { Remove-Item -LiteralPath $staging -Recurse -Force }
}
