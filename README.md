# DevTools

Personal GitHub Copilot skills and agents distributed as one native Copilot plugin.

The repository is private. Do not add credentials, tokens, connection strings, private keys,
customer data, production evidence, or machine-bound coordination archives.

## Install

Requirements:

- GitHub Copilot CLI with plugin support
- Access to `brownch_microsoft/devtools`
- PowerShell 7 or Windows PowerShell 5.1

Clone the repository, then run:

```powershell
.\Install-DevTools.ps1
```

The installer uses Copilot's supported marketplace and plugin commands. It does not copy files into
Copilot configuration directories:

```powershell
copilot plugin marketplace add brownch_microsoft/devtools
copilot plugin install brownch-devtools@brownch-devtools
```

Running the installer again refreshes the marketplace and updates the installed plugin. Start a new
Copilot session or run `/restart` after installation.

For local plugin development:

```powershell
.\Install-DevTools.ps1 -MarketplaceSource $PWD
```

## Included capabilities

| Capability | Kind | Purpose |
|---|---|---|
| `paw-moderated-local-review` | Skill | Local PAW Society-of-Thought review with human moderation, editable pending GitHub comments, and authorization-only submission. |
| `type-driven-development` | Skill | Type-oriented design, boundary parsing, closed state models, and compiler-guided refactoring. |
| `type-safety-reviewer` | Custom agent | Read-only review for concrete type-safety and invalid-state failures. |
| `offscreen-windows-ui-automation` | Skill | Background-safe Windows UI Automation against real application state. |
| `stable-public-ip-sampler` | Skill | Sanitized repeated sampling of public egress IPv4 stability. |

The type-driven skill bundles its concise Copilot instruction block and PAW specialist profile as
references. Copilot plugins install skills and custom agents natively; they do not write arbitrary
global instruction files or PAW persona directories.

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
