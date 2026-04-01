# Design: Key-Value Store CLI

A minimal command-line key-value store backed by a single JSON file. This is a
test project for validating the forge plugin's execution pipeline.

## What It Does

A CLI tool called `kv` that stores and retrieves string key-value pairs in a
local `.kv.json` file. No server, no database, no dependencies beyond Node.js
standard library.

### Commands

- `kv set <key> <value>` — stores the key-value pair
- `kv get <key>` — prints the value or exits with code 1 if not found
- `kv del <key>` — removes the key
- `kv list` — prints all keys, one per line, sorted alphabetically
- `kv clear` — deletes the store file entirely

### Behavior

- The store file is `.kv.json` in the current working directory.
- If the store file doesn't exist, `get` and `del` exit with code 1 and a
  message to stderr. `set` creates it. `list` prints nothing. `clear` is a
  no-op.
- Keys must be non-empty strings. Values can be any string including empty.
- All output goes to stdout. All errors go to stderr.
- Exit code 0 on success, 1 on failure.

## Tech Stack

- Node.js (no TypeScript, no build step)
- Single entry point: `bin/kv.js` with a `#!/usr/bin/env node` shebang
- Module source in `src/store.js` (the read/write/delete logic)
- Tests in `test/` using Node's built-in `node:test` and `node:assert`

## Global Constraints

- **No external dependencies.** No npm install. Only Node.js built-in modules.
- **No mocks or stubs in tests.** Tests operate on a real `.kv.json` file in a
  temp directory. Each test creates its own temp dir and cleans up after.
- **No placeholder implementations.** Every function must be fully working
  before the task is considered done.
- **Tests must actually run and pass**, not just exist as files.
