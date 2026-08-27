---
name: evidence-based-technical-communication
description: "Human-facing technical updates, reviews, handoffs, diagnoses, and explanations: identify what matters, verify the immediate cause and consequence from workspace evidence, and communicate the result clearly."
---

# Evidence-based technical communication

Use this skill when reporting technical work to a human. Decide what they need to know, gather enough evidence to explain it, and write the result clearly.

## 1. Identify what matters

Start with the outcome that affects the human:

- What changed, passed, failed, or remains blocked?
- Why does it matter now?
- Does the human need to decide, act, investigate, or simply know?

Lead with the outcome that matters to the human. Include workflow state when it explains what happened, limits what can happen next, or helps another person continue the work.

**Complete when:** you can state the main outcome in one concrete sentence and name why the human needs it.

## 2. Gather the missing evidence

Find the immediate cause, consequence, and next action when they are relevant to the outcome. Use the smallest set of targeted workspace checks that can answer those questions, such as the latest test result, review state, error output, or changed artifact.

Stop when either:

- direct evidence answers the relevant questions; or
- the targeted sources do not contain the answer.

Do not start an open-ended diagnosis merely to write an update. If deeper investigation is required, report that as the next action.

Classify each important claim:

- **Reported:** stated by a person, tool, artifact, or log but not yet independently confirmed.
- **Verified:** confirmed against the current authoritative source.
- **Supported:** follows from verified evidence through an explicit connection.
- **Unknown:** the available evidence does not answer it.

Treat every report as a claim to verify. When verification is quick and relevant, check the current authoritative source. When sources disagree, or verification would require a lengthy investigation, report the disagreement or uncertainty instead of silently choosing one account.

Never turn nearby facts into cause and effect without evidence.

Check only sources directly responsible for the reported outcome, such as the failing command, current review state, or referenced artifact. If those sources do not explain the outcome, stop and report what remains unknown. Do not expand into unrelated systems or begin root-cause analysis unless the human asked for diagnosis.

The **immediate cause** explains the current outcome. A **root cause** explains why that immediate failure occurred. Report the immediate cause by default. Include a known root cause when it changes the human's decision or next action; otherwise leave deeper diagnosis for separate work.

**Complete when:** the outcome, its known immediate cause, its consequence, and its next action are each verified, supported, or explicitly marked unknown.

## 3. Select useful details

Keep information that helps the human:

- understand the outcome;
- judge its importance;
- take the next action; or
- investigate further;
- verify what was tested or observed; or
- continue the work safely.

Technical details may include exact errors, commands, file paths, identifiers, test results, reproduction steps, cleanup state, retained artifacts, and work that was not run.

When a detail matters but would distract from the main outcome, group it after the main message rather than removing it. When you cannot determine whether a detail matters to the intended audience, keep it and make its role clear.

**Complete when:** the message clearly separates the main outcome from supporting evidence and handoff information.

## 4. Write the message

Lead with the outcome. Follow with the verified cause, consequence, and next action when relevant.

Use named nouns, active verbs, and concrete language. Explain necessary technical terms in place:

> Two related artifacts contained hashes that should match but did not.

Write causal relationships explicitly when evidence supports them:

> Revision 5 is blocked because the artifacts contain conflicting hashes.

When the facts are unrelated, explain the actual cause:

> The checks missed conflicting hashes, but Revision 5 is blocked because it still needs reviewer approval.

When the cause is unknown, preserve the gap:

> Revision 5 is blocked, but the available status and logs do not say why. The next step is to inspect the validation run.

Do not imply that resolving one problem will unblock the work unless the evidence shows it is the only remaining blocker.

## 5. Verify before sending

Confirm that:

- the first sentence gives the human the main outcome;
- every stated cause is supported by evidence;
- uncertainty remains visible;
- the consequence and next action are clear when the human needs them;
- technical details are organized so the reader can understand why they are included; and
- the likely recipient can understand the message without decoding unexplained internal shorthand.

Rewrite until every check passes.

## Example

Evidence available in the workspace:

> Automated checks passed but did not compare hashes across related artifacts. The artifacts contain conflicting hashes. Revision 5 cannot proceed while that mismatch exists. A separate cache warning did not affect the result.

Human-facing update:

> Revision 5 is blocked because two related artifacts contain hashes that should match but do not. The automated checks passed because they checked each artifact separately and missed the conflict. The next validation must compare the hashes across both artifacts.

Supporting detail:

> A separate cache warning also appeared, but it did not affect this result.
