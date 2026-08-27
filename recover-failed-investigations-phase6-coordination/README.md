# Recover Failed Investigations Phase 6 coordination pack

This pack coordinates Phase 6 of the PAW work item `recover-failed-investigations`.

## Fixed configuration

| Setting | Value |
| --- | --- |
| Repository | `C:\Projects\dbagent-recover-phase6` |
| Repository slug | `azure-data-database-platform/dbagent` |
| Target branch | `feature/recover-failed-investigations_phase6` |
| PR base | `feature/recover-failed-investigations_phase4` |
| Workflow | `paw-prs` |
| Plan | `C:\Projects\dbagent-recover-phase6\.paw\work\recover-failed-investigations\ImplementationPlan.md` |
| Workflow context | `C:\Projects\dbagent-recover-phase6\.paw\work\recover-failed-investigations\WorkflowContext.md` |
| Telex backend | `azure-telex` |
| Telex transport | Copilot plugin push bridge |
| Telex scope | `recover-failed-investigations-phase6` |
| Coordinator | `recover-failed-investigations-phase6-coordinator-sol` |
| Coordination pack | `C:\Users\brownch\OneDrive - Microsoft\DevTools\recover-failed-investigations-phase6-coordination` |
| Assignment template | `C:\Users\brownch\OneDrive - Microsoft\DevTools\recover-failed-investigations-phase6-coordination\assignment-template.md` |

The Phase 4 branch contains Phases 1-5.5 through merge commit `7765f667`. Consolidation remains paused while repository CI has unrelated problems.

## Startup

1. Create `C:\Projects\dbagent-recover-phase6` from `origin/feature/recover-failed-investigations_phase4`.
2. Create and check out `feature/recover-failed-investigations_phase6`.
3. Start a Sol coordinator with `coordinator-sol.md`.
4. Prove the Telex binary, plugin, active `COPILOT_HOME`, and live bridge as described below.
5. The coordinator reads `assignment-template.md`, completes one copy per task, records its claims, and sends it through Telex.
6. Attach workers only after the coordinator sends their completed assignment.
7. Keep implementation workers free of subagents. Use a distinct Sol worker for integrated review.

## Telex preflight

Telex uses the installed CLI and Copilot plugin push bridge, not an assumed MCP server. Each session must run the version-matched workflow from `telex copilot skill`.

1. Run `Get-Command telex`, `telex --version`, and `telex copilot skill`.
2. Record `$env:COPILOT_HOME`. Installing Telex under `%USERPROFILE%\.copilot` does not make it available to a CLI launched with another `COPILOT_HOME`.
3. Confirm the Telex plugin is installed and enabled in the active home. Restart the CLI after changing plugin registration.
4. Attach with the assigned address, scope, description, and `--copilot-bridge`.
5. Call `extensions_reload`.
6. Require `telex-bridge` to report `ready`, call `telex_bridge_info`, and run `telex --json --address <address> status`.
7. Verify the current session ID, address, scope, `push_registered: true`, and `station_health: attended_push`.

If `extensions_reload` reports zero extensions or `telex_bridge_info` is unavailable, compare the active `COPILOT_HOME` with the plugin and generated bridge paths. Stop and repair that profile mismatch before coordinating. Do not claim Telex is ready because the binary alone exists, and do not substitute informal coordination.

### Phase 6 setup finding

On 2026-08-19, Telex `0.1.2` was installed under `C:\Users\brownch\.copilot`, but Agency launched Copilot with `COPILOT_HOME=C:\Projects\Scout\.copilot-install-diagnostic`. The binary worked, yet the active CLI lacked the plugin and `extensions_reload` found zero extensions. The repair registered the same plugin version in the active home and installed the bridge as an active-home user extension. Verification showed `telex-bridge` ready from `[user]`, a live `telex_bridge_info` endpoint, and `station_health: attended_push`.

An already-open CLI must restart after plugin registration changes. Every session must still attach or resume its own Telex address and verify its session ID.

## Model capability floor

Use the capability order `Sol > Terra > Luna`. A more capable model may take a lower-floor worker type when capacity requires it:

| Worker type | Minimum model | Permitted models |
| --- | --- | --- |
| `validation-evidence` | Luna | Luna, Terra, or Sol |
| `bounded-implementation` | Terra | Terra or Sol |
| `integration-implementation` | Sol | Sol |
| `independent-review` | Sol | Sol |

Never assign a task below its minimum model. The assigned model keeps the worker type's authority, restrictions, address identity, and completion contract; a Sol validation worker remains read-only.

## Recommended lanes

Phase 6 crosses durable cancellation, API, MCP, and telemetry boundaries. Keep each state transition with one owner.

| Lane | Worker |
| --- | --- |
| Durable command acceptance, enqueue lifecycle, LRO, and API projection | Sol integration |
| History query, cursor, and API tests | Sol integration or bounded Terra/Sol after contracts stabilize |
| MCP client, tools, formatter, and sanitization | Bounded Terra or Sol |
| Telemetry catalog, generated artifacts, dashboards, and alerts | Bounded Terra or Sol |
| Targeted and final validation evidence | Luna, Terra, or Sol validation worker |
| Integrated read-only review | Separate Sol reviewer |

Do not parallelize edits to shared API contracts, OpenAPI baselines, recovery schemas, generated telemetry artifacts, or PAW plan records.

## Required final gates

```powershell
npm run lint
npm run typecheck
npm test
dotnet build .\platform\src\DBAgent.sln
dotnet test .\apps\api\DBAgentAPI.UnitTest\DBAgentAPI.UnitTest.csproj --filter "(TestCategory!=Integration)&(FullyQualifiedName~Investigation|FullyQualifiedName~Traversal|FullyQualifiedName~RecoveryOperation)"
pnpm --filter @dbagent/mcp test
pnpm --filter @dbagent/mcp test:integration
pnpm --filter @dbagent/telemetry test
pnpm run check:telemetry-v2
.\script\worktree-env.ps1 -Doctor
.\devtools\validation\health-runtime-e2e\run.ps1
```

The health-runtime harness is the mandatory pre-push PAW gate and must complete teardown.
