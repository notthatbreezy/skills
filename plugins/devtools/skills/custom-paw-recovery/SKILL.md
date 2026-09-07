---
name: custom-paw-recovery
description: Consult when presenting or revising documents or recovering authority and state after interruption.
---

# Presentation, persistence and recovery

## 1. At entry

Recover exact identities and grants before replaying any side effect. Presentation is not an approval action.

**Consult:** `planning-review-canvas` for document readers; `html-visuals` for layout and `canvas-apps` for interactive/shared behavior; `paw-status` for workflow recovery.

## 2. Present and recover without changing authority

When presenting planning, use the planning-review-canvas skill: full current documents, instant local navigation, exact Source, source hashes, and a clear separation of current text from historical reviews. Open the document already under discussion. Reading or requesting a canvas does not approve it. Do not add approval controls unless requested; real authorization must be recorded explicitly.

Persist decisions, current pointers/hashes, grants, review lineage, phase status, known remote writes, and next authorized action. Use facts for compact state and artifacts for applicable file outputs at their declared stable current names and locations. Repository planning commits, when required, are separate from session artifacts. Pinned artifacts support session recovery but are not a permanent repository backup.

After interruption, reload durable state and inspect actual local/remote state. Do not blindly recreate a worktree, duplicate a commit or PR, consume an old child completion as current evidence, or re-ask a source that already supplied a complete reply. Check hashes and timestamps; reconcile drift before resuming.

For document changes, update the authoritative body and affected references, mappings, and current pointers. A superseded banner does not repair contradictory text. Keep a previous output only when its exact-input history, required report, dissent, disposition, approval, or lineage remains applicable. Preserve its hashes and links, and do not transfer its verdict to new bytes.

On recovery, reconcile declared authoritative outputs against repository and active-stage requirements; do not recreate optional checklist files. Consolidate redundant evidence only after verifying the surviving durable copy and retaining required lineage. Clean up only bounded scratch owned by this workflow after its accepted durable handoff; never delete unrelated files, another owner's scratch, or a repository, workspace, session, or artifact-store root.

If recovery cannot establish the next authorized action, pause with a specific question. Otherwise resume that action rather than spending repeated turns restating status.

## 3. Return

Return reconciled phase status, current pointers, completed writes and the next authorized action to the root router. Unknown authority blocks action.
