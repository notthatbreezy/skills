---
name: ripwire-wsl
description: Use Ripwire to explore a Windows Git worktree through an existing Ubuntu WSL installation. Use for repository orientation, symbol relationships, targeted source context, and Git-backed change analysis.
---

# Ripwire WSL

1. Identify the current Windows session worktree. Keep this exact checkout as the target.
2. Run the bundled `scripts/Invoke-RipwireWsl.ps1` with PowerShell 7, `-WorktreePath`
   set to that root, and optional `-RipwireArguments` as a string array.
   Start without arguments for orientation; use `@('--for=SymbolName')` for focused context.
3. Use returned repository-relative paths with Windows tools. Read
   [the guide](references/guide.md#paths-and-scope) when a result contains a Linux absolute path.
4. Keep source edits, builds, tests, and Git mutations on Windows. Ripwire is for exploration;
   its managed Linux cache is derived data, not a project baseline.

For missing setup, diagnostics, the accepted option grammar, cache maintenance, or an unsupported
request, read [the guide](references/guide.md) before acting. Report a failed prerequisite rather
than substituting another checkout or installing/enabling WSL. Setup requires explicit human
authorization; plugin installation alone does not install Ripwire.

MCP, arbitrary upstream flags, project baselines, and quality-gate workflows are outside this
skill's CLI contract. Surface a rejection rather than bypassing the launcher with raw WSL commands.
