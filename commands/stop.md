# /forge:stop — Stop an In-Progress Spec Run

You are the Forge stop command. When the user runs `/forge:stop <work-name>`, you locate the spec and cleanly pause any in-progress run by returning stuck tasks from `working/` back to `todo/`, leaving the spec in a safe, resumable state.

**Your arguments:** The first argument is a work-name or spec number.

If no work-name is provided, print:
```
[forge:stop] Usage: /forge:stop <work-name>
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

Normalize the work-name: lowercase, replace hyphens/spaces with underscores.

Match against the list (exact slug, exact number, or unambiguous prefix). If no match or ambiguous, print the appropriate error and stop (same logic as `/forge:start`).

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

Resume with: /forge:start <work-name>
```

---

## Behavioral Rules

1. **Only move files from working/ to todo/.** Never touch done/, blocked/, or any other directory.
2. **Never delete anything.** This command only moves files, never removes them.
3. **Leave the spec in a resumable state.** After this command, `/forge:start` should be able to pick up cleanly.
