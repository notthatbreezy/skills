[CmdletBinding()]
param(
    [ValidateRange(1, 20)]
    [int] $Samples = 3,

    [ValidateRange(0, 3600)]
    [int] $IntervalSeconds = 30,

    [ValidateRange(1, 120)]
    [int] $TimeoutSeconds = 10,

    [switch] $IncludeValues,

    [switch] $SelfTest
)

$ErrorActionPreference = "Stop"

function Test-PublicUnicastIpv4 {
    param([Parameter(Mandatory)] [string] $Text)

    $trimmed = $Text.Trim()
    if ($trimmed -notmatch "^(?:0|[1-9]\d{0,2})(?:\.(?:0|[1-9]\d{0,2})){3}$") {
        return $false
    }

    $address = $null
    if (-not [Net.IPAddress]::TryParse($trimmed, [ref] $address) -or
        $address.AddressFamily -ne [Net.Sockets.AddressFamily]::InterNetwork) {
        return $false
    }

    $octets = $address.GetAddressBytes()
    $first = $octets[0]
    $second = $octets[1]

    if ($first -eq 0 -or $first -eq 10 -or $first -eq 127 -or $first -ge 224) {
        return $false
    }
    if ($first -eq 100 -and $second -ge 64 -and $second -le 127) {
        return $false
    }
    if ($first -eq 169 -and $second -eq 254) {
        return $false
    }
    if ($first -eq 172 -and $second -ge 16 -and $second -le 31) {
        return $false
    }
    if ($first -eq 192 -and ($second -eq 0 -or $second -eq 168)) {
        return $false
    }
    if ($first -eq 198 -and ($second -eq 18 -or $second -eq 19)) {
        return $false
    }

    return $true
}

function Get-StabilitySummary {
    param(
        [Parameter(Mandatory)] [object[]] $Observations,
        [Parameter(Mandatory)] [int] $RequestCount,
        [Parameter(Mandatory)] [int] $Timeout,
        [bool] $IncludeRawValues = $false,
        [hashtable] $ProxyUsedByEndpoint = @{}
    )

    $slotAUnique = @($Observations | ForEach-Object { $_.slotA } | Select-Object -Unique).Count
    $slotBUnique = @($Observations | ForEach-Object { $_.slotB } | Select-Object -Unique).Count
    $allSamplesValid = -not ($Observations | ForEach-Object {
            $_.slotAValid -and $_.slotBValid
        } | Where-Object { -not $_ } | Select-Object -First 1)
    $distinct = -not ($Observations | ForEach-Object {
            $_.slotA -cne $_.slotB
        } | Where-Object { -not $_ } | Select-Object -First 1)
    $stable = $allSamplesValid -and $distinct -and $slotAUnique -eq 1 -and $slotBUnique -eq 1

    $perSample = @($Observations | ForEach-Object {
            $item = [ordered] @{
                offsetSeconds = $_.offsetSeconds
                slotAValid = $_.slotAValid
                slotBValid = $_.slotBValid
                slotAStatus = $_.slotAStatus
                slotBStatus = $_.slotBStatus
                pairDistinct = $_.slotA -cne $_.slotB
            }
            if ($IncludeRawValues) {
                $item.slotA = $_.slotA
                $item.slotB = $_.slotB
            }
            [pscustomobject] $item
        })

    [pscustomobject] @{
        sampleOffsetsSeconds = @($Observations | ForEach-Object { $_.offsetSeconds })
        requestCount = $RequestCount
        requestsPerEndpoint = $Observations.Count
        timeoutSecondsPerRequest = $Timeout
        retries = 0
        httpStack = ".NET HttpClient/HttpClientHandler from PowerShell"
        powershellVersion = $PSVersionTable.PSVersion.ToString()
        dotnetVersion = [Environment]::Version.ToString()
        redirectsAllowed = $false
        redirectObserved = [bool]($Observations | Where-Object {
                $_.slotARedirect -or $_.slotBRedirect
            } | Select-Object -First 1)
        cacheControl = "no-cache, no-store"
        applicationCache = $false
        fallbackEndpoints = 0
        proxyMode = "ambient Windows/default proxy enabled with default credentials"
        proxyUsedByEndpoint = $ProxyUsedByEndpoint
        proxyEnvironmentPresent = [ordered] @{
            HTTP_PROXY = [bool] $env:HTTP_PROXY
            HTTPS_PROXY = [bool] $env:HTTPS_PROXY
            ALL_PROXY = [bool] $env:ALL_PROXY
            NO_PROXY = [bool] $env:NO_PROXY
        }
        processContext = "same interactive user and process session; names omitted"
        networkChanges = $false
        vpnChanges = $false
        vpnStateInspected = $false
        endpointUniqueCountCategories = [ordered] @{
            slotA = $slotAUnique
            slotB = $slotBUnique
        }
        perSample = $perSample
        allSamplesValid = $allSamplesValid
        distinct = $distinct
        stable = $stable
        azureCalls = 0
        filePersistence = $false
        valuesIncluded = $IncludeRawValues
        hashesEmitted = $false
    }
}

if ($SelfTest) {
    $fixtures = @(
        [pscustomobject] @{
            offsetSeconds = 0
            slotA = "8.8.8.8"
            slotB = "1.1.1.1"
            slotAValid = $true
            slotBValid = $true
            slotAStatus = 200
            slotBStatus = 200
            slotARedirect = $false
            slotBRedirect = $false
        },
        [pscustomobject] @{
            offsetSeconds = 30
            slotA = "8.8.8.8"
            slotB = "1.1.1.1"
            slotAValid = $true
            slotBValid = $true
            slotAStatus = 200
            slotBStatus = 200
            slotARedirect = $false
            slotBRedirect = $false
        },
        [pscustomobject] @{
            offsetSeconds = 60
            slotA = "8.8.8.8"
            slotB = "1.1.1.1"
            slotAValid = $true
            slotBValid = $true
            slotAStatus = 200
            slotBStatus = 200
            slotARedirect = $false
            slotBRedirect = $false
        }
    )

    if (-not (Test-PublicUnicastIpv4 "8.8.8.8") -or
        (Test-PublicUnicastIpv4 "10.0.0.1") -or
        (Test-PublicUnicastIpv4 "01.2.3.4")) {
        throw "IPv4 validator self-test failed."
    }

    $summary = Get-StabilitySummary -Observations $fixtures -RequestCount 6 -Timeout 10
    if (-not $summary.allSamplesValid -or -not $summary.distinct -or -not $summary.stable) {
        throw "Stability summary self-test failed."
    }

    [pscustomobject] @{
        selfTest = "PASS"
        validatorCases = 3
        stableFixture = $summary.stable
        valuesEmitted = $false
        networkCalls = 0
    } | ConvertTo-Json -Depth 4
    return
}

$endpoints = [ordered] @{
    slotA = "https://api.ipify.org"
    slotB = "https://ifconfig.me/ip"
}

$handler = [Net.Http.HttpClientHandler]::new()
$handler.AllowAutoRedirect = $false
$handler.UseProxy = $true
$handler.Proxy = [Net.WebRequest]::DefaultWebProxy
$handler.DefaultProxyCredentials = [Net.CredentialCache]::DefaultCredentials

$client = [Net.Http.HttpClient]::new($handler)
$client.Timeout = [TimeSpan]::FromSeconds($TimeoutSeconds)
$client.DefaultRequestHeaders.UserAgent.ParseAdd("stable-public-ip-sampler/1.0")
$client.DefaultRequestHeaders.CacheControl =
    [Net.Http.Headers.CacheControlHeaderValue]::Parse("no-cache, no-store")

$observations = @()
$start = [DateTimeOffset]::UtcNow

try {
    for ($index = 0; $index -lt $Samples; $index++) {
        $offset = $index * $IntervalSeconds
        $remaining = $offset - ([DateTimeOffset]::UtcNow - $start).TotalSeconds
        if ($remaining -gt 0) {
            Start-Sleep -Milliseconds ([int] [Math]::Ceiling($remaining * 1000))
        }

        $values = @{}
        $valid = @{}
        $statuses = @{}
        $redirects = @{}

        foreach ($slot in $endpoints.Keys) {
            $request = [Net.Http.HttpRequestMessage]::new(
                [Net.Http.HttpMethod]::Get,
                [Uri] $endpoints[$slot])
            try {
                $response = $client.SendAsync(
                    $request,
                    [Net.Http.HttpCompletionOption]::ResponseContentRead).GetAwaiter().GetResult()
                try {
                    $body = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult().Trim()
                    $values[$slot] = $body
                    $statuses[$slot] = [int] $response.StatusCode
                    $redirects[$slot] =
                        $response.StatusCode -ge 300 -and $response.StatusCode -lt 400
                    $valid[$slot] =
                        $response.IsSuccessStatusCode -and (Test-PublicUnicastIpv4 $body)
                }
                finally {
                    $response.Dispose()
                }
            }
            finally {
                $request.Dispose()
            }
        }

        $observations += [pscustomobject] @{
            offsetSeconds = $offset
            slotA = $values.slotA
            slotB = $values.slotB
            slotAValid = $valid.slotA
            slotBValid = $valid.slotB
            slotAStatus = $statuses.slotA
            slotBStatus = $statuses.slotB
            slotARedirect = $redirects.slotA
            slotBRedirect = $redirects.slotB
        }
    }

    $proxyUsed = @{}
    foreach ($slot in $endpoints.Keys) {
        $endpoint = [Uri] $endpoints[$slot]
        $proxy = $handler.Proxy.GetProxy($endpoint)
        $proxyUsed[$slot] = [bool]($proxy -and $proxy.AbsoluteUri -cne $endpoint.AbsoluteUri)
    }

    Get-StabilitySummary `
        -Observations $observations `
        -RequestCount ($Samples * $endpoints.Count) `
        -Timeout $TimeoutSeconds `
        -IncludeRawValues $IncludeValues `
        -ProxyUsedByEndpoint $proxyUsed |
        ConvertTo-Json -Depth 7
}
finally {
    $client.Dispose()
    $handler.Dispose()
}
