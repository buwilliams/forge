# Forge

A Claude Code plugin for executing ambitious projects through design specifications, without losing sight of your constraints.

> Forge has replaced my use of [ralph-loops](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum).

## The Problem

When agents tackle multi-step projects, requirements drift. An instruction like "no external dependencies" or "match the existing tone" gets buried in context and ignored by step 10. Forge fixes this.

## How It Works

Forge takes a design document and runs it through a pipeline:

1. **Council** — determines the agent roles (perspectives) needed for the project
2. **Pipeline Design** — captures the project's constraints, conventions, and quality bar
3. **Agent Generation** — generates project-specific agents for the council
4. **Plan Decomposition** — breaks work into small, self-contained tasks
5. **Execution** — runs each task through an experiment → verify → save loop, syncing with the remote between tasks
6. **Report** — summarizes what was built

The filesystem is the source of truth. Tasks move through `todo/` → `working/` → `done/` (or `blocked/`). Runs are always resumable — re-run the same command and forge picks up where it left off.

## Installation

Forge is a Claude Code plugin. See the [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code) for how to install plugins from the marketplace or load them locally via `--plugin-dir`.

## Workflow

1. **Write a design doc** — describe what to build and any non-negotiable constraints
2. **Open a Claude Code session** — in your project directory
3. **Run forge** — `/forge design.md` works through the full pipeline automatically
4. **If tasks block** — forge creates `design-blocked.md` summarizing each failure and its reason
5. **Resolve the issues** — edit `design-blocked.md` to clarify requirements, add context, or adjust constraints
6. **Run forge again** — `/forge design-blocked.md` starts a fresh run targeting only the failures

Always forward — completed work is never re-run.

## Usage

### Spec-first workflow (recommended)

Forge includes native spec management. Start here when beginning a new project:

```
/forge:init                        # create constitution.md + product.md (once per project)
/forge:create auth-system          # create a new project spec interactively
/forge:list                        # see all specs and their status
/forge:forge auth-system           # run forge on a named spec
/forge:forge auth-system --ask     # run with approval gates at each phase
/forge:forge auth-system --clean   # clear state and start over
/forge:del old-experiment          # delete a spec
```

Project specs live in numbered directories under `.forge/`:
```
.forge/
  constitution.md          # non-negotiable principles for the whole project
  product.md               # what and why (non-technical requirements)
  00001_auth_system/
    design.md              # the project spec
    pipeline.md            # generated
    todo/  working/  done/ # task lifecycle
```

### Direct workflow

You can also pass a design file directly — useful for one-off runs or integrating with spec-kit:

```
/forge path/to/design.md           # run fully automated (no prompts)
/forge path/to/design.md --ask     # pause for approval at each phase
/forge path/to/design.md --clean   # delete the .forge/ state and start over
```

With `--ask`, forge pauses at the council, pipeline, and agent generation phases, letting you review and request changes before proceeding. Without it, forge auto-approves everything and runs to completion. Interrupted runs resume automatically on the next invocation.

**Testing forge itself:**

```
./tests/test.sh --reset  # wipe state, run forge, then verify
./tests/test.sh          # verify only (after forge has already run)
```

## Key Concepts

**Global Constraints** — defined once in `pipeline.md`, injected into every task. Constraints are verified after each task, not just at the end.

**Council Deliberation** — before execution, the task agent reasons through each council role's perspective in a single context. This catches issues before work begins.

**`council/*.md` files** — generated in Phase 3, one per role (e.g., `programmer.md`, `tester.md`). These are project-specific agent instructions tailored to the design and pipeline. They are used in two ways:
- **Phase 4 (Plan Decomposition):** the plan-decomposer reads all of them to understand each role's scope and assign tasks to the right role.
- **Phase 5 (Execution):** the file matching the task's role becomes that agent's primary instructions. All council files are also passed together so the agent can deliberate from every perspective before acting.

**Dynamic Verification** — every task that produces output with observable behavior includes a check that exercises it directly: starting a server and calling an endpoint, invoking a CLI with real arguments, running a script against real data. Static checks (file exists, pattern absent) confirm structure; dynamic checks confirm the output actually works.

**Sync** — before each task, forge pulls the latest changes so work done by others is visible. After each task completes, forge pushes so others receive it immediately. If a pull fails (conflict, no connectivity), the run stops cleanly for manual resolution. If there is no remote, sync is skipped silently.

**Attempt Tracking** — each task gets up to 3 attempts (configurable). After max attempts, the task moves to `blocked/` for manual review rather than silently failing.

**Task Context** — each task agent receives its role's generated instructions, `pipeline.md`, the task file, and all council member files for deliberation. It does not receive the original `design.md` directly — by execution time, everything relevant should be captured in the task and pipeline.

**Not Just for Code** — Forge works for any file-based project. If no tech stack is detected, the council is inferred from the design document alone. Default roles (`programmer`, `tester`, `product-manager`) can be replaced during the approval step with whatever fits the project (e.g., `writer`, `editor`, `strategist`).

## Docs

- [goal.md](docs/goal.md) — problem statement and motivation
- [plan.md](docs/plan.md) — full implementation blueprint
- [support-specs.md](docs/support-specs.md) — native spec management (constitution, product, project specs)
- [spec-kit.md](docs/spec-kit.md) — using spec-kit with Forge for spec-driven development

## Requirements

- [Claude Code](https://claude.ai/code) CLI
- A git repository for the target project
