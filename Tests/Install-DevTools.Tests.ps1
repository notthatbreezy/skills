[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$installer = Join-Path $repositoryRoot 'Install-DevTools.ps1'
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ("skills-installer-tests-{0}" -f [Guid]::NewGuid())
$logPath = Join-Path $testRoot 'commands.log'
$existingCopilotFunction = Get-Command copilot -CommandType Function -ErrorAction SilentlyContinue

function Assert-Equal {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object] $Expected,

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object] $Actual,

        [Parameter(Mandatory)]
        [string] $Message
    )

    $expectedText = ($Expected -join [Environment]::NewLine)
    $actualText = ($Actual -join [Environment]::NewLine)
    if ($expectedText -cne $actualText) {
        throw "$Message`nExpected:`n$expectedText`nActual:`n$actualText"
    }
}

function Invoke-InstallerCase {
    param(
        [Parameter(Mandatory)]
        [string] $Name,

        [string] $MarketplaceList = '',

        [string] $PluginList = '',

        [string] $FailCommand = '',

        [string] $MarketplaceSource,

        [switch] $MigrateMarketplaceSource,

        [Parameter(Mandatory)]
        [int] $ExpectedExitCode,

        [switch] $ExpectParameterValidationFailure,

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]] $ExpectedCommands
    )

    Remove-Item -LiteralPath $logPath -Force -ErrorAction SilentlyContinue
    $env:COPILOT_MOCK_LOG = $logPath
    $env:COPILOT_MOCK_MARKETPLACES = $MarketplaceList
    $env:COPILOT_MOCK_PLUGINS = $PluginList
    $env:COPILOT_MOCK_FAIL = $FailCommand

    $installerParameters = @{}
    if ($PSBoundParameters.ContainsKey('MarketplaceSource')) {
        $installerParameters['MarketplaceSource'] = $MarketplaceSource
    }
    if ($MigrateMarketplaceSource) {
        $installerParameters['MigrateMarketplaceSource'] = $true
    }

    $failure = $null
    try {
        & $installer @installerParameters *> (Join-Path $testRoot "$Name.output")
        $exitCode = 0
    } catch {
        $failure = $_
        $_ | Out-File -LiteralPath (Join-Path $testRoot "$Name.output") -Append
        $exitCode = 1
    }
    $commands = @(
        if (Test-Path -LiteralPath $logPath) {
            Get-Content -LiteralPath $logPath
        }
    )

    Assert-Equal -Expected $ExpectedExitCode -Actual $exitCode -Message "$Name exit code mismatch."
    Assert-Equal -Expected $ExpectedCommands -Actual $commands -Message "$Name command sequence mismatch."
    if ($ExpectParameterValidationFailure) {
        Assert-Equal -Expected 'System.Management.Automation.ParameterBindingValidationException' `
            -Actual $failure.Exception.GetType().FullName `
            -Message "$Name must fail parameter validation."
    }
}

try {
    New-Item -ItemType Directory -Path $testRoot | Out-Null
    function global:copilot {
        $command = $args -join ' '
        Add-Content -LiteralPath $env:COPILOT_MOCK_LOG -Value $command

        if ($command -eq $env:COPILOT_MOCK_FAIL) {
            $global:LASTEXITCODE = 7
            Write-Output "Mock failure: $command"
            return
        }

        $global:LASTEXITCODE = 0
        if ($command -eq 'plugin marketplace list') {
            Write-Output $env:COPILOT_MOCK_MARKETPLACES
        } elseif ($command -eq 'plugin list') {
            Write-Output $env:COPILOT_MOCK_PLUGINS
        }
    }

    Invoke-InstallerCase -Name 'fresh-install' -ExpectedExitCode 0 -ExpectedCommands @(
        'plugin marketplace list'
        'plugin marketplace add notthatbreezy/skills'
        'plugin list'
        'plugin install brownch-devtools@brownch-devtools'
    )

    Invoke-InstallerCase -Name 'existing-update' `
        -MarketplaceList 'brownch-devtools  former/source' `
        -PluginList 'brownch-devtools@brownch-devtools  1.3.0' `
        -ExpectedExitCode 0 `
        -ExpectedCommands @(
            'plugin marketplace list'
            'plugin marketplace update brownch-devtools'
            'plugin list'
            'plugin update brownch-devtools'
        )

    Invoke-InstallerCase -Name 'explicit-migration' `
        -MarketplaceList 'brownch-devtools  former/source' `
        -PluginList '' `
        -MigrateMarketplaceSource `
        -ExpectedExitCode 0 `
        -ExpectedCommands @(
            'plugin marketplace list'
            'plugin marketplace remove brownch-devtools --force'
            'plugin marketplace add notthatbreezy/skills'
            'plugin list'
            'plugin install brownch-devtools@brownch-devtools'
        )

    Invoke-InstallerCase -Name 'local-development' `
        -MarketplaceList 'brownch-devtools  notthatbreezy/skills' `
        -PluginList '' `
        -MarketplaceSource 'C:\workspace\skills' `
        -MigrateMarketplaceSource `
        -ExpectedExitCode 0 `
        -ExpectedCommands @(
            'plugin marketplace list'
            'plugin marketplace remove brownch-devtools --force'
            'plugin marketplace add C:\workspace\skills'
            'plugin list'
            'plugin install brownch-devtools@brownch-devtools'
        )

    Invoke-InstallerCase -Name 'list-failure' `
        -FailCommand 'plugin marketplace list' `
        -ExpectedExitCode 1 `
        -ExpectedCommands @('plugin marketplace list')

    Invoke-InstallerCase -Name 'migration-add-failure' `
        -MarketplaceList 'brownch-devtools  former/source' `
        -FailCommand 'plugin marketplace add notthatbreezy/skills' `
        -MigrateMarketplaceSource `
        -ExpectedExitCode 1 `
        -ExpectedCommands @(
            'plugin marketplace list'
            'plugin marketplace remove brownch-devtools --force'
            'plugin marketplace add notthatbreezy/skills'
        )

    foreach ($source in @(
        @{ Name = 'null'; Value = $null }
        @{ Name = 'empty'; Value = '' }
        @{ Name = 'spaces'; Value = '   ' }
        @{ Name = 'whitespace'; Value = "`t`r`n" }
    )) {
        foreach ($migrate in @($false, $true)) {
            Invoke-InstallerCase -Name "invalid-source-$($source.Name)-migrate-$migrate" `
                -MarketplaceList $(if ($migrate) { 'brownch-devtools  former/source' } else { '' }) `
                -MarketplaceSource $source.Value `
                -MigrateMarketplaceSource:$migrate `
                -ExpectedExitCode 1 `
                -ExpectParameterValidationFailure `
                -ExpectedCommands @()
        }
    }

    Write-Host 'Install-DevTools.ps1 tests passed.'
} finally {
    if ($existingCopilotFunction) {
        Set-Item Function:\global:copilot -Value $existingCopilotFunction.ScriptBlock
    } else {
        Remove-Item Function:\global:copilot -ErrorAction SilentlyContinue
    }
    Remove-Item Env:COPILOT_MOCK_LOG, Env:COPILOT_MOCK_MARKETPLACES, Env:COPILOT_MOCK_PLUGINS, Env:COPILOT_MOCK_FAIL -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
