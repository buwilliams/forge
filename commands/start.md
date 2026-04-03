# /forge:start — Execute a Named Project Spec

You are the Forge execution engine. When the user runs `/forge:start <work-name>`, you resolve the spec directory, ensure it is fully set up, and execute its tasks through an implement → verify → commit loop. Completed work is never re-run. Interrupted runs resume exactly where they stopped.

**Your arguments:** `<work-name>` (spec name, number, or prefix) plus optional flags:
- `--ask` — pause for approval at each setup phase
- `--clean` — clear the spec's Forge state and start over from setup

If no work-name is provided, print:
```
[forge:start] Usage: /forge:start <work-name> [--ask|--clean]
```
and stop.

---

## Tool Access

You have full access to all Claude Code tools: Bash, Read, Write, Edit, Glob, Grep, LSP, Agent, and any others available in the session.

---

## Step 1: Resolve the Spec Directory

Run `pwd` via Bash. That is `PROJECT_ROOT`.

Extract the work-name (first non-flag argument). Set:
- `ASK_MODE = true` if `--ask` is present, otherwise `ASK_MODE = false`
- `CLEAN_MODE = true` if `--clean` is present, otherwise `CLEAN_MODE = false`

List all numbered spec directories:
```bash
ls -d <PROJECT_ROOT>/.forge/[0-9][0-9][0-9][0-9][0-9]_* 2>/dev/null | sort
```

**Match the work-name against the list:**

Normalize the work-name: lowercase, replace hyphens/spaces with underscores.

For each spec directory, extract the slug (everything after the first `_`). Compare:
- Exact match on slug: `auth_system` matches `00003_auth_system`
- Exact match on number: `00003` matches `00003_auth_system`
- Prefix match on slug: `auth` matches `00003_auth_system` if no exact slug match exists

**If no match:** Print:
```
[forge:start] No spec matching '<work-name>' found. Run /forge:list to see available specs.
```
and stop.

**If multiple matches** (ambiguous prefix): Print:
```
[forge:start] '<work-name>' is ambiguous. Matching specs:
  <list each match>
Re-run with the full name or spec number.
```
and stop.

**If exactly one match:**

Set:
- `SPEC_DIR` = matched directory absolute path (e.g., `<PROJECT_ROOT>/.forge/00003_auth_system`)
- `FORGE_DIR` = `SPEC_DIR`
- `DESIGN_FILE` = `<SPEC_DIR>/project.md`
- `NAME` = matched directory basename (e.g., `00003_auth_system`)

Verify `DESIGN_FILE` exists using the Read tool. If it does not exist, print:
```
[forge:start] Spec directory found but project.md is missing.
Run /forge:new-spec to set up the spec first.
```
and stop.

Print: `[forge:start] Found spec: <NAME>`

---

## Step 2: Git Check

Check whether `<PROJECT_ROOT>/.git/` exists:
```bash
test -d <PROJECT_ROOT>/.git
```
If it does not exist, run `git init <PROJECT_ROOT>`. If that fails, print `[forge:start] Error: could not initialize a git repository here` and stop.

---

## Step 3: Create Directory Tree

Ensure subdirectories exist (idempotent):
```bash
mkdir -p <SPEC_DIR>/todo <SPEC_DIR>/working <SPEC_DIR>/done <SPEC_DIR>/blocked <SPEC_DIR>/council
```

---

## Step 4: Handle --clean

If `CLEAN_MODE = true`:

1. Delete all task files from todo/, working/, done/, blocked/, and all agent files from council/:
   ```bash
   rm -f <SPEC_DIR>/todo/*.md <SPEC_DIR>/working/*.md <SPEC_DIR>/done/*.md \
         <SPEC_DIR>/blocked/*.md <SPEC_DIR>/blocked/*.reason.md \
         <SPEC_DIR>/council/*.md
   ```
2. Delete generated artifacts:
   ```bash
   rm -f <SPEC_DIR>/council.md <SPEC_DIR>/verifier.md <SPEC_DIR>/plan.md
   ```
3. Strip the Forge execution config from `project.md`: read the file and remove everything from the `---` separator that precedes `## Global Constraints` to the end of the file. Write the truncated version back.
4. Print: `[forge:start] Cleaned. Running full setup...`
5. Proceed to Step 5 (Resume Check), which will start from the beginning.

---

## Step 5: Resume Check

Check the current state of `<SPEC_DIR>` and skip forward to the appropriate step. Evaluate these conditions in order:

1. `<SPEC_DIR>/todo/` contains any `*.md` files **OR** `<SPEC_DIR>/working/` contains any `*.md` files, **AND** `<SPEC_DIR>/verifier.md` does NOT exist → **skip to Step 8** (Verifier), then proceed to Step 10 (Execute). Print: `[forge:start] Resuming — verifier missing, regenerating before execution...`

2. `<SPEC_DIR>/todo/` contains any `*.md` files **OR** `<SPEC_DIR>/working/` contains any `*.md` files → **skip to Step 10** (Execute). Print: `[forge:start] Resuming execution — <N> tasks pending.`

3. `<SPEC_DIR>/verifier.md` exists AND `<SPEC_DIR>/council/` has `*.md` files AND `<SPEC_DIR>/todo/` is empty → **skip to Step 9** (Tasks). Print: `[forge:start] Resuming at task decomposition...`

4. `<SPEC_DIR>/council/` has `*.md` files AND `<SPEC_DIR>/verifier.md` does not exist → **skip to Step 8** (Verifier). Print: `[forge:start] Resuming at verifier generation...`

5. `<SPEC_DIR>/council.md` exists AND `<SPEC_DIR>/council/` has no `*.md` files AND `project.md` contains `## Global Constraints` → **skip to Step 7** (Role Agents). Print: `[forge:start] Resuming at role agent generation...`

6. `<SPEC_DIR>/council.md` exists AND `project.md` does NOT contain `## Global Constraints` → **skip to Step 6b** (Spec Agent). Print: `[forge:start] Resuming at spec finalization...`

7. Otherwise: start from Step 6 (Council).

---

## Step 6: Determine Council

Print: `[forge:start] Determining council...`

Read `<SPEC_DIR>/project.md`. Read any tech stack files that exist at `PROJECT_ROOT`: `package.json`, `Cargo.toml`, `pyproject.toml`, `requirements.txt`, `go.mod`, `Makefile`, `tsconfig.json`, `Dockerfile`.

Determine the council of agent roles. Always include at minimum: `programmer`, `tester`, `product-manager`. Add domain-specific roles as warranted.

Write `<SPEC_DIR>/council.md`:
```
# Council

## Roles

- **<role>** — <one-line description>
...
```

Display council.md.

If `ASK_MODE = true`: Ask `Approve this council? Reply 'approve' to proceed, or describe changes.` Loop until approved.
If `ASK_MODE = false`: Print `[forge:start] Council set.` and proceed.

---

## Step 6b: Run Spec Agent

Print: `[forge:start] Running spec agent...`

Read `${CLAUDE_PLUGIN_ROOT}/agents/spec.md`. Read constitution.md and product.md if they exist at `<PROJECT_ROOT>/.forge/`. Invoke the Agent tool:

```
You are the spec agent.

Project root: <PROJECT_ROOT>
Spec dir: <SPEC_DIR>
project.md path: <SPEC_DIR>/project.md

council.md contents:
---
<COUNCIL_MD_CONTENTS>
---

project.md contents:
---
<PROJECT_MD_CONTENTS>
---

<If constitution.md exists:>
constitution.md contents (treat all Hard Constraints as Global Constraints):
---
<CONSTITUTION_MD_CONTENTS>
---
</If>

<If product.md exists:>
product.md contents:
---
<PRODUCT_MD_CONTENTS>
---
</If>

<SPEC_AGENT_INSTRUCTIONS>
```

After the agent returns, read and display the generated portion of `project.md`.

If `ASK_MODE = true`: Ask `Approve these constraints and execution config? Reply 'approve' to proceed, or describe changes.` If changes requested, re-invoke the spec agent with feedback appended. Repeat until approved.
If `ASK_MODE = false`: Print `[forge:start] Spec finalized.` and proceed.

---

## Step 7: Generate Role Agents

Print: `[forge:start] Generating role agents...`

Read `${CLAUDE_PLUGIN_ROOT}/agents/roles.md`. Read project.md and council.md. Invoke the Agent tool:

```
You are the roles agent.

Project root: <PROJECT_ROOT>
Forge dir: <SPEC_DIR>

council.md contents:
---
<COUNCIL_MD_CONTENTS>
---

project.md contents (includes Forge execution config):
---
<PROJECT_MD_CONTENTS>
---

<ROLES_AGENT_INSTRUCTIONS>
```

After the agent returns, read all `*.md` files in `<SPEC_DIR>/council/` and display a summary (one line per file).

If `ASK_MODE = true`: Ask `Do these role agents look correct? Reply 'approve' or describe issues.` If issues, re-invoke with feedback. Repeat until approved.
If `ASK_MODE = false`: Print `[forge:start] Role agents generated: <comma-separated list>.` and proceed.

---

## Step 8: Generate Verifier

Print: `[forge:start] Generating verifier...`

Determine `PROJECT_TYPE`: if `project.md` references code files, languages, or tech stack → `technical`; otherwise → `general`.

Determine template path:
- `technical` → `${CLAUDE_PLUGIN_ROOT}/templates/verifier-technical.template.md`
- `general` → `${CLAUDE_PLUGIN_ROOT}/templates/verifier-general.template.md`

Read the template and `${CLAUDE_PLUGIN_ROOT}/agents/verifier.md`. Invoke the Agent tool:

```
You are the verifier generator agent.

Project root: <PROJECT_ROOT>
Spec dir: <SPEC_DIR>
PROJECT_TYPE: <PROJECT_TYPE>
Template path: <TEMPLATE_PATH>

project.md contents:
---
<PROJECT_MD_CONTENTS>
---

Template contents:
---
<TEMPLATE_CONTENTS>
---

<VERIFIER_GENERATOR_INSTRUCTIONS>
```

After the agent returns, verify `<SPEC_DIR>/verifier.md` was created.

Print: `[forge:start] Verifier generated.`

---

## Step 9: Decompose into Tasks

Print: `[forge:start] Decomposing into tasks...`

Read all `*.md` files in `<SPEC_DIR>/council/`. Read `${CLAUDE_PLUGIN_ROOT}/agents/tasks.md`. Invoke the Agent tool:

```
You are the tasks agent.

Project root: <PROJECT_ROOT>
Forge dir: <SPEC_DIR>

project.md contents (includes Forge execution config):
---
<PROJECT_MD_CONTENTS>
---

Council agent files:
<For each file in <SPEC_DIR>/council/:>
### <filename>
---
<FILE_CONTENTS>
---
</For each>

<TASKS_AGENT_INSTRUCTIONS>
```

After the agent returns, count `*.md` files in `<SPEC_DIR>/todo/`.

Print: `[forge:start] <N> tasks ready.`

---

## Step 10: Execute

**Read max tries from project.md:**

Search `<SPEC_DIR>/project.md` for a line matching the pattern `\*\*Max task tries:\*\*\s*(\d+)`. Extract the integer. If absent or not parseable, default to `3`. Store as `MAX_TRIES`.

**Print execution summary:**
```
[forge:start] Execution plan ready.
  Tasks pending: <N>
  Max tries per task: <MAX_TRIES>
  Press Esc at any time to interrupt. Re-run /forge:start <NAME> to resume.
```

If `ASK_MODE = true`: Ask `Ready to execute? Reply 'yes' to begin, or 'no' to stop here.` If `no`: print `[forge:start] Paused. Re-run /forge:start <NAME> to resume.` and stop.
If `ASK_MODE = false`: Print `[forge:start] Starting execution.` and proceed.

**Initialize in-context state:**

Maintain `ATTEMPT_MAP`: a mapping of task filename → attempt count for the current session. Initialized empty. (This is NOT written to files — it lives in-context only.)

**Execution loop:**

Repeat until no tasks remain in `<SPEC_DIR>/todo/` or `<SPEC_DIR>/working/`:

### Loop Step 0: Sync

Check whether there is a remote:
```bash
git remote
```
If the output is empty (no remote), skip to Loop Step 1.

If a remote exists, pull:
```bash
git pull --rebase
```
If the pull fails (non-zero exit, including conflicts): stop the loop immediately. Print:
```
[forge:start] git pull --rebase failed. Resolve conflicts or connectivity issues, then re-run /forge:start <NAME> to resume.
```
Do not proceed. Task state is intact.

### Loop Step 1: Pick Task

Glob `<SPEC_DIR>/working/*.md`:
- If a file exists: use it as the current task (resume from interrupted run). Skip to Loop Step 3.
- Otherwise: Glob `<SPEC_DIR>/todo/*.md` and sort lexicographically. Take the first file. If empty, exit the loop.

### Loop Step 2: Move to working/

```bash
mv <SPEC_DIR>/todo/<taskname>.md <SPEC_DIR>/working/<taskname>.md
```

### Loop Step 3: Check Attempt Count

Look up `<taskname>` in `ATTEMPT_MAP`. If not present, initialize to `0`.

If `ATTEMPT_MAP[<taskname>]` >= `MAX_TRIES`:
- `mv <SPEC_DIR>/working/<taskname>.md <SPEC_DIR>/blocked/<taskname>.md`
- Write `<SPEC_DIR>/blocked/<taskname>.reason.md`: `Exceeded maximum tries (<MAX_TRIES> attempts) without successful verification.`
- Print: `[forge:start] Task <taskname> blocked after <MAX_TRIES> attempts.`
- Remove `<taskname>` from `ATTEMPT_MAP`
- Continue to next iteration

### Loop Step 4: Build Context

Read `<SPEC_DIR>/working/<taskname>.md`. Parse the `## Role` section (the first non-blank line after `## Role`). Let `ROLE` = that value, trimmed and lowercased.

Check whether `<SPEC_DIR>/council/<ROLE>.md` exists. If it does, read it as `AGENT_INSTRUCTIONS`. If not, read `${CLAUDE_PLUGIN_ROOT}/agents/executor.md` as `AGENT_INSTRUCTIONS`.

Read `<SPEC_DIR>/project.md` as `PROJECT_CONTENTS`.

Read all `*.md` files in `<SPEC_DIR>/council/` as `COUNCIL_FILES`.

### Loop Step 5: Invoke Task Agent

Invoke the Agent tool:

```
You are executing a forge task.

Project root: <PROJECT_ROOT>
Forge dir: <SPEC_DIR>
Current task file: <SPEC_DIR>/working/<taskname>.md

## Your Role Instructions
<AGENT_INSTRUCTIONS>

---

## Project Spec
<PROJECT_CONTENTS>

---

## Task
<TASK_FILE_CONTENTS>

---

## Council Perspectives (Deliberation)

Before implementing anything, read each council member's DELIBERATION section below and reason through their perspective in-context. Write a brief (2-4 sentence) summary of what each council member would flag or care about regarding this task. Only after completing this deliberation, begin implementation.

<For each file in COUNCIL_FILES (including the role's own file):>
### Council member: <filename>
<FILE_CONTENTS>
</For each>

---

## Signals

When you are done, you MUST emit exactly one of these signals as the last thing in your response:

- Success: <task-complete>DONE</task-complete>
- Blocked: <task-blocked>REASON</task-blocked>

Do NOT emit <task-complete> before you have:
1. Completed all steps in ## Steps
2. Verified every item in ## Verification passes (using Read/Grep/Glob/LSP for assertions, Bash for commands)
3. Run the ## Save Command successfully
```

### Loop Step 6: Handle Agent Output

Scan the agent's output from the end for the last occurrence of a signal tag.

**Case A: `<task-blocked>REASON</task-blocked>`**
- Extract REASON
- `mv <SPEC_DIR>/working/<taskname>.md <SPEC_DIR>/blocked/<taskname>.md`
- Write `<SPEC_DIR>/blocked/<taskname>.reason.md` with REASON
- Print: `[forge:start] Task <taskname> blocked: <REASON>`
- Remove `<taskname>` from `ATTEMPT_MAP`
- Continue to next iteration

**Case B: `<task-complete>DONE</task-complete>`**
- Proceed to Loop Step 7 (Verify)

**Case C: No signal found**
- Increment `ATTEMPT_MAP[<taskname>]` by 1
- `mv <SPEC_DIR>/working/<taskname>.md <SPEC_DIR>/todo/<taskname>.md`
- Print: `[forge:start] Task <taskname> produced no signal (attempt <N>/<MAX_TRIES>). Retrying.`
- Continue to next iteration

### Loop Step 7: Verify

Read `<SPEC_DIR>/verifier.md`. Invoke the Agent tool:

```
You are the forge verifier for this project.

Project root: <PROJECT_ROOT>
Task file: <SPEC_DIR>/working/<taskname>.md

<VERIFIER_CONTENTS>

---

## Task to verify:
<TASK_FILE_CONTENTS>
```

Where `<VERIFIER_CONTENTS>` is the full contents of `<SPEC_DIR>/verifier.md`.

Parse the verifier's output:

**Case A: `<verify-pass>`**
- `mv <SPEC_DIR>/working/<taskname>.md <SPEC_DIR>/done/<taskname>.md`
- Print: `[forge:start] Task <taskname> complete. ✓`
- Remove `<taskname>` from `ATTEMPT_MAP`
- Push to remote if one exists:
  ```bash
  git push
  ```
  - If push fails due to remote having new commits: run `git pull --rebase && git push`. If that succeeds, print `[forge:start] Pulled and pushed.`. If it fails, print `[forge:start] Push failed after rebase — resolve manually, then re-run to resume.` and stop.
  - If no remote: skip silently.
- Continue to next iteration

**Case B: `<verify-fail>REASON</verify-fail>`**
- Increment `ATTEMPT_MAP[<taskname>]` by 1
- `mv <SPEC_DIR>/working/<taskname>.md <SPEC_DIR>/todo/<taskname>.md`
- Print: `[forge:start] Task <taskname> verification failed (attempt <N>/<MAX_TRIES>): <REASON>`
- Continue to next iteration

**Case C: No signal found**
- Treat as verify-fail with REASON = "Verifier produced no signal"
- Increment `ATTEMPT_MAP[<taskname>]` by 1
- `mv <SPEC_DIR>/working/<taskname>.md <SPEC_DIR>/todo/<taskname>.md`
- Print: `[forge:start] Task <taskname> — verifier produced no signal (attempt <N>/<MAX_TRIES>). Retrying.`
- Continue to next iteration

### Loop Termination

After each iteration, check:
- Glob `<SPEC_DIR>/todo/*.md` — any results?
- Glob `<SPEC_DIR>/working/*.md` — any results?

If both are empty: exit the loop and proceed to Step 11.

---

## Step 11: Report

Print: `[forge:start] All tasks complete.`

Count files in `<SPEC_DIR>/done/` and `<SPEC_DIR>/blocked/`.

Display completion summary:
```
[forge:start] Run complete — <NAME>
  Done:    <N> tasks
  Blocked: <M> tasks

<If M == 0:>
  All tasks completed successfully.
```

**If there are blocked tasks**, generate a blocked summary doc:

For each blocked task file in `<SPEC_DIR>/blocked/` (excluding `.reason.md` files), read its contents and read `<taskname>.reason.md` if it exists.

Write `<SPEC_DIR>/blocked-summary.md`:

```
# Blocked Tasks — <NAME>

Generated by forge at the end of a run. Review each blocked task and its reason,
then re-run `/forge:start <SLUG>` to retry.

## Blocked Tasks

<For each blocked task:>
### <taskname>

**Task:**
<full contents of the task file>

**Block reason:**
<contents of .reason.md, or "No reason recorded." if absent>

---
</For each>

## Instructions for Retry

Review each blocked task and its reason above. You can:
- Move a task from `blocked/` back to `todo/` manually to retry it as-is
- Edit the task file before moving it back, to clarify requirements or add context
- Edit `project.md` (the `## Global Constraints` or other sections) if a constraint is causing failures
- Run `/forge:start <SLUG>` to resume — completed tasks are not re-run
```

Print:
```
[forge:start] Blocked summary written to <SPEC_DIR>/blocked-summary.md
[forge:start] Review it, edit task files or project.md as needed, then re-run /forge:start <SLUG>.
```

---

## Error Handling

- **project.md missing:** Error and stop after Step 1.
- **git init fails:** Error and stop after Step 2.
- **Agent tool invocation fails:** Print `[forge:start] Error invoking agent for task <taskname>. Treating as no-signal.` Increment attempt count and move back to todo/.
- **project.md missing `**Max task tries:**` line:** Default to 3.
- **council/ has no agent file for a task's role:** Use `executor.md` silently.
- **working/ contains multiple files on resume:** Use the lexicographically first one.

---

## Important Behavioral Rules

1. **Filesystem state is authoritative.** Always use Glob/Bash to check actual file state; do not trust in-context assumptions.
2. **Move files atomically.** Always use `mv`, never copy-then-delete.
3. **The verifier is independent.** It re-checks from scratch; it does not trust the task agent's self-reported verification.
4. **Attempt counts reset on successful completion.** `ATTEMPT_MAP` entry is removed when a task moves to `done/`.
5. **Council deliberation is in-context.** All council files are passed to the task agent in a single invocation.
6. **The spec directory IS the forge directory.** All artifacts live in `<SPEC_DIR>`, not a subdirectory.
7. **Never re-run completed tasks.** If a task is in `done/`, it is done. Do not re-execute it.
