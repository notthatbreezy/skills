---
name: custom-paw-implement-phase
description: Implement one authorized PAW phase, integrate its deliverables and establish meaningful closure evidence.
---

# Phase 4: Implement and close one phase

## 1. At entry

Load paw-implement - everything that follows is meant to to supplement and in some cases override the default implementation guidance.

**Consult before work:** `paw-implement`, then `paw-impl-review`; `type-driven-development` for substantial type-oriented changes. Consult `paw-docs-guidance` for phase documentation. Before starting this phase, load the required skills and follow their instructions.

**Required-skill availability:** If any skill required for the current phase is unavailable or cannot be loaded, stop the phase and report BLOCKED to the user. Name the missing skill, explain which work it blocks, and state what is needed to proceed. Do not skip it, reconstruct its instructions from memory, or substitute another skill or reviewer without explicit user approval. Resume only after the required skill is available or the user explicitly approves a revised requirement. Missing required external skills, named agents, or specialist personas remains BLOCKED until resolved or explicitly waived by the user.

**Exit gate:** Integrated deliverables, passing required evidence, usable downstream handoffs, and a current `paw-impl-review` report bound to the integrated phase revision satisfy the phase contract. Adjudicate findings under `custom-paw-review-policy`; unresolved blockers or FAIL/BLOCKED review outcomes prevent closure. Honor the phase human stop before advancing.

Run the smallest existing checks that establish the changed behavior, plus every command the repository or user mandates at its designated checkpoint. Install or restore dependencies only when the task requires dependency changes or a chosen command establishes that required tools are missing.

Where feasible, falsify a regression test by temporarily disabling the relevant guard in an isolated authorized checkout, confirm the intended assertion fails, then restore it. Verify injected failures reach the intended operation; an earlier consumer of the injection can make a test meaningless. Never perform fault injection against live systems without its own authorization.

After integration, run `paw-impl-review`.
