# Using spec-kit with Forge

[spec-kit](https://github.com/github/spec-kit) is GitHub's toolkit for Spec-Driven Development (SDD) — a methodology that makes specifications executable and binding rather than advisory. It guides you through producing a structured specification before any code is written, using AI agents (Claude, Copilot, Gemini) via slash commands.

## What spec-kit produces

| Command | Output |
|---|---|
| `/speckit.specify` | `spec.md` — what to build and why |
| `/speckit.plan` | `plan.md` — architecture and strategy |
| `/speckit.tasks` | `tasks.md` — high-level task breakdown |

## How it fits with Forge

spec-kit and Forge occupy complementary phases of a project. spec-kit handles the **what and why** — turning an idea into a well-structured specification. Forge handles the **how and when** — turning that specification into working code through a verified, resumable execution loop.

The bridge is your design document. Feed spec-kit's output into Forge as `design.md`:

```
/speckit.constitute       # set up the project
/speckit.specify          # produces spec.md
/speckit.plan             # produces plan.md
# Combine or use spec.md directly as your design.md
/forge design.md          # Forge takes it from here
```

Forge's `pipeline-designer` reads your design document to extract **Global Constraints** — non-negotiable rules injected into every task. A rich spec-kit document (with explicit requirements and constraints) means more accurate constraint extraction and fewer blocked tasks.

Forge's `plan-decomposer` translates spec-kit's high-level tasks into fully self-contained Forge task files, each with concrete `## Verification` steps (assertions + shell commands). spec-kit describes *what* the tasks are; Forge figures out *how to verify* each one passed.

## What spec-kit adds

Without spec-kit, you write `design.md` by hand. That works fine, but spec-kit raises the quality of that input:

- Forces you to separate *what* from *how* before implementation begins
- Produces a structured document that Forge's agents can parse unambiguously
- Catches underspecified requirements before they become blocked tasks

The more detailed and constraint-explicit your spec-kit output, the better Forge's task decomposition and verification will be.
