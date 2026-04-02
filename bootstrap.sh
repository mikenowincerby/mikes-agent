#!/bin/bash
set -euo pipefail

# COO Chief of Staff Agent — Bootstrap Script
# Sets up a new machine from zero to working.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK_ONLY=false

if [[ "${1:-}" == "--check" ]]; then
  CHECK_ONLY=true
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "  ${GREEN}✓${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; }
warn() { echo -e "  ${YELLOW}!${NC} $1"; }
header() { echo -e "\n${YELLOW}$1${NC}"; }

ERRORS=0

# --- Step 1: Check prerequisites ---
header "Checking prerequisites..."

if command -v node &>/dev/null; then
  pass "node $(node --version)"
else
  fail "node not found (required for gws CLI)"
  ERRORS=$((ERRORS + 1))
fi

if command -v claude &>/dev/null; then
  pass "claude CLI found"
else
  warn "claude CLI not found (optional but recommended)"
fi

if command -v gh &>/dev/null; then
  pass "gh CLI found"
else
  warn "gh CLI not found (needed for automation health checks)"
fi

if $CHECK_ONLY; then
  # Skip install steps in check mode
  :
else
  # --- Step 2: Install gws CLI if missing ---
  header "Checking gws CLI..."

  if command -v gws &>/dev/null; then
    pass "gws CLI $(gws --version 2>/dev/null || echo 'installed')"
  else
    echo "  Installing gws CLI..."
    npm install -g gws-cli
    if command -v gws &>/dev/null; then
      pass "gws CLI installed"
    else
      fail "gws CLI installation failed"
      ERRORS=$((ERRORS + 1))
    fi
  fi

  # --- Step 3: Authenticate gws ---
  header "Checking gws authentication..."

  if [[ -f "$HOME/.config/gws/token_cache.json" ]]; then
    pass "Token cache exists"
  else
    echo "  No token cache found. Starting authentication..."
    echo "  A browser window will open for Google OAuth."
    gws auth login -s sheets,drive
  fi
fi

# --- Step 4: Validate auth ---
header "Validating Google Workspace auth..."

AUTH_TEST=$(gws drive files list --params '{"pageSize": 1}' 2>/dev/null | grep -v "Using keyring" || true)
if echo "$AUTH_TEST" | grep -q "files"; then
  pass "Google Drive API accessible"
else
  fail "Google Drive API not accessible — run: gws auth login -s sheets,drive"
  ERRORS=$((ERRORS + 1))
fi

# --- Step 5: Install global CLAUDE.md shim ---
if ! $CHECK_ONLY; then
  header "Setting up global CLAUDE.md shim..."

  CLAUDE_DIR="$HOME/.claude"
  CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"

  mkdir -p "$CLAUDE_DIR"

  if [[ -f "$CLAUDE_MD" ]]; then
    if grep -q "Global Shim" "$CLAUDE_MD" 2>/dev/null; then
      pass "Global CLAUDE.md shim already in place"
    else
      cp "$CLAUDE_MD" "$CLAUDE_MD.bak"
      warn "Backed up existing CLAUDE.md to CLAUDE.md.bak"
      cat > "$CLAUDE_MD" << 'SHIM'
# Cerby AI — Global Shim

All instructions, briefings, and configuration live in the project repository's CLAUDE.md.
Briefings are at `briefings/` relative to the project root. Knowledge is at `knowledge.md`.
Guides are at `guides/` relative to the project root.
SHIM
      pass "Global CLAUDE.md shim installed"
    fi
  else
    cat > "$CLAUDE_MD" << 'SHIM'
# Cerby AI — Global Shim

All instructions, briefings, and configuration live in the project repository's CLAUDE.md.
Briefings are at `briefings/` relative to the project root. Knowledge is at `knowledge.md`.
Guides are at `guides/` relative to the project root.
SHIM
    pass "Global CLAUDE.md shim created"
  fi
fi

# --- Step 6: Set up memory directory ---
header "Setting up briefings..."

BRIEFINGS_DIR="$SCRIPT_DIR/briefings"
mkdir -p "$BRIEFINGS_DIR"

if [[ -f "$SCRIPT_DIR/knowledge.md" ]]; then
  pass "knowledge.md exists (tracked)"
else
  fail "knowledge.md missing — this should be in git"
  ERRORS=$((ERRORS + 1))
fi

if [[ -f "$BRIEFINGS_DIR/briefings.md" ]]; then
  pass "briefings.md exists (session state)"
else
  if [[ -f "$BRIEFINGS_DIR/briefings.template.md" ]]; then
    if ! $CHECK_ONLY; then
      cp "$BRIEFINGS_DIR/briefings.template.md" "$BRIEFINGS_DIR/briefings.md"
      pass "briefings.md created from template"
    else
      warn "briefings.md missing — run bootstrap without --check to create from template"
    fi
  else
    warn "briefings.md missing and no template found"
  fi
fi

if [[ -f "$BRIEFINGS_DIR/active-work.md" ]]; then
  pass "active-work.md exists (session state)"
else
  if ! $CHECK_ONLY; then
    cat > "$BRIEFINGS_DIR/active-work.md" << 'EOF'
# Active Work
Last updated: (bootstrap)

## Current Priority: None
**Status**: idle

No active tasks. Ready for new work.
EOF
    pass "active-work.md created"
  else
    warn "active-work.md missing — run bootstrap without --check to create"
  fi
fi

# --- Step 7: Validate project structure ---
header "Validating project structure..."

REQUIRED_FILES=(
  "CLAUDE.md"
  "TODO.md"
  "knowledge.md"
  "business-logic/pipeline-registry.md"
  "agents/README.md"
  "codespecs/inspection-protocol.md"
  "guides/gws-quickstart.md"
)

for f in "${REQUIRED_FILES[@]}"; do
  if [[ -f "$SCRIPT_DIR/$f" ]]; then
    pass "$f"
  else
    fail "$f missing"
    ERRORS=$((ERRORS + 1))
  fi
done

# Check dispatch files match registered pipelines
header "Validating dispatch files..."

DISPATCH_DIR="$SCRIPT_DIR/.claude/agents"
if [[ -d "$DISPATCH_DIR" ]]; then
  DISPATCH_COUNT=$(ls "$DISPATCH_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
  pass "$DISPATCH_COUNT dispatch files in .claude/agents/"
else
  fail ".claude/agents/ directory missing"
  ERRORS=$((ERRORS + 1))
fi

# --- Step 8: Summary ---
header "Summary"
echo ""

if [[ $ERRORS -eq 0 ]]; then
  echo -e "${GREEN}Setup complete — no errors.${NC}"
else
  echo -e "${RED}Setup finished with $ERRORS error(s). Fix the issues above.${NC}"
fi

echo ""
echo "  Project:    $SCRIPT_DIR"
echo "  Memory:     knowledge.md ($(wc -l < "$SCRIPT_DIR/knowledge.md" 2>/dev/null || echo '?') lines)"
echo "  Pipelines:  $(grep -c '|.*agents/' "$SCRIPT_DIR/business-logic/pipeline-registry.md" 2>/dev/null || echo '?') registered"
echo ""

if $CHECK_ONLY; then
  echo "  (ran in --check mode: validation only, no changes made)"
  echo ""
fi

exit $ERRORS
