<!-- type-driven-development start -->
## Type-driven development

Before finalizing edits to typed code or interfaces, inspect changed boundaries, public signatures, state models, and assertions for opportunities to move runtime assumptions into compiler-checked types.

- Treat external data as untrusted. Parse it once at the boundary into domain types, return structured errors, and trust those types internally instead of scattering validation.
- Prefer ADTs, discriminated unions, sealed hierarchies, typestate, or equivalent closed models over boolean flags and bags of optional fields that admit contradictory states.
- Use semantic value types for primitives that carry invariants or are easy to interchange accidentally. Keep construction validated and representation encapsulated.
- Preserve evidence in types: if a check proves a property, return a refined value rather than `void` or the original loose value.
- Make matching exhaustive so adding a variant creates compiler errors at every incomplete consumer.
- Derive types from authoritative schemas instead of maintaining parallel handwritten shapes.
- Treat `any`, unchecked casts, non-null assertions, unsafe coercions, and "impossible" defaults as proof gaps. Eliminate them or confine and justify them at a narrow boundary.
- Strengthen types only when the prevented failure justifies the added ceremony. Do not introduce wrappers or type-level machinery merely because the language permits recreational mathematics.

Apply localized, proportional improvements during the requested change. Surface broader type-oriented architectural opportunities without silently expanding scope. Use the `type-driven-development` skill for substantial domain modeling, boundary design, state-machine work, or compiler-guided refactoring.

For PAW Society-of-Thought reviews, set WorkflowContext `Final Review Specialists: all` or explicitly include `type-safety` (the SoT review-context key is `specialists`); adaptive selection alone does not guarantee that lens.
<!-- type-driven-development end -->
