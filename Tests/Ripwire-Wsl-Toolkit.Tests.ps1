[CmdletBinding()]
param(
    [ValidateSet('AllDeterministic', 'Unit', 'Feasibility')]
    [string] $Mode = 'AllDeterministic',
    [string] $Distribution,
    [switch] $AllowDownload,
    [switch] $AllowInstall,
    [string] $LinuxCacheRoot,
    [string] $ResultPath
)

$ErrorActionPreference = 'Stop'
if ($Mode -in @('Unit', 'AllDeterministic')) {
    & (Join-Path $PSScriptRoot 'Ripwire-Wsl.Static.Tests.ps1')
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        Write-Output 'Windows PowerShell runs static/manifest checks only; runtime checks require PowerShell 7.'
        exit 0
    }
    & pwsh -NoProfile -File (Join-Path $PSScriptRoot 'Ripwire-Wsl.Unit.Tests.ps1')
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    if ($Mode -eq 'Unit') { exit 0 }
}
if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Console]::Error.WriteLine('RIPWIRE_WSL_UNSUPPORTED_RUNTIME')
    exit 78
}
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$assets = Join-Path $PSScriptRoot 'fixtures\ripwire-wsl'
. (Join-Path $assets 'ProbeProcess.ps1')
$cases = [Collections.Generic.List[string]]::new()

function Assert-True([bool] $Condition, [string] $Message) {
    if (-not $Condition) { throw "ASSERTION_FAILED: $Message" }
}

function Assert-Equal($Expected, $Actual, [string] $Message) {
    Assert-True (($Expected | ConvertTo-Json -Depth 20 -Compress) -ceq
        ($Actual | ConvertTo-Json -Depth 20 -Compress)) $Message
}

function Require-Success([ProbeProcessResult] $Result, [string] $Operation) {
    if ($Result.ExitCode -ne 0) {
        throw "${Operation}: exit $($Result.ExitCode)`n$($Result.ErrorText())"
    }
    return $Result.OutputText().Trim()
}

function Convert-RipwireXml([string] $Text) {
    # Upstream legends include XML-invalid double hyphens inside comments.
    return [xml] ($Text -replace '(?s)<!--.*?-->', '')
}

function Invoke-Wsl([string[]] $NativeArguments, [hashtable] $Environment = @{}) {
    Invoke-ProbeProcess 'wsl.exe' (@('--distribution', $Distribution, '--exec') + $NativeArguments) $Environment
}

function Convert-LinuxPath([string] $Path) {
    Require-Success (Invoke-Wsl @('wslpath', '-a', '-u', '--', $Path)) 'wslpath'
}

function Get-CacheNamespaceKey([string] $Root, [string] $GitDir, [string] $CommonDir) {
    $identity = ConvertTo-Json -InputObject @($Root, $GitDir, $CommonDir) -Compress -EscapeHandling EscapeNonAscii
    return [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData(
        [Text.Encoding]::UTF8.GetBytes($identity))).ToLowerInvariant()
}

function Get-OutsideCacheSnapshot([string] $Snapshot, [string] $CacheRoot) {
    $entries = ConvertFrom-Json -InputObject $Snapshot -AsHashtable
    $outside = [ordered] @{}
    foreach ($path in @($entries.Keys | Sort-Object -CaseSensitive)) {
        if ($path -cne $CacheRoot -and -not $path.StartsWith("$CacheRoot/", [StringComparison]::Ordinal)) {
            $outside[$path] = $entries[$path]
        }
    }
    return $outside
}

function Get-FileSnapshot([string[]] $Paths) {
    $snapshot = [ordered] @{}
    foreach ($path in $Paths) {
        if (-not (Test-Path -LiteralPath $path)) {
            $snapshot[$path] = 'missing'
            continue
        }
        $files = if (Test-Path -LiteralPath $path -PathType Container) {
            Get-ChildItem -LiteralPath $path -Recurse -Force -File
        } else { Get-Item -LiteralPath $path -Force }
        foreach ($file in @($files | Sort-Object FullName)) {
            $snapshot[$file.FullName] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        }
    }
    return $snapshot
}

function Test-EnvironmentContracts {
    $envBlock = New-ProbeEnvironment @{ GIT_DIR = '/tmp/git' } 'EXAMPLE/u' '1' @{
        GIT_CONFIG_KEY_0 = 'probe.note'; GIT_CONFIG_VALUE_0 = ''
    }
    Assert-True ($envBlock.WSLENV.StartsWith('EXAMPLE/u:')) 'Existing WSLENV order'
    Assert-Equal '' $envBlock.GIT_CONFIG_VALUE_0 'Empty Git config value'
    foreach ($invalid in @(
        @{ Wslenv = 'GIT_DIR/p' },
        @{ Wslenv = 'X/u:X/u' },
        @{ Wslenv = 'X/uu' },
        @{ Wslenv = 'X/uw' },
        @{ Wslenv = 'X/u:' },
        @{ GitConfigCount = '-1' },
        @{ GitConfigCount = 'x' },
        @{ GitConfigCount = '1' },
        @{ GitConfigEntries = @{ GIT_CONFIG_KEY_0 = 'extra' } }
    )) {
        $rejected = $false
        try { $null = New-ProbeEnvironment @{ GIT_DIR = '/tmp/git' } @invalid }
        catch {
            if ($_.Exception.Message -notlike 'PROBE_*') { throw }
            $rejected = $true
        }
        Assert-True $rejected 'Malformed environment rejected before process creation'
    }
    foreach ($name in @('bootstrap.sh', 'fsmonitor.sh')) {
        Assert-True (-not [IO.File]::ReadAllBytes((Join-Path $assets $name)).Contains([byte] 13)) "$name LF endings"
    }
    $cases.Add('deterministic environment rejection and LF contracts')
    $runtime = (Get-Process -Id $PID).Path
    $exitProbe = Invoke-ProbeProcess $runtime @('-NoProfile', '-Command', 'exit 19')
    Assert-Equal 19 $exitProbe.ExitCode 'Native process exit propagation'
    $timedOut = $false
    try {
        $null = Invoke-ProbeProcess $runtime @('-NoProfile', '-Command', 'Start-Sleep 10') -TimeoutSeconds 1
    } catch {
        if ($_.Exception.Message -notlike 'PROBE_TIMED_OUT:*') { throw }
        $timedOut = $true
    }
    Assert-True $timedOut 'Bounded process timeout'
    $cases.Add('deterministic process exit and timeout')
    Assert-True ((Get-CacheNamespaceKey '/root/a' '/git/a' '/git') -cne
        (Get-CacheNamespaceKey '/root/b' '/git/b' '/git')) 'Linked-worktree cache identities differ'
    $filtered = Get-OutsideCacheSnapshot '{"/cache":{},"/cache/a":{},"/cache-escape":{"kind":"file"}}' '/cache'
    Assert-Equal @('/cache-escape') @($filtered.Keys) 'Cache exception respects path boundaries'
    $cases.Add('deterministic cache identity and snapshot boundary')
}

Test-EnvironmentContracts
if ($Mode -eq 'AllDeterministic') {
    Write-Host "Passed $($cases.Count) deterministic group; live WSL not invoked."
    return
}
if (-not $IsWindows) { throw 'FEASIBILITY_BLOCKED: Windows host required' }
if ([string]::IsNullOrWhiteSpace($Distribution)) { throw 'FEASIBILITY_BLOCKED: explicit -Distribution required' }
if (-not ($AllowDownload -and $AllowInstall)) {
    throw 'FEASIBILITY_BLOCKED: this probe requires approved -AllowDownload and -AllowInstall staging'
}
if ($LinuxCacheRoot -cnotmatch '^/tmp/ripwire-cache-feasibility\.[0-9a-f]{32}$') {
    throw 'FEASIBILITY_BLOCKED: -LinuxCacheRoot must be a fresh /tmp/ripwire-cache-feasibility.<uuid-hex> path'
}

$testRoot = Join-Path ([IO.Path]::GetTempPath()) ("ripwire-feasibility-{0}" -f [Guid]::NewGuid())
$linuxPrefix = $null
$report = [ordered] @{
    outcome = 'Blocked'
    release = 'v0.5.0'
    powershell = $PSVersionTable.PSVersion.ToString()
    cases = $cases
    failure = $null
    cleanup = 'NotStarted'
}
$parentEnvironment = [Environment]::GetEnvironmentVariables() | ConvertTo-Json -Compress
$linuxCleanupCreated = $false
$cacheCleanupCreated = $false

try {
    $ubuntu = Require-Success (Invoke-Wsl @('/bin/bash', '-c',
        '. /etc/os-release; printf "%s %s" "$ID" "$VERSION_ID"')) 'Ubuntu probe'
    Assert-True ($ubuntu -match '^ubuntu (\d+)\.(\d+)$' -and [int] $Matches[1] -ge 20) 'Ubuntu prerequisite'
    $report['ubuntu'] = $ubuntu
    $arch = Require-Success (Invoke-Wsl @('uname', '-m')) 'Architecture probe'
    $assetArch, $digest = switch ($arch) {
        'x86_64' { 'x64'; 'f06e9d7e55032e8e5c397405ed72a19d6e70767d28c8c617a925de4401779f50' }
        'aarch64' { 'arm64'; 'efe049b1645045e96751a51b1bc321b2d8653aa1f6ab5d7c2390eb3d49716bf0' }
        default { throw "FEASIBILITY_BLOCKED: unsupported probe architecture $arch" }
    }
    $report['architecture'] = $arch
    $report['archiveSha256'] = $digest
    $report['linuxGit'] = Require-Success (Invoke-Wsl @('git', '--version')) 'Linux Git probe'
    $report['probePython'] = Require-Success (Invoke-Wsl @('python3', '--version')) 'Test-only Python prerequisite'
    $null = Require-Success (Invoke-Wsl @('tar', '--version')) 'tar prerequisite'
    $linuxProbe = Convert-LinuxPath (Join-Path $assets 'probe.py')
    $linuxCacheFixture = Convert-LinuxPath (Join-Path $assets 'cache-fixture.py')
    $createdCacheRoot = Require-Success (Invoke-Wsl @('python3', $linuxCacheFixture, 'init', $LinuxCacheRoot)) 'Private Linux test cache'
    $cacheCleanupCreated = $true
    Assert-Equal $LinuxCacheRoot $createdCacheRoot 'Created exact requested test cache root'
    $null = New-Item -ItemType Directory -Path $testRoot
    $archiveName = "ripwire-0.5.0-linux-$assetArch"
    $archive = Join-Path $testRoot "$archiveName.tar.gz"
    Invoke-WebRequest "https://github.com/redhat-et/ripwire/releases/download/v0.5.0/$archiveName.tar.gz" -OutFile $archive
    Assert-Equal $digest.ToUpperInvariant() (Get-FileHash $archive -Algorithm SHA256).Hash 'Pinned archive digest'
    $linuxArchive = Convert-LinuxPath $archive
    $entries = Require-Success (Invoke-Wsl @('tar', '-tzf', $linuxArchive)) 'Archive layout'
    foreach ($entry in ($entries -split "`n")) {
        Assert-True ($entry.StartsWith("$archiveName/", [StringComparison]::Ordinal) -and
            '..' -cnotin ($entry -split '/') -and -not $entry.Contains('\')) "Unexpected archive entry: $entry"
    }
    $types = Require-Success (Invoke-Wsl @('tar', '-tvzf', $linuxArchive)) 'Archive entry types'
    foreach ($entry in ($types -split "`n")) {
        Assert-True ($entry.StartsWith('d') -or $entry.StartsWith('-')) 'Archive rejects links and special files'
    }
    $linuxPrefix = Require-Success (Invoke-Wsl @('mktemp', '-d', '/tmp/ripwire-feasibility.XXXXXXXXXX')) 'Disposable Linux prefix'
    Assert-True ($linuxPrefix -cmatch '^/tmp/ripwire-feasibility\.[A-Za-z0-9]{10}$') 'Exact disposable prefix'
    $linuxCleanupCreated = $true
    # Bundled upstream skills/hooks are not needed and must not be activated by the probe.
    $null = Require-Success (Invoke-Wsl @('tar', '-xzf', $linuxArchive, '--no-same-owner',
        '-C', $linuxPrefix, '--', "$archiveName/ripwire")) 'Binary-only extraction'
    $binary = "$linuxPrefix/$archiveName/ripwire"
    $report['binaryVersion'] = Require-Success (Invoke-Wsl @($binary, '--version')) 'Staged binary health'
    Assert-True ($report.binaryVersion -match '\b0\.5\.0\b') 'Expected staged binary version'

    $report.outcome = 'Fail'
    $main = Join-Path $testRoot 'main fixture'
    $linked = Join-Path $testRoot ("linked fixture " + [char] 0x00e9)
    $emptyConfig = Join-Path $testRoot 'empty.gitconfig'
    [IO.File]::WriteAllText($emptyConfig, '')
    $gitEnv = @{
        GIT_DIR = $null; GIT_WORK_TREE = $null; GIT_COMMON_DIR = $null; GIT_INDEX_FILE = $null
        GIT_CONFIG = $null; GIT_CONFIG_COUNT = '0'; GIT_CONFIG_PARAMETERS = $null
        GIT_CONFIG_NOSYSTEM = '1'; GIT_CONFIG_GLOBAL = $emptyConfig; GIT_OPTIONAL_LOCKS = '0'
    }
    function Invoke-FixtureGit([string[]] $GitArguments) {
        Require-Success (Invoke-ProbeProcess 'git' (
            @('-c', 'core.fsmonitor=false', '-c', 'core.hooksPath=/dev/null') + $GitArguments) $gitEnv) 'Windows fixture Git'
    }
    $null = Invoke-FixtureGit @('init', '-b', 'main', $main)
    $null = Invoke-FixtureGit @('-C', $main, 'config', 'user.name', 'Ripwire Fixture')
    $null = Invoke-FixtureGit @('-C', $main, 'config', 'user.email', 'fixture@example.invalid')
    [IO.File]::WriteAllText((Join-Path $main 'core.cpp'), "int base_value() { return 7; }`nint caller() { return base_value(); }`n")
    $null = Invoke-FixtureGit @('-C', $main, 'add', 'core.cpp')
    $null = Invoke-FixtureGit @('-C', $main, 'commit', '-m', 'Fixture baseline')
    $null = Invoke-FixtureGit @('-C', $main, 'worktree', 'add', '-b', 'fixture-linked', $linked)
    [IO.File]::AppendAllText((Join-Path $linked 'core.cpp'), "int committed_feature() { return caller(); }`n")
    $null = Invoke-FixtureGit @('-C', $linked, 'add', 'core.cpp')
    $null = Invoke-FixtureGit @('-C', $linked, 'commit', '-m', 'Fixture linked commit')
    [IO.File]::AppendAllText((Join-Path $linked 'core.cpp'), "int uncommitted_feature() { return committed_feature(); }`n")
    $linuxBootstrap = Convert-LinuxPath (Join-Path $assets 'bootstrap.sh')
    $linuxHook = Convert-LinuxPath (Join-Path $assets 'fsmonitor.sh')
    $null = Invoke-FixtureGit @('-C', $main, 'config', 'core.fsmonitor', "/bin/sh `"$linuxHook`"")
    $contexts = @{}
    foreach ($root in @($main, $linked)) {
        $linuxRoot = Convert-LinuxPath $root
        $gitDir = Invoke-FixtureGit @('-C', $root, 'rev-parse', '--absolute-git-dir')
        $commonDir = Invoke-FixtureGit @('-C', $root, 'rev-parse', '--git-common-dir')
        if (-not [IO.Path]::IsPathRooted($commonDir)) { $commonDir = Join-Path $root $commonDir }
        $linuxGitDir = Convert-LinuxPath $gitDir
        $linuxCommonDir = Convert-LinuxPath ([IO.Path]::GetFullPath($commonDir))
        $cache = (Require-Success (Invoke-Wsl @('python3', $linuxCacheFixture, 'namespace',
            $LinuxCacheRoot, 'v0.5.0', $assetArch, $linuxRoot, $linuxGitDir, $linuxCommonDir)) 'Cache namespace') | ConvertFrom-Json
        Assert-Equal (Get-CacheNamespaceKey $linuxRoot $linuxGitDir $linuxCommonDir) $cache.key 'Independent namespace identity'
        $contexts[$root] = @{
            root = $linuxRoot; gitDir = $linuxGitDir; commonDir = $linuxCommonDir; cache = $cache.path
        }
    }
    Assert-True ($contexts[$main].cache -cne $contexts[$linked].cache) 'Separate linked-worktree namespaces'
    $windowsGlobal = @((Join-Path $HOME '.gitconfig'), (Join-Path $HOME '.config\git\config'))
    $baseline = Get-FileSnapshot (@($main, $linked, $emptyConfig) + $windowsGlobal)
    $repositoryRoot = Split-Path -Parent $PSScriptRoot
    $primaryBaseline = Get-FileSnapshot @($repositoryRoot)
    $primaryStatus = Invoke-FixtureGit @('-C', $repositoryRoot, 'status', '--porcelain')
    function Get-LinuxSnapshot {
        Require-Success (Invoke-Wsl @('python3', $linuxProbe, 'snapshot', $linuxPrefix, $LinuxCacheRoot)) 'Linux snapshot'
    }
    $linuxBaseline = Get-LinuxSnapshot
    $results = [ordered] @{}
    $report['observations'] = $results
    foreach ($root in @($main, $linked)) {
        $linuxRoot = $contexts[$root].root
        $namespace = $contexts[$root].cache
        $otherNamespace = $contexts[$(if ($root -eq $main) { $linked } else { $main })].cache
        $otherBefore = Require-Success (Invoke-Wsl @('python3', $linuxProbe, 'snapshot', $otherNamespace)) 'Other namespace baseline'
        $head = Invoke-FixtureGit @('-C', $root, 'rev-parse', 'HEAD')
        $dirty = Invoke-FixtureGit @('-C', $root, 'status', '--porcelain')
        $shallow = Invoke-FixtureGit @('-C', $root, 'rev-parse', '--is-shallow-repository')
        $expectedStamp = $head.Substring(0, 9) + $(if ($dirty) { '+dirty' } else { '' }) +
            $(if ($shallow -eq 'true') { '+shallow' } else { '' })
        $variables = @{
            GIT_DIR = $contexts[$root].gitDir
            GIT_COMMON_DIR = $contexts[$root].commonDir
            GIT_WORK_TREE = $linuxRoot
            GIT_CONFIG_GLOBAL = Convert-LinuxPath $emptyConfig
            GIT_CONFIG_NOSYSTEM = '1'
            GIT_OPTIONAL_LOCKS = '0'
            RIPWIRE_BIN = '/usr/bin/python3'
            TMPDIR = "$namespace/tmp"
            XDG_CACHE_HOME = "$namespace/xdg"
            RIPWIRE_CACHE_STATS = '1'
        }
        $childEnv = New-ProbeEnvironment $variables ([string] $env:WSLENV) '2' @{
            GIT_CONFIG_KEY_0 = 'probe.note'; GIT_CONFIG_VALUE_0 = "kept value $([char] 0x00e9)"
            GIT_CONFIG_KEY_1 = 'core.fsmonitor'; GIT_CONFIG_VALUE_1 = 'true'
        }
        function Invoke-Boundary([string[]] $ProbeArguments) {
            Invoke-ProbeProcess 'wsl.exe' (@('--distribution', $Distribution, '--cd', $linuxRoot,
                '--exec', '/bin/bash', '--', $linuxBootstrap, '--') + $ProbeArguments) $childEnv
        }
        function Invoke-CacheObservation([string[]] $QueryArguments, [int] $Reparsed, [int] $Reused) {
            $watch = [Diagnostics.Stopwatch]::StartNew()
            $processResult = Invoke-Boundary $QueryArguments
            $watch.Stop()
            $null = Require-Success $processResult 'Cached Ripwire invocation'
            $stats = [regex]::Matches($processResult.ErrorText(),
                '(?m)^ripwire: cache-stats reparsed=(\d+) reused=(\d+) files=(\d+) cached_records=(\d+) blob_entries=(\d+)\r?$')
            Assert-Equal 1 $stats.Count 'Exactly one upstream cache-stats observation'
            Assert-Equal $Reparsed ([int] $stats[0].Groups[1].Value) 'Expected reparsed file count'
            Assert-Equal $Reused ([int] $stats[0].Groups[2].Value) 'Expected reused file count'
            Assert-Equal 1 ([int] $stats[0].Groups[3].Value) 'Fixture source file count'
            return [pscustomobject] @{
                text = $processResult.OutputText()
                stats = $stats[0].Value
                elapsedMs = $watch.Elapsed.TotalMilliseconds
            }
        }
        function Assert-FreshNamespace([string[]] $QueryArguments, [string] $Expected) {
            $fresh = "$namespace/reference-$([Guid]::NewGuid().ToString('N'))"
            $null = Require-Success (Invoke-Wsl @('mkdir', '-m', '700', '-p', '--', "$fresh/tmp", "$fresh/xdg")) 'Fresh cache reference'
            $savedTmp = $childEnv.TMPDIR
            $savedXdg = $childEnv.XDG_CACHE_HOME
            try {
                $childEnv.TMPDIR = "$fresh/tmp"
                $childEnv.XDG_CACHE_HOME = "$fresh/xdg"
                $reference = Invoke-CacheObservation $QueryArguments 1 0
                Assert-Equal $Expected $reference.text 'Reused and fresh-namespace stdout agree'
            } finally {
                $childEnv.TMPDIR = $savedTmp
                $childEnv.XDG_CACHE_HOME = $savedXdg
            }
        }
        $argvCases = @('', 'two words', 'a"b', "single'quote", 'back\slash\', 'a=b',
            '--looks-like=path', "unicode-$([char] 0x00e9)", (Join-Path $root 'does not exist'))
        $context = (Require-Success (Invoke-Boundary (@($linuxProbe, 'context') + $argvCases)) 'Live context') | ConvertFrom-Json
        Assert-Equal $argvCases $context.argv 'Real WSL argv boundaries'
        Assert-Equal $linuxRoot $context.root 'Live Git root'
        Assert-Equal $linuxRoot $context.cwd 'Live cwd'
        Assert-Equal $variables.GIT_DIR $context.gitDir 'Live Git directory'
        Assert-Equal $variables.GIT_COMMON_DIR $context.commonDir 'Live common directory'
        Assert-Equal $head $context.head 'Live HEAD'
        Assert-Equal 'false' $context.fsmonitor 'Final fsmonitor override'
        Assert-Equal @(@('probe.note', "kept value $([char] 0x00e9)"),
            @('core.fsmonitor', 'true'), @('core.fsmonitor', 'false')) $context.overrides 'Preserved Git overrides'
        $cases.Add("live transport/context: $(Split-Path $root -Leaf)")
        $bytes = Invoke-Boundary @($linuxProbe, 'bytes')
        $expectedOut = [byte[]] (([byte[]] (0..255) * 4096) + [Text.Encoding]::UTF8.GetBytes("`r`nutf8:$([char] 0x00e9)"))
        $expectedErr = [byte[]] (([byte[]] (255..0) * 4096) + [Text.Encoding]::UTF8.GetBytes("`r`npartial"))
        Assert-Equal ([Convert]::ToBase64String($expectedOut)) ([Convert]::ToBase64String($bytes.Stdout)) 'Raw stdout bytes'
        Assert-Equal ([Convert]::ToBase64String($expectedErr)) ([Convert]::ToBase64String($bytes.Stderr)) 'Raw stderr bytes'
        Assert-Equal 23 $bytes.ExitCode 'Partial output with non-zero exit'
        $empty = Invoke-Boundary @($linuxProbe, 'empty')
        Assert-Equal 0 $empty.ExitCode 'Empty output exit'
        Assert-Equal 0 $empty.Stdout.Length 'Empty stdout'
        Assert-Equal 0 $empty.Stderr.Length 'Empty stderr'
        $cases.Add("live raw streams/exit: $(Split-Path $root -Leaf)")

        $childEnv.RIPWIRE_BIN = $binary
        $mapCold = Invoke-CacheObservation @($linuxRoot) 1 0
        $mapWarm = Invoke-CacheObservation @($linuxRoot) 0 1
        Assert-Equal $mapCold.text $mapWarm.text 'Cold/warm map stdout'
        $map = $mapWarm.text
        $mapXml = Convert-RipwireXml $map
        Assert-Equal $linuxRoot $mapXml.DocumentElement.GetAttribute('root') 'Ripwire map root'
        Assert-Equal 1 $mapXml.SelectNodes('/r/f[@p="core.cpp"]/s[@n="base_value"]').Count 'Default orientation symbol'
        Assert-Equal $(if ($root -eq $linked) { 1 } else { 0 }) `
            $mapXml.SelectNodes('/r/f/s[@n="uncommitted_feature"]').Count 'Dirty symbol only in linked worktree'
        $query = if ($root -eq $linked) { 'uncommitted_feature' } else { 'base_value' }
        $queryArgs = @($linuxRoot, "--for=$query")
        $queryCold = Invoke-CacheObservation $queryArgs 1 0
        $queryWarm = Invoke-CacheObservation $queryArgs 0 1
        Assert-Equal $queryCold.text $queryWarm.text 'Cold/warm analysis stdout'
        $analysis = $queryWarm.text
        Assert-FreshNamespace $queryArgs $analysis
        $analysisXml = Convert-RipwireXml $analysis
        Assert-Equal $expectedStamp $analysisXml.DocumentElement.GetAttribute('at') 'Ripwire commit/dirty stamp'
        Assert-Equal $linuxRoot $analysisXml.DocumentElement.GetAttribute('root') 'Ripwire analysis root'
        Assert-Equal 1 $analysisXml.SelectNodes("/ctx/sigs/d[@n='$query'][@p='core.cpp']").Count 'Ripwire source symbol'
        $sourceLine = if ($root -eq $linked) { 3 } else { 0 }
        Assert-Equal ([IO.File]::ReadAllLines((Join-Path $root 'core.cpp'))[$sourceLine]) `
            $analysisXml.SelectSingleNode("/ctx/bodies/b[@n='$query']").FirstChild.Value `
            'Ripwire body matches dirty Windows source'
        $callers = Require-Success (Invoke-Boundary @($linuxRoot, '--callers=base_value')) 'Ripwire callers'
        $callersXml = Convert-RipwireXml $callers
        Assert-Equal 1 $callersXml.SelectNodes('/callers[@of="base_value"]/s[@n="caller"][@p="core.cpp:2"]').Count 'Known caller relationship'
        if ($root -eq $linked) {
            $history = Require-Success (Invoke-Boundary @($linuxRoot, '--pr-context=main')) 'Ripwire Git-backed history'
            $historyXml = Convert-RipwireXml $history
            Assert-True ($historyXml.SelectNodes('//*[@p="core.cpp"]').Count -gt 0) 'PR context observes changed file'
            Assert-Equal $expectedStamp $historyXml.DocumentElement.GetAttribute('at') 'PR context commit/dirty stamp'
            Assert-Equal $results.main.head.Substring(0, 9) $historyXml.DocumentElement.GetAttribute('base_sha') 'PR context base commit'
            $report['history'] = $history
        }
        $results[$(if ($root -eq $main) { 'main' } else { 'linked' })] = @{
            head = $head; stamp = $expectedStamp; map = $map; analysis = $analysis; callers = $callers
            cacheNamespace = $namespace
            mapCold = $mapCold.stats; mapWarm = $mapWarm.stats
            queryCold = $queryCold.stats; queryWarm = $queryWarm.stats
            timingsMs = @{ mapCold = $mapCold.elapsedMs; mapWarm = $mapWarm.elapsedMs
                queryCold = $queryCold.elapsedMs; queryWarm = $queryWarm.elapsedMs }
        }
        $cases.Add("Ripwire root/HEAD/source/callers: $(Split-Path $root -Leaf)")
        $cases.Add("cross-process source-cache reuse and cold/warm/fresh equality: $(Split-Path $root -Leaf)")
        foreach ($family in @('source', 'history')) {
            foreach ($fault in @('missing', 'corrupt')) {
                $beforeFault = Require-Success (Invoke-Wsl @('python3', $linuxProbe, 'snapshot',
                    "$namespace/tmp", "$namespace/xdg")) 'Cache baseline before fault'
                $faultInfo = (Require-Success (Invoke-Wsl @('python3', $linuxCacheFixture, 'fault',
                    $LinuxCacheRoot, $namespace, $fault, $family)) 'Declared cache fault injection') | ConvertFrom-Json
                $reparsed = if ($family -eq 'source') { 1 } else { 0 }
                $rebuilt = Invoke-CacheObservation $queryArgs $reparsed (1 - $reparsed)
                Assert-Equal $analysis $rebuilt.text "Results survive $fault $family cache"
                $rewarmed = Invoke-CacheObservation $queryArgs 0 1
                Assert-Equal $analysis $rewarmed.text "Rebuilt $fault $family cache is reusable"
                $afterFault = Require-Success (Invoke-Wsl @('python3', $linuxProbe, 'snapshot',
                    "$namespace/tmp", "$namespace/xdg")) 'Cache after rebuild'
                $beforeEntries = $beforeFault | ConvertFrom-Json -AsHashtable
                $afterEntries = $afterFault | ConvertFrom-Json -AsHashtable
                foreach ($relativePath in $faultInfo.relativePaths) {
                    $cachePath = "$LinuxCacheRoot/$relativePath"
                    Assert-True ($afterEntries.Contains($cachePath)) 'Missing cache is rebuilt'
                    Assert-Equal 'file' $afterEntries[$cachePath].kind 'Rebuilt cache is regular'
                    $corruptHash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData(
                        [Text.Encoding]::UTF8.GetBytes('deliberately-invalid-cache'))).ToLowerInvariant()
                    Assert-True ($afterEntries[$cachePath].sha256 -cne $corruptHash) 'Corruption was replaced'
                    # Derived binary serialization need not be identical; query results and reuse must be.
                    $beforeEntries[$cachePath].sha256 = '<rebuilt>'
                    $afterEntries[$cachePath].sha256 = '<rebuilt>'
                }
                Assert-Equal $beforeEntries $afterEntries 'Rebuild preserves modes and unrelated cache files'
            }
        }
        $cases.Add("missing/corrupt source and history cache rebuild: $(Split-Path $root -Leaf)")
        Assert-Equal $otherBefore (Require-Success (Invoke-Wsl @('python3', $linuxProbe, 'snapshot', $otherNamespace)) 'Other namespace after queries') `
            'Queries and faults leave other worktree namespace unchanged'
    }
    Assert-True ($results.main.head -ne $results.linked.head) 'Distinct fixture commits'
    $sentinel = Join-Path $testRoot 'fsmonitor-fired'
    Assert-True (-not (Test-Path -LiteralPath $sentinel)) 'No hook execution during Ripwire calls'
    $positive = $childEnv.Clone()
    $positive.GIT_CONFIG_COUNT = '0'
    $null = Require-Success (Invoke-Wsl @('git', 'status', '--porcelain') $positive) 'Fsmonitor positive control'
    Assert-True (Test-Path -LiteralPath $sentinel) 'Positive control must execute hook'
    Remove-Item -LiteralPath $sentinel
    $cases.Add('fsmonitor positive/negative control')
    Assert-Equal $baseline (Get-FileSnapshot (@($main, $linked, $emptyConfig) + $windowsGlobal)) 'No source/Git/config mutation'
    Assert-Equal $primaryStatus (Invoke-FixtureGit @('-C', $repositoryRoot, 'status', '--porcelain')) 'Primary repository status unchanged'
    Assert-Equal $primaryBaseline (Get-FileSnapshot @($repositoryRoot)) 'Primary repository content unchanged'
    Assert-Equal $parentEnvironment ([Environment]::GetEnvironmentVariables() | ConvertTo-Json -Compress) 'Parent environment unchanged'
    $cases.Add('Windows target/Git/config and primary repository unchanged; parent environment preserved')

    # Each deliberate Windows edit/commit establishes a new non-mutation interval.
    $linkedFile = Join-Path $linked 'core.cpp'
    $otherBefore = Require-Success (Invoke-Wsl @('python3', $linuxProbe, 'snapshot', $contexts[$main].cache)) 'Main cache before linked edits'
    $originalText = [IO.File]::ReadAllText($linkedFile)
    $modifiedText = $originalText.Replace('return committed_feature();', 'return committed_feature() + 9;')
    Assert-True ($modifiedText -cne $originalText) 'Fixture edit changes the uncommitted function'
    [IO.File]::WriteAllText($linkedFile, $modifiedText)
    $changedBaseline = Get-FileSnapshot (@($main, $linked, $emptyConfig) + $windowsGlobal)
    $edited = Invoke-CacheObservation $queryArgs 1 0
    $editedXml = Convert-RipwireXml $edited.text
    Assert-Equal "$($results.linked.head.Substring(0, 9))+dirty" $editedXml.DocumentElement.GetAttribute('at') 'Dirty edit stamp'
    Assert-Equal 'int uncommitted_feature() { return committed_feature() + 9; }' `
        $editedXml.SelectSingleNode('/ctx/bodies/b[@n="uncommitted_feature"]').FirstChild.Value 'Cache reflects changed body'
    Assert-FreshNamespace $queryArgs $edited.text
    Assert-Equal $changedBaseline (Get-FileSnapshot (@($main, $linked, $emptyConfig) + $windowsGlobal)) 'Analysis after edit is non-mutating'

    $savedTime = [IO.File]::GetLastWriteTimeUtc($linkedFile)
    [IO.File]::WriteAllText($linkedFile, $modifiedText.Replace('+ 9;', '+ 8;'))
    [IO.File]::SetLastWriteTimeUtc($linkedFile, $savedTime)
    $changedBaseline = Get-FileSnapshot (@($main, $linked, $emptyConfig) + $windowsGlobal)
    $sameSize = Invoke-CacheObservation $queryArgs 1 0
    $sameSizeXml = Convert-RipwireXml $sameSize.text
    Assert-Equal 'int uncommitted_feature() { return committed_feature() + 8; }' `
        $sameSizeXml.SelectSingleNode('/ctx/bodies/b[@n="uncommitted_feature"]').FirstChild.Value 'Hash freshness despite same size/mtime'
    Assert-FreshNamespace $queryArgs $sameSize.text
    Assert-Equal $changedBaseline (Get-FileSnapshot (@($main, $linked, $emptyConfig) + $windowsGlobal)) 'Analysis after same-size edit is non-mutating'
    $cases.Add('Dirty source and same-size/same-mtime edit refresh cached bodies')

    $null = Invoke-FixtureGit @('-C', $linked, 'add', 'core.cpp')
    $null = Invoke-FixtureGit @('-C', $linked, 'commit', '-m', 'Fixture cache freshness commit')
    $newHead = Invoke-FixtureGit @('-C', $linked, 'rev-parse', 'HEAD')
    Assert-True ($newHead -cne $results.linked.head) 'Fixture HEAD advances'
    $changedBaseline = Get-FileSnapshot (@($main, $linked, $emptyConfig) + $windowsGlobal)
    $committed = Invoke-CacheObservation $queryArgs 0 1
    $committedXml = Convert-RipwireXml $committed.text
    Assert-Equal $newHead.Substring(0, 9) $committedXml.DocumentElement.GetAttribute('at') 'Current clean HEAD with reused source cache'
    Assert-FreshNamespace $queryArgs $committed.text
    Assert-Equal $changedBaseline (Get-FileSnapshot (@($main, $linked, $emptyConfig) + $windowsGlobal)) 'Analysis after HEAD change is non-mutating'
    Assert-Equal $otherBefore (Require-Success (Invoke-Wsl @('python3', $linuxProbe, 'snapshot', $contexts[$main].cache)) 'Main cache after linked edits') `
        'Linked source/HEAD changes do not mutate main cache'
    $report['freshness'] = @{ dirty = $edited.stats; sameSizeSameMtime = $sameSize.stats
        committed = $committed.stats; newHead = $newHead }
    $cases.Add('HEAD change preserves namespace, refreshes history, and reuses unchanged source')

    $linuxAfter = Get-LinuxSnapshot
    Assert-Equal (Get-OutsideCacheSnapshot $linuxBaseline $LinuxCacheRoot) `
        (Get-OutsideCacheSnapshot $linuxAfter $LinuxCacheRoot) 'Only managed cache storage changes'
    $cases.Add('Only managed Linux cache storage changed; binary and monitored home paths unchanged')
    $report.outcome = 'Pass'
} catch {
    $report.failure = $_.Exception.Message
    throw
} finally {
    $cleanupErrors = [Collections.Generic.List[string]]::new()
    try {
        foreach ($created in @(
            @{ Exists = $linuxCleanupCreated; Path = $linuxPrefix },
            @{ Exists = $cacheCleanupCreated; Path = $LinuxCacheRoot }
        )) {
            if ($created.Exists) {
                try {
                    $null = Require-Success (Invoke-Wsl @('rm', '-rf', '--', $created.Path)) 'Disposable Linux cleanup'
                } catch {
                    $cleanupErrors.Add($_.Exception.Message)
                }
            }
        }
        try {
            if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force }
        } catch {
            $cleanupErrors.Add($_.Exception.Message)
        }
        if ($cleanupErrors.Count -gt 0) {
            $report.outcome = 'Fail'
            $report.cleanup = 'Failed: ' + ($cleanupErrors -join '; ')
            throw $report.cleanup
        } else {
            $report.cleanup = 'Succeeded'
        }
    } finally {
        if ($ResultPath) {
            $report | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $ResultPath -Encoding utf8
        }
    }
}
Write-Host "Feasibility $($report.outcome): $($cases.Count) groups."
