# Changelog

## 1.4.0

- Add the packaged `scope-creep-reviewer` agent for tracing planned work to approved requirements
  and distinguishing necessary enabling work from unauthorized expansion.
- Expand the mandatory custom PAW planning gate from five reviewers to six by adding the dedicated
  scope-creep seat.
- Bump plugin and marketplace manifests to version `1.4.0`.

## 1.3.1

- Move canonical repository and package identity references to `notthatbreezy/skills` while
  preserving the installed `brownch-devtools` marketplace and plugin names.
- Add explicit marketplace source migration to the installer without silently replacing existing
  repository or local-development registrations.
- Define cross-phase artifact hygiene and its setup, delegation, and recovery mechanics.
- Bump the delegation orchestrator to v1.0.2 for its canonical source identity update.
- Bump plugin and marketplace manifests to version `1.3.1`.

## 1.3.0

- Add the `delegation-orchestrator` custom agent (v1.0.1 amendment text) to the installable plugin package.
- Add the `delegation-type-safety` skill used by the orchestrator's focused type-safety reviewer seat.
- Add the modular custom PAW workflow skills:
  `custom-paw-workflow`, `custom-paw-setup`, `custom-paw-plan`, `custom-paw-plan-gate`,
  `custom-paw-implement-phase`, `custom-paw-finalize`, `custom-paw-deliver`,
  `custom-paw-delegation`, `custom-paw-review-policy`, and `custom-paw-recovery`.
- Normalize custom workflow cross-links to package-relative skill paths and remove draft-only adoption/evidence references.
- Bump plugin and marketplace manifests to version `1.3.0`.

## 1.2.0

- Add the self-contained `paw-moderated-local-reviewer` agent.
- Remove the Tennex planning and execution skills.
- Remove the reusable reviewer's dependency on the generic `reviewer` skill.
