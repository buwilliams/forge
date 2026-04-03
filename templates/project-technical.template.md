# Project Spec: [Work Name]

<!-- This is a technical project spec — for software, infrastructure, tooling, or any work
     where code is the primary deliverable. Forge will use this as the design.md that drives
     council selection, pipeline design, and task decomposition.

     Be specific about requirements and constraints. Vague specs produce blocked tasks.
     The more concrete your constraints and acceptance criteria, the better Forge's output. -->

## Goal

<!-- One paragraph. What concrete, observable outcome will exist when this project is done?
     Not "improve performance" — "p99 latency under 200ms for the search endpoint with 10k records."
     Not "add auth" — "users can sign up, log in, and reset their password via email." -->


## Why This Matters

<!-- Why now? What breaks or stays broken without this? What does it unlock?
     This becomes context for every task agent — they'll make better tradeoffs when they understand why. -->


## Deliverables

<!-- What specifically will exist when this project is complete? List concrete artifacts.
     For software: files, endpoints, commands, UIs, integrations.
     Each entry here should be verifiable — something a test or human can confirm exists and works. -->

- [ ] 
- [ ] 
- [ ] 

## Tech Stack

<!-- Be explicit. Forge generates agents tailored to your stack.
     List what you want used — this prevents agents from introducing unwanted dependencies. -->

- Language: 
- Runtime / Platform: 
- Key dependencies: 
- Build tool: 
- Package manager: 

## Architecture Overview

<!-- How does the system fit together? What are the main components?
     Even a few sentences prevents agents from making incompatible architectural decisions. -->


## Testing Requirements

<!-- What kinds of tests are required? What coverage is expected?
     "All code tested" is too vague. "All public functions have unit tests; all HTTP endpoints have integration tests" is testable. -->

- Unit tests: 
- Integration / end-to-end tests: 
- Test framework: 
- Coverage threshold: 
- What must never be mocked (must use real implementations): 

## Code Quality

<!-- Linting, formatting, and type-checking standards. These become Global Constraints.
     List the commands that must pass: e.g., `npm run lint`, `cargo clippy -- -D warnings` -->

- Linter / static analysis: 
- Formatter: 
- Type checking: 
- Commands that must exit 0: 

## Constraints

<!-- Non-negotiable technical rules for this project. These are injected into every Forge task.
     Write them as checkable assertions. Be specific.
     Examples:
       - "No TypeScript `any` or `@ts-ignore` in src/"
       - "No direct database access outside src/db/"
       - "All secrets via environment variables — never in source"
       - "No dependencies not listed in package.json" -->

- 
- 
- 

## Performance Requirements

<!-- Are there latency, throughput, memory, or size targets? If none, say "none." -->


## Security Considerations

<!-- Auth, input validation, secret handling, access control, data exposure risks.
     If not applicable, say "none." -->


## Out of Scope

<!-- What is explicitly NOT part of this project? Prevents agents from adding unrequested features. -->

- 
- 

## Open Questions

<!-- Unresolved decisions that need answering before or during implementation.
     Leave none blank — Forge's pipeline-designer will try to resolve them or flag them as blockers. -->

- 
