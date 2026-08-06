#!/usr/bin/env bash
# Claude Code Power User Setup — Phalkon Dev
# Tested on: Ubuntu/Debian with zsh
# Run: bash install.sh

set -e

CLAUDE_DIR="$HOME/.claude"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_TYPE=""      # set during shell detection step
PROFILE_FILE=""    # ~/.zshrc or ~/.bashrc
ALIASES_FILE=""    # ~/.zsh_aliases or ~/.bash_aliases
ALIASES_SRC=""     # path to the right aliases file in this repo

BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

ok()      { echo -e "${GREEN}  ✅ $1${NC}"; }
warn()    { echo -e "${YELLOW}  ⚠  $1${NC}"; }
fail()    { echo -e "${RED}  ✗  $1${NC}"; exit 1; }
note()    { echo -e "${DIM}     $1${NC}"; }
prompt()  { echo -e "${CYAN}  ?  $1${NC}"; }
action()  { echo -e "${BLUE}  →  $1${NC}"; }

section() {
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  $1${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════
#  WELCOME
# ═══════════════════════════════════════════════════════════════════

clear
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║       Claude Code Power User Setup               ║${NC}"
echo -e "${BOLD}║       Phalkon Dev — github.com/Phalkon-Dev       ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo "  This script sets up a complete AI-assisted development environment"
echo "  on top of Claude Code. It installs and configures:"
echo ""
echo "    • Claude Code           — Anthropic's AI developer CLI"
echo "    • RTK                   — reduces Claude token usage by 60–90%"
echo "    • Headroom              — local proxy to switch between AI providers"
echo "    • DeepSeek integration  — use DeepSeek models as a cheaper alternative"
echo "    • Ruflo (claude-flow)   — multi-agent orchestration and memory"
echo "    • Settings & rules      — pre-tuned config, permissions, and workflows"
echo "    • Shell aliases         — productivity shortcuts for git, python, docker"
echo ""
echo "  Nothing is installed without your confirmation."
echo "  You can skip any optional component and add it later."
echo ""
read -rp "  Press Enter to begin, or Ctrl+C to cancel: "


# ═══════════════════════════════════════════════════════════════════
#  SHELL DETECTION
# ═══════════════════════════════════════════════════════════════════

section "Shell Detection"

echo "  This setup installs shell aliases and modifies your shell config file."
echo "  It needs to know which shell you use so it edits the right files:"
echo ""
echo "    zsh  → config: ~/.zshrc   | aliases: ~/.zsh_aliases"
echo "    bash → config: ~/.bashrc  | aliases: ~/.bash_aliases"
echo ""

DETECTED=$(basename "$SHELL" 2>/dev/null || echo "unknown")

if [[ "$DETECTED" == "zsh" || "$DETECTED" == "bash" ]]; then
    echo "  Detected login shell: $DETECTED"
    echo ""
    prompt "Is $DETECTED your shell? (Y/n)"
    read -rp "  → " CONFIRM_SHELL
    if [[ "$CONFIRM_SHELL" =~ ^[Nn]$ ]]; then
        DETECTED=""
    fi
fi

if [[ -z "$DETECTED" || ( "$DETECTED" != "zsh" && "$DETECTED" != "bash" ) ]]; then
    echo "  Could not detect your shell automatically."
    echo ""
    prompt "Which shell do you use? Enter 1 or 2:"
    echo "    1) zsh   (default on macOS, common on Ubuntu 20.04+)"
    echo "    2) bash  (default on most Linux systems)"
    echo ""
    read -rp "  → " SHELL_CHOICE
    case "$SHELL_CHOICE" in
        1) DETECTED="zsh" ;;
        2) DETECTED="bash" ;;
        *) fail "Invalid choice. Please re-run the script and enter 1 or 2." ;;
    esac
fi

SHELL_TYPE="$DETECTED"

case "$SHELL_TYPE" in
    zsh)
        PROFILE_FILE="$HOME/.zshrc"
        ALIASES_FILE="$HOME/.zsh_aliases"
        ALIASES_SRC="$SCRIPT_DIR/zsh/aliases.zsh"
        ;;
    bash)
        PROFILE_FILE="$HOME/.bashrc"
        ALIASES_FILE="$HOME/.bash_aliases"
        ALIASES_SRC="$SCRIPT_DIR/bash/aliases.bash"
        ;;
esac

ok "Shell: $SHELL_TYPE | Config: $PROFILE_FILE | Aliases: $ALIASES_FILE"


# ═══════════════════════════════════════════════════════════════════
#  STEP 1 — PREREQUISITES
# ═══════════════════════════════════════════════════════════════════

section "Step 1 of 13 — Prerequisites"

echo "  Checking that the required system tools are available."
echo "  These are not installed by this script — they must already be present."
echo ""
note "Requires: Node.js 18+, npx (ships with Node), zsh"
echo ""

command -v node >/dev/null 2>&1 \
    || fail "Node.js not found. Install it via nvm: https://github.com/nvm-sh/nvm"
command -v npx >/dev/null 2>&1 \
    || fail "npx not found. It ships with Node.js — try reinstalling Node."

NODE_VER=$(node -e "process.exit(parseInt(process.version.slice(1)) < 18 ? 1 : 0)" 2>/dev/null && echo "ok" || echo "old")
[ "$NODE_VER" = "old" ] && fail "Node.js 18+ required. You have: $(node --version). Upgrade via nvm."

ok "Node.js $(node --version)"
ok "npx available"


# ═══════════════════════════════════════════════════════════════════
#  STEP 2 — CLAUDE CODE
# ═══════════════════════════════════════════════════════════════════

section "Step 2 of 13 — Claude Code"

echo "  Claude Code is Anthropic's official AI CLI for software development."
echo "  It lets you chat with Claude directly in your terminal, edit files,"
echo "  run commands, and use multi-agent workflows — all from the command line."
echo ""
note "Install from: https://claude.ai/download  (native installer, not npm)"
echo ""

if command -v claude >/dev/null 2>&1; then
    ok "Claude Code already installed — $(claude --version 2>/dev/null || echo 'version unknown')"
else
    warn "Claude Code is not installed."
    echo ""
    echo "  Download and run the native installer from https://claude.ai/download"
    echo "  then re-run this script. The native installer is required — do not use"
    echo "  the npm package, which is a different (older) tool."
    echo ""
    read -rp "  Press Enter to continue in config-only mode, or Ctrl+C to install Claude first: "
fi


# ═══════════════════════════════════════════════════════════════════
#  STEP 3 — ANTHROPIC API KEY
# ═══════════════════════════════════════════════════════════════════

section "Step 3 of 13 — Anthropic Authentication"

echo "  Claude Code needs to authenticate with Anthropic's API to function."
echo "  There are two ways to do this:"
echo ""
echo "    Option A — Claude.ai subscription (Pro or Max plan):"
echo "      No key needed here. After this script finishes, run 'claude' and"
echo "      it will open your browser to log in with your Claude.ai account."
echo ""
echo "    Option B — Anthropic API key:"
echo "      For users who pay per-use via the API (console.anthropic.com)."
echo "      The key starts with 'sk-ant-...' and is found in your API settings."
echo ""
note "Your key will be stored in ~/.claude/anthropic_env with owner-only (600)"
note "permissions. It will NOT be written to $PROFILE_FILE or any world-readable file."
echo ""

CREDS_FILE="$HOME/.claude/.credentials.json"
API_KEY_SET=false

if [ -f "$CREDS_FILE" ] && [ -s "$CREDS_FILE" ]; then
    ok "Existing credentials file found — Claude Code is already authenticated"
    API_KEY_SET=true
fi
if [ -n "$ANTHROPIC_API_KEY" ]; then
    ok "ANTHROPIC_API_KEY is already set in the current environment"
    API_KEY_SET=true
fi

if [ "$API_KEY_SET" = false ]; then
    prompt "Do you have an Anthropic API key to enter now? (y/N)"
    note "Say N if you use a Claude.ai subscription — you'll log in after setup."
    read -rp "  → " USE_API_KEY
    if [[ "$USE_API_KEY" =~ ^[Yy]$ ]]; then
        prompt "Paste your Anthropic API key (input is hidden):"
        read -rsp "  → " ANTHROPIC_API_KEY_INPUT
        echo ""
        if [ -n "$ANTHROPIC_API_KEY_INPUT" ]; then
            SECRETS_FILE="$CLAUDE_DIR/anthropic_env"
            mkdir -p "$CLAUDE_DIR" && chmod 700 "$CLAUDE_DIR"
            ( umask 077 && printf 'export ANTHROPIC_API_KEY=%q\n' "$ANTHROPIC_API_KEY_INPUT" > "$SECRETS_FILE" )
            chmod 600 "$SECRETS_FILE"
            ok "Key saved to $SECRETS_FILE (permissions: 600, visible only to you)"
            if ! grep -q "anthropic_env" "$PROFILE_FILE" 2>/dev/null; then
                echo "" >> "$PROFILE_FILE"
                echo '[ -f "$HOME/.claude/anthropic_env" ] && source "$HOME/.claude/anthropic_env"' >> "$PROFILE_FILE"
                ok "Added loader line to $PROFILE_FILE — key available in every new shell"
            fi
            export ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY_INPUT"
        else
            warn "Nothing entered — skipping. Run 'claude' after setup to authenticate via browser."
        fi
    else
        warn "Skipping. After setup, run 'claude' and follow the browser login prompt."
    fi
fi


# ═══════════════════════════════════════════════════════════════════
#  STEP 4 — GIT CONFIG
# ═══════════════════════════════════════════════════════════════════

section "Step 4 of 13 — Git Identity"

echo "  Git requires a name and email to attach to every commit you make."
echo "  If these are not set, 'git commit' will fail with an error."
echo "  This sets them globally (~/.gitconfig), so they apply to all repos."
echo ""

GIT_NAME=$(git config --global user.name 2>/dev/null || echo "")
GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

if [ -n "$GIT_NAME" ] && [ -n "$GIT_EMAIL" ]; then
    ok "Git identity already configured: $GIT_NAME <$GIT_EMAIL>"
else
    warn "Git identity is not fully configured."
    echo ""
    if [ -z "$GIT_NAME" ]; then
        prompt "Your full name (will appear in git commits, e.g. 'Ana García'):"
        read -rp "  → " INPUT_NAME
        if [ -n "$INPUT_NAME" ]; then
            git config --global user.name "$INPUT_NAME"
            ok "git user.name set to: $INPUT_NAME"
        else
            warn "Skipped — git commits may fail until this is set."
        fi
    fi
    if [ -z "$GIT_EMAIL" ]; then
        prompt "Your work email (will appear in git commits):"
        read -rp "  → " INPUT_EMAIL
        if [ -n "$INPUT_EMAIL" ]; then
            git config --global user.email "$INPUT_EMAIL"
            ok "git user.email set to: $INPUT_EMAIL"
        else
            warn "Skipped — git commits may fail until this is set."
        fi
    fi
fi


# ═══════════════════════════════════════════════════════════════════
#  STEP 5 — RTK (RUST TOKEN KILLER)
# ═══════════════════════════════════════════════════════════════════

section "Step 5 of 13 — RTK (Rust Token Killer)"

echo "  Every time Claude runs a shell command (git status, ls, npm install…),"
echo "  the full raw output is sent back as tokens. On a busy session this adds"
echo "  up fast and drives API costs up."
echo ""
echo "  RTK sits between Claude and your shell. It intercepts command output and"
echo "  strips everything that isn't useful to Claude — formatting, noise, blank"
echo "  lines — cutting token usage by 60–90% on typical dev operations."
echo ""
echo "  RTK is activated automatically via a hook in settings.json. Once installed,"
echo "  it works silently in the background — no change to how you use Claude."
echo ""
note "Source: https://github.com/rtk-ai/rtk"
note "Binary will be placed at: ~/.local/bin/rtk"
echo ""

install_rtk() {
    local INSTALL_DIR="$HOME/.local/bin"
    mkdir -p "$INSTALL_DIR"
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)   ARCH="x86_64" ;;
        aarch64|arm64) ARCH="aarch64" ;;
        *) warn "Unsupported architecture: $ARCH — cannot auto-install RTK."; return 1 ;;
    esac
    action "Downloading rtk-${OS}-${ARCH} from GitHub releases..."
    if curl -fsSL "https://github.com/rtk-ai/rtk/releases/latest/download/rtk-${OS}-${ARCH}" \
            -o "$INSTALL_DIR/rtk"; then
        chmod +x "$INSTALL_DIR/rtk"
        if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
            echo "" >> "$PROFILE_FILE"
            echo 'export PATH="$PATH:$HOME/.local/bin"' >> "$PROFILE_FILE"
            export PATH="$PATH:$INSTALL_DIR"
            ok "Added ~/.local/bin to PATH in $PROFILE_FILE"
        fi
        ok "RTK installed — $(rtk --version 2>/dev/null || echo 'version unknown')"
    else
        warn "Download failed. Install manually from: https://github.com/rtk-ai/rtk"
        return 1
    fi
}

if command -v rtk >/dev/null 2>&1; then
    ok "RTK already installed — $(rtk --version 2>/dev/null)"
else
    prompt "Install RTK now? (Y/n)"
    note "Recommended — significant cost and speed improvement over time."
    read -rp "  → " INSTALL_RTK_ANS
    if [[ ! "$INSTALL_RTK_ANS" =~ ^[Nn]$ ]]; then
        install_rtk || warn "RTK install failed. Try again manually later."
    else
        warn "Skipping RTK. You can install it later from: https://github.com/rtk-ai/rtk"
    fi
fi


# ═══════════════════════════════════════════════════════════════════
#  STEP 6 — HEADROOM
# ═══════════════════════════════════════════════════════════════════

section "Step 6 of 13 — Headroom (AI Provider Proxy)"

echo "  Headroom is a lightweight local proxy that sits between Claude Code and"
echo "  the AI provider. It runs on your machine at port 8787 and intercepts"
echo "  every API call Claude Code makes."
echo ""
echo "  This gives you two superpowers:"
echo ""
echo "    1. Provider switching — with one alias you can point Claude Code at"
echo "       DeepSeek, OpenAI, or any OpenAI-compatible API instead of Anthropic."
echo "       Useful when Anthropic is down, or when you want cheaper models for"
echo "       routine tasks."
echo ""
echo "    2. Request analytics — Headroom tracks every call, so you can see"
echo "       exactly how many tokens each session used and what it cost."
echo ""
echo "  After installation, the aliases 'claude-default' and 'claude-deepseek'"
echo "  will be available in your shell to launch Claude Code through Headroom."
echo ""
note "Source: https://github.com/headroomlabs-ai/headroom"
note "Binary will be placed at: ~/.local/bin/headroom"
echo ""

install_headroom() {
    local INSTALL_DIR="$HOME/.local/bin"
    mkdir -p "$INSTALL_DIR"
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)   ARCH="x86_64" ;;
        aarch64|arm64) ARCH="aarch64" ;;
        *) warn "Unsupported architecture: $ARCH — cannot auto-install Headroom."; return 1 ;;
    esac
    action "Downloading headroom-${OS}-${ARCH} from GitHub releases..."
    if curl -fsSL "https://github.com/headroomlabs-ai/headroom/releases/latest/download/headroom-${OS}-${ARCH}" \
            -o "$INSTALL_DIR/headroom"; then
        chmod +x "$INSTALL_DIR/headroom"
        ok "Headroom installed — $(headroom version 2>/dev/null || headroom --version 2>/dev/null || echo 'version unknown')"
    else
        warn "Download failed. Install manually from: https://github.com/headroomlabs-ai/headroom"
        return 1
    fi
}

if command -v headroom >/dev/null 2>&1; then
    ok "Headroom already installed — $(headroom version 2>/dev/null || headroom --version 2>/dev/null)"
else
    prompt "Install Headroom now? (Y/n)"
    note "Required if you want to use DeepSeek or switch AI providers."
    read -rp "  → " INSTALL_HEADROOM_ANS
    if [[ ! "$INSTALL_HEADROOM_ANS" =~ ^[Nn]$ ]]; then
        install_headroom || warn "Headroom install failed. Try again manually later."
    else
        warn "Skipping Headroom. The claude-deepseek alias will not work without it."
    fi
fi


# ═══════════════════════════════════════════════════════════════════
#  STEP 7 — DEEPSEEK API KEY
# ═══════════════════════════════════════════════════════════════════

section "Step 7 of 13 — DeepSeek API Key"

echo "  DeepSeek is a Chinese AI lab that offers models competitive with Claude"
echo "  at a fraction of the cost. Via Headroom, Claude Code can be pointed at"
echo "  DeepSeek's API for tasks where you don't need Anthropic-level quality"
echo "  (e.g. boilerplate generation, simple refactors, documentation)."
echo ""
echo "  Once configured, you switch providers with a single command:"
echo ""
echo "    claude-default     → launches Claude Code using Anthropic's API"
echo "    claude-deepseek    → launches Claude Code using DeepSeek's API"
echo ""
echo "  You can get a DeepSeek API key at: https://platform.deepseek.com"
echo "  Keys start with 'sk-...'"
echo ""
note "Your key will be stored in ~/.claude/deepseek_env with owner-only (600)"
note "permissions — same secure storage used for the Anthropic key."
echo ""

DEEPSEEK_ENV="$CLAUDE_DIR/deepseek_env"

if [ -f "$DEEPSEEK_ENV" ] && [ -s "$DEEPSEEK_ENV" ]; then
    ok "DeepSeek credentials file already exists at $DEEPSEEK_ENV"
else
    prompt "Do you have a DeepSeek API key to configure now? (y/N)"
    note "This is optional — you can add it later by creating ~/.claude/deepseek_env"
    read -rp "  → " USE_DEEPSEEK
    if [[ "$USE_DEEPSEEK" =~ ^[Yy]$ ]]; then
        prompt "Paste your DeepSeek API key (input is hidden):"
        read -rsp "  → " DEEPSEEK_KEY_INPUT
        echo ""
        if [ -n "$DEEPSEEK_KEY_INPUT" ]; then
            mkdir -p "$CLAUDE_DIR" && chmod 700 "$CLAUDE_DIR"
            ( umask 077 && printf 'export DEEPSEEK_API_KEY=%q\n' "$DEEPSEEK_KEY_INPUT" > "$DEEPSEEK_ENV" )
            chmod 600 "$DEEPSEEK_ENV"
            ok "Key saved to $DEEPSEEK_ENV (permissions: 600, visible only to you)"
            if ! grep -q "deepseek_env" "$PROFILE_FILE" 2>/dev/null; then
                echo "" >> "$PROFILE_FILE"
                echo '[ -f "$HOME/.claude/deepseek_env" ] && source "$HOME/.claude/deepseek_env"' >> "$PROFILE_FILE"
                ok "Added loader line to $PROFILE_FILE — key available in every new shell"
            fi
        else
            warn "Nothing entered — skipping."
        fi
    else
        warn "Skipping. To add it later, create ~/.claude/deepseek_env with:"
        note "  export DEEPSEEK_API_KEY=your-key-here"
    fi
fi


# ═══════════════════════════════════════════════════════════════════
#  STEP 8 — RUFLO MCP SERVER
# ═══════════════════════════════════════════════════════════════════

section "Step 8 of 13 — Ruflo MCP Server"

echo "  MCP (Model Context Protocol) is a standard that lets Claude Code connect"
echo "  to external tools and services. Ruflo is the MCP server for claude-flow,"
echo "  which adds three capabilities to Claude:"
echo ""
echo "    • Multi-agent orchestration — spawn specialized sub-agents that work"
echo "      in parallel on different parts of a task, then combine their output."
echo ""
echo "    • Persistent memory — Claude remembers patterns, decisions, and context"
echo "      across sessions using a hybrid vector+graph memory store."
echo ""
echo "    • Workflow hooks — automated actions before/after tool use (e.g. the"
echo "      RTK token-saving hook and the GSD context monitor are both hooks)."
echo ""
echo "  Ruflo is configured in ~/.mcp.json and starts on demand via npx."
echo "  No separate install required — it downloads automatically on first use."
echo ""
note "Config will be written to: ~/.mcp.json"
note "Mode: v3, topology: hierarchical-mesh, max agents: 15"
echo ""

if [ -f "$HOME/.mcp.json" ]; then
    if grep -q '"ruflo"' "$HOME/.mcp.json" 2>/dev/null; then
        ok "Ruflo already present in ~/.mcp.json"
    else
        warn "~/.mcp.json exists but doesn't include ruflo."
        action "You'll need to manually merge $SCRIPT_DIR/config/.mcp.json into ~/.mcp.json"
    fi
else
    action "Creating ~/.mcp.json with ruflo MCP server configuration..."
    cp "$SCRIPT_DIR/config/.mcp.json" "$HOME/.mcp.json"
    ok "~/.mcp.json created"
fi


# ═══════════════════════════════════════════════════════════════════
#  STEP 9 — CLAUDE CODE SETTINGS
# ═══════════════════════════════════════════════════════════════════

section "Step 9 of 13 — Claude Code Settings"

echo "  Two configuration files control how Claude Code behaves:"
echo ""
echo "  settings.json — the main config. This sets:"
echo "    • Model: claude-sonnet-4-6 (main), claude-haiku-4-5 (fast tasks)"
echo "    • Permissions: pre-approved bash commands (git, npm, python, curl…)"
echo "      so Claude doesn't pause to ask permission on common operations."
echo "    • Plugins: 15+ curated plugins enabled (code review, frontend design,"
echo "      PR toolkit, Playwright browser automation, Atlassian, and more)."
echo "    • Hooks: RTK token-saver, GSD context monitor, GSD status line."
echo "    • Extra plugin marketplaces: claude-mem, cc-fleet, karpathy-skills."
echo ""
echo "  settings.local.json — machine-specific overrides. This sets:"
echo "    • ANTHROPIC_BASE_URL to http://127.0.0.1:8787 (the Headroom proxy)."
echo "      This means all Claude Code traffic routes through Headroom, which"
echo "      is what makes provider switching (claude-deepseek alias) work."
echo ""
note "Files written to: ~/.claude/settings.json and ~/.claude/settings.local.json"
echo ""

mkdir -p "$CLAUDE_DIR"

if [ -f "$CLAUDE_DIR/settings.json" ]; then
    warn "settings.json already exists at ~/.claude/settings.json"
    echo "  Overwriting it will replace your current Claude Code configuration."
    echo "  A backup will be saved to settings.json.bak first, so you can restore it."
    echo ""
    prompt "Overwrite your existing settings.json with the Phalkon defaults? (Y/n)"
    read -rp "  → " OVERWRITE_SETTINGS
    if [[ ! "$OVERWRITE_SETTINGS" =~ ^[Nn]$ ]]; then
        action "Backing up existing settings.json → settings.json.bak"
        cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.bak"
        ok "Backup saved to ~/.claude/settings.json.bak"
        action "Writing settings.json..."
        cp "$SCRIPT_DIR/config/settings.json" "$CLAUDE_DIR/settings.json"
        ok "settings.json installed"
    else
        warn "Skipping settings.json. Your existing config is unchanged."
        note "To apply later: cp $SCRIPT_DIR/config/settings.json ~/.claude/settings.json"
    fi
else
    action "Writing settings.json..."
    cp "$SCRIPT_DIR/config/settings.json" "$CLAUDE_DIR/settings.json"
    ok "settings.json installed"
fi

if [ -f "$CLAUDE_DIR/settings.local.json" ]; then
    warn "settings.local.json already exists at ~/.claude/settings.local.json"
    echo "  This file contains machine-specific overrides (e.g. a custom API base URL)."
    echo "  The Phalkon version sets ANTHROPIC_BASE_URL to the Headroom proxy at 127.0.0.1:8787."
    echo ""
    prompt "Overwrite your existing settings.local.json? (Y/n)"
    read -rp "  → " OVERWRITE_LOCAL
    if [[ ! "$OVERWRITE_LOCAL" =~ ^[Nn]$ ]]; then
        cp "$CLAUDE_DIR/settings.local.json" "$CLAUDE_DIR/settings.local.json.bak"
        ok "Backup saved to ~/.claude/settings.local.json.bak"
        action "Writing settings.local.json..."
        cp "$SCRIPT_DIR/config/settings.local.json" "$CLAUDE_DIR/settings.local.json"
        ok "settings.local.json installed"
    else
        warn "Skipping settings.local.json. Your existing overrides are unchanged."
    fi
else
    action "Writing settings.local.json (Headroom proxy config)..."
    cp "$SCRIPT_DIR/config/settings.local.json" "$CLAUDE_DIR/settings.local.json"
    ok "settings.local.json installed"
fi


# ═══════════════════════════════════════════════════════════════════
#  STEP 10 — CLAUDE.md (GLOBAL RULES)
# ═══════════════════════════════════════════════════════════════════

section "Step 10 of 13 — CLAUDE.md (Global Rules)"

echo "  CLAUDE.md is a special file that Claude Code reads automatically at the"
echo "  start of every session. It contains persistent instructions that shape"
echo "  how Claude behaves — without you having to repeat them every time."
echo ""
echo "  The global CLAUDE.md (at ~/.claude/CLAUDE.md) applies to ALL projects."
echo "  Individual projects can have their own CLAUDE.md at the repo root."
echo ""
echo "  This setup's global CLAUDE.md includes:"
echo "    • Project workflow reference (how to start and manage projects)"
echo "    • Frontend design system defaults (Tailwind, shadcn/ui, Lucide)"
echo "    • Document template rules (letter paper, PDF generation)"
echo "    • RTK usage instructions"
echo "    • Ruflo/claude-flow integration guidance"
echo ""
note "If CLAUDE.md already exists, it will NOT be overwritten."
note "You can diff the new version with: diff ~/.claude/CLAUDE.md $SCRIPT_DIR/config/CLAUDE.md"
echo ""

if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    warn "~/.claude/CLAUDE.md already exists — skipping to avoid overwriting your customizations."
    note "Review $SCRIPT_DIR/config/CLAUDE.md and manually merge any sections you want."
else
    action "Writing ~/.claude/CLAUDE.md..."
    cp "$SCRIPT_DIR/config/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
    ok "CLAUDE.md installed"
fi


# ═══════════════════════════════════════════════════════════════════
#  STEP 11 — REFERENCE DOCS
# ═══════════════════════════════════════════════════════════════════

section "Step 11 of 13 — Reference Docs"

echo "  Two reference documents are installed into ~/.claude/ so Claude can"
echo "  read them during sessions when needed:"
echo ""
echo "  RTK.md — quick reference for RTK commands (rtk gain, rtk discover, etc.)"
echo "    Loaded via @RTK.md in CLAUDE.md so it's always available."
echo ""
echo "  project-workflow.md — the full Phalkon project lifecycle guide:"
echo "    repo creation from templates, docs structure, session protocols,"
echo "    template sync workflow, and all GSD slash commands."
echo ""
note "Files written to: ~/.claude/RTK.md and ~/.claude/project-workflow.md"
echo ""

action "Writing RTK.md..."
cp "$SCRIPT_DIR/config/RTK.md" "$CLAUDE_DIR/RTK.md"
ok "RTK.md installed"

action "Writing project-workflow.md..."
cp "$SCRIPT_DIR/docs/project-workflow.md" "$CLAUDE_DIR/project-workflow.md"
ok "project-workflow.md installed"


# ═══════════════════════════════════════════════════════════════════
#  STEP 12 — SHELL ALIASES
# ═══════════════════════════════════════════════════════════════════

section "Step 12 of 13 — Shell Aliases"

echo "  A set of productivity aliases for your $SHELL_TYPE shell, covering:"
echo ""
echo "    • git shortcuts     (gst, gp, gpl, gc, gcb, gl, gs…)"
echo "    • Python / venv     (a = activate, d = deactivate, create-venv…)"
echo "    • Docker            (dps, dcup, dcdown, dlog…)"
echo "    • System tools      (ll, myip, listen, genpass…)"
echo "    • Claude + Headroom (claude-default, claude-deepseek and -continue variants)"
echo ""
echo "  The Claude/Headroom aliases let you launch Claude Code through the"
echo "  Headroom proxy with a single word:"
echo ""
echo "    claude-default          → Claude Code via Anthropic API"
echo "    claude-default-continue → same, resumes your last session"
echo "    claude-deepseek         → Claude Code via DeepSeek API (cheaper)"
echo "    claude-deepseek-continue→ same, resumes your last session"
echo ""
note "If $ALIASES_FILE already exists it will NOT be overwritten."
note "Aliases will be written to: $ALIASES_FILE"
echo ""

if [ -f "$ALIASES_FILE" ]; then
    warn "$ALIASES_FILE already exists — skipping to avoid overwriting your aliases."
    note "Review $ALIASES_SRC and add the lines you want manually."
else
    action "Writing $ALIASES_FILE..."
    cp "$ALIASES_SRC" "$ALIASES_FILE"
    ok "$ALIASES_FILE installed"
    if [[ "$SHELL_TYPE" == "zsh" ]]; then
        if ! grep -q "zsh_aliases" "$PROFILE_FILE" 2>/dev/null; then
            echo "" >> "$PROFILE_FILE"
            echo "source ~/.zsh_aliases" >> "$PROFILE_FILE"
            ok "Added 'source ~/.zsh_aliases' to $PROFILE_FILE"
        fi
    else
        if ! grep -q "bash_aliases" "$PROFILE_FILE" 2>/dev/null; then
            echo "" >> "$PROFILE_FILE"
            echo '[ -f "$HOME/.bash_aliases" ] && source "$HOME/.bash_aliases"' >> "$PROFILE_FILE"
            ok "Added bash_aliases loader to $PROFILE_FILE"
        else
            ok "bash_aliases already sourced in $PROFILE_FILE"
        fi
    fi
fi


# ═══════════════════════════════════════════════════════════════════
#  STEP 13 — DONE
# ═══════════════════════════════════════════════════════════════════

section "Step 13 of 13 — Complete"

echo -e "${GREEN}${BOLD}  All done! Here's what to do next:${NC}"
echo ""
echo "  ① Reload your shell to activate the new aliases and PATH changes:"
echo ""
echo "       source $PROFILE_FILE"
echo ""
echo "  ② Launch Claude Code for the first time:"
echo ""
echo "       claude                   (direct, uses Anthropic API)"
echo "       claude-default           (through Headroom proxy)"
echo "       claude-deepseek          (through Headroom → DeepSeek API)"
echo ""
echo "     On first run, if you didn't set an API key in Step 3, Claude will"
echo "     open your browser to log in with your Claude.ai account."
echo ""
echo "  ③ Inside Claude Code, install the plugin suite:"
echo ""
echo "       /plugins"
echo ""
echo "     Enable these official plugins:"
echo "       frontend-design, code-review, feature-dev, playwright,"
echo "       claude-md-management, security-guidance, commit-commands,"
echo "       claude-code-setup, pr-review-toolkit, pyright-lsp,"
echo "       atlassian, remember, circleback"
echo ""
echo "     Third-party plugins (marketplaces already registered in settings.json):"
echo "       claude-mem (thedotmack), cc-fleet (ethanhq),"
echo "       andrej-karpathy-skills (karpathy-skills)"
echo ""
echo "  ④ Check your RTK token savings after your first session:"
echo ""
echo "       rtk gain"
echo ""
echo "  ⑤ Start a new project with the Phalkon workflow:"
echo ""
echo "       /gsd:new-project"
echo ""
echo "  Full reference guide: $SCRIPT_DIR/README.md"
echo ""
echo -e "${DIM}  Installed by: https://github.com/Phalkon-Dev/claude-setup${NC}"
echo ""
