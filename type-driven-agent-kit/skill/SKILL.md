---
name: type-driven-development
description: Use for substantial type-oriented design or refactoring involving domain models, trust boundaries, state machines, public APIs, data parsing, typed holes, ADTs, impossible states, compiler-guided migration, or an explicit request to improve type safety.
---

# Type-Driven Development

Use the type system as an implementation partner. The goal is not maximal type sophistication; it is to make important mistakes difficult or impossible to express while keeping the code idiomatic and maintainable.

## Desired Outcome

Prefer a program where:

- raw external values cannot reach domain logic without parsing;
- invalid domain states cannot be constructed through public APIs;
- state transitions expose only legal operations;
- adding a case breaks incomplete consumers at compile time;
- compiler errors identify unfinished integration work;
- runtime checks remain only where runtime information enters the system;
- the complexity of the model is proportional to the failure it prevents.

## Workflow

### 1. Establish the Domain and Constraints

Before changing types:

1. Inspect compiler settings, language version, existing domain patterns, schemas, and boundary libraries.
2. State the domain invariants in plain language.
3. Identify the authoritative source for each shape: domain model, protocol schema, database schema, configuration schema, or external contract.
4. Distinguish compatibility constraints from accidental legacy looseness.

Reason from domain intent to type design to language mechanics. Do not patch a compiler symptom before understanding which invariant the compiler is trying to protect.

### 2. Map Trust Boundaries

Treat CLI arguments, environment variables, configuration, files, network payloads, queue messages, database rows, deserialized values, and third-party responses as untrusted.

At each entry point:

1. Accept the language's raw or unknown representation.
2. Parse the complete input before performing effects.
3. Return a domain value or a structured parse error.
4. Map transport and storage types to domain types.
5. Keep raw representations from leaking through domain-facing APIs.

Do not revalidate parsed values in the core. If internal code repeatedly checks the same condition, the parser or domain type is not carrying enough evidence.

### 3. Design the Valid State Space

Choose the smallest idiomatic representation that encodes the invariant:

- **Mutually exclusive cases**: sum type, discriminated union, enum with payload, or sealed hierarchy.
- **Semantic primitive**: newtype, branded type, value object, or opaque alias with a smart constructor.
- **Valid lifecycle**: typestate, state-specific interfaces, or transition functions that consume one state and return another.
- **Required staged construction**: builder whose final operation is unavailable or fallible until required fields exist.
- **Capability**: marker type, trait/interface constraint, phantom type, or dedicated capability token.
- **Non-empty or bounded collection**: structural wrapper with controlled construction.

Prefer one authoritative representation. Derive booleans and summaries instead of storing fields that can disagree.

### 4. Localize Partiality

Search changed code for:

- assertions, force unwraps, null-forgiving operators, unchecked indexing, unsafe casts, and suppression directives;
- comments such as "must already be valid" or "cannot happen";
- exceptions used for ordinary invalid input;
- functions that validate but return no refined value;
- broad strings, integers, or option bags representing a finite domain.

Select the contract based on meaning:

- If invalidity is expected at a boundary, return `Result`/`Either`/a structured parse outcome.
- If absence is a normal domain result, return `Option`/`Maybe`/the language equivalent.
- If the caller logically possesses a stronger invariant, strengthen the argument type rather than weakening every return path.
- If a branch should be impossible after parsing, redesign construction so the compiler can prove it.

### 5. Implement Type-First

For new work, define the domain types and public signatures before implementation. For refactoring:

1. Add characterization tests for behavior that must not change.
2. Introduce the intended signatures, ADTs, or constructors.
3. Use language-supported typed holes or temporary compiler-visible placeholders on the working branch.
4. Treat compiler errors as an explicit dependency-ordered work queue.
5. Resolve leaf obligations first, then propagate changed constraints to callers.
6. Type-check after each coherent step.
7. Split a hole when it spans unrelated invariants, multiple subsystems, or cannot be completed safely in the current change.
8. Remove every placeholder before completion.

Do not silence errors with broad casts just to regain a green build. That converts useful compiler output into delayed production archaeology.

### 6. Make Consumption Exhaustive

Use the language's strongest available exhaustiveness mechanism:

- pattern matching over closed variants;
- sealed or closed hierarchies;
- a `never`/unreachable proof in default branches where required;
- compiler warnings promoted to errors when consistent with repository policy.

Avoid catch-all branches that silently absorb future variants unless forward compatibility explicitly requires them. At external protocol boundaries, preserve an explicit unknown case when the protocol can evolve independently.

### 7. Verify the Proof Boundary

Before completion, confirm:

- external raw values are parsed before domain use;
- public constructors cannot create invalid values;
- illegal state combinations are structurally absent;
- transitions accept only legal source states;
- escape hatches are removed or narrowly documented;
- schema-derived and handwritten types do not duplicate authority;
- new variants force incomplete consumers to fail compilation;
- type checking and targeted behavioral tests pass.

Tests still matter. Types prove structural properties; tests verify boundary behavior, semantics, integrations, and properties the language cannot express.

## Cross-Language Pattern Map

| Intent | Typical mechanisms |
|---|---|
| Sum/ADT | Rust enum; TypeScript discriminated union; C# sealed records; Kotlin/Scala sealed types; Swift enum; tagged structs plus private constructors where necessary |
| Refined value | Rust newtype; TypeScript brand plus parser; C# readonly record struct/value object; opaque type/private constructor |
| Fallible construction | `Result`, `Either`, `TryParse`, smart constructor, schema parser |
| Exhaustiveness | `match`, expression `switch`, sealed-type analysis, `never` assertion |
| Lifecycle | typestate generics, state-specific interfaces/classes, transition functions |
| Boundary schema | Zod/Valibot/JSON Schema, Serde plus validation, `System.Text.Json` plus domain mapping, generated OpenAPI/Protobuf/GraphQL types |

Follow repository idioms before importing a new library or advanced pattern.

## Language Notes

### TypeScript

- Keep external values `unknown` until parsed.
- Prefer schema-first parsing and infer static types from the schema.
- Use discriminated unions and `satisfies`; avoid assertion-driven narrowing.
- Use branded IDs when same-shaped identifiers can be swapped.
- Respect and improve existing strictness incrementally; do not conceal missing strictness with `as`.

### Rust

- Use newtypes and private fields for invariants.
- Use enums for state and `Result` for boundary failures.
- Use typestate, marker traits, and `PhantomData` when they remove illegal operations without obscuring ordinary code.
- Treat `unsafe` as a separately audited proof boundary with documented invariants.

### C#/.NET

- Enable nullable reasoning already supported by the project; avoid the null-forgiving operator as a design substitute.
- Use sealed records/classes for closed variants and readonly record structs for small semantic values when appropriate.
- Use private constructors with `TryCreate`/result-returning factories for invariants.
- Expose read-only collection contracts and keep mutable representation private.

### Less Expressive or Dynamic Type Systems

Use the strongest practical static checker, tagged data models, opaque modules, explicit parse results, and exhaustive tests. Do not pretend annotations validate runtime input. Encapsulation and boundary parsing remain useful even when the compiler cannot prove the full model.

## Guardrails

- Do not wrap every primitive. Add a semantic type when it prevents interchange, centralizes a real invariant, or clarifies a domain boundary.
- Do not replace clear runtime code with type-level puzzles the team cannot maintain.
- Do not create a second schema to gain prettier local types; derive or map from the authority.
- Do not spread parsing through business logic or perform effects before input parsing completes.
- Do not expose transport, ORM, or framework types as the domain API merely because they already exist.
- Do not claim guaranteed correctness beyond what the type system proves.
- Do not expand a focused change into an architectural rewrite. Record larger opportunities for deliberate follow-up.

## Sources and Inspiration

This skill is an original synthesis of ideas from:

- [Parse, don't validate](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/)
- [cc-polymath typed-hole and programming-language-theory skills](https://github.com/rand/cc-polymath)
- [actionbook Rust type-driven skills](https://github.com/actionbook/rust-skills)
- [PStack boundary discipline](https://github.com/cursor/plugins/blob/main/pstack/skills/principle-boundary-discipline/SKILL.md)
- [PStack type-system discipline](https://github.com/cursor/plugins/blob/main/pstack/skills/principle-type-system-discipline/SKILL.md)
- [Type-safety validation](https://github.com/ArieGoldkin/ai-agent-hub/blob/main/skills/type-safety-validation/SKILL.md)
- [C# type design and performance](https://github.com/Aaronontheweb/dotnet-skills/blob/master/skills/csharp-type-design-performance/SKILL.md)
- [Offensive type safety](https://github.com/jonmumm/skills/blob/main/offensive-typesafety/SKILL.md)
- [Type-safety review](https://github.com/doodledood/codex-workflow/blob/main/skills/review-type-safety/SKILL.md)
