# WorkflowContext

Work Title: Ripwire WSL Toolkit
Work ID: ripwire-wsl-toolkit
Base Branch: main
Target Branch: brownch-microsoft-ripwire-wsl-toolkit
Execution Mode: current-checkout
Repository Identity: github.com/notthatbreezy/skills@0173d30141c20aae6f51c4064eb8fb8989fa27a3
Execution Binding: none
Workflow Mode: custom
Review Strategy: local
Review Policy: final-pr-only
Session Policy: continuous
Final Agent Review: enabled
Final Review Mode: society-of-thought
Final Review Interactive: true
Final Review Models: gpt-5.6-sol-fast, gemini-3.8-flash, grok-4.6
Final Review Specialists: all
Final Review Interaction Mode: parallel
Final Review Specialist Models: gpt-5.6-sol-fast, grok-4.6, gemini-3.8-flash
Final Review Perspectives: auto
Final Review Perspective Cap: 2
Implementation Model: none
Plan Generation Mode: single-model
Plan Generation Models: gpt-5.6-sol-fast
Planning Docs Review: enabled
Planning Review Mode: multi-model
Planning Review Interactive: false
Planning Review Models: gpt-5.6-sol-fast, gemini-3.8-flash, grok-4.6
Planning Review Specialists: all
Planning Review Interaction Mode: parallel
Planning Review Specialist Models: none
Planning Review Perspectives: auto
Planning Review Perspective Cap: 2
Custom Workflow Instructions: Use PAW Lite stages: preserve approved shaping decisions, create WorkShaping.md plus the explicitly requested Spec.md and Plan.md, run the configured multi-model planning review, and pause for human approval before product implementation. Later implementation, final review, and PR stages remain separate gates. Do not install Ripwire, change host MCP configuration, publish, push, or open a PR during initialization or planning.
Implementation Authorization: Phase 0 evidence accepted on 2026-09-10. Complete remaining implementation, documentation, review, and progressive updates to existing draft PR #3 without routine phase approvals. Pause for genuine blockers, critical scope changes, and interactive review decisions. Keep the PR description current; do not create another PR or merge.
Worker Model Policy: Explicit OpenAI (preferred), Grok, Gemini, or MAI models only for workers, reviewers, synthesis, and all descendants. Anthropic/Claude prohibited. Medium reasoning and default context required; never maximum/1M context.
Final Review Requirements: Parallel SoT with interactive findings, as explicitly selected by the user. Include all discovered specialists and the type-safety lens; assign at least one specialist to Grok. One parallel initial sweep and synthesis, not debate rounds. Model restrictions override stale persona defaults. Discuss actionable findings one at a time.
Completion Reporting: Report completion or a concrete blocker to the home chat; include delivered versus incomplete scope and existing draft PR status.
Initial Prompt: Create a portable self-contained Copilot plugin skill toolkit that runs Linux Ripwire in Ubuntu WSL against the current Windows session worktree, with a stable launcher, repeatable pinned and checksummed installation, diagnostics, agent instructions, and existing-runner-compatible regression coverage. Keep machine-local settings out of version control and defer MCP integration unless explicitly added later.
Issue URL: none
Remote: origin
Artifact Lifecycle: commit-and-clean
Artifact Paths: auto-derived
Additional Inputs: none
