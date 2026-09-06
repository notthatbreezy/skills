# brownch-devtools plugin

This plugin installs the repository's maintained Copilot skills and custom agents as one versioned
unit. Install it through the `brownch-devtools` marketplace rather than copying individual files.

The plugin intentionally has no hooks, MCP servers, LSP servers, or post-install scripts.

## Included capability groups

- Custom PAW workflow skills:
  `custom-paw-workflow`, `custom-paw-setup`, `custom-paw-plan`, `custom-paw-plan-gate`,
  `custom-paw-implement-phase`, `custom-paw-finalize`, `custom-paw-deliver`,
  `custom-paw-delegation`, `custom-paw-review-policy`, `custom-paw-recovery`
- Delegation/type-safety package assets:
  `delegation-orchestrator` (agent) and `delegation-type-safety` (skill)
- Existing maintained assets:
  `paw-moderated-local-review` (skill), `paw-moderated-local-reviewer` (agent),
  `type-driven-development` (skill), `type-safety-reviewer` (agent),
  `html-decision-explainers`, `offscreen-windows-ui-automation`, `stable-public-ip-sampler`

## Runtime prerequisites

Some packaged workflow instructions explicitly require external skills, agents, or runtime tools
that are intentionally not bundled here. Missing required dependencies are expected to yield
`BLOCKED` behavior until resolved or explicitly waived.
