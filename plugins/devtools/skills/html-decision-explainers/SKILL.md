---
name: html-decision-explainers
description: Explain a design decision whose consequences unfold over time or across states by building one self-contained HTML page for review. Use when a reviewer must compare current behaviour, proposed behaviour, and rejected alternatives, or must see where a state machine ends up. Produces the HTML page and stops there. Not for a handful of exact values — that is still a Markdown table.
metadata:
  version: "1.1.0"
  origin: "Generalized from a six-round pre-PR review (dbagent #1211), 2026-09-05"
---

# HTML Decision Explainers

Prose is bad at multi-state consequences. Every individual fact can be stated
correctly and the reader still cannot decide, because they are being asked to
simulate several timelines in their head *while also* judging the decision.

A self-contained HTML page removes the simulation step. Put the timelines side by
side and the answer becomes visible rather than inferable.

## When to reach for this

**Trigger signals**, any one of which is enough:

- The reviewer asks the same question twice, or asks "what is the end state?"
- A finding requires comparing *current*, *proposed*, and *rejected* behaviour.
- The consequence is a **stuck state** or an **ordering hazard** — something that
  only shows up after N repetitions or in one interleaving.
- You catch yourself writing "and then, on a later run…" for the third time.

**Do not use it when** the answer is a handful of exact values. That is a Markdown
table. Reaching for HTML there is decoration, and it costs the reader a context
switch for nothing.

## The layouts that work, in order of value

### 1. Situations as rows, versions as columns

The highest-value layout. Columns are `today` / `this change` / `proposed`. Rows are
the *same concrete situations* under each.

The reader scans one row to see how a single situation differs across versions, or
one column to see a whole world. Both readings are useful, which is why this beats
three separate diagrams.

Give every cell a small muted **"why" line** under the verdict. Without it you have
a grid; with it you have an explanation.

### 2. Follow one subject through time

Do not describe a state machine abstractly. Walk **one** entity — one server, one
issue, one request — through four or five concrete episodes and show its state after
each.

A stuck state is unmissable when the same cell reads `still Diagnosed` four columns
running. The same fact in prose ("the issue is never retired") slides straight past.

### 3. Make boundaries explicit when asked

When the reviewer asks where some enclosing scope begins and ends, add a dashed
**lifecycle band** row between the run rows.

This is worth doing even if you think you understand the system: in the origin
session, adding these bands surfaced that two entities had *deliberately decoupled*
lifetimes — a design fact neither the reviewer nor the author had articulated. The
diagram taught the author, not just the reader.

### 4. Three-column failure comparison

For "ordering A vs ordering B vs proposed": hold the **failure constant** and vary
only the ordering. Each column ends in a verdict block — what state is left behind,
and whether it is recoverable.

### 5. Kill the comforting explanation

If anyone offered a reason the problem is harmless — **especially if that anyone was
you** — verify it and show the working in its own section.

This is where credibility is won. A page that quietly drops a mitigation the author
previously claimed reads as evasion; a page that says "I claimed X, I checked, X is
false, here is why" reads as trustworthy.

### 6. State the accepted cost

A page that only argues for the recommendation is advocacy.

Include a **"what this does NOT fix"** or **"what is not lost"** block. In the origin
session that block is what let the reviewer accept a disclosed limitation instead of
demanding a larger fix — it made the residual risk small and legible rather than
unknown.

## Craft rules

- **Dark palette, semantic colour only.** Red = bad, green = good, amber = caution,
  purple = a lifecycle band. Never colour alone — always pair it with a word or a
  symbol, or a red/green reader learns nothing.
- **One "how to read this" line under every section heading.** Charts do not explain
  themselves.
- **Monospace only for real identifiers.** If everything is monospace, nothing is.
- **CSS grid with `minmax()`** so it reflows; give any SVG a `viewBox`.
- **Fully self-contained.** No CDN, no web fonts, no remote images, no `fetch`.
  Inline every byte.
- **Footer lists sources**, and labels which claims were *reproduced live* versus
  reasoned about. Traceability is what makes the page reviewable rather than
  decorative.

## Delivery

Use the supported `draw_canvas` visual surface by default. Use `show_artifact` when
the user explicitly wants a file. The previously reported portal cross-session
display defect was repaired and re-verified, so do not default to local temp files.

When the portal is unavailable or a local-browser view is explicitly needed:

1. Write the file to a temporary path.
2. Verify its size and `<title>`.
3. Launch it with the OS default handler.
4. Print the absolute path as an environment-specific fallback.

If none of these delivery surfaces is available, explain the limitation instead of
claiming the page was presented.

## Where this skill stops

This skill produces **one HTML page for local review**, and ends there.

It does not convert the page into another format, does not write it into any
document, and does not decide what ships anywhere. If the reviewer asks for a
follow-on artefact after reading the page, treat that as a separate task with its own
requirements rather than an implied part of building the explainer.

## Template

A working template with all of the above wired up, including the full CSS and inline
comments on when each section earns its place, is stored alongside this skill as
`template.html`. Confirm it exists before relying on it, and reuse it rather than
rebuilding the page from scratch.

## Scope caveat

Generalized from one long code-review session with one reviewer on a Windows
workstation and corroborated once against the repaired portal display path. The
**layouts** should transfer to any multi-state design decision; re-corroborate the
practice in other settings rather than treating one environment as universal.
