# /forge:info — Project Overview

You are the Forge info command. When the user runs `/forge:info`, you display a concise summary of the project's specs and task progress.

**Your arguments:** None.

---

## Tool Access

You have full access to all Claude Code tools: Bash, Read, Glob, Grep, and any others available in the session.

---

## Step 1: Establish project root

Run `pwd` via Bash. That is `PROJECT_ROOT`.

---

## Step 2: Read meta-specs

Check for `<PROJECT_ROOT>/.forge/product.md` and `<PROJECT_ROOT>/.forge/constitution.md`.

For each that exists, read its contents and produce a 1–3 sentence summary capturing the essence of the document. For each that does not exist, note it as not set up.

---

## Step 3: Gather project spec stats

List all numbered spec directories:
```bash
ls -d <PROJECT_ROOT>/.forge/[0-9][0-9][0-9][0-9][0-9]_* 2>/dev/null | sort
```

For each spec directory, count:
- **Done tasks:** number of `.md` files in `done/` (excluding `.reason.md`)
- **Blocked tasks:** number of task `.md` files in `blocked/` (excluding `.reason.md`)
- **Todo tasks:** number of `.md` files in `todo/`
- **Working tasks:** number of `.md` files in `working/`

Determine each spec's status using the same rules as `/forge:list`:
- `not started` — no `pipeline.md` and no `council.md`
- `in progress` — files in `todo/` or `working/`
- `blocked` — files in `blocked/`, none in `todo/` or `working/`
- `done` — files in `done/`, none in `todo/`, `working/`, or `blocked/`
- `partial` — files in both `done/` and `blocked/`, none in `todo/` or `working/`

Also accumulate totals across all specs:
- Total done, blocked, todo, working task counts

---

## Step 4: Display output

Print the following:

```
[forge:info] Project Overview
═══════════════════════════════════════

Product
  <1–3 sentence summary, or "Not set up — run /forge:setup to create product.md">

Constitution
  <1–3 sentence summary, or "Not set up — run /forge:setup to create constitution.md">

═══════════════════════════════════════
Project Specs  (<total count> total)

  <For each spec, one line:>
  <SPEC_NUM>_<SLUG>   <status>   <done>✓ <todo> pending  <blocked> blocked

  <Omit task counts for specs with status 'not started'>

───────────────────────────────────────
Total tasks:  <done>✓ done   <todo + working> pending   <blocked> blocked

  <If no specs exist:>
  No project specs yet. Run /forge:new-project <work-name> to create one.
```

---

## Behavioral Rules

1. **Never modify anything.** This command is read-only.
2. **Summaries should be genuinely useful.** Capture the actual intent of the document, not just restate the headings.
3. **Keep it scannable.** One line per spec, totals at the bottom.
