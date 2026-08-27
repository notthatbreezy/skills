# Native Copilot coordination skills

This pack coordinates work through Copilot's native agent and session tools.

## Skills

- `coordinator`: user-invoked router and end-to-end workflow owner.
- `validator`: independent command execution and evidence collection.
- `reviewer`: independent correctness and risk review.

Implementation and integration are assignment modes owned by the coordinator rather than separate skills. Workers may activate project-specific implementation skills when the assignment calls for them.

## Design changes

### Native IPC

The coordinator uses:

- background `task` workers for bounded one-off research, implementation, validation, or review;
- `create_session` when a known sequence of related assignments benefits from retained context, an isolated worktree, or a durable process;
- `send_session_message` for continuation, correction, pausing, and rerouting within a session lease;
- child-session idle notifications instead of polling.

Communication and coordination state remain within native Copilot tools and workflow artifacts.

### Bounded continuity

A background worker owns one assignment and disappears after returning its checkpoint packet. Use it when no follow-up is expected.

A child project session owns one milestone role, normally two to four related assignments for the same state owner or integration boundary. It pauses at each checkpoint and continues only when the coordinator already knows the next assignment. It expires at the milestone boundary, role change, stale-context point, or declared lease horizon.

Independent review and validation require fresh workers, not necessarily fresh sessions. Single-pass work defaults to background workers; a child session is justified only by a known sequence, durable process, UI environment, or likely evidence follow-up.

### Coordinator altitude

The coordinator owns the outcome graph, phase gates, claims, decisions, and acceptance state. Workers own implementation detail. Their reports are deliberately compact and evidence-oriented so the coordinator can oversee an entire PAW or comparable workflow without becoming another implementation session.

## Streamlined execution

1. Map exhaustive consumers, module exports, manifests, lockfiles, generated outputs, migrations, and tests before assigning claims.
2. Land shared identifiers and module scaffolding before parallel lanes.
3. Use one-off background workers by default; create a milestone session only when planned continuity will pay for it.
4. Freeze workers at checkpoint submission and verify no unassigned post-checkpoint edits.
5. Let the coordinator perform conflict-free Git integration; create an integration worker only for semantic conflicts, wiring, generated-output reconciliation, or source edits.
6. Review risk-first before spending expensive full validation.
7. Validate through a fail-fast ladder from focused checks to full workspace evidence.
8. Prepare the next phase's research and lane plan during read-only gates, but wait for transition before implementation.
9. Use fresh independent reviewer and validator workers for every final exact checkpoint.
10. Keep the durable ledger in workflow artifacts or the session database, not worker transcripts.
11. Refresh authoritative context at every major milestone and maintain ready-to-launch downstream assignment packets.

For golden-path POCs, the coordinator fixes core-path, durability, security, cleanup, recovery, and evidence-truth defects now. Unsupported multi-instance, scale, polish, and adversarial sharp edges may be deferred when they fail visibly and are recorded in a pre-1.0 defect ledger.

All workers use the default context tier. Long/high contexts, including 1M and 1.1M, are prohibited.

## Assessment

Open the `native-skills` folder in VS Code and review each `SKILL.md`. When ready, copy the three skill directories into the active Copilot skills directory.

## Install or update

Run from this folder:

```powershell
.\Install-CoordinationSkills.ps1
```

The default destination is `$HOME\.agents\skills`. When `COPILOT_HOME` is set, the installer also mirrors the skills into `$env:COPILOT_HOME\skills`. Duplicate paths are installed once.

Override the defaults when needed:

```powershell
.\Install-CoordinationSkills.ps1 -DestinationRoot 'C:\path\to\skills'
```

Pass multiple explicit roots as an array. Explicit roots replace the defaults.

Preview changes with `-WhatIf`. The installer mirrors only `coordinator`, `validator`, and `reviewer`; root files such as the installer and this README are excluded.
