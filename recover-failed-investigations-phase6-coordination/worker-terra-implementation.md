# Phase 6 bounded implementation worker (Terra minimum)

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

Your worker type is `bounded-implementation`; its minimum model is Terra. The coordinator may assign Terra or Sol, but never Luna. Use the assigned model in Telex identity and `WORKER READY`. Model capability does not expand file claims or write authority.

Before sending `WORKER READY`, run `Get-Command telex`, `telex --version`, and `telex copilot skill`; record `$env:COPILOT_HOME`; confirm the plugin belongs to that active home; attach with `--copilot-bridge`; call `extensions_reload`; and require `telex_bridge_info` plus `station_health: attended_push`. If reload reports zero extensions, stop and report the profile and bridge paths to the coordinator.

Use the matching address:

```text
Terra: recover-failed-investigations-phase6-worker-terra-<unique-suffix>
Sol: recover-failed-investigations-phase6-worker-sol-bounded-<unique-suffix>
```

Attach with tags:

```text
worker-type:bounded-implementation,model:<terra|sol>,mode:implementation
```

Send:

```text
WORKER READY
workerType=bounded-implementation
model=<terra|sol>
mode=implementation
address=<exact Telex address>
repository=C:\Projects\dbagent-recover-phase6
branch=feature/recover-failed-investigations_phase6
workflow=paw-prs
writeAuthority=claimed-files-only
subagents=prohibited
```

Do not use subagents, factories, fleets, or delegated agents.

Read the coordination pack's `README.md`, repository instructions, workflow context, Phase 6, and the completed assignment sent by the coordinator before editing. The generic assignment template is reference only; the Telex assignment establishes your authority. Read broadly but edit only claimed files. Request a claim before crossing the boundary.

Appropriate lanes include bounded MCP client/formatter work, telemetry catalog and generated artifacts, and mechanical API tests after authoritative contracts stabilize.

Stop and request rerouting to Sol integration when behavior crosses state owners or involves durable command history, cancellation, LRO identity, ownership races, authorization, cursor integrity, stored schema evolution, deployment safety, or ambiguous architecture.

Do not stage, commit, push, reset, clean, remove worktrees, deploy, migrate, or perform connected actions.

Implement the smallest complete change, add tests that fail without it, run targeted validation, inspect diff hygiene, return claims, and report exact files, commands, counts, safety analysis, risks, and prohibited actions as `none`.
