# Forge

A Claude Code plugin for executing large, ambitious coding projects without losing sight of your constraints.

## The Problem

When coding agents tackle multi-step projects, requirements drift. An instruction like "no mocks or stubs" or "use real data only" gets buried in context and ignored by step 10. Forge fixes this.

## How It Works

Forge takes a design document and runs it through a pipeline:

1. **Council** — determines the agent roles (perspectives) needed for the project
2. **Pipeline Design** — captures tech stack, global constraints, and quality bar
3. **Agent Generation** — generates project-specific agents for the council
4. **Plan Decomposition** — breaks work into small, self-contained tasks
5. **Execution** — runs each task through a verify → save → confirm loop
6. **Report** — summarizes what was built

The filesystem is the source of truth. Tasks move through `todo/` → `working/` → `done/` (or `blocked/`). Runs are always resumable — re-run the same command and forge picks up where it left off.

## Workflow

1. **Write a design doc** — describe what to build, the tech stack, and any non-negotiable constraints
2. **Run forge** — `/forge design.md` works through the full pipeline automatically
3. **If tasks block** — forge creates `design-blocked.md` summarizing each failure and its reason
4. **Resolve the issues** — edit `design-blocked.md` to clarify requirements, add context, or adjust constraints
5. **Run forge again** — `/forge design-blocked.md` starts a fresh run targeting only the failures

Always forward — completed work is never re-run.

## Usage

Open a Claude Code session in your project directory, then:

```
/forge path/to/design.md           # run fully automated (no prompts)
/forge path/to/design.md --ask     # pause for approval at each phase
/forge path/to/design.md --restart # delete the .forge/ state and start over
```

With `--ask`, forge pauses at the council, pipeline, and agent generation phases, letting you review and request changes before proceeding. Without it, forge auto-approves everything and runs to completion. Interrupted runs resume automatically on the next invocation.

Your design document should describe what you want to build, the tech stack, and any non-negotiable constraints (e.g., no external dependencies, all tests use real data, strict TypeScript).

**Testing forge itself:**

```
./tests/test.sh --reset  # wipe state, run forge, then verify
./tests/test.sh          # verify only (after forge has already run)
```

## Key Concepts

**Global Constraints** — defined once in `pipeline.md`, injected into every task. Constraints are verified after each task, not just at the end.

**Council Deliberation** — before implementation, the task agent reasons through each council role's perspective (programmer, tester, product-manager, etc.) in a single context. This catches issues before code is written.

**`council/*.md` files** — generated in Phase 3, one per role (e.g., `programmer.md`, `tester.md`). These are project-specific agent instructions tailored to the design and pipeline. They are used in two ways:
- **Phase 4 (Plan Decomposition):** the plan-decomposer reads all of them to understand each role's scope and assign tasks to the right role.
- **Phase 5 (Execution):** the file matching the task's role becomes that agent's primary instructions. All council files are also passed together so the agent can deliberate from every perspective before acting.

**Attempt Tracking** — each task gets up to 3 attempts (configurable). After max attempts, the task moves to `blocked/` for manual review rather than silently failing.

**Task Context** — each task agent receives its role's generated instructions, `pipeline.md`, the task file, and all council member files for deliberation. It does not receive the original `design.md` directly — by execution time, everything relevant should be captured in the task and pipeline.

**Not Just for Code** — Forge works for any file-based project. If no tech stack is detected, the council is inferred from the design document alone. Default roles (`programmer`, `tester`, `product-manager`) can be replaced during the approval step with whatever fits the project (e.g., `writer`, `editor`, `strategist`).

## Docs

- [goal.md](docs/goal.md) — problem statement and motivation
- [plan.md](docs/plan.md) — full implementation blueprint

## Requirements

- [Claude Code](https://claude.ai/code) CLI
- A git repository for the target project
