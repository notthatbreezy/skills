# Coordinator restart handoff - DBAgent #1055/#1057

- **Launching the coordinator starts coordination immediately:** no separate confirmation is
  needed.
- **Azure is clean:** the campaign resource group is absent and the campaign-tagged resource count
  is zero.
- **Phase 2A is complete:** implementation, independent validation, cleanup, complete-diff review,
  and completion-artifact review all passed with zero open findings.
- **Phase 4A is paused after attempt 7:** A-H passed with the reviewed fresh run-scoped pair, I
  created the dedicated resource group, and J returned `MissingRequiredParameter` for
  `administratorLoginPassword` despite the reviewed Entra-only argv omitting both native
  credential flags and disabling password authentication.
- **Attempt 7 failed closed with no credential fallback:** no password was requested or supplied,
  no alternate API path was tried, and campaign-only rollback restored Azure to zero resources.
- **Independent rollback validation PASS 697 accepted the clean result:** the resource group is
  absent, campaign resource count is zero, no server, administrator, firewall, token, or `psql`
  success occurred, artifacts are clean, and the exact ten tracked changes remain unchanged.
- **The operator explicitly paused the work:** User input: `"ok - it failed - let's pause"`.
  No retry, password path, alternate API test, or other connected action is authorized.
- **Cloud baseline is clean:** validation PASS 654 confirmed Azure empty, provider/account gates
  clean, more than 435 minutes remaining at baseline, and validator readiness for post-execution
  validation.

## What this is

This document is the restart handoff for the coordinator of DBAgent issues #1055 and #1057. It
captures the completed local work, the exact Phase 4A authorization, the Azure attempts and
rollbacks, the current blocker, and the safe restart sequence.

The coordination packet now references this handoff from `README.md`, `coordinator.md`, all three
worker role prompts, and `assignment-template.md`. A restarted role must read this document before
accepting work; the original prompts remain durable role definitions but do not override this
handoff's authorization or Azure-state baseline.

## Bound configuration

```text
Repository: C:\Projects\dbagent-1055-1057-cache-efficiency
Repository slug: azure-data-database-platform/dbagent
Target branch: work/1055-1057-cache-efficiency
Base branch: main
Committed HEAD: 60da6936aabd140b848049d49786b62fafa2ac9b
Workflow: direct
Anchor checkout: C:\Projects\dbagent
Prompt pack: C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools\dbagent-1055-1057-coordination
Telex backend: local
Telex scope: dbagent-1055-1057
Coordinator address: dbagent-1055-1057-coordinator
Required address prefix: dbagent-1055-1057-
Issue set: 1055,1057
Draft PR: https://github.com/azure-data-database-platform/dbagent/pull/1119
```

Stop on repository, branch, HEAD, worktree, scope, issue-set, or address-prefix drift. Never use or
repair the `dbagent-1059-1061` coordination network.

## Current gate and authorization state

The prior create attempts supplied a native administrator login. Local Azure CLI 2.89.0 validation
now confirms that this caused `administratorLogin` to serialize and explains the service demand
for `administratorLoginPassword`. The corrected true Entra-only shape explicitly uses:

- `--microsoft-entra-auth Enabled`;
- `--password-auth Disabled`;
- inline Entra administrator object ID, display name, and type;
- no `--admin-user`/`-u`;
- no `--admin-password`/`-p`.

The installed CLI generates a password only when password authentication is Enabled. Local SDK
serialization omitted both `administratorLogin` and `administratorLoginPassword` for the corrected
shape. This evidence made no service call and does not itself authorize a retry.

The operator extended the prior fixed expiry by exactly six hours: User input:
`"Ok - I the operator am extending it by 6 hours"`. The new fixed expiry is
`2026-08-23T08:23:58Z` (`2026-08-23 04:23:58 Eastern`). All other Phase 4A bounds remain
unchanged.

Independent review finding #2 concerning alias/equals-form validator coverage is explicitly
accepted as a waiver/carry-forward, not fixed: User input:
`"Ok - let's not worry about #2 for sure - that's not an issue"`.

Independent re-review PASS 643 accepted the integrated Entra-only correction, six-hour expiry
amendment, synchronized authorization state, and the explicit operator waiver with zero blocker,
high, or medium findings. That reviewed state authorized execution within the unchanged envelope,
before the fixed expiry, and with all existing cost, identity, exact-IP, rollback, scenario, and
safety gates.

Execution attempt 6 then passed Checkpoints A-G and stopped before mutation at Checkpoint H because
the current valid distinct endpoint pair differed from historical ledger values. Blocker
validation PASS 668 accepted the sanitized evidence: Azure remained empty, no rollback was
required, and the tracked ten-file baseline was unchanged.

The operator authorized replacing cross-attempt endpoint-value immutability with a run-scoped
stability rule. Every execution restart from Checkpoint A must establish a fresh pair by sampling
both approved endpoints at offsets 0/30/60 seconds, bind only that run's stable distinct ordered
pair, and revalidate it immediately before firewall creation and connectivity. Historical values
remain append-only audit history and have no authorization effect. The amendment must receive
independent review PASS before execution restarts. Review FAIL 680 identified that the first
amendment pre-created an unbound `currentRunBinding`. The corrected model keeps it null through
A-G, H sampling, and H failure; stores pending/failed metadata separately as non-authoritative;
promotes one complete six-sample `state=bound` object atomically only on H PASS; and archives only
complete bound objects on restart.

Independent egress re-review PASS 685 accepted the corrected run-scoped model. Execution attempt 7
then passed A-H, including the fresh six-sample stability window and same-run binding. Checkpoint I
created and ledgered the reviewed resource group. At the first Checkpoint J server create, the live
service returned `MissingRequiredParameter` for `administratorLoginPassword` even though the
rendered long-form command used Entra authentication Enabled, password authentication Disabled,
and contained neither native credential flag. The worker attempted no credential fallback, retry,
alternate API, or later checkpoint. Campaign-only rollback deleted the resource group and verified
zero campaign resources.

Independent validation PASS 697 accepted the rollback and artifacts: Azure is empty; no server,
inline administrator, firewall rule, token, or metadata-only `psql` success occurred; unresolved
rollback count is zero; sensitive values remain local; and the exact ten tracked modifications are
unchanged. The operator then paused Phase 4A. The prior authorization is not executable again
without new explicit operator authorization and independent review.

## Current Azure state

The coordinator performed a sanitized, read-only Azure verification after the final rollback:

```text
Subscription matched: true
Resource group exists: false
Campaign-tagged resource count: 0
Zero-resource state: true
```

The fixed resource group name is:

```text
rg-dbagent-brownch-1055-1057-e2e
```

No server, Entra administrator assignment, firewall rule, PostgreSQL token operation, or `psql`
connection remains from the attempts. No Azure resource is currently accruing campaign cost.

Re-run the same sanitized absence check before any future mutation. Do not print the ledger run ID,
resource IDs, server names, IPs, rule names, or hashes.

### Cloud validation baseline

Cloud validation PASS 654 confirmed, using sanitized results only:

- Azure remains empty for the campaign;
- provider, account, subscription, and tenant gates are clean;
- more than 435 minutes remained before `2026-08-23T08:23:58Z` at baseline time;
- the cloud-capable validator is ready for a separate post-execution validation assignment.

This baseline is not execution and does not replace the execution worker's required pre-mutation
checks or the separate post-execution validation gate.

## Phase 2A completed work

Phase 2A is complete as local evidence readiness only. It does not close either issue or authorize
connected evidence collection.

### Exact tracked changes

The worktree contains exactly these ten unstaged tracked modifications:

1. `devtools/validation/cache-efficiency-live-evidence/run.ps1`
2. `devtools/validation/cache-efficiency-live-evidence/Validate-CacheEfficiencyLiveEvidence.ps1`
3. `devtools/validation/cache-efficiency-live-evidence/Test-CacheEfficiencyLiveEvidence.ps1`
4. `devtools/validation/cache-efficiency-live-evidence/cache-efficiency-live-evidence.schema.json`
5. `devtools/validation/cache-efficiency-live-evidence/README.md`
6. `platform/src/Test/DBAgent.HealthRuntime.E2ETests/Infrastructure/KustoEmulatorContext.cs`
7. `platform/src/Test/DBAgent.HealthRuntime.E2ETests/HealthRuntimeEndToEndTests.cs`
8. `platform/src/Test/DBAgent.Grains.UnitTests/KustoMetricsCollectorTests.cs`
9. `devtools/validation/health-runtime-e2e/run.ps1`
10. `devtools/validation/health-runtime-e2e/README.md`

Nothing is staged, committed, or pushed.

### Delivered behavior

- Closed v2 `complete`, `incomplete`, `aborted`, and `not-collected` report states.
- Fixed 46-request allocation under a 50-request hard ceiling.
- Signed readiness, permit, receipt, replay, expiry, and ordering controls.
- Strict permit-to-receipt temporal attribution.
- Seven-day local retention contract simulation.
- Idle replay proving `Idle` to `NotEvaluable` with no Investigation.
- Sparse-Geneva replay proving Geneva cannot manufacture Kusto-only cache evidence.
- Fresh/aged replay proving aged cache evidence fails closed to `Missing`/`NotEvaluable`.
- Explicit refusal to invent a distinct cache `Stale` state.

### Validation and review

- Live-evidence self-tests passed.
- `KustoMetricsCollectorTests`: 98/98 passed.
- Health-runtime E2E: 9/9 passed.
- Scheduled-task suites: 6/6 each.
- `git diff --check` passed.
- Independent complete-diff review passed.
- Phase 2A completion artifacts passed review with zero open findings.

Important local artifacts:

- `.paw\work\1055-1057-cache-efficiency\IssueClosurePhase2ACompletionRecord.md`
- `.paw\work\1055-1057-cache-efficiency\IssueClosurePlan.md`
- `.paw\work\1055-1057-cache-efficiency\IssueClosurePhase2Assignment.md`
- `.paw\work\1055-1057-cache-efficiency\IssueClosurePhase2ClaimAmendment01.md`

The `.paw\work\1055-1057-cache-efficiency` directory is ignored and must never be committed.

## Approved Phase 4A envelope

The operator approved Phase 4A setup and metadata-only preflight with:

| Input | Approved value |
| --- | --- |
| Subscription | `Azure PostgreSQL Developer Experiences R&D Test` |
| Tenant | Current Microsoft corporate tenant |
| Resource group | `rg-dbagent-brownch-1055-1057-e2e` |
| Regions | One target in `eastus2`, one in `westus2` |
| Cost ceiling | USD $25 projected aggregate |
| Last projected cost | USD $10.23 including 20% contingency |
| Expiry | `2026-08-23T08:23:58Z` |
| Authentication intent | Entra-only connectivity |
| Failed creation | Immediate campaign-only rollback |
| Workloads | Not authorized |
| Connected evidence | Not authorized |

### Expiry gate

The fixed expiry is 2026-08-23 04:23:58 Eastern. Before execution:

1. Verify the current UTC time.
2. Require enough remaining time for creation, validation, rollback, later authorization, and
   teardown.
3. Stop if the expiry has passed or is operationally too close for the complete authorized flow.

Do not extend the expiry again without new explicit operator authorization and independent review.

## Phase 4A reviewed design

The current source of truth is:

```text
.paw\work\1055-1057-cache-efficiency\IssueClosurePhase4AAssignment.md
```

The artifact retains these previously independently reviewed controls:

- Azure CLI 2.89.0 command shapes.
- Atomic pinned scenario acquisition.
- Semantic expiry-tag comparison.
- Two exact corporate egress-IP firewall rules per target.
- Conditional `random-access` classification.
- Cost, expiry, ledger, idempotency, sanitization, and rollback.

The true Entra-only correction with both native credential flags absent passed local validation.
Independent re-review PASS 643 accepted the integrated Entra-only correction, six-hour expiry
amendment, waiver carry-forward, and synchronized authorization state with zero blocker, high, or
medium findings. The existing Phase 4A authorization is executable only through a reviewed
execution assignment, within its unchanged envelope, and before `2026-08-23T08:23:58Z`.

### Target shape

```text
PostgreSQL version: 16
Tier/SKU: General Purpose Standard_D2s_v3
Storage: 32 GiB
High availability: disabled
Backup retention: 7 days
Geo-redundant backup: disabled
Public access: only the approved exact /32 rules
Server parameters: defaults during Phase 4A
```

### Two exact-IP firewall approach

Corporate routing caused the two approved public-IP endpoints to observe different egress
addresses. The operator approved a fresh run-scoped stable pair, still used only as separate exact
`/32` rules.

Requirements:

- Endpoint 1: `https://api.ipify.org`
- Endpoint 2: `https://ifconfig.me/ip`
- On every execution after A-G, sample both endpoints at offsets 0/30/60 seconds.
- Use one reused .NET `HttpClient`, ten-second timeout, redirects disabled, ambient default proxy,
  no-cache/no-store, zero retries, zero fallbacks, and in-memory comparison.
- Require all six responses to be valid public-unicast dotted-quad IPv4; each slot's unique count
  must equal one; the pair must be distinct at every offset.
- Bind the stable ordered pair only to that execution run. Preserve historical values append-only
  as audit evidence with no authorization effect.
- Revalidate the same run-bound pair once per endpoint immediately before firewall creation.
- Revalidate again once per endpoint immediately before token acquisition and `psql`.
- Create exactly two start=end rules per server, four total.
- Never combine them into a range, CIDR, subnet, wildcard, `0.0.0.0`, or Azure-services rule.
- Treat raw IPs, rule names, and IP-derived hashes as sensitive.
- Any same-run changed pair or partial rule creation stops execution; post-mutation failure
  triggers full campaign rollback.

### Conditional `random-access` status

Pinned scenario checkout:

```text
C:\Projects\postgres-dbagent-scenarios-1055-1057
Revision: ecaa957e75a6fc4674fcfe8f420fada1a913bc32
```

The checkout was created by the campaign and was clean at the pinned revision. Do not fetch, pull,
reset, checkout, clean, modify, or delete it without reviewed authorization.

`random-access` is:

```text
conditionally-viable-pending-Phase4B-parameter-and-workload-authorization
```

Future-only candidate Azure parameters:

| Parameter | Candidate value |
| --- | --- |
| `work_mem` | `4096` |
| `effective_cache_size` | `16384` |
| `maintenance_work_mem` | `32768` |
| `max_parallel_workers_per_gather` | `2` |
| `min_parallel_table_scan_size` | `1024` |
| `parallel_setup_cost` | `1000` |
| `parallel_tuple_cost` | `0.1` |

None is authorized or executed in Phase 4A. `shared_buffers`, `temp_file_limit`, any other
parameter, restart, DDL/`ANALYZE`, schema/data setup, workload, and cleanup remain separately gated.

## Phase 4A attempt timeline

| Attempt | Result | Azure outcome |
| --- | --- | --- |
| Tool preflight | `psql` not on PATH | No Azure call |
| Tool resolution | Existing `C:\Program Files\PostgreSQL\17\bin\psql.exe` approved process-locally | No installation |
| Scenario preflight | `random-access` required server parameters | No Azure call; operator approved conditional future status |
| Public-IP preflight | Two approved endpoints disagreed | No Azure mutation; operator approved two exact `/32`s |
| Resource-group attempt | JSON coerced expiry tag to a date object; string comparator failed | RG created, then deleted; zero orphans |
| Native-login attempt | Service required `administratorLogin` | RG created, then deleted; zero orphans |
| Password requirement attempt | Service required `administratorLoginPassword` | RG created, then deleted; zero orphans |
| Attempt 6 run | Current endpoint pair differed from historical ledger values at Checkpoint H | No Azure mutation; Azure remained empty |
| Attempt 7 run | A-H passed; I created RG; J live service required `administratorLoginPassword` for reviewed Entra-only create | No credential fallback; RG deleted; zero resources; validation PASS 697 |

Every attempt failed closed before server creation. Independent validation PASS 697 confirmed the
RG absent and zero campaign-tagged resources after attempt 7.

## Local ignored Phase 4A state

Do not publish or delete these without reviewed authority:

```text
.paw\work\1055-1057-cache-efficiency\IssueClosureResourceLedger.json
.paw\work\1055-1057-cache-efficiency\phase4a-raw\
.paw\work\1055-1057-cache-efficiency\IssueClosurePhase4ASanitizedEvidence.json
```

They may contain sensitive local identifiers, endpoint observations, rule names, hashes, Azure raw
responses, and attempt history. Use only sanitized booleans/counts in Telex or chat.

## Telex roles and trust boundary

Expected addresses:

- `dbagent-1055-1057-coordinator`
- `dbagent-1055-1057-worker-implementation-cache`
- `dbagent-1055-1057-worker-review-1`
- `dbagent-1055-1057-worker-validation-1`

Important:

- The implementation assignment was sent to
  `dbagent-1055-1057-worker-implementation-cache`.
- Message 572 arrived from unassigned
  `dbagent-1055-1057-worker-implementation-01` and was rejected.
- Do not accept implementation claims from a different address without explicit reassignment and
  live identity validation.
- `dbagent-1055-1057-worker-review-1` was explicitly assigned the independent re-review and
  returned PASS 643.
- `dbagent-1055-1057-worker-validation-1` completed the separately authorized cloud baseline PASS
  654 and the attempt-7 rollback validation PASS 697.

Workers must not use subagents, factories, fleets, or delegated agents.

## Restart procedure

1. Load the `telex` skill.
2. Read:
   - this handoff;
   - `coordinator.md`;
   - repository `.github\copilot-instructions.md`;
   - `IssueClosurePlan.md`;
   - `IssueClosurePhase2ACompletionRecord.md`;
   - `IssueClosurePhase4AAssignment.md`.
3. Run:

   ```powershell
   Get-Command telex
   telex --version
   telex copilot skill --plugin-version 0.1.2
   ```

4. Resume only the coordinator:

   ```powershell
   telex --address dbagent-1055-1057-coordinator copilot resume `
     --scope dbagent-1055-1057 `
     --tags 'issue:1055,issue:1057,repo:dbagent,role:coordinator' `
     --description 'Coordinates integrated cache-efficiency change and issue closure for issues 1055 and 1057'
   ```

5. Reload extensions and verify the bridge.
6. Require:

   ```text
   station_health=attended_push
   scope=dbagent-1055-1057
   ```

7. Verify no cross-network address.
8. Acknowledge replayed backlog and deduplicate by message ID.
9. Do not proactively drain the inbox during normal push delivery.

## Worktree safety

Before raw builds/tests or any resumed execution:

```powershell
Set-Location 'C:\Projects\dbagent-1055-1057-cache-efficiency'
Invoke-Expression ((& '.\script\worktree-env.ps1') -join [Environment]::NewLine)
& '.\script\worktree-env.ps1' -Doctor
```

Require:

```text
DBAGENT_SESSION_ID=dbagent-1055-1057-cache-efficiency
COMPOSE_PROJECT_NAME=dbagent-1055-1057-cache-efficiency
```

Never stage, commit, push, mark the PR ready, merge, or close issues without explicit operator
authorization.

## Recommended next-coordinator sequence

1. Keep Phase 4A paused. Do not issue an Azure, network, password, alternate-API, or retry
   assignment.
2. Wait for a separately prepared branch in
   `azure-data-database-platform/postgres-dbagent-scenarios`.
3. Review that branch and decide separately whether it changes the required Phase 4A/Phase 4B
   approach.
4. Resume Phase 4A only after new explicit operator authorization, an amended assignment, and
   independent review PASS.
5. Preserve the ignored ledger, raw evidence, and sanitized evidence under the existing
   sensitive-data retention rules.

## Telex evidence landmarks

Useful message IDs:

| ID | Meaning |
| --- | --- |
| 429 | Phase 2A implementation complete |
| 436 | Independent Phase 2A validation PASS |
| 438 | Phase 2A ignored-artifact cleanup |
| 440 | Phase 2A complete-diff review PASS |
| 453 | Phase 2A completion artifacts clean PASS |
| 532 | Phase 4A assignment PASS |
| 548 | Conditional `random-access` amendment PASS |
| 557 | Two exact-IP amendment PASS |
| 569 | Semantic expiry comparator PASS |
| 589 | Deterministic native administrator login amendment PASS |
| 601 | Password requirement blocker and clean rollback |
| 620 | True Entra-only command amendment assignment |
| 626 | Independent local Entra-only validation PASS |
| 629 | Entra-only command amendment completed |
| 636 | Independent review FAIL: stale expiry contradiction plus accepted validator-coverage finding |
| 637 | Six-hour expiry extension and handoff reconciliation assignment |
| 643 | Independent re-review PASS with zero blocker/high/medium findings and waiver retained |
| 654 | Cloud validation baseline PASS; Azure empty and validator ready |
| 664 | Attempt 6 stopped at H before mutation; Azure clean |
| 668 | Independent blocker validation PASS |
| 671 | Run-scoped stable egress-pair amendment assignment |
| 672 | Operator clarification: every execution establishes a fresh pair |
| 678 | Initial run-scoped egress amendment completed |
| 680 | Independent review FAIL: one Medium current-binding state-model defect |
| 681 | Current-binding null-until-H-PASS correction assignment |
| 685 | Corrected run-scoped egress amendment re-review PASS |
| 693 | Attempt 7 blocked at J; campaign-only rollback completed with zero resources |
| 697 | Independent attempt-7 rollback and artifact validation PASS |

## Final status

```text
Phase 2A: complete, local-only, independently approved
Phase 4A: paused by operator after attempt 7 live-service Entra-only create failure
Fixed expiry: 2026-08-23T08:23:58Z
Azure resources: zero
Campaign cost currently accruing: none
Tracked worktree changes: exactly ten, unstaged
Commit/push/PR/issue mutation: none
Connected actions authorized: none
Next safe action: wait for a separately prepared postgres-dbagent-scenarios branch, then obtain new
explicit operator authorization and independent review before any Phase 4A resume
```
