# Phase 6 validation and evidence worker (Luna minimum)

## Configuration

```text
Repository: C:\Projects\dbagent-recover-phase6
Target branch: feature/recover-failed-investigations_phase6
Workflow: paw-prs
Coordination pack: C:\Users\brownch\OneDrive - Microsoft\DevTools\recover-failed-investigations-phase6-coordination
Assignment template: C:\Users\brownch\OneDrive - Microsoft\DevTools\recover-failed-investigations-phase6-coordination\assignment-template.md
Primary plan: C:\Projects\dbagent-recover-phase6\.paw\work\recover-failed-investigations\ImplementationPlan.md
Workflow context: C:\Projects\dbagent-recover-phase6\.paw\work\recover-failed-investigations\WorkflowContext.md
Telex backend: azure-telex
Telex transport: Copilot plugin push bridge; stop unless verified live
Telex scope: recover-failed-investigations-phase6
Coordinator: recover-failed-investigations-phase6-coordinator-sol
```

Your worker type is `validation-evidence`; its minimum model is Luna. The coordinator may assign Luna, Terra, or Sol. Never move work below Luna's floor. Remain read-only unless the coordinator grants one exact mechanical correction claim; a more capable model does not gain broader authority.

Before sending `WORKER READY`, run `Get-Command telex`, `telex --version`, and `telex copilot skill`; record `$env:COPILOT_HOME`; confirm the plugin belongs to that active home; attach with `--copilot-bridge`; call `extensions_reload`; and require `telex_bridge_info` plus `station_health: attended_push`. If reload reports zero extensions, stop and report the profile and bridge paths to the coordinator.

Use the address matching the assigned model:

```text
Luna: recover-failed-investigations-phase6-worker-luna-<unique-suffix>
Terra: recover-failed-investigations-phase6-worker-terra-validation-<unique-suffix>
Sol: recover-failed-investigations-phase6-worker-sol-validation-<unique-suffix>
```

Attach with tags:

```text
worker-type:validation-evidence,model:<luna|terra|sol>,mode:validation
```

Send the standard `WORKER READY` message with the actual model, repository, branch, workflow, `writeAuthority=none`, and `subagents=prohibited`.

Do not use subagents, factories, fleets, or delegated agents.

Read the coordination pack's `README.md` and the completed assignment sent by the coordinator. The generic assignment template is reference only; the Telex assignment establishes your scope. Verify repository, branch, HEAD, dirty ownership, and the serialized validation window. Run only assigned commands. Record exact commands, timestamps, duration, counts, warnings, skips, failure output, artifacts, hashes, and cleanup.

Phase 6 validation may include:

```powershell
dotnet test .\apps\api\DBAgentAPI.UnitTest\DBAgentAPI.UnitTest.csproj --filter "(TestCategory!=Integration)&(FullyQualifiedName~Investigation|FullyQualifiedName~Traversal|FullyQualifiedName~RecoveryOperation)"
pnpm --filter @dbagent/mcp test
pnpm --filter @dbagent/mcp test:integration
pnpm --filter @dbagent/telemetry test
pnpm run check:telemetry-v2
npm run lint
npm run typecheck
npm test
dotnet build .\platform\src\DBAgent.sln
.\script\worktree-env.ps1 -Doctor
.\devtools\validation\health-runtime-e2e\run.ps1
```

The final harness must produce fresh passing evidence and complete automatic teardown. Preserve failures before any authorized retry. Do not weaken tests, silently retry, infer unavailable evidence, stage, commit, push, reset, clean, or remove worktrees.

Return PASS or FAIL with source identity, exact evidence, cleanup state, unavailable evidence, edits, connected actions, staging, commit, push, and subagents.
