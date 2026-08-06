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
CYAN='\033[0;36m'
NC='\033[0m'

ok()    { echo -e "${GREEN}✅ $1${NC}"; }
warn()  { echo -e "${YELLOW}⚠️  $1${NC}"; }
fail()  { echo -e "${RED}❌ $1${NC}"; exit 1; }
info()  { echo -e "${BOLD}→ $1${NC}"; }
ask()   { echo -e "${CYAN}? $1${NC}"; }

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
    warn "Claude Code not found."
    echo "  Download the native installer from: https://claude.ai/download"
    echo "  After installing, re-run this script."
    echo ""
    read -rp "Press Enter to continue (config-only), or Ctrl+C to exit: "
fi

# ── 3. Anthropic API Key ─────────────────────────────────────────────────────

info "Checking Anthropic authentication..."

CREDS_FILE="$HOME/.claude/.credentials.json"
API_KEY_SET=false

# Check if already authenticated (credentials file exists and is non-empty)
if [ -f "$CREDS_FILE" ] && [ -s "$CREDS_FILE" ]; then
    ok "Credentials file found — Claude Code appears authenticated"
    API_KEY_SET=true
fi

# Check env var
if [ -n "$ANTHROPIC_API_KEY" ]; then
    ok "ANTHROPIC_API_KEY is set in environment"
    API_KEY_SET=true
fi

if [ "$API_KEY_SET" = false ]; then
    echo ""
    warn "No Anthropic credentials found. You need one of:"
    echo ""
    echo "  Option A — Claude.ai subscription (Pro or Max):"
    echo "    Run 'claude' after this script and it will open a browser to log in."
    echo ""
    echo "  Option B — Anthropic API key:"
    ask "Do you have an Anthropic API key to configure now? (y/N)"
    read -rp "  " USE_API_KEY
    if [[ "$USE_API_KEY" =~ ^[Yy]$ ]]; then
        ask "Paste your Anthropic API key (starts with sk-ant-...):"
        read -rsp "  " ANTHROPIC_API_KEY_INPUT
        echo ""
        if [ -n "$ANTHROPIC_API_KEY_INPUT" ]; then
            # Write to a dedicated secrets file (600) — not ~/.zshrc which is world-readable
            SECRETS_FILE="$CLAUDE_DIR/anthropic_env"
            mkdir -p "$CLAUDE_DIR" && chmod 700 "$CLAUDE_DIR"
            ( umask 077 && printf 'export ANTHROPIC_API_KEY=%q\n' "$ANTHROPIC_API_KEY_INPUT" > "$SECRETS_FILE" )
            chmod 600 "$SECRETS_FILE"
            ok "ANTHROPIC_API_KEY written to $SECRETS_FILE (owner-only, 600)"
            # Source it from ~/.zshrc if not already wired up
            PROFILE_FILE="$HOME/.zshrc"
            if ! grep -q "anthropic_env" "$PROFILE_FILE" 2>/dev/null; then
                echo "" >> "$PROFILE_FILE"
                echo '[ -f "$HOME/.claude/anthropic_env" ] && source "$HOME/.claude/anthropic_env"' >> "$PROFILE_FILE"
                ok "Added anthropic_env source line to ~/.zshrc"
            fi
            export ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY_INPUT"
        else
            warn "No key entered — skipping. Run 'claude' later to authenticate."
        fi
    else
        warn "Skipping API key setup. Run 'claude' after installation to authenticate."
    fi
fi

# ── 4. Git config ────────────────────────────────────────────────────────────

info "Checking git configuration..."

GIT_NAME=$(git config --global user.name 2>/dev/null || echo "")
GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

if [ -n "$GIT_NAME" ] && [ -n "$GIT_EMAIL" ]; then
    ok "git user: $GIT_NAME <$GIT_EMAIL>"
else
    warn "Git user not configured — required for commits."
    echo ""
    if [ -z "$GIT_NAME" ]; then
        ask "Your full name (for git commits):"
        read -rp "  " INPUT_NAME
        [ -n "$INPUT_NAME" ] && git config --global user.name "$INPUT_NAME" && ok "git user.name set"
    fi
    if [ -z "$GIT_EMAIL" ]; then
        ask "Your email (for git commits):"
        read -rp "  " INPUT_EMAIL
        [ -n "$INPUT_EMAIL" ] && git config --global user.email "$INPUT_EMAIL" && ok "git user.email set"
    fi
fi

# ── 5. RTK (Rust Token Killer) ───────────────────────────────────────────────

info "Checking RTK..."

install_rtk() {
    local INSTALL_DIR="$HOME/.local/bin"
    mkdir -p "$INSTALL_DIR"

    # Detect OS/arch for the right release asset
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)  ARCH="x86_64" ;;
        aarch64|arm64) ARCH="aarch64" ;;
        *) warn "Unsupported architecture: $ARCH"; return 1 ;;
    esac

    RELEASE_URL="https://github.com/rtk-ai/rtk/releases/latest/download/rtk-${OS}-${ARCH}"
    echo "  Downloading RTK from GitHub releases..."
    if curl -fsSL "$RELEASE_URL" -o "$INSTALL_DIR/rtk"; then
        chmod +x "$INSTALL_DIR/rtk"
        if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
            echo "" >> "$HOME/.zshrc"
            echo 'export PATH="$PATH:$HOME/.local/bin"' >> "$HOME/.zshrc"
            export PATH="$PATH:$INSTALL_DIR"
            ok "Added ~/.local/bin to PATH in ~/.zshrc"
        fi
        ok "RTK installed to $INSTALL_DIR/rtk ($(rtk --version 2>/dev/null))"
    else
        warn "Download failed. Install manually from: https://github.com/rtk-ai/rtk"
        return 1
    fi
}

if command -v rtk >/dev/null 2>&1; then
    ok "RTK $(rtk --version 2>/dev/null)"
else
    warn "RTK not found."
    echo "  RTK rewrites bash commands to save 60-90% tokens per Claude session."
    echo "  Source: https://github.com/rtk-ai/rtk"
    echo ""
    ask "Install RTK now? (Y/n)"
    read -rp "  " INSTALL_RTK
    if [[ ! "$INSTALL_RTK" =~ ^[Nn]$ ]]; then
        install_rtk || warn "RTK install failed — you can retry later."
    else
        warn "Skipping RTK. Install later from: https://github.com/rtk-ai/rtk"
    fi
fi

# ── 6. Ruflo / claude-flow MCP ───────────────────────────────────────────────

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

# ── 7. settings.json ─────────────────────────────────────────────────────────

info "Configuring ~/.claude/settings.json..."

mkdir -p "$CLAUDE_DIR"

if [ -f "$CLAUDE_DIR/settings.json" ]; then
    warn "settings.json already exists — backed up to settings.json.bak"
    cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.bak"
fi
cp "$SCRIPT_DIR/config/settings.json" "$CLAUDE_DIR/settings.json"
ok "settings.json installed"

# ── 8. CLAUDE.md ─────────────────────────────────────────────────────────────

info "Setting up ~/.claude/CLAUDE.md..."

if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    warn "CLAUDE.md already exists — skipping (diff with $SCRIPT_DIR/config/CLAUDE.md if needed)"
else
    cp "$SCRIPT_DIR/config/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
    ok "CLAUDE.md installed"
fi

# ── 9. RTK.md + project-workflow.md ─────────────────────────────────────────

cp "$SCRIPT_DIR/config/RTK.md" "$CLAUDE_DIR/RTK.md"
ok "RTK.md installed"

cp "$SCRIPT_DIR/docs/project-workflow.md" "$CLAUDE_DIR/project-workflow.md"
ok "project-workflow.md installed"

# ── 10. Shell aliases ────────────────────────────────────────────────────────

info "Checking shell aliases..."

ALIASES_FILE="$HOME/.zsh_aliases"
if [ -f "$ALIASES_FILE" ]; then
    warn "~/.zsh_aliases already exists — not overwriting."
    warn "Review $SCRIPT_DIR/zsh/aliases.zsh and merge what you need."
else
    cp "$SCRIPT_DIR/zsh/aliases.zsh" "$ALIASES_FILE"
    ok "~/.zsh_aliases installed"
    if ! grep -q "source.*\.zsh_aliases" "$HOME/.zshrc" 2>/dev/null; then
        echo "" >> "$HOME/.zshrc"
        echo "source ~/.zsh_aliases" >> "$HOME/.zshrc"
        ok "Added 'source ~/.zsh_aliases' to ~/.zshrc"
    fi
fi

# ── 11. Summary ──────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}Setup complete!${NC}"
echo ""
echo "Next steps:"
echo ""
echo "  1. Reload your shell:"
echo "       source ~/.zshrc"
echo ""
echo "  2. Open Claude Code (authenticates on first run if no API key set):"
echo "       claude"
echo ""
echo "  3. Install plugins inside Claude Code:"
echo "       /plugins"
echo "       Enable: frontend-design, code-review, feature-dev, playwright,"
echo "               claude-md-management, security-guidance, commit-commands,"
echo "               claude-code-setup, pr-review-toolkit, pyright-lsp,"
echo "               atlassian, remember, circleback"
echo "       Third-party (already registered): claude-mem, cc-fleet, andrej-karpathy-skills"
echo ""
echo "  4. Verify RTK token savings after first session:"
echo "       rtk gain"
echo ""
echo "  Full guide: $SCRIPT_DIR/README.md"
echo ""
