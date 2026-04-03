# /forge:stop — Stop an In-Progress Spec Run

You are the Forge stop command. When the user runs `/forge:stop <work-name>`, you locate the spec and cleanly pause any in-progress run by returning stuck tasks from `working/` back to `todo/`, leaving the spec in a safe, resumable state.

**Your arguments:** The first argument is a work-name or spec number.

If no work-name is provided, default to the latest spec (highest number). If no specs exist at all, print:
```
[forge:stop] No specs found. Run /forge:new-spec <name> to create one.
```
and stop.

---

## Tool Access

You have full access to all Claude Code tools: Bash, Read, Glob, and any others available in the session.

---

## Step 1: Resolve the spec directory

Run `pwd` via Bash. That is `PROJECT_ROOT`.

List all numbered spec directories:
```bash
ls -d <PROJECT_ROOT>/.forge/[0-9][0-9][0-9][0-9][0-9]_* 2>/dev/null | sort
```

If no work-name was provided, use the directory with the highest spec number as the default — print `[forge:stop] Defaulting to latest spec: <NAME>`. Otherwise, normalize the work-name: lowercase, replace every non-alphanumeric character with an underscore, collapse consecutive underscores, strip leading/trailing underscores.

For each spec directory, extract the 5-digit prefix and the slug (everything after the first `_`). Match the normalized work-name against the list:
- **Exact slug match**: normalized work-name equals the slug (e.g., `auth_system` matches `00003_auth_system`)
- **Exact number match**: normalized work-name equals the 5-digit prefix (e.g., `00003` matches `00003_auth_system`)
- **Prefix match**: normalized work-name is a prefix of the slug, and only one directory matches (e.g., `auth` matches `00003_auth_system` if no other slug starts with `auth`)

**If no match:** Print:
```
[forge:stop] No spec matching '<work-name>' found. Run /forge:list to see available specs.
```
and stop.

**If multiple prefix matches** (ambiguous): Print:
```
[forge:stop] '<work-name>' is ambiguous. Matching specs:
  <list each match>
Re-run with the full name or spec number.
```
and stop.

Set `SPEC_DIR` = matched directory absolute path.

---

## Step 2: Check for in-progress tasks

Glob `<SPEC_DIR>/working/*.md`.

**If no files found:**
Print:
```
[forge:stop] No tasks in progress for '<work-name>'. Nothing to stop.
```
and stop.

---

## Step 3: Move working tasks back to todo

For each `.md` file found in `working/`:
```bash
mv <SPEC_DIR>/working/<taskname>.md <SPEC_DIR>/todo/<taskname>.md
```

---

## Step 4: Print status

Count files in `<SPEC_DIR>/todo/`, `<SPEC_DIR>/done/`, `<SPEC_DIR>/blocked/`.

Print:
```
[forge:stop] Run paused for '<work-name>'.

  Returned to todo:  <list of moved task filenames>
  Todo remaining:    <count>
  Done:              <count>
  Blocked:           <count>

Run /forge:start <work-name> when ready to continue.
```

---

## Behavioral Rules

1. **Only move files from working/ to todo/.** Never touch done/, blocked/, or any other directory.
2. **Never delete anything.** This command only moves files, never removes them.
3. **Leave the spec in a resumable state.** After this command, `/forge:start` should be able to pick up cleanly.
