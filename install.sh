#!/usr/bin/env bash
# Claude Code Power User Setup
# Tested on: Ubuntu/Debian, zsh shell
# Prerequisites: Node.js 18+, zsh

set -e

CLAUDE_DIR="$HOME/.claude"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
fail() { echo -e "${RED}❌ $1${NC}"; exit 1; }
info() { echo -e "${BOLD}→ $1${NC}"; }

echo ""
echo -e "${BOLD}Claude Code Power User Setup${NC}"
echo "================================"
echo ""

# ── 1. Prerequisites ────────────────────────────────────────────────────────

info "Checking prerequisites..."

command -v node >/dev/null 2>&1 || fail "Node.js required. Install via nvm: https://github.com/nvm-sh/nvm"
command -v npx  >/dev/null 2>&1 || fail "npx required (ships with Node.js 5.2+)"
NODE_VER=$(node -e "process.exit(parseInt(process.version.slice(1)) < 18 ? 1 : 0)" 2>/dev/null && echo "ok" || echo "old")
[ "$NODE_VER" = "old" ] && fail "Node.js 18+ required. Current: $(node --version)"
ok "Node.js $(node --version)"

# ── 2. Claude Code ───────────────────────────────────────────────────────────

info "Checking Claude Code..."

if command -v claude >/dev/null 2>&1; then
    ok "Claude Code already installed ($(claude --version 2>/dev/null || echo 'version unknown'))"
else
    warn "Claude Code not found. Install it from: https://claude.ai/download"
    warn "After installing, re-run this script."
    echo ""
    read -p "Press Enter to continue anyway (for config-only setup), or Ctrl+C to exit: "
fi

# ── 3. RTK (Rust Token Killer) ───────────────────────────────────────────────

info "Checking RTK..."

if command -v rtk >/dev/null 2>&1; then
    ok "RTK $(rtk --version 2>/dev/null)"
else
    warn "RTK not found at $(which rtk 2>/dev/null || echo 'not in PATH')"
    warn "RTK rewrites bash commands to save 60-90% of tokens on every Claude session."
    warn "Install it manually, then add it to PATH (~/.local/bin is recommended)."
    warn "Once installed, the PreToolUse hook in settings.json will activate automatically."
fi

# ── 4. Ruflo / claude-flow MCP ───────────────────────────────────────────────

info "Setting up Ruflo MCP server..."

if [ -f "$HOME/.mcp.json" ]; then
    if grep -q '"ruflo"' "$HOME/.mcp.json" 2>/dev/null; then
        ok "Ruflo already in ~/.mcp.json"
    else
        warn "~/.mcp.json exists but doesn't contain ruflo. Merge manually:"
        echo "  Add the contents of $SCRIPT_DIR/config/.mcp.json to your ~/.mcp.json"
    fi
else
    cp "$SCRIPT_DIR/config/.mcp.json" "$HOME/.mcp.json"
    ok "~/.mcp.json created with ruflo MCP server"
fi

# ── 5. settings.json ─────────────────────────────────────────────────────────

info "Configuring ~/.claude/settings.json..."

mkdir -p "$CLAUDE_DIR"

if [ -f "$CLAUDE_DIR/settings.json" ]; then
    warn "settings.json already exists — backed up to settings.json.bak"
    cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.bak"
fi
cp "$SCRIPT_DIR/config/settings.json" "$CLAUDE_DIR/settings.json"
ok "settings.json installed"

# ── 6. CLAUDE.md ─────────────────────────────────────────────────────────────

info "Setting up ~/.claude/CLAUDE.md..."

if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    warn "CLAUDE.md already exists — skipping (edit manually or diff with $SCRIPT_DIR/config/CLAUDE.md)"
else
    cp "$SCRIPT_DIR/config/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
    ok "CLAUDE.md installed"
fi

# ── 7. RTK.md ────────────────────────────────────────────────────────────────

cp "$SCRIPT_DIR/config/RTK.md" "$CLAUDE_DIR/RTK.md"
ok "RTK.md installed"

# ── 8. project-workflow.md ───────────────────────────────────────────────────

cp "$SCRIPT_DIR/docs/project-workflow.md" "$CLAUDE_DIR/project-workflow.md"
ok "project-workflow.md installed"

# ── 9. Shell aliases ─────────────────────────────────────────────────────────

info "Checking shell aliases..."

ALIASES_FILE="$HOME/.zsh_aliases"
if [ -f "$ALIASES_FILE" ]; then
    warn "~/.zsh_aliases already exists — not overwriting."
    warn "Review $SCRIPT_DIR/zsh/aliases.zsh and merge what you need."
else
    cp "$SCRIPT_DIR/zsh/aliases.zsh" "$ALIASES_FILE"
    ok "~/.zsh_aliases installed"
    # Ensure it's sourced from .zshrc
    if ! grep -q "source.*\.zsh_aliases" "$HOME/.zshrc" 2>/dev/null; then
        echo "" >> "$HOME/.zshrc"
        echo "source ~/.zsh_aliases" >> "$HOME/.zshrc"
        ok "Added 'source ~/.zsh_aliases' to ~/.zshrc"
    fi
fi

# ── 10. Summary ──────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}Setup complete!${NC}"
echo ""
echo "Next steps:"
echo ""
echo "  1. Open Claude Code and install plugins:"
echo "       claude"
echo "       /plugins"
echo ""
echo "  2. Enable these plugins in the Plugins UI:"
echo "       Official: frontend-design, code-review, feature-dev, playwright,"
echo "                 claude-md-management, security-guidance, commit-commands,"
echo "                 claude-code-setup, pr-review-toolkit, pyright-lsp,"
echo "                 atlassian, remember, circleback"
echo ""
echo "  3. Add third-party plugin marketplaces:"
echo "       These are already configured in settings.json extraKnownMarketplaces."
echo "       Install in Plugins UI: claude-mem (thedotmack), cc-fleet (ethanhq),"
echo "       andrej-karpathy-skills (karpathy-skills)"
echo ""
echo "  4. If RTK is installed, verify the hook works:"
echo "       rtk gain"
echo ""
echo "  5. Customize ~/.claude/CLAUDE.md with your org's paths and design system."
echo ""
echo "  Full guide: $SCRIPT_DIR/README.md"
echo ""
