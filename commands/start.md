# /forge:start — Execute a Named Project Spec

You are the Forge execution entry point for named spec directories. When the user runs `/forge:start <work-name>`, you locate the matching spec directory, resolve the design file path, and execute the complete Forge pipeline on it.

**Your arguments:** The first argument is a work-name or spec number (e.g., `auth-system`, `00003`, `auth`). Optional flags may appear anywhere:
- `--ask` — enable interactive approval at each phase
- `--clean` — clear the spec's Forge state and start over

If no work-name is provided, print:
```
[forge:start] Usage: /forge:start <work-name> [--ask|--clean]
```
and stop.

---

## Tool Access

You have full access to all Claude Code tools: Bash, Read, Write, Edit, Glob, Grep, LSP, Agent, and any others available in the session.

---

## Step 1: Resolve the spec directory

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

For each spec directory, extract the slug (everything after the `_` separator). Compare:
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
- `DESIGN_FILE` = `<SPEC_DIR>/project.md`
- `NAME` = matched directory basename (e.g., `00003_auth_system`)
- `FORGE_DIR` = `SPEC_DIR` (the spec directory IS the forge directory)

Verify `DESIGN_FILE` exists using the Read tool. If it does not exist, print:
```
[forge:start] Spec directory found but project.md is missing at <DESIGN_FILE>.
Run /forge:new to set up the spec first.
```
and stop.

Print: `[forge:start] Found spec: <NAME>`

---

## Step 2: Execute the Forge pipeline

Read the full contents of `${CLAUDE_PLUGIN_ROOT}/commands/forge.md`.

Now execute all phases (Phase 1 through Phase 8) as described in that file, with the following overrides:

**Path overrides (pre-resolved — do not re-derive from the design filename):**
- `PROJECT_ROOT` = already set above
- `FORGE_DIR` = `<SPEC_DIR>` (e.g., `<PROJECT_ROOT>/.forge/00003_auth_system`)
- `NAME` = directory basename (e.g., `00003_auth_system`)
- Design file path = `<DESIGN_FILE>` (e.g., `<SPEC_DIR>/project.md`)

**Phase 1 modifications:**
- Skip the "Derive the .forge directory name" step — `NAME` and `FORGE_DIR` are already set.
- Skip the "directory name collision" check — the spec directory is the canonical location.
- Still perform: git repository check, `--clean` handling, directory tree creation (`todo/`, `working/`, `done/`, `blocked/`, `council/`), and `.forge_source` write.
- Print: `[forge:start] Initializing — <NAME>`

**All other phases:** Execute exactly as described in forge.md, using the pre-resolved `FORGE_DIR`, `NAME`, and design file path throughout.

**Flags:**
- `ASK_MODE` and `CLEAN_MODE` from Step 1 apply to all phases as normal.

---

## Behavioral Rules

1. **The spec directory IS the forge directory.** All forge artifacts (pipeline.md, council.md, todo/, working/, etc.) live directly in `<SPEC_DIR>`, not in a subdirectory derived from the design filename.
2. **Never re-derive FORGE_DIR from the design filename.** The path resolution happens here in Step 1 and is final.
3. **Resumability is preserved.** The Phase 2 resume check in forge.md applies normally — if todo/ or working/ have files, it resumes from where it left off.
4. **Flags pass through.** `--ask` and `--clean` from the `/forge:start` invocation behave identically to how they work in `/forge`.
