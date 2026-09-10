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
Final Review Interaction Mode: debate
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
Final Review Requirements: User switched the existing SoT to debate mode on 2026-09-10. Reuse the completed parallel sweep as round 1; continue threaded rounds with all discovered specialists, including type-safety and Grok participation. Use the SoT adaptive termination and round/continuation limits. Preserve explicit F01-F03 user decisions. Model restrictions override stale persona defaults. Escalate genuine trade-offs interactively, one at a time.
Review Remediation Gate: Satisfied on 2026-09-10 after three global debate rounds and explicit disposition of all 17 threads. Remediate only the approved runtime change (F03 inherited Git redirection rejection) and documentation-only limits (F02, F04, F07, F08, F11), then perform verification review. Diagnose the deferred F03 integration workspace-snapshot failure without weakening its non-mutation oracle.
Review Decisions: F01 preserve unsafe-cache guards; F02 document interruption limits; F03 reject unsupported Git redirects; F04 trusted configuration with documentation only; F05 withdraw; F06 defer repeatability; F07 document orphan/old-release cleanup limits; F08 retain structured failure with retry guidance; F09/F10/F16 defer unmeasured performance proposals; F11 document unsupported concurrent setup against one config; F12 keep diagnostics; F13 withdraw; F14 preserve bounded locks and skip folded error-formatting proposal; F15 keep existing coverage; F17 withdraw. Do not reopen accepted scope in verification review without materially new evidence.
Review Outcome: Complete. All approved remediation is applied; nine specialist verification workers plus the parent testing lens reported no actionable findings. Isolated fresh-install integration passed 20 groups with successful cleanup and the strict non-mutation oracle intact. Preserve all accepted limits. Final handoff updates existing draft PR #3 and retains planning documents in commit history under commit-and-clean; no merge is authorized.
Completion Reporting: Report completion or a concrete blocker to the home chat; include delivered versus incomplete scope and existing draft PR status.
Initial Prompt: Create a portable self-contained Copilot plugin skill toolkit that runs Linux Ripwire in Ubuntu WSL against the current Windows session worktree, with a stable launcher, repeatable pinned and checksummed installation, diagnostics, agent instructions, and existing-runner-compatible regression coverage. Keep machine-local settings out of version control and defer MCP integration unless explicitly added later.
Issue URL: none
Remote: origin
Artifact Lifecycle: commit-and-clean
Artifact Paths: auto-derived
Additional Inputs: none
