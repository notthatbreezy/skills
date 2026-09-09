---
name: custom-paw-review-policy
description: Consult before commissioning reviews or adjudicating findings to preserve independence, grounding and authority.
---

# Shared review and remediation policy

## 1. At entry

Use in planning, phase and final review. This companion does not replace the phase-specific acceptance gate.

## 2. Review lineage

After the first reports are preserved, reuse seats for bounded correction closure. Label those rounds accurately and keep them distinct.

If a defect is systematic, inspect its affected population rather than only the examples the reviewer named. A structural/schema PASS does not establish semantic correctness.

## 3. Adjudicate findings before remediation

Verify each surviving finding against source and requirements before presenting it as established. Reviewers are fallible; preserve useful rebuttals and reject unsupported recommendations rather than echoing them.

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
