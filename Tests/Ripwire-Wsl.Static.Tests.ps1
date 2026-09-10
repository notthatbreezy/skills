[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$package = Join-Path (Split-Path -Parent $PSScriptRoot) 'plugins\devtools\skills\ripwire-wsl'
function Assert-Static([bool] $Condition, [string] $Message) {
    if (-not $Condition) { throw "ASSERTION_FAILED: $Message" }
}
foreach ($relative in @('SKILL.md', 'references\guide.md', 'references\release.json',
    'evals\evals.json', 'scripts\RipwireWsl.Common.ps1', 'scripts\invoke-ripwire-wsl.sh')) {
    Assert-Static (Test-Path -LiteralPath (Join-Path $package $relative) -PathType Leaf) "Packaged $relative exists"
}
foreach ($relative in @('references\release.json', 'evals\evals.json')) {
    $null = Get-Content -LiteralPath (Join-Path $package $relative) -Raw | ConvertFrom-Json
}
$skill = Get-Content -LiteralPath (Join-Path $package 'SKILL.md') -Raw
Assert-Static ($skill -match '(?s)\A---\r?\nname: ripwire-wsl\r?\ndescription: [^\r\n]+\r?\n---') 'Skill frontmatter'
Assert-Static ($skill -match 'references/guide\.md') 'Skill discloses guide'
$evals = Get-Content -LiteralPath (Join-Path $package 'evals\evals.json') -Raw | ConvertFrom-Json
Assert-Static ($evals.skill_name -ceq 'ripwire-wsl' -and $evals.evals.Count -ge 5) 'Substantive evaluation cases'
foreach ($file in Get-ChildItem -LiteralPath $package -Recurse -File) {
    $text = [IO.File]::ReadAllText($file.FullName)
    Assert-Static ($text -notmatch '(?i)[A-Z]:[\\/](?:Users|Projects)[\\/]|brownch-microsoft-ripwire|agency[\\/]2026') `
        "No host/session-specific path in $($file.Name)"
    if ($file.Extension -eq '.sh') {
        Assert-Static (-not ([IO.File]::ReadAllBytes($file.FullName) -contains 13)) "LF-only $($file.Name)"
    }
    if ($file.Extension -eq '.ps1') {
        $tokens = $null
        $errors = $null
        $null = [Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref] $tokens, [ref] $errors)
        Assert-Static (@($errors).Count -eq 0) "Parseable PowerShell $($file.Name): $errors"
    }
}
Write-Output 'Passed Ripwire static package checks (no WSL, configuration, or network access).'
