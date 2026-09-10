# Test-only process boundary; not the public Ripwire launcher.
Set-StrictMode -Version Latest

class ProbeProcessResult {
    [int] $ExitCode
    [byte[]] $Stdout
    [byte[]] $Stderr

    [string] OutputText() { return [Text.Encoding]::UTF8.GetString($this.Stdout) }
    [string] ErrorText() { return [Text.Encoding]::UTF8.GetString($this.Stderr) }
}

function Invoke-ProbeProcess {
    param(
        [Parameter(Mandatory)][string] $FilePath,
        [AllowEmptyCollection()][AllowEmptyString()][string[]] $Arguments = @(),
        [hashtable] $Environment = @{},
        [ValidateRange(1, 600)][int] $TimeoutSeconds = 60
    )

    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = $FilePath
    $start.UseShellExecute = $false
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    foreach ($argument in $Arguments) { $start.ArgumentList.Add($argument) }
    foreach ($name in $Environment.Keys) {
        if ($null -eq $Environment[$name]) {
            $null = $start.Environment.Remove($name)
        } else {
            $start.Environment[$name] = [string] $Environment[$name]
        }
    }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $start
    $stdout = [IO.MemoryStream]::new()
    $stderr = [IO.MemoryStream]::new()
    try {
        if (-not $process.Start()) { throw 'PROBE_START_FAILED' }
        $outPump = $process.StandardOutput.BaseStream.CopyToAsync($stdout)
        $errPump = $process.StandardError.BaseStream.CopyToAsync($stderr)
        $completion = [Threading.Tasks.Task]::WhenAll(
            [Threading.Tasks.Task[]] @($process.WaitForExitAsync(), $outPump, $errPump))
        if (-not $completion.Wait($TimeoutSeconds * 1000)) {
            $process.Kill($true)
            $process.WaitForExit()
            throw "PROBE_TIMED_OUT: $FilePath"
        }
        $result = [ProbeProcessResult]::new()
        $result.ExitCode = $process.ExitCode
        $result.Stdout = $stdout.ToArray()
        $result.Stderr = $stderr.ToArray()
        return $result
    } finally {
        $process.Dispose()
        $stdout.Dispose()
        $stderr.Dispose()
    }
}

function New-ProbeEnvironment {
    param(
        [Parameter(Mandatory)][hashtable] $Variables,
        [AllowEmptyString()][string] $Wslenv = '',
        [AllowEmptyString()][string] $GitConfigCount = '',
        [hashtable] $GitConfigEntries = @{}
    )

    $names = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $tokens = [Collections.Generic.List[string]]::new()
    foreach ($token in ($Wslenv -split ':')) {
        if ($token -eq '' -and $Wslenv -eq '') { continue }
        if ($token -cnotmatch '^([A-Za-z_][A-Za-z0-9_]*)(/[pluw]+)?$') {
            throw "PROBE_INVALID_WSLENV: $token"
        }
        $name = $Matches[1]
        $flags = $Matches[2]
        if (-not $names.Add($name)) { throw "PROBE_DUPLICATE_WSLENV: $name" }
        if ($flags) {
            $letters = $flags.Substring(1).ToCharArray()
            if (@($letters | Select-Object -Unique).Count -ne $letters.Count -or
                ($flags.Contains('u') -and $flags.Contains('w'))) {
                throw "PROBE_INVALID_WSLENV_FLAGS: $token"
            }
        }
        $tokens.Add($token)
    }
    $count = 0
    if ($GitConfigCount -ne '' -and
        ($GitConfigCount -cnotmatch '^(0|[1-9][0-9]*)$' -or
         -not [int]::TryParse($GitConfigCount, [ref] $count))) {
        throw 'PROBE_INVALID_GIT_CONFIG_COUNT'
    }
    if ($GitConfigEntries.Count -ne 2 * $count) { throw 'PROBE_INVALID_GIT_CONFIG_ENTRIES' }
    $result = @{}
    foreach ($name in $Variables.Keys) { $result[$name] = $Variables[$name] }
    $result['GIT_CONFIG_COUNT'] = [string] $count
    for ($i = 0; $i -lt $count; $i++) {
        foreach ($part in @('KEY', 'VALUE')) {
            $name = "GIT_CONFIG_${part}_$i"
            if (-not $GitConfigEntries.ContainsKey($name) -or $null -eq $GitConfigEntries[$name]) {
                throw "PROBE_MISSING_GIT_CONFIG_ENTRY: $name"
            }
            if ($part -eq 'KEY' -and [string]::IsNullOrWhiteSpace($GitConfigEntries[$name])) {
                throw "PROBE_EMPTY_GIT_CONFIG_KEY: $name"
            }
            $result[$name] = $GitConfigEntries[$name]
        }
    }
    foreach ($name in @($result.Keys | Sort-Object)) {
        if ($names.Contains($name)) {
            if (-not $tokens.Contains("$name/u")) { throw "PROBE_CONFLICTING_WSLENV: $name" }
        } else {
            $tokens.Add("$name/u")
        }
    }
    $result['WSLENV'] = $tokens -join ':'
    return $result
}
