# Forge

A Claude Code plugin for executing ambitious projects through design specifications, without losing sight of your constraints. No new tools or CLIs required — just your existing Claude Code session.

> Forge has replaced my use of [ralph-loops](https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum).

## The Problem

Specs are how you direct AI to do things for you — they capture what to build, why it matters, and the rules that can't be broken. Without them, you're reprompting constantly and hoping the agent remembers what you said three steps ago.

When agents tackle multi-step projects, requirements drift. An instruction like "no external dependencies" or "match the existing tone" gets buried in context and ignored by step 10. Forge fixes this by making specs first-class: you define them once, and they're enforced at every step.

## How It Works

### Specs layer on top of each other

There are three kinds of specs, each narrowing the scope for the next:

- **Constitution** — non-negotiable principles for the entire project. Every task Forge generates must comply with these rules. Written once, enforced always.
- **Product spec** — the what and why. Defines who the product is for, what problems it solves, and what success looks like. Keeps individual project specs mission-aligned.
- **Project specs** — concrete goals: what to build, how to verify it's done, and any constraints specific to that piece of work. Each lives in a numbered directory (`.forge/00001_name/`). When you create a project spec, Forge reads your constitution and product to flag conflicts before any work begins.

### Project specs become tasks

When you run `/forge:work`, Forge reads the project spec and drives it through a pipeline using Claude Code subagents — each launched with precisely the context it needs and nothing more:

1. **Council** — a subagent reads the spec and determines the right mix of roles (e.g. programmer, tester, security engineer, writer). Roles are tailored to the domain, not generic.
2. **Pipeline design** — a subagent reads the spec and council to produce `pipeline.md`: the project's global constraints, quality bar, verification approach, and tech stack. These constraints are injected into every task.
3. **Agent generation** — a subagent generates one role-specific agent file per council member, each with execution instructions and a deliberation perspective tailored to this project.
4. **Plan decomposition** — a subagent reads the pipeline and all agent files to produce self-contained task files in `todo/`. Each task includes its role, steps, verification checks, and a save command. A fresh subagent could execute any task with only the task file and pipeline.
5. **Execution** — for each task, Forge launches a subagent carrying its role's agent file, `pipeline.md`, the task, and all council files for deliberation. The subagent implements, verifies, and commits. An independent verifier subagent then re-checks every verification item from scratch before the task is marked done.
6. **Report** — summarizes completed and blocked tasks. Blocked tasks are written to a new design doc for a focused retry run.

The filesystem is the source of truth. Tasks move through `todo/` → `working/` → `done/` (or `blocked/`). Runs are always resumable — re-run the same command and Forge picks up exactly where it left off.

## Installation

Forge is a Claude Code plugin. See the [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code) for how to install plugins from the marketplace or load them locally via `--plugin-dir`.

## Workflow

1. **`/forge:init`** — set up your project's constitution (non-negotiable principles) and product spec (what and why). Do this once per project.
2. **`/forge:create <name>`** — define a new project spec through a guided conversation. Forge reads your constitution and product spec to keep the work aligned.
3. **`/forge:work <name>`** — execute the spec. Forge determines the council, designs the pipeline, generates agents, decomposes the work into tasks, and runs them one by one.
4. **If tasks block** — Forge writes a `*-blocked.md` doc summarizing each failure. Edit it to add context or clarify requirements, then re-run.
5. **`/forge:list`** — check progress across all specs at any time.

Always forward — completed work is never re-run. Interrupted runs resume from where they stopped.

## Usage

```
/forge:init                        # set up constitution.md + product.md (once per project)
/forge:create auth-system          # create a new project spec interactively
/forge:list                        # see all specs and their status
/forge:work auth-system            # run forge on a named spec
/forge:work auth-system --ask      # pause for approval at each phase
/forge:work auth-system --clean    # clear state and start over
/forge:del old-experiment          # delete a spec
```

Project specs live in numbered directories under `.forge/`:

```
.forge/
  constitution.md            # non-negotiable principles for the whole project
  product.md                 # what and why (non-technical requirements)
  00001_auth_system/
    design.md                # the project spec
    pipeline.md              # generated by forge
    council.md               # generated by forge
    todo/  working/  done/   # task lifecycle
    council/                 # generated role agents
```

### Direct usage

You can also pass a design file directly — useful for one-off runs or when integrating with spec-kit:

```
/forge path/to/design.md           # run fully automated
/forge path/to/design.md --ask     # pause for approval at each phase
/forge path/to/design.md --clean   # delete the .forge/ state and start over
```

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
