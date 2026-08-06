# Claude Code Power User Setup

A complete, reproducible Claude Code environment with multi-agent orchestration, token optimization, structured project workflows, and a curated plugin stack.

---

## What You Get

| Layer | Tool | What it does |
|-------|------|--------------|
| **Core** | Claude Code | AI-powered CLI for software development |
| **Token savings** | RTK (Rust Token Killer) | 60–90% fewer tokens on every bash command |
| **Orchestration** | Ruflo / claude-flow | Multi-agent swarms, persistent memory, hooks |
| **Workflow** | GSD (`/gsd:*`) | Structured project planning and execution |
| **Plugins** | 15+ curated plugins | Frontend, testing, code review, memory, Atlassian, Playwright |
| **Hooks** | Pre/PostToolUse | Automatic context management and status line |

---

## Prerequisites

| Tool | Minimum version | How to install |
|------|----------------|----------------|
| Node.js | 18+ | [nvm](https://github.com/nvm-sh/nvm) |
| zsh | any | `sudo apt install zsh` |
| Claude Code | latest | [claude.ai/download](https://claude.ai/download) |
| RTK | 0.42+ | See [RTK setup](#rtk-setup) below |

---

## Quick Start

```bash
git clone <this-repo> claude-setup
cd claude-setup
./install.sh
```

The script backs up existing config files before overwriting them. After it finishes, follow the printed "Next steps."

---

## Manual Setup (step by step)

If you prefer to set things up manually, or if you already have a Claude Code configuration and only want specific parts:

### 1. Install Claude Code

Download the native installer from [claude.ai/download](https://claude.ai/download).

### 2. Copy configuration files

```bash
CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR"

# Core config
cp config/settings.json "$CLAUDE_DIR/settings.json"
cp config/CLAUDE.md     "$CLAUDE_DIR/CLAUDE.md"
cp config/RTK.md        "$CLAUDE_DIR/RTK.md"
cp docs/project-workflow.md "$CLAUDE_DIR/project-workflow.md"

# MCP servers
cp config/.mcp.json "$HOME/.mcp.json"

# Shell aliases
cp zsh/aliases.zsh ~/.zsh_aliases
echo "source ~/.zsh_aliases" >> ~/.zshrc
```

### 3. RTK setup

RTK rewrites every bash command through a token-optimizing proxy before Claude sees the output.

```bash
# Verify installation
rtk --version        # should print: rtk X.Y.Z
rtk gain             # show token savings dashboard
```

The `PreToolUse` hook in `settings.json` activates RTK automatically:
```json
"PreToolUse": [{ "matcher": "Bash", "hooks": [{ "command": "rtk hook claude" }] }]
```

If RTK is not yet installed, the hook will fail silently. Claude Code will still work — you just won't get the token savings.

### 4. Ruflo MCP server

Ruflo provides multi-agent orchestration, persistent vector memory, and workflow hooks.

**~/.mcp.json** (already copied above) registers the ruflo server. On first use, Claude Code will download it automatically via `npx -y ruflo@latest mcp start`.

To verify:
```bash
npx ruflo@latest --version
```

### 5. GSD (Get Shit Done) workflow

GSD is included automatically through the `claude-code-setup` and `gsd` plugins. It adds slash commands for structured project management:

```
/gsd:new-project        Create roadmap for a new project
/gsd:plan-phase         Plan a single milestone
/gsd:execute-phase      Execute a planned milestone
/gsd:progress           Show milestone status
/gsd:check-todos        Review open tasks
/gsd:debug              Systematic debugging session
```

The GSD hooks (`gsd-check-update.js`, `gsd-context-monitor.js`, `gsd-statusline.js`) are installed automatically by the GSD plugin — they live in `~/.claude/hooks/`.

### 6. Plugins

After opening Claude Code, go to `/plugins` and enable:

**Official marketplace** (`claude-plugins-official`):

| Plugin | Purpose |
|--------|---------|
| `frontend-design` | UI component and design guidance |
| `code-review` | Code quality review agent |
| `feature-dev` | End-to-end feature implementation |
| `playwright` | Browser automation for UI testing |
| `claude-md-management` | Manage and update CLAUDE.md files |
| `security-guidance` | Security best practices and review |
| `commit-commands` | Smart git commit messages |
| `claude-code-setup` | Project scaffolding + GSD workflow |
| `pr-review-toolkit` | PR review: types, tests, silent failures, comments |
| `pyright-lsp` | Python type checking integration |
| `atlassian` | Jira/Confluence integration |
| `remember` | Persistent user memory |
| `circleback` | Meeting notes → Jira/Confluence |

**Third-party marketplaces** (already registered in `settings.json`):

| Plugin | Source | Purpose |
|--------|--------|---------|
| `claude-mem` | `thedotmack/claude-mem` | Semantic search over conversation history |
| `andrej-karpathy-skills` | `forrestchang/andrej-karpathy-skills` | Karpathy coding guidelines |
| `cc-fleet` | `ethanhq/cc-fleet` | Coordinate multiple Claude instances |

Third-party plugins appear in `/plugins` once the `extraKnownMarketplaces` entries are in `settings.json`.

---

## What Each File Does

```
config/
  settings.json         Main Claude Code config:
                          - Model: claude-sonnet-4-6 (main), claude-haiku-4-5 (fast)
                          - Broad Bash permissions (no prompts for git, npm, python, etc.)
                          - Pre-approved Playwright MCP tools
                          - RTK pre-tool hook
                          - GSD session/context hooks
                          - Status line via GSD
                          - All plugins enabled
                          - Extra marketplaces registered

  .mcp.json             Ruflo MCP server config:
                          - Mode: v3, topology: hierarchical-mesh
                          - Max agents: 15, memory: hybrid

  CLAUDE.md             Global rules loaded at every Claude session:
                          - Project workflow reference
                          - Design system defaults
                          - RTK usage
                          - Ruflo integration note

  RTK.md                RTK quick reference (loaded via @RTK.md in CLAUDE.md)

docs/
  project-workflow.md   Full project lifecycle guide:
                          - Repo creation from templates
                          - Docs structure
                          - Session start/end protocols
                          - Template sync workflow
                          - GSD command cheatsheet

zsh/
  aliases.zsh           Shell aliases for git, python, docker, system tools
```

---

## Customization

### Replace placeholder paths

The org is set to `Phalkon-Dev`. Update this if deploying outside the Phalkon organization.

### Add your design system

In `config/CLAUDE.md`, replace the design system section with a reference to your org's actual token file and design system docs.

### Add your document template

If your org has standard HTML/PDF document templates, update the "Documents HTML/PDF" section in `config/CLAUDE.md` with the actual template path.

### Adjust permissions

The `permissions.allow` list in `settings.json` is intentionally broad to minimize interruptions. Remove any entries you don't need or add new ones using the pattern `Bash(command *)`.

### Adjust models

```json
"env": {
  "ANTHROPIC_MODEL": "claude-opus-5",          // upgrade main model
  "ANTHROPIC_SMALL_FAST_MODEL": "claude-haiku-4-5-20251001"
}
```

See current model IDs: Opus 5, Sonnet 5, Haiku 4.5, Fable 5.

---

## Hooks Explained

Claude Code runs shell commands at specific lifecycle points. This setup uses three hooks:

| Hook | Trigger | Command | Effect |
|------|---------|---------|--------|
| **PreToolUse** | Before every Bash call | `rtk hook claude` | Rewrites command output to save tokens |
| **PostToolUse** | After every tool call | `gsd-context-monitor.js` | Tracks context window usage, warns before overflow |
| **SessionStart** | When Claude opens | `gsd-check-update.js` | Checks for GSD updates |

The status line (bottom of screen) is powered by `gsd-statusline.js` — it shows current context usage, active tasks, and session info.

---

## Multi-Agent Quick Reference

From `config/CLAUDE.md` — how to spawn coordinated agent pipelines:

```javascript
// All agents in ONE message, each knows WHO to message next
Agent({ prompt: "Research the codebase. SendMessage findings to 'architect'.",
  subagent_type: "researcher", name: "researcher", run_in_background: true })
Agent({ prompt: "Wait for 'researcher'. Design solution. SendMessage to 'coder'.",
  subagent_type: "system-architect", name: "architect", run_in_background: true })
Agent({ prompt: "Wait for 'architect'. Implement it. SendMessage to 'tester'.",
  subagent_type: "coder", name: "coder", run_in_background: true })

// Kick off the pipeline
SendMessage({ to: "researcher", message: "[task context]" })
```

**Rules**: Always name agents. Spawn ALL in one message. After spawning: stop and wait for results — never poll.

---

## Troubleshooting

**`rtk gain` fails** — you may have the wrong `rtk` binary. Run `which rtk` and check the path. See `config/RTK.md` for the name-collision note.

**GSD hooks not running** — the hooks (`~/.claude/hooks/*.js`) are installed by the `claude-code-setup` plugin. If missing, reinstall the plugin via `/plugins`.

**Ruflo MCP not connecting** — run `npx ruflo@latest doctor --fix` to diagnose.

**Plugin not showing up** — check that `extraKnownMarketplaces` is in `settings.json`, then reload Claude Code and go to `/plugins`.
