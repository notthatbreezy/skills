---
name: stable-public-ip-sampler
description: "Determine whether a machine has stable, distinct public egress IPv4 addresses using repeated sanitized samples. Trigger on \"find my stable public IPs\", \"check egress IP stability\", \"sample api.ipify.org and ifconfig.me\", or firewall allowlist preflight. Do NOT use to change VPN, proxy, firewall, Azure, or network configuration; this skill measures only."
compatibility: PowerShell 7+ with .NET HttpClient and outbound HTTPS access.
---

# Stable public IP sampler

Use the bundled `scripts\Test-StablePublicIp.ps1` instead of writing a new sampler.

## Safety

- Treat public IP values as sensitive environment data.
- Default to sanitized output. Do not print values or hashes.
- Use `-IncludeValues` only when the user explicitly requests the actual values and the current
  channel is appropriate for them.
- Make no Azure calls and no VPN, proxy, firewall, route, or adapter changes.
- Do not add retries, caching, fallback endpoints, or file persistence.
- State that a successful sample proves only the observed interval and process environment.

## Standard procedure

Run from the skill directory:

```powershell
pwsh -NoProfile -File .\scripts\Test-StablePublicIp.ps1
```

The defaults are the reviewed procedure:

- endpoints: `https://api.ipify.org` and `https://ifconfig.me/ip`;
- samples at 0, 30, and 60 seconds;
- six requests total, three per endpoint;
- ten-second timeout per request;
- one reused `.NET HttpClient`;
- redirects disabled;
- ambient Windows/default proxy behavior with default credentials;
- `Cache-Control: no-cache, no-store`;
- zero retries and zero fallback endpoints;
- in-memory comparison and sanitized JSON output.

For a fast implementation check without network access:

```powershell
pwsh -NoProfile -File .\scripts\Test-StablePublicIp.ps1 -SelfTest
```

## Interpretation

Report:

- request count, timeout, redirect and proxy behavior, HTTP stack, and process context;
- environment-proxy presence as booleans only;
- per-endpoint unique-count categories;
- per-sample validity and pair distinctness;
- `allSamplesValid`, `distinct`, and `stable`;
- confirmation of zero retries, fallback endpoints, Azure calls, network changes, and persistence.

`stable=true` requires:

1. every response is one valid public-unicast dotted-quad IPv4;
2. the two endpoint values differ in every sample;
3. each endpoint returns exactly one unique value across all samples.

If stability fails, report the measured categories without guessing the cause. Compare HTTP stack,
proxy behavior, redirect policy, process reuse, cache headers, timing, user/session context, and
ambient VPN state with other samplers. Do not claim a precise cause without evidence from both
procedures.

## Actual values

When explicitly authorized:

```powershell
pwsh -NoProfile -File .\scripts\Test-StablePublicIp.ps1 -IncludeValues
```

Keep the values process-local whenever possible. Never persist them merely to compare stability.
