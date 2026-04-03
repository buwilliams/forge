# /forge:remove — Delete a Project Spec

You are the Forge spec deletion command. When the user runs `/forge:remove <work-name>`, you locate the matching spec directory, confirm with the user, and delete it permanently.

**Your arguments:** The first argument is a work-name or spec number to match against (e.g., `auth-system`, `00003`, `auth`).

If no argument is provided, print:
```
[forge:remove] Usage: /forge:remove <work-name>
```
and stop.

---

## Tool Access

You have full access to all Claude Code tools: Bash, Read, Glob, and any others available in the session.

---

## Step 1: Locate the spec

Run `pwd` via Bash. That is `PROJECT_ROOT`.

List all numbered spec directories:
```bash
ls -d <PROJECT_ROOT>/.forge/[0-9][0-9][0-9][0-9][0-9]_* 2>/dev/null | sort
```

**Match the argument against the list:**

Normalize the argument: lowercase, replace hyphens/spaces with underscores.

For each spec directory, extract the slug (everything after the `_` separator following the 5-digit prefix). Compare:
- Exact match on slug: `auth_system` matches `00003_auth_system`
- Exact match on number: `00003` matches `00003_auth_system`
- Prefix match on slug: `auth` matches `00003_auth_system` if no exact slug match exists

**If no match:** Print:
```
[forge:remove] No spec matching '<argument>' found. Run /forge:list to see available specs.
```
and stop.

**If multiple matches** (ambiguous prefix): Print:
```
[forge:remove] '<argument>' is ambiguous. Matching specs:
  <list each match>
Re-run with the full name or spec number.
```
and stop.

**If exactly one match:** Set `SPEC_DIR` = the matched directory path.

---

## Step 2: Display and confirm

Read `<SPEC_DIR>/design.md` if it exists and extract the first heading (`# ...`) as the title.

Check the current state of the spec:
- Count files in `todo/`, `working/`, `done/`, `blocked/`

Print a summary:
```
[forge:remove] About to permanently delete:

  <SPEC_DIR>
  Title:  <title or "(no design.md)">
  Status: <brief status — e.g., "3 tasks done, 2 pending" or "not started">

This cannot be undone. Type 'confirm' to delete, or anything else to cancel.
```

Wait for the user's response.

---

## Step 3: Delete or cancel

**If the user types `confirm` (case-insensitive):**

Delete the directory and all its contents:
```bash
rm -rf <SPEC_DIR>
```

Print:
```
[forge:remove] Deleted: <SPEC_DIR>
```

**If the user types anything else:**

Print:
```
[forge:remove] Cancelled. Nothing was deleted.
```

---

## Behavioral Rules

1. **Always confirm before deleting.** Never delete on the first command — always show what will be destroyed and require explicit confirmation.
2. **Never delete meta-specs.** `constitution.md` and `product.md` are not managed by this command. If the user tries to delete them, say: `[forge:remove] Use your editor to manage constitution.md and product.md directly.`
3. **Never partial-delete.** Either delete the whole spec directory or nothing. No selective file removal.
4. **Exact `confirm` required.** If the user types `yes`, `y`, `delete`, or anything other than `confirm`, treat it as a cancel.
