# brownch-devtools plugin

This plugin installs the repository's maintained Copilot skills and custom agents as one versioned
unit. Install it through the `brownch-devtools` marketplace rather than copying individual files.
Its canonical source is `https://github.com/notthatbreezy/skills`, under `plugins/devtools`.

The plugin intentionally has no hooks, MCP servers, LSP servers, or post-install scripts.

## Included capability groups

- Custom PAW workflow skills:
  `custom-paw-workflow`, `custom-paw-setup`, `custom-paw-plan`, `custom-paw-plan-gate`,
  `custom-paw-implement-phase`, `custom-paw-finalize`, `custom-paw-deliver`,
  `custom-paw-review-policy`
- Delegation/type-safety package assets:
  `delegation-orchestrator` (agent) and `delegation-type-safety` (skill)
- Planning review package assets:
  `test-plan-reviewer` (agent) and `scope-creep-reviewer` (agent)
- Existing maintained assets:
  `paw-moderated-local-review` (skill), `paw-moderated-local-reviewer` (agent),
  `type-driven-development` (skill), `type-safety-reviewer` (agent),
  `html-decision-explainers`, `offscreen-windows-ui-automation`, `stable-public-ip-sampler`
- Repository exploration:
  `ripwire-wsl` runs pinned Linux Ripwire against the current Windows worktree, with an explicit
  installer, read-only diagnostics, persistent private Linux caches, and scoped cache clearing.

## Runtime prerequisites

Some packaged workflow instructions explicitly require external skills, agents, or runtime tools
that are intentionally not bundled here. Missing required dependencies are expected to yield
`BLOCKED` behavior until resolved or explicitly waived.

`ripwire-wsl` requires PowerShell 7, Windows Git, and an existing Ubuntu WSL distribution with Linux
Git and archive/core utilities. Its setup does not enable Windows features or install distributions.
The [bundled guide](skills/ripwire-wsl/references/guide.md) explains setup and the CLI-only,
single-worktree boundary. Windows tools retain responsibility for edits, builds, tests, and Git
mutations; WSL access is not a read-only sandbox.
