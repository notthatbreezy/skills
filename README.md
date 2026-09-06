# DevTools

Personal GitHub Copilot skills and agents distributed as one native Copilot plugin.

The repository is private. Do not add credentials, tokens, connection strings, private keys,
customer data, production evidence, or machine-bound coordination archives.

## Try it now

### Ask an agent to install everything

Send this message to a GitHub Copilot CLI agent:

```text
Install all Copilot tools from the private GitHub repository
https://github.com/brownch_microsoft/devtools.

Use the native Copilot plugin marketplace. Do not copy individual skill or agent files into my
Copilot configuration. If the brownch-devtools marketplace or plugin is already installed, update
it instead of treating that as an error.

Run the appropriate commands from this set:

copilot plugin marketplace add brownch_microsoft/devtools
copilot plugin marketplace update brownch-devtools
copilot plugin install brownch-devtools@brownch-devtools
copilot plugin update brownch-devtools

Then verify that `copilot plugin marketplace list` includes brownch-devtools and that
`copilot plugin list` includes brownch-devtools@brownch-devtools. Tell me whether installation or
update succeeded and remind me to start a new Copilot session or run /restart.
```

The agent should install one plugin containing every maintained skill and custom agent in this
repository.

### Install directly with Copilot CLI

For a first installation:

```powershell
copilot plugin marketplace add brownch_microsoft/devtools
copilot plugin marketplace browse brownch-devtools
copilot plugin install brownch-devtools@brownch-devtools
copilot plugin list
```

Start a new Copilot session or run `/restart` after installation.

**Requirements**:

- [GitHub Copilot CLI](https://github.com/github/copilot-cli) with plugin support
- Access to `brownch_microsoft/devtools`
- GitHub authentication that can read the private repository

### Install with the repository script

The repository script handles both first installation and future updates:

```powershell
git clone https://github.com/brownch_microsoft/devtools.git
Set-Location .\devtools
.\Install-DevTools.ps1
```

The installer uses Copilot's supported marketplace and plugin commands. It does not copy files into
Copilot configuration directories. It requires PowerShell 7 or Windows PowerShell 5.1.

### Update

Run the installer again, or use the native commands:

```powershell
copilot plugin marketplace update brownch-devtools
copilot plugin update brownch-devtools
copilot plugin list
```

To ask an agent to update everything, send:

```text
Update my brownch-devtools Copilot plugin. Refresh the brownch-devtools marketplace, update the
brownch-devtools plugin, verify the installed version with `copilot plugin list`, and report the
result. Do not reinstall individual skills or agents. Remind me to start a new Copilot session or
run /restart.
```

### Uninstall

```powershell
copilot plugin uninstall brownch-devtools
```

This removes the installed plugin but leaves the marketplace registered.

### Develop locally

For local plugin development:

```powershell
.\Install-DevTools.ps1 -MarketplaceSource $PWD
```

## Included capabilities

| Capability | Kind | Purpose |
|---|---|---|
| `custom-paw-workflow` | Skill | Routes substantial work through setup, planning, gate, implementation, finalization, and delivery stages with explicit authority and evidence boundaries. |
| `custom-paw-setup` | Skill | Establishes authority, package/runtime prerequisites, and workflow operating agreement before planning or implementation. |
| `custom-paw-plan` | Skill | Produces bounded planning artifacts and review-ready proof obligations. |
| `custom-paw-plan-gate` | Skill | Enforces the mandatory five-seat planning review gate and exact-input approval boundary. |
| `custom-paw-implement-phase` | Skill | Executes one authorized implementation phase with integrated review/evidence closure requirements. |
| `custom-paw-finalize` | Skill | Completes required documentation and full final SoT review readiness on integrated outputs. |
| `custom-paw-deliver` | Skill | Prepares publication handoff while preserving review/approval/write authority boundaries. |
| `custom-paw-delegation` | Skill | Applies bounded delegation packet design, ownership controls, and worker lifecycle rules. |
| `custom-paw-review-policy` | Skill | Keeps severity, disposition, and posting authority separate with grounded remediation policy. |
| `custom-paw-recovery` | Skill | Recovers durable workflow state and prevents duplicate or stale write actions after interruption. |
| `delegation-type-safety` | Skill | Focused type-safety reviewer persona for delegated plan/code review seats. |
| `delegation-orchestrator` | Custom agent | Coordinates bounded direct/delegated execution using Delegation Policy 2.1 with v1.0.1 amendment text. |
| `paw-moderated-local-review` | Skill | Local PAW Society-of-Thought review with human moderation, editable pending GitHub comments, and authorization-only submission. |
| `paw-moderated-local-reviewer` | Custom agent | End-to-end moderated PAW review from a fresh temporary clone with terminal cleanup and authorization-only GitHub submission. |
| `type-driven-development` | Skill | Type-oriented design, boundary parsing, closed state models, and compiler-guided refactoring. |
| `type-safety-reviewer` | Custom agent | Read-only review for concrete type-safety and invalid-state failures. |
| `offscreen-windows-ui-automation` | Skill | Background-safe Windows UI Automation against real application state. |
| `stable-public-ip-sampler` | Skill | Sanitized repeated sampling of public egress IPv4 stability. |

The type-driven and delegation type-safety skills bundle persona instructions in skill assets.
Copilot plugins install skills and custom agents natively; they do not write arbitrary global
instruction files, external PAW persona directories, or machine-bound coordination archives.

### Runtime prerequisites for custom PAW workflow assets

The modular custom PAW workflow and delegation orchestrator reference additional runtime skills/tools
that are not vendored in this repository. If required dependencies are unavailable, those workflows
must report `BLOCKED` instead of silently substituting behavior.

- Core PAW workflow skills and activities (for example `paw-workflow`, `paw-planning-docs-review`,
  `paw-sot`, `paw-plan-review`, `paw-impl-review`, `paw-review-workflow`).
- `clear-workplace-writing` skill.
- Named `test-plan-reviewer` custom agent (v1.0.0 as referenced by workflow policy text).
- `planning-review-canvas` skill for the required planning approval handoff, plus
  `html-visuals` and `canvas-apps` when their presentation triggers apply.
- PilotSwarm runtime tools expected by the instructions (for example durable facts/artifacts and
  native delegation tooling).

## Repository layout

```text
.github/plugin/marketplace.json  Private marketplace catalog
plugins/devtools/plugin.json     Plugin manifest
plugins/devtools/agents/         Custom agents
plugins/devtools/skills/         Skills and their scripts or references
Install-DevTools.ps1             Native marketplace/plugin bootstrap
```

## Maintenance

- Keep installable assets under `plugins/devtools/`.
- Update the version in both `plugin.json` and `marketplace.json` for releases.
- Store editable source, not ZIP exports or generated packages.
- Use repository-relative links and paths inside plugin assets.
- Validate PowerShell, JSON, plugin loading, skill discovery, and agent discovery before release.
- Keep GitHub reviews pending until the human reviewer edits and explicitly authorizes submission.

## Distribution model

This repository follows GitHub's supported plugin marketplace layout. See:

- [About GitHub Copilot plugins](https://docs.github.com/copilot/concepts/agents/about-plugins)
- [Creating a plugin](https://docs.github.com/copilot/how-tos/copilot-cli/customize-copilot/plugins-creating)
- [Creating a plugin marketplace](https://docs.github.com/copilot/how-tos/copilot-cli/customize-copilot/plugins-marketplace)
- [Copilot CLI plugin reference](https://docs.github.com/copilot/reference/copilot-cli-reference/cli-plugin-reference)
