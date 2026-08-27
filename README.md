# DevTools

Personal development tools, agent skills, coordination packs, and operational guides.

This repository is private because several coordination packs contain machine-local paths and
project-specific execution context. Do not add credentials, tokens, connection strings, private
keys, customer data, or production evidence.

## Reusable tools

| Path | Purpose |
|---|---|
| [`generic-coordination/`](generic-coordination/) | Project-agnostic coordinator, worker, validation, review, and Telex launcher pack. |
| [`paw-moderated-local-review/`](paw-moderated-local-review/) | Local PAW Society-of-Thought review with human moderation, editable pending GitHub comments, and authorization-only submission. |
| [`stable-public-ip-sampler/`](stable-public-ip-sampler/) | Sanitized repeated sampling of public egress IPv4 stability. |
| [`type-driven-agent-kit/`](type-driven-agent-kit/) | Installer and source files for type-driven Copilot instructions, skills, agents, and PAW personas. |

## Guides

| Path | Purpose |
|---|---|
| [`Offscreen-Windows-UI-Automation-Guide.md`](Offscreen-Windows-UI-Automation-Guide.md) | Background-safe Windows UI automation guidance. |

## Project-bound coordination packs

These directories preserve task-specific prompts, manifests, and handoffs. They may contain absolute
paths, fixed commits, paused-state assumptions, or safety boundaries from the machine and worktree
where they were created. Read each `README.md` and revalidate every bound value before reuse.

| Path | Scope |
|---|---|
| [`dbagent-1055-1057-coordination/`](dbagent-1055-1057-coordination/) | DBAgent cache-efficiency coordination. |
| [`dbagent-1059-1061-coordination/`](dbagent-1059-1061-coordination/) | DBAgent replication-risk coordination. |
| [`dbagent-phase7a-remediation-coordination/`](dbagent-phase7a-remediation-coordination/) | DBAgent Phase 7A remediation coordination. |
| [`recover-failed-investigations-phase6-coordination/`](recover-failed-investigations-phase6-coordination/) | Failed-investigation recovery Phase 6 coordination. |
| [`recover-failed-investigations-phase7-coordination/`](recover-failed-investigations-phase7-coordination/) | Failed-investigation recovery Phase 7 coordination. |
| [`recover-failed-investigations-phase7-coordination-v2/`](recover-failed-investigations-phase7-coordination-v2/) | Revised Phase 7 coordination and handoff. |

## Repository conventions

- Keep reusable tools project-neutral. Put task-bound prompts in a clearly named coordination pack.
- Add a `README.md` that states purpose, prerequisites, safety boundaries, and validation steps.
- Store editable source, not duplicate ZIP exports or generated packages.
- Use repository-relative links for reusable documentation. Mark unavoidable machine-local paths.
- Run local validation before changing a coordination launcher, installer, or agent skill.
- Keep GitHub reviews pending until the human reviewer edits and explicitly authorizes submission.

## Import source

The initial contents came from:

```text
C:\Users\brownch\OneDrive - Microsoft\Documents\DevTools
```

The import omitted `type-driven-agent-kit.zip` because it exactly duplicated the tracked
`type-driven-agent-kit/` source directory.
