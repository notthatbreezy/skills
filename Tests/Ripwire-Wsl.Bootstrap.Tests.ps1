[CmdletBinding()]
param([Parameter(Mandatory)][string] $Distribution)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'fixtures\ripwire-wsl\ProbeProcess.ps1')
$repo = Split-Path -Parent $PSScriptRoot
$fixture = '/tmp/ripwire-bootstrap.' + [Guid]::NewGuid().ToString('N')
$created = $false
$holder = $null
function Run-Wsl([string[]] $Arguments, [hashtable] $Environment = @{}) {
    Invoke-ProbeProcess 'wsl.exe' (@('--distribution', $Distribution, '--exec') + $Arguments) $Environment
}
function Text($Result) {
    if ($Result.ExitCode -ne 0) { throw "Bootstrap test command failed: $($Result.ErrorText())" }
    $Result.OutputText().Trim()
}
function Equal($Expected, $Actual, [string] $Label) {
    if ($Expected -cne $Actual) { throw "ASSERTION_FAILED: $Label ($Expected != $Actual)" }
}
function Linux([string] $Path) { Text (Run-Wsl @('wslpath', '-a', '-u', '--', $Path)) }
try {
    $shell = Linux (Join-Path $repo 'plugins\devtools\skills\ripwire-wsl\scripts\invoke-ripwire-wsl.sh')
    $target = Linux (Join-Path $PSScriptRoot 'fixtures\ripwire-wsl\bootstrap-target.sh')
    $probe = Linux (Join-Path $PSScriptRoot 'fixtures\ripwire-wsl\probe.py')
    $foreignStat = Linux (Join-Path $PSScriptRoot 'fixtures\ripwire-wsl\foreign-owner-stat.sh')
    $failClear = Linux (Join-Path $PSScriptRoot 'fixtures\ripwire-wsl\fail-clear.sh')
    $null = Text (Run-Wsl @('mkdir', '-m', '700', '--', $fixture))
    $created = $true
    $cache = "$fixture/cache"
    $null = Text (Run-Wsl @('mkdir', '-m', '700', '--', $cache, "$fixture/project", "$fixture/git", "$fixture/bin"))
    $key = 'a' * 64
    $namespace = "$cache/releases/v0.5.0/x64/$key"
    $variables = @{
        GIT_DIR = "$fixture/git"; GIT_COMMON_DIR = "$fixture/git"; GIT_WORK_TREE = "$fixture/project"
        RIPWIRE_BIN = $target; RIPWIRE_WSL_DIAGNOSTIC = '1'; RIPWIRE_WSL_OPERATION = 'diagnostic'; GIT_OPTIONAL_LOCKS = '0'
        TMPDIR = "$namespace/tmp"; XDG_CACHE_HOME = "$namespace/xdg"
        RIPWIRE_WSL_LOCK_TIMEOUT_SECONDS = '1'
    }
    $child = New-ProbeEnvironment $variables '' '0' @{}
    $before = Text (Run-Wsl @('python3', $probe, 'snapshot', $fixture))
    $diagnostic = Text (Run-Wsl @('/bin/bash', '--', $shell, '--', "$fixture/project") $child) | ConvertFrom-Json
    Equal $false $diagnostic.cacheReady 'First-use diagnostic is not ready'
    Equal 2 $diagnostic.gitConfigCount 'Safety overrides appended to empty block'
    Equal $before (Text (Run-Wsl @('python3', $probe, 'snapshot', $fixture))) 'Diagnostic does not create cache or lock'
    $child.RIPWIRE_WSL_DIAGNOSTIC = '0'
    $child.RIPWIRE_WSL_OPERATION = 'analysis'
    # Execute a test-only target through Bash without relying on NTFS executable bits.
    $nativeTarget = "$fixture/bin/target"
    $null = Text (Run-Wsl @('cp', '--', $target, $nativeTarget))
    $null = Text (Run-Wsl @('chmod', '700', '--', $nativeTarget))
    $child.RIPWIRE_BIN = $nativeTarget
    $context = Text (Run-Wsl @('/bin/bash', '--', $shell, '--', "$fixture/project", $probe, 'bootstrap-context') $child) | ConvertFrom-Json
    Equal "$fixture/project" $context.environment.GIT_WORK_TREE 'Child worktree identity'
    Equal 'diff.autoRefreshIndex' $context.environment.GIT_CONFIG_KEY_0 'Child index-refresh override'
    Equal 'false' $context.environment.GIT_CONFIG_VALUE_0 'Child index refresh is disabled'
    Equal 'core.fsmonitor' $context.environment.GIT_CONFIG_KEY_1 'Child final fsmonitor override'
    Equal 'false' $context.environment.GIT_CONFIG_VALUE_1 'Child fsmonitor is disabled'
    $null = Text (Run-Wsl @('chmod', '755', '--', "$namespace/tmp"))
    $rejected = Run-Wsl @('/bin/bash', '--', $shell, '--', "$fixture/project", $probe, 'bootstrap-context') $child
    Equal 70 $rejected.ExitCode 'Reject unsafe permissions instead of adopting them'
    $null = Text (Run-Wsl @('chmod', '700', '--', "$namespace/tmp"))
    $null = Text (Run-Wsl @('mv', '--', "$namespace/tmp", "$namespace/tmp.saved"))
    $null = Text (Run-Wsl @('ln', '-s', '--', "$fixture/project", "$namespace/tmp"))
    $rejected = Run-Wsl @('/bin/bash', '--', $shell, '--', "$fixture/project", $probe, 'bootstrap-context') $child
    Equal 70 $rejected.ExitCode 'Reject cache symlink escaping namespace'
    $null = Text (Run-Wsl @('rm', '--', "$namespace/tmp"))
    $null = Text (Run-Wsl @('mv', '--', "$namespace/tmp.saved", "$namespace/tmp"))
    $null = Text (Run-Wsl @('mkdir', '-m', '700', '--', "$fixture/mockbin"))
    $null = Text (Run-Wsl @('cp', '--', $foreignStat, "$fixture/mockbin/stat"))
    $null = Text (Run-Wsl @('chmod', '700', '--', "$fixture/mockbin/stat"))
    $rejected = Run-Wsl @('/usr/bin/env', "PATH=$fixture/mockbin`:/usr/bin:/bin", '/bin/bash', '--',
        $shell, '--', "$fixture/project", $probe, 'bootstrap-context') $child
    Equal 70 $rejected.ExitCode 'Reject foreign ownership observation from native stat shim'
    if ($rejected.ErrorText() -notmatch 'CACHE_OWNER_MISMATCH') { throw 'Expected explicit foreign-owner rejection' }
    $lock = "$cache/locks/v0.5.0/x64/$key.lock"
    $null = Text (Run-Wsl @('rm', '--', $lock))
    $null = Text (Run-Wsl @('ln', '-s', '--', "$fixture/sentinel", $lock))
    $rejected = Run-Wsl @('/bin/bash', '--', $shell, '--', "$fixture/project", $probe, 'bootstrap-context') $child
    Equal 70 $rejected.ExitCode 'Reject linked lock file'
    Equal 1 (Run-Wsl @('test', '-e', "$fixture/sentinel")).ExitCode 'Lock link target untouched'
    $null = Text (Run-Wsl @('rm', '--', $lock))
    $child.RIPWIRE_WSL_OPERATION = 'clear'
    $null = Text (Run-Wsl @('mkdir', '-m', '700', '--', "$fixture/failbin"))
    $null = Text (Run-Wsl @('cp', '--', $failClear, "$fixture/failbin/rm"))
    $null = Text (Run-Wsl @('chmod', '700', '--', "$fixture/failbin/rm"))
    $failedClear = Run-Wsl @('/usr/bin/env', "PATH=$fixture/failbin`:/usr/bin:/bin", '/bin/bash', '--',
        $shell, '--', "$fixture/project") $child
    Equal 91 $failedClear.ExitCode 'Deletion failure remains explicit'
    Equal 0 (Run-Wsl @('test', '-d', $namespace)).ExitCode 'Failed clear preserves namespace'
    $holder = [Diagnostics.Process]::new()
    $holder.StartInfo.FileName = 'wsl.exe'
    $holder.StartInfo.UseShellExecute = $false
    foreach ($argument in @('--distribution', $Distribution, '--exec', 'flock', '-x', $lock,
        '/bin/bash', '-c', 'touch -- "$1"; sleep 6', '_', "$fixture/lock-ready")) {
        $holder.StartInfo.ArgumentList.Add($argument)
    }
    if (-not $holder.Start()) { throw 'Failed to start lock holder' }
    $ready = $false
    for ($attempt=0; $attempt -lt 20; $attempt++) {
        if ((Run-Wsl @('test', '-f', "$fixture/lock-ready")).ExitCode -eq 0) { $ready=$true; break }
        Start-Sleep -Milliseconds 100
    }
    if (-not $ready) { throw 'Lock holder did not become ready' }
    $contended = Run-Wsl @('/bin/bash', '--', $shell, '--', "$fixture/project") $child
    Equal 75 $contended.ExitCode 'Clear cannot delete data under active namespace lock'
    Equal 0 (Run-Wsl @('test', '-d', $namespace)).ExitCode 'Contended clear preserves namespace'
    if (-not $holder.WaitForExit(10000)) { throw 'Lock holder failed to finish' }
    $null = Text (Run-Wsl @('/bin/bash', '--', $shell, '--', "$fixture/project") $child)
    Equal 1 (Run-Wsl @('test', '-e', $namespace)).ExitCode 'Explicit clear removes selected namespace'
    Equal 0 (Run-Wsl @('test', '-f', $lock)).ExitCode 'Explicit clear retains stable lock inode'
    Equal 0 (Run-Wsl @('test', '-d', $cache)).ExitCode 'Explicit clear retains root'
    Write-Output 'Passed real WSL bootstrap diagnosis, first use, permissions, escaped links, lock links, and simulated foreign-owner cases.'
} finally {
    if ($null -ne $holder) {
        if (-not $holder.HasExited) { $holder.Kill($true); $holder.WaitForExit() }
        $holder.Dispose()
    }
    if ($created) { $null = Text (Run-Wsl @('rm', '-rf', '--', $fixture)) }
}
