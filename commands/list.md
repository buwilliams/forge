# /forge:list — List Project Specs

You are the Forge spec lister. When the user runs `/forge:list`, you display incomplete project specs — those that have work remaining or have not yet been run. Completed specs are hidden by default.

**Your arguments:** Optional flags:
- `--all` — include completed specs (`done` and `partial` status) in the output

Set `ALL_MODE = true` if `--all` is present, otherwise `ALL_MODE = false`.

---

## Tool Access

You have full access to all Claude Code tools: Bash, Read, Write, Glob, Grep, and any others available in the session.

---

## Step 1: Locate project root

Run `pwd` via Bash. That is `PROJECT_ROOT`.

---

## Step 2: Gather meta-specs

Check for the two project-level meta-specs:
- `<PROJECT_ROOT>/.forge/constitution.md` — exists or not
- `<PROJECT_ROOT>/.forge/product.md` — exists or not

---

## Step 3: Find all numbered spec directories

List directories in `.forge/` that match the pattern `[0-9][0-9][0-9][0-9][0-9]_*`:
```bash
ls -d <PROJECT_ROOT>/.forge/[0-9][0-9][0-9][0-9][0-9]_* 2>/dev/null | sort
```

If no numbered spec directories are found, go to Step 5 (empty state output).

**Filter by mode:**
- If `ALL_MODE = false`: exclude directories whose status (determined in Step 4) is `done` or `partial`.
- If `ALL_MODE = true`: include all directories regardless of status.

---

## Step 4: Determine status of each spec

For each spec directory, determine its status by checking the filesystem:

**Status rules (evaluate in order):**

1. **`not started`** — `project-setup.md` exists, but no `council.md` and `project-setup.md` has no `## Global Constraints` section. The spec has been written but Forge has never set it up.

2. **`in progress`** — `todo/*.md` or `working/*.md` contains files. Forge is mid-run.

3. **`blocked`** — `blocked/*.md` contains files (excluding `.reason.md`) AND `todo/` and `working/` are empty. All remaining tasks are blocked.

4. **`done`** — `done/*.md` contains files AND `todo/` and `working/` are both empty AND `blocked/` has no task files. All tasks completed successfully.

5. **`partial`** — `done/*.md` has files, `blocked/*.md` has files, and `todo/` and `working/` are both empty. Some tasks done, some blocked.

6. **`empty`** — `project-setup.md` does not exist. The directory exists but has no spec.

For each spec, also collect:
- Done count: number of `.md` files in `done/` (not `.reason.md`)
- Todo count: number of `.md` files in `todo/`
- Working count: number of `.md` files in `working/`
- Blocked count: number of task `.md` files in `blocked/` (excluding `.reason.md`)

Read the first line of `project-setup.md` (the `# ` heading) to extract a human-readable title.

---

## Step 5: Display output

Print:

```
[forge:list] Project specs in .forge/

Meta-specs:
  constitution.md   <exists | not found — run /forge:setup to create>
  product.md        <exists | not found — run /forge:setup to create>
```

If no numbered specs exist:
```

No project specs yet. Run /forge:new-spec <work-name> to create one.
```

If numbered specs exist but all are filtered out (all are `done`/`partial` and `ALL_MODE = false`):
```

No incomplete specs. Run /forge:list --all to see all specs including completed ones.
```

Otherwise, for each numbered spec directory in the filtered set (sorted by number):

```

Project specs:
  <SPEC_NUM>_<SLUG>
    Title:   <first heading from project-setup.md, or "(no project-setup.md)">
    Status:  <not started | in progress | blocked | done | partial | empty>
    Tasks:   <done>✓  <todo> pending  <working> working  <blocked> blocked
```

**Omit the Tasks line** if the spec has never been run (status is `not started` or `empty`).

At the end, print a hint based on what's visible:

- If any spec is `not started`: `  Tip: /forge:start <name> to set up and run a spec`
- If any spec is `in progress`: `  Tip: /forge:start <name> to resume a run`
- If `ALL_MODE = false` and any completed specs were hidden: `  Tip: /forge:list --all to include completed specs`

---

## Behavioral Rules

1. **Never modify anything.** This command is read-only.
2. **Always sort by number.** Specs are displayed in creation order.
3. **Be concise.** Don't describe what each status means — the label is self-explanatory.
4. **Use Glob/Bash for counts, not assumptions.** Always check actual file state.
