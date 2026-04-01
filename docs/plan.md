# forge Plugin — Implementation Plan

## Context

forge is a Claude Code plugin that solves a real problem: coding agents fail at large, ambitious tasks because instructions span too much implementation space. forge takes a `design.md` document, designs a pipeline (workflow), decomposes the work into small chunks (each completable in a single Agent call), and then executes those chunks in a loop until the whole project is done. The core execution substrate for every task is: **experiment → verify → save** (repeat). The plugin is a native Claude Code plugin — Bash and all other Claude Code tools are available; the key shift is that the control flow is driven by Claude, not by shell scripts.


---

## Plugin Architecture Overview

The plugin lives at `/home/buddy/projects/forge/`. When a user runs `/forge path/to/design.md` on any project, forge creates artifacts inside that project under `<project>/.forge/<name>/` where `<name>` is the sanitized design filename.

**Key design decisions:**
- The `/forge` command is the execution loop — it uses the `Agent` tool to run tasks one at a time, in-session, blocking the main Claude Code session
- All tools available in the Claude Code session (Bash, Read, Write, Edit, Glob, Grep, LSP, Agent, etc.) are on the table for the `/forge` command and its agents
- Council deliberation happens **in-context**: the task agent receives all council agent files and reasons through each perspective before implementing — no parallel agent calls
- Task verification uses both **assertions** (file exists, export present — checked with Read/Grep/Glob/LSP) and **commands** (tests pass, types check, linter clean — run via Bash)
- Directory names are derived from the design.md **filename** (sanitized: lowercase, non-alphanumeric → underscores) giving a readable, stable identity even when the file is edited mid-project
- Filesystem state (todo/ → working/ → done/ / blocked/) is the task queue — atomic, universally visible, no parsing
- Task files use **no metadata/frontmatter** — plain markdown, ordered strictly by numeric filename prefix (`00000_task.md`)
- The **council** (set of agent roles) is determined per-project at the very start, before pipeline design — it drives everything that follows
- Agents, hooks, and skills are **generated per-project** from the approved council and design.md

---

## File Tree

```
/home/buddy/projects/forge/
├── .claude-plugin/
│   └── plugin.json
├── README.md
├── docs/
│   └── plan.md                 # This file
├── commands/
│   └── forge.md                # Main /forge entry point — owns the execution loop
├── agents/
│   ├── pipeline-designer.md    # Designs pipeline.md from design.md
│   ├── agent-generator.md      # Generates project-specific agents/hooks/skills
│   ├── plan-decomposer.md      # Creates plan.md + todo/*.md task files
│   ├── verifier.md             # Per-task verification after task agent completes
│   └── task-executor.md        # Generic fallback executor
└── hooks/
    └── hooks.json              # SessionStart reminder if run is in progress
```

**Generated artifacts in user's project:**
```
<project>/.forge/<name>/
├── council.md              # Approved council roster (roles + one-line purpose each)
├── pipeline.md             # Approved pipeline spec
├── plan.md                 # Work decomposition summary
├── todo/                   # Pending task files (00000_task.md)
├── working/                # In-progress (at most 1 file during exec)
├── done/                   # Completed tasks
├── blocked/                # Blocked tasks (user moves back to todo/ to retry)
├── council/                # Generated: role-specific agents for this project
│   ├── programmer.md
│   ├── tester.md
│   ├── product-manager.md
│   └── <custom>.md
├── hooks/                  # Generated: lifecycle hooks if needed
│   └── hooks.json
└── skills/                 # Generated: project-specific skills if useful
```

---

## User Workflow (8 phases)

### `/forge path/to/design.md`

1. **Init** — Read design.md. Ensure the project is a git repository: if `.git/` does not exist at the project root, run `git init`; if that fails, exit with `[forge] Error: could not initialize a git repository here`. Derive the directory name from the design file's basename: strip the `.md` extension, replace non-alphanumeric characters with underscores, collapse consecutive underscores, and lowercase — e.g. `My Cool Design.md` → `my_cool_design`. Set `FORGE_DIR=<project-root>/.forge/<name>`. If `<forge_dir>/` already exists, read `<forge_dir>/.forge_source`: if it contains a different basename, exit with `[forge] Error: directory name collision — '<name>' is already claimed by a different design file`. Otherwise create the directory tree (todo/, working/, done/, blocked/, council/, hooks/, skills/, log/) and write the design file's basename to `<forge_dir>/.forge_source`. Echo: `[forge] Initializing — <name>`

2. **Resume check** — Check which artifacts exist and resume at the earliest incomplete phase:
   - `todo/` or `working/` have files → skip to phase 7 (Execute). Print: `[forge] Resuming existing run — <N> tasks remaining`.
   - `council/` has agent files but no tasks → skip to phase 6 (Decompose).
   - `pipeline.md` exists but no agent files → skip to phase 5 (Generate agents).
   - `council.md` exists but no `pipeline.md` → skip to phase 4 (Design pipeline).
   - Otherwise start at phase 3.
   - If the user explicitly asked to restart, clear todo/, working/, done/, blocked/, council/, and all generated artifacts, then start at phase 3.

3. **Determine council** — Echo: `[forge] Determining council...`. Read design.md and the project tech stack. Determine which agent roles are needed for this project (e.g., `programmer`, `tester`, `product-manager`, plus any domain-specific roles). Write `<forge_dir>/council.md` — a plain list of roles, one per line, each with a one-line purpose. Display `council.md` to the user. Enter **conversational approval loop**:
   - Ask: "Approve this council? Reply 'approve' to proceed, or describe changes."
   - If user requests changes: revise `council.md` in place → display again. Repeat.
   - Once user replies "approve": proceed to phase 4.

4. **Design pipeline** — Echo: `[forge] Designing pipeline...`. Invoke `pipeline-designer` agent with `design.md` and `council.md` as input → writes `pipeline.md`. Read and display the full contents of `pipeline.md` to the user. Enter **conversational approval loop**:
   - Ask: "Approve this pipeline? Reply 'approve' to proceed, or describe changes."
   - If user requests changes: re-invoke `pipeline-designer` with feedback appended → rewrites `pipeline.md` → display again. Repeat.
   - Once user replies "approve": proceed to phase 5.

5. **Generate agents/hooks/skills** — Echo: `[forge] Generating project agents...`. Invoke `agent-generator` with `council.md`, `pipeline.md`, and `design.md` → writes one agent file per role in `<forge_dir>/council/`, plus `hooks/` and `skills/` if appropriate. Then enter **agent verification loop**:
   - Display the list of generated council agent files and their first 20 lines each.
   - Ask: "Do these agents look correct? Reply 'approve' or describe issues."
   - If issues: re-invoke `agent-generator` with feedback → regenerate → display again. Repeat.
   - Once approved: echo the roles generated, proceed.

6. **Decompose plan** — Echo: `[forge] Decomposing work into tasks...`. Invoke `plan-decomposer` → writes `plan.md` and all `todo/00000_task.md` task files. Echo: `[forge] <N> tasks created`.

7. **Execute** — Confirm with user, then enter the execution loop (see below). The user can press **Esc** at any time to interrupt; the current `working/` file stays as a resume marker. Re-running `/forge design.md` picks up from `working/` and continues.

8. **Report** — Echo: `[forge] All tasks complete.` and display a brief completion summary in-context.

---

## Execution Loop

The `/forge` command drives this loop directly. Each iteration:

1. **Pick task** — If `working/` contains a file, use it as the current task (resume from interrupted run) and skip to step 3. Otherwise, select the lexicographically first `*.md` from `todo/`. If neither, exit loop.
2. **Try count** — Track attempt count for this task in-context (starts at 0 per session, resets on successful completion). Read `Max task tries:` from `pipeline.md` (e.g. `Max task tries: 3`); if absent or not parseable, default to 3. Track current attempts as `Task tries: N` in-context. If attempts ≥ max, move task to `blocked/` and continue to next task.
3. **Move to working/** — Move the task file from `todo/` to `working/<taskname>.md`. (Skip if resuming — file is already there.)
4. **Build context** — Assemble: agent file (by Role field, from `<forge_dir>/council/`) + `pipeline.md` + task file + all other files in `<forge_dir>/council/`. If Role is absent or unrecognized, use `task-executor.md`.
5. **Invoke Agent** — Single Agent tool call. The agent reasons through council perspectives in-context, then implements.
6. **Handle result** — Parse agent output for signals:
   - `<task-blocked>REASON</task-blocked>` → move to `blocked/`, write reason file, continue
   - No signal → increment in-context attempt count, move back to `todo/`, continue
   - `<task-complete>DONE</task-complete>` → proceed to step 7
7. **Verify** — Invoke `verifier` agent with the task file. The verifier independently checks every item in `## Verification` (assertions via Read/Grep/Glob/LSP, commands via Bash):
   - `<verify-pass>` → move to `done/`, reset in-context attempt count
   - `<verify-fail>REASON</verify-fail>` → increment in-context attempt count, move back to `todo/`
8. **Repeat.**

---

## Plugin Agents (static)

### `agents/pipeline-designer.md`
- Receives `design.md` and the approved `council.md` as input; scans project tech stack (package.json, Cargo.toml, pyproject.toml, etc.)
- Produces `pipeline.md` with: Overview, Execution Substrate section, **Global Constraints section**, Blocked Task Policy, Completion Condition, and an optional `Max task tries: N` line (integer, defaults to 3 if absent)
- **Global Constraints** are non-negotiable rules that apply to every task (e.g., "no stubs, mocks, or smoke-tests", "use real data", "no `any` types"). Sourced explicitly from design.md. Each constraint is a single, checkable statement.
- Does **not** define the council — that is already established in `council.md` before this agent runs
- If invoked with user feedback appended, reads the existing `pipeline.md` and revises it in place

### `agents/agent-generator.md`
- Reads approved `council.md`, `pipeline.md`, and `design.md` to understand roles, domain, and tech stack
- Generates exactly the roles listed in `council.md` — no more, no less
- Each agent file has two sections:
  - **EXECUTION mode** — how the agent implements tasks assigned to its role
  - **DELIBERATION mode** — the agent's perspective lens: what it cares about, what it flags, how it frames concerns. Used when the task agent reasons through council perspectives in-context. Must not implement or write files.
- Also generates `hooks/` and `skills/` if appropriate for the project type
- Each generated agent is tailored to the tech stack, libraries, conventions, and quality bar from design.md
- If invoked with user feedback: receives original inputs (`council.md`, `pipeline.md`, `design.md`), all existing generated files, and the feedback — revises in place

### `agents/plan-decomposer.md`
- Reads `pipeline.md`, `design.md`, and generated agents in `<forge_dir>/council/`
- Writes `plan.md` (decomposition summary)
- Writes every task file as **plain markdown with no YAML frontmatter and no metadata fields**
- Task files are named `00000_task.md`, `00001_task.md`, etc. — the numeric prefix alone encodes order
- Each task must be **fully self-contained**: a fresh Agent call must be able to execute it with only the task file + `pipeline.md` + its agent file
- Self-check before writing: "Can a fresh Agent instance complete this task with only these files?" If no, enrich the Context section until the answer is yes
- Verification steps use both assertions (Read/Grep/Glob/LSP for structural checks) and shell commands (Bash for test runs, type checks, linter passes) as appropriate
- **For every task that writes code**, reads `## Global Constraints` from `pipeline.md` and adds a concrete verification step for each applicable constraint (e.g., `grep -r 'mock\|stub' src/` returns no matches; seed script uses live DB, not fixtures). Constraints are never left implicit — they must appear as checkable verification steps in the task file.
- Ensures the user's project has a `.gitignore` covering common secrets and build artifacts so that `git add -A` in Save Commands is safe

### `agents/verifier.md`
- Invoked by the execution loop after a task agent emits `<task-complete>`
- Receives the task file only; reads `## Verification` to know what to check
- Checks assertions (file exists, export present, pattern matches) using Read/Grep/Glob/LSP
- Checks commands (tests pass, types check, linter clean) via Bash
- Returns `<verify-pass>` or `<verify-fail>REASON</verify-fail>` with a plain-language explanation of what failed

### `agents/task-executor.md`
- Generic fallback executor used when no role-specific agent matches
- Follows experiment → verify → save strictly
- Verifies using Read/Grep/Glob/LSP for structural assertions and Bash for test/lint/typecheck commands
- Completion signal: `<task-complete>DONE</task-complete>`
- Blocked signal: `<task-blocked>REASON</task-blocked>`
- Does NOT emit the completion signal before running the Save Command

---

## Task File Template (`todo/00000_task.md`)

Plain markdown only. No frontmatter. No metadata. The filename encodes identity and order.

```markdown
# Task 00000: Title

## Role
programmer

## Objective
One paragraph, concrete.

## Context
Relevant files, patterns to follow, constraints. Must be complete enough that a fresh
Agent call needs nothing beyond this file, pipeline.md, and its agent file.

## Steps
1. ...

## Verification
- File `src/foo.ts` exists and exports function `bar`
- `src/foo.ts` contains no references to the deprecated `oldApi`
- Test file `src/foo.test.ts` exists and covers the `bar` function
- `npm test src/foo.test.ts` passes
- `npm run typecheck` exits 0

## Done When
- [ ] Objective fully implemented
- [ ] All verification checks pass (assertions via Read/Grep/Glob/LSP, commands via Bash)

## Save Command
```
git add -A && git commit -m "task-00000: title"
```
```

- `## Role` names one of the generated agents. If absent or unrecognized, `task-executor.md` is used.
- `## Verification` lists both structural assertions (checked with Read/Grep/Glob/LSP) and behavioral commands (run via Bash — test suites, type checkers, linters). The executing agent checks all of them before emitting the completion signal.

---

## Council Deliberation (in-context)

Council deliberation is not a separate agent call. When the execution loop builds the prompt for a task agent, it includes all files from `<forge_dir>/council/` alongside the task file and `pipeline.md`. The task agent is instructed to read each council member's DELIBERATION section and reason through their perspective before beginning implementation.

This keeps deliberation in a single context window — no parallel spawning, no extra latency — while still ensuring the agent considers multiple viewpoints before acting.

---

## `.gitignore` Integration

Before writing task files, `plan-decomposer` ensures the user's project root has a `.gitignore` that covers common secrets and build artifacts (`.env`, `*.key`, `node_modules/`, `__pycache__/`, `dist/`, `target/`, etc.). This makes `git add -A` in every Save Command safe by default.

---

## `.claude-plugin/plugin.json`

Registers the plugin's command with Claude Code:

```json
{
  "name": "forge",
  "version": "0.1.0",
  "description": "Pipeline-based project execution for Claude Code agents",
  "commands": ["./commands/forge.md"]
}
```

---

## `hooks/hooks.json` (plugin-level)

SessionStart hook: checks for `<project>/.forge/*/working/*.md`. If any exist, prints:
> `[forge] A run is in progress (task in working/). Re-run /forge <design.md> to resume.`

This prevents silent state confusion if the user opens a new session mid-run.

---

## Verification Plan

1. Create a small test `design.md` in a temp git repo
2. Run `/forge design.md` — verify `.forge/design/council.md` is created and the council approval loop works: request a change, verify it is incorporated before proceeding
3. Verify `.forge/design/pipeline.md` is created and its approval loop works: request a change, verify it is incorporated before proceeding
4. Verify the agent approval loop works: request a change, verify regeneration before proceeding
5. Verify `.forge/design/council/` contains exactly the roles listed in `council.md` (at minimum `programmer.md`, `tester.md`, `product-manager.md`)
6. Verify `.forge/design/todo/*.md` files use `00000_` numeric prefix, contain no YAML frontmatter, no `## Stage` field, and have `## Verification` sections with both assertions and commands
7. Run `/forge design.md` to trigger execution — confirm tasks move from todo/ → working/ → (verifier pass) → done/ in ascending numeric order
8. Test verifier failure: make a task's implementation incomplete → confirm `verifier` returns `<verify-fail>`, task moves back to `todo/`, and is retried
9. Verify completion summary is echoed in-context after all tasks finish
10. Test blocked path: create a task that always returns no signal → confirm it lands in `blocked/` after exactly 3 attempts (default). Also test with `Max task tries: 2` in `pipeline.md` → confirm it blocks after 2 attempts
11. Test explicit block: create a task that emits `<task-blocked>` → confirm it moves to `blocked/` immediately
12. Test resume: press Esc mid-run, re-run `/forge design.md` → confirm the working/ task is picked up directly and run continues
13. Test phase-aware resume: interrupt after council.md is written but before pipeline.md → confirm re-run skips council phase and resumes at pipeline design
14. Test .gitignore: verify `plan-decomposer` creates or augments `.gitignore` in the user's project root
