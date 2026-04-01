# Design: Bookmark Manager API

A REST API for managing tagged bookmarks with full-text search, backed by SQLite.
This test project is designed to stress-test forge's constraint enforcement and
council deliberation across a larger task surface.

## What It Does

A local HTTP API for saving, tagging, searching, and exporting bookmarks. A user
can save a URL with a title and tags, search their bookmarks by text or tag, and
export everything as a flat JSON array.

### Endpoints

**POST /bookmarks**
Creates a bookmark. Request body:
```json
{ "url": "https://example.com", "title": "Example", "tags": ["reference", "docs"] }
```
Returns the created bookmark with an `id` and `created_at` timestamp.
Validates: `url` is required and must be a valid URL. `title` is required and
non-empty. `tags` is optional, defaults to `[]`. Duplicate URLs are rejected
with 409.

**GET /bookmarks**
Lists all bookmarks, newest first. Supports query params:
- `?tag=foo` — filter by tag (exact match, multiple allowed: `?tag=foo&tag=bar`
  means bookmarks that have ALL listed tags)
- `?q=search+term` — full-text search across url, title, and tags
- `?limit=N&offset=M` — pagination, default limit 50

**GET /bookmarks/:id**
Returns a single bookmark by ID. 404 if not found.

**PUT /bookmarks/:id**
Updates title and/or tags. URL and created_at are immutable. 404 if not found.

**DELETE /bookmarks/:id**
Deletes a bookmark. 204 on success. 404 if not found.

**GET /export**
Returns every bookmark as a flat JSON array, no pagination. For backup purposes.

### Data Model

Single `bookmarks` table:
- `id` INTEGER PRIMARY KEY AUTOINCREMENT
- `url` TEXT UNIQUE NOT NULL
- `title` TEXT NOT NULL
- `tags` TEXT NOT NULL (JSON array stored as text)
- `created_at` TEXT NOT NULL (ISO 8601)

Full-text search uses SQLite FTS5 on `url`, `title`, and `tags`.

## Tech Stack

- Node.js with Express
- better-sqlite3 for the database (synchronous API, no ORM)
- Database file: `./data/bookmarks.db` (created on first run)
- Tests use Node's built-in `node:test` and `node:assert`
- Entry point: `src/index.js` (starts the server)
- Source layout:
  - `src/db.js` — database setup, migrations, connection
  - `src/routes/bookmarks.js` — route handlers
  - `src/routes/export.js` — export route
  - `src/validation.js` — input validation functions
  - `test/bookmarks.test.js` — API integration tests
  - `test/validation.test.js` — validation unit tests
  - `scripts/seed.js` — seed script that populates 20 realistic bookmarks

## Global Constraints

- **No mocks, stubs, or test doubles of any kind.** Tests spin up the real
  Express server on a random port, hit it with real HTTP requests using
  `node:http`, and assert against real responses. The test database is a real
  SQLite file in a temp directory — not an in-memory database, not a mock.
- **No placeholder or smoke-test implementations.** If a test file exists, every
  test in it must exercise real behavior end-to-end. A test that just checks
  "response is not undefined" is a smoke test and is not acceptable.
- **The seed script must use real data.** The 20 bookmarks must have realistic
  URLs (real domains, plausible paths), descriptive titles, and meaningful tags.
  No "Test Bookmark 1" or "https://example.com/1".
- **No in-memory SQLite databases.** Every database interaction — including in
  tests — must read and write a real `.db` file on disk.
- **Validation errors must return structured JSON**, not plain text. Format:
  `{ "error": "description" }` with appropriate HTTP status codes.
- **No `any` type annotations or equivalent looseness.** If JSDoc is used, types
  must be specific.
- **Express error handling must use a centralized error middleware**, not
  try/catch in every route.
- **The only allowed npm dependency beyond Express is better-sqlite3.** No
  lodash, no uuid, no body-parser (Express has built-in JSON parsing). Timestamp
  generation uses `new Date().toISOString()`.
