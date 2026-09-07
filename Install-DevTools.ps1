[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ -not [string]::IsNullOrWhiteSpace($_) })]
    [string] $MarketplaceSource = 'notthatbreezy/skills',

    [switch] $MigrateMarketplaceSource
)

$ErrorActionPreference = 'Stop'

$marketplaceName = 'brownch-devtools'
$pluginName = 'brownch-devtools'
$marketplaceWasReRegistered = $false

if (-not (Get-Command copilot -ErrorAction SilentlyContinue)) {
    throw 'GitHub Copilot CLI is required. Install or update it before running this installer.'
}

function Invoke-Copilot {
    param(
        [Parameter(Mandatory)]
        [string[]] $Arguments
    )

    & copilot @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Copilot command failed: copilot $($Arguments -join ' ')"
    }
}

$registeredMarketplaces = (& copilot plugin marketplace list 2>&1) -join [Environment]::NewLine
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to list registered Copilot plugin marketplaces.'
}

$marketplacePattern = "(?m)^\s*[^\r\n]*\b$([Regex]::Escape($marketplaceName))\b"
if ($registeredMarketplaces -match $marketplacePattern) {
    if ($MigrateMarketplaceSource) {
        # Re-registration is explicit because --force also uninstalls plugins from this marketplace.
        Invoke-Copilot -Arguments @('plugin', 'marketplace', 'remove', $marketplaceName, '--force')
        Invoke-Copilot -Arguments @('plugin', 'marketplace', 'add', $MarketplaceSource)
        $marketplaceWasReRegistered = $true
    } else {
        Invoke-Copilot -Arguments @('plugin', 'marketplace', 'update', $marketplaceName)
    }
} else {
    Invoke-Copilot -Arguments @('plugin', 'marketplace', 'add', $MarketplaceSource)
}

$installedPlugins = (& copilot plugin list 2>&1) -join [Environment]::NewLine
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to list installed Copilot plugins.'
}

$pluginPattern = "(?m)^\s*[^\r\n]*\b$([Regex]::Escape($pluginName))\b"
if (-not $marketplaceWasReRegistered -and $installedPlugins -match $pluginPattern) {
    Invoke-Copilot -Arguments @('plugin', 'update', $pluginName)
} else {
    Invoke-Copilot -Arguments @('plugin', 'install', "$pluginName@$marketplaceName")
}

Write-Host 'brownch-devtools is installed.' -ForegroundColor Green
Write-Host 'Start a new Copilot session or use /restart to load the updated plugin.'
