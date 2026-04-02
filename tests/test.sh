#!/usr/bin/env bash
# Forge test verifier — tests/simple
#
# Usage:
#   ./tests/test.sh          # verify forge output (run after /forge in Claude Code)
#   ./tests/test.sh --reset  # wipe generated files and forge state, then exit
#
# Full test workflow:
#   1. ./tests/test.sh --reset
#   2. Open tests/simple/ in Claude Code and run: /forge design.md
#   3. ./tests/test.sh
#
# Run from the forge project root.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SIMPLE_DIR="$SCRIPT_DIR/simple"
FORGE_DIR="$SIMPLE_DIR/.forge/design"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass()  { echo -e "  ${GREEN}✓${NC} $1"; }
fail()  { echo -e "  ${RED}✗${NC} $1"; exit 1; }
info()  { echo -e "  ${YELLOW}→${NC} $1"; }
header(){ echo -e "\n${YELLOW}[$1]${NC}"; }

# ── Reset ────────────────────────────────────────────────────────────────────

if [ "${1:-}" = "--reset" ]; then
  header "reset"
  info "Removing generated files and forge state..."
  rm -rf \
    "$SIMPLE_DIR/.forge" \
    "$SIMPLE_DIR/src" \
    "$SIMPLE_DIR/bin" \
    "$SIMPLE_DIR/test" \
    "$SIMPLE_DIR/package.json" \
    "$SIMPLE_DIR/node_modules"
  pass "Reset complete"
  echo ""
  echo "Next: open tests/simple/ in Claude Code and run: /forge design.md"
  exit 0
fi

# ── Verify Forge State ───────────────────────────────────────────────────────

header "verify: forge state"

[ -d "$FORGE_DIR" ] || fail ".forge/design/ not found — run /forge design.md in tests/simple/ first"

DONE_COUNT=$(find "$FORGE_DIR/done" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
TODO_COUNT=$(find "$FORGE_DIR/todo" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
BLOCKED_COUNT=$(find "$FORGE_DIR/blocked" -name "*.md" ! -name "*.reason.md" 2>/dev/null | wc -l | tr -d ' ')

[ "$DONE_COUNT" -gt 0 ] || fail "No tasks in done/ — forge may not have completed"
[ "$TODO_COUNT" -eq 0 ] || fail "$TODO_COUNT task(s) still in todo/"
[ "$BLOCKED_COUNT" -eq 0 ] || fail "$BLOCKED_COUNT task(s) blocked — check .forge/design/blocked/*.reason.md"

pass "$DONE_COUNT tasks completed, 0 blocked"

# ── Verify Generated Files ───────────────────────────────────────────────────

header "verify: generated files"

[ -f "$SIMPLE_DIR/src/store.js" ]     || fail "src/store.js not found"
[ -f "$SIMPLE_DIR/bin/kv.js" ]        || fail "bin/kv.js not found"
[ -f "$SIMPLE_DIR/test/cli.test.js" ] || fail "test/cli.test.js not found"

pass "src/store.js"
pass "bin/kv.js"
pass "test/cli.test.js"

# ── Run Tests ────────────────────────────────────────────────────────────────

header "verify: node tests"

cd "$SIMPLE_DIR"
node --test test/cli.test.js
cd "$SCRIPT_DIR/.."

echo ""
echo -e "${GREEN}All checks passed.${NC}"
