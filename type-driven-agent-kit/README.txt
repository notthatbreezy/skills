TYPE-DRIVEN AGENT KIT

Requirements
------------
- Windows PowerShell 5.1 or PowerShell 7
- GitHub Copilot CLI
- PAW, if you want Society-of-Thought integration

Install on the Dev Box
----------------------
1. Copy this entire folder, or type-driven-agent-kit.zip, to the Dev Box.
2. Extract the ZIP if necessary.
3. Open PowerShell in the extracted folder.
4. Run:

   Set-ExecutionPolicy -Scope Process Bypass
   .\Install-TypeDrivenAgentKit.ps1

5. Restart Copilot CLI.

Installed locations
-------------------
%USERPROFILE%\.copilot\copilot-instructions.md
%USERPROFILE%\.copilot\skills\type-driven-development\SKILL.md
%USERPROFILE%\.copilot\agents\type-safety-reviewer.agent.md
%USERPROFILE%\.paw\personas\type-safety.md

The installer preserves unrelated Copilot instructions, replaces only the
marked type-driven instruction block, and backs up existing destination files
under %USERPROFILE%\.type-driven-agent-kit-backup\.

If COPILOT_HOME is set, the installer places Copilot instructions, skills, and
agents there instead of %USERPROFILE%\.copilot. PAW personas remain under
%USERPROFILE%\.paw, as required by PAW discovery.

Usage
-----
Implementation:
  Use the type-driven-development skill to redesign this state model.

Standalone review:
  copilot --agent type-safety-reviewer --prompt "Review the current branch diff"

PAW Society-of-Thought:
  Set "Final Review Mode" to "society-of-thought" and set
  "Final Review Specialists" to "all" or explicitly include "type-safety".
