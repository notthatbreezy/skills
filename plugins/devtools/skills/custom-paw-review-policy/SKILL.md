---
name: custom-paw-review-policy
description: Consult before commissioning reviews or adjudicating findings to preserve independence, grounding and authority.
---

# Shared review and remediation policy

## 1. At entry

Use in planning, phase and final review. Confirm the owner's remediation policy before any fix. This companion does not replace the phase-specific acceptance gate.

## 2. Review lineage

Initial reviewers receive requirements and source evidence without the author's preferred verdict or earlier reviewers' conclusions. After the first reports are preserved, reuse seats for bounded correction closure. Label those rounds accurately: **independent initial review**, **prompted closure**, and **coordinator synthesis of panel findings** are different evidence. The coordinator verifies and combines reports; its synthesis is not another independent reviewer.

After revisions, freeze new inputs and re-review affected obligations. If a defect is systematic, inspect its affected population rather than only the examples the reviewer named. A structural/schema PASS does not establish semantic correctness.

Preserve failed reports, dissent, rejected findings, and the reasons for demotions. Neither a cycle cap nor agreement among reviewers authorizes advancement with an unresolved blocker. At the budget limit or repeated no-progress, present the blocker and a bounded next decision.

## 3. Adjudicate findings before remediation

The coordinator verifies each surviving finding against source and requirements before presenting it as established. Reviewers are fallible; preserve useful rebuttals and reject unsupported recommendations rather than echoing them.

Use stable finding IDs. Record severity separately from posting or action disposition:

| Evidence | Decision record |
| --- | --- |
| Exact source/revision, file-and-symbol or verified lines, failure scenario, violated invariant, counterexample or evidence gap. | Original severity, confidence, direct/inferential grounding, reviewer and round provenance. |
| Impact attributable to this change versus pre-existing behavior; smallest sufficient correction; focused falsifying test. | Parent verification, rebuttal/dissent, complexity and tradeoff, owner/checkpoint, applied/rejected/deferred/waived status. |
| After-fix evidence and affected interfaces/consumers. | Current closure hash and scope; publication disposition such as blocking, non-blocking, report-only, or pending comment. |

Select the remediation policy explicitly:

| Policy | Behavior |
| --- | --- |
| Human-first | Present every verified finding or tight cluster before any remediation. Wait for the user's disposition. |
| Bounded autonomous | Fix only verified, localized, spec-preserving issues inside existing write authority with no material design tradeoff; report changes and obtain closure evidence. |
| Review-only | Produce findings and dispositions; make no source changes. |

Human-first overrides smart/automatic fix defaults. Under bounded autonomy, direct high-confidence evidence is necessary but not sufficient: a public contract, migration, security boundary, accepted rollout tradeoff, new dependency, or material scope decision still needs a human decision.

Present one decision at a time in plain language: the observed behavior, evidence, consequence, smallest correction, alternatives, what each option does not fix, and the action you recommend. Do not ask the user to adjudicate an unverified pile of reviewer speculation.

## 4. Return

Return stable finding IDs, source-verified dispositions, dissent, remaining blockers and exact closure inputs to the invoking phase. No verdict authorizes publication.
