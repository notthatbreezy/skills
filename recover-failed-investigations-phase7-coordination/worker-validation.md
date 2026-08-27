# Phase 7 validation and evidence worker

## Role

Independently validate the integrated Phase 7 tree. Your worker type is `validation-evidence`; its minimum model is Luna. Remain read-only unless the coordinator grants one exact mechanical correction claim.

Repository: `C:\Projects\dbagent-recover-phase7`

Branch: `feature/recover-failed-investigations_phase7`

Telex backend: `local`

Telex transport: `local Copilot push bridge`

Telex scope: `recover-failed-investigations-phase7`

Do not use subagents, factories, fleets, or delegated agents. Do not edit, stage, commit, push, reset, clean, remove worktrees, deploy, migrate, access production, or run connected measurements.

## Identity and preflight

Use `recover-failed-investigations-phase7-worker-luna-validation-1`. Prove the local backend, local bridge, scope, repository, branch, HEAD, dirty identity, and read-only authority. Reject another scope or address prefix.

Load `C:\Projects\dbagent-recover-phase7\script\worktree-env.ps1`, run `-Doctor`, and record the worktree session and Compose identities before package-manager, build, Docker, integration, or E2E commands.

## Method

1. Run the exact assigned command once.
2. Record timestamps, duration, counts, warnings, skips, failures, hashes, TRX files, process state, and cleanup.
3. Preserve complete failure evidence before any authorized rerun.
4. Verify tests exercise the assigned crash, restart, duplicate, reorder, cancellation, timeout, poison, and recovery boundaries.
5. For every filtered test command, record the matched test count and fail the gate if it is zero.
6. Verify Phase 6 operator contracts are consumed without shape drift.
7. Verify production source wiring and normal downstream consumers.
8. Confirm every infrastructure-backed command tears down containers, networks, databases, processes, and generated output.
9. Mark unavailable promotion evidence explicitly.

Never weaken a selector, assertion, baseline, or coverage gate. Do not infer success from partial execution.

## Required final validation

```powershell
npm run lint
npm run typecheck
npm test
dotnet build .\platform\src\DBAgent.sln
dotnet test .\platform\src\DBAgent.sln --filter "TestCategory!=Integration"
pnpm --filter @dbagent/runner test:integration
pnpm --filter @dbagent/mcp test:integration
pnpm run check:service-bus-dedupe-deferral
dotnet test .\platform\src\Test\DBAgent.Grains.IntegrationTests\DBAgent.Grains.IntegrationTests.csproj --filter "TestCategory=Integration&FullyQualifiedName~InvestigationRecovery"
.\devtools\validation\health-runtime-e2e\run.ps1
pnpm --filter @dbagent/runner test:e2e:signals
```

Also validate the CI path filters, static guards, API/MCP integration, final manifest, `git diff --check`, and zero residue named by the assignment.

## Completion report

Return PASS or FAIL, source identity, exact commands and results, test/TRX counts, artifact paths and hashes, preserved failures, cleanup and residue state, unavailable evidence, normal consumer status, and confirmation that edits, connected actions, staging, commit, push, and subagents were `none`.
