# Claude Code Power User Setup

> **Phalkon Dev** — [github.com/Phalkon-Dev/claude-setup](https://github.com/Phalkon-Dev/claude-setup)

A complete, reproducible Claude Code environment with token optimization, multi-provider switching, multi-agent orchestration, structured project workflows, and a curated plugin stack.

---

## What You Get

| Layer | Tool | What it does |
|-------|------|--------------|
| **Core** | Claude Code | AI-powered CLI for software development |
| **Token savings** | RTK (Rust Token Killer) | 60–90% fewer tokens on every bash command |
| **Provider proxy** | Headroom | Local proxy — switch between Anthropic and DeepSeek with one alias |
| **Cheap alternative** | DeepSeek API | Run Claude Code against DeepSeek models for routine tasks |
| **Orchestration** | Ruflo / claude-flow | Multi-agent swarms, persistent memory, workflow hooks |
| **Workflow** | GSD (`/gsd:*`) | Structured project planning and execution |
| **Plugins** | 15+ curated plugins | Frontend, testing, code review, memory, Atlassian, Playwright |
| **Hooks** | Pre/PostToolUse | Automatic context management and status line |

---

## Prerequisites

| Tool | Minimum version | How to install |
|------|----------------|----------------|
| Node.js | 18+ | [nvm](https://github.com/nvm-sh/nvm) |
| zsh or bash | any | pre-installed on most systems |
| Claude Code | latest | [claude.ai/download](https://claude.ai/download) |

---

## Quick Start

```bash
git clone git@github.com:Phalkon-Dev/claude-setup.git
cd claude-setup
bash install.sh
```

The script walks you through 13 steps, explains every tool, backs up existing files before touching them, and asks before overwriting anything.

---

## Manual Setup

If you already have a partial setup and only want specific pieces:

```bash
CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR"

# Core config
cp config/settings.json     "$CLAUDE_DIR/settings.json"
cp config/settings.local.json "$CLAUDE_DIR/settings.local.json"
cp config/CLAUDE.md         "$CLAUDE_DIR/CLAUDE.md"
cp config/RTK.md            "$CLAUDE_DIR/RTK.md"
cp docs/project-workflow.md "$CLAUDE_DIR/project-workflow.md"

# MCP servers
cp config/.mcp.json "$HOME/.mcp.json"

# Shell aliases (choose your shell)
cp zsh/aliases.zsh  ~/.zsh_aliases   # zsh
cp bash/aliases.bash ~/.bash_aliases  # bash
```

---

## What Each File Does

```
config/
  settings.json         Main Claude Code config:
                          - Model: claude-sonnet-4-6 (main), claude-haiku-4-5 (fast)
                          - Pre-approved Bash permissions (git, npm, python, curl, etc.)
                            so Claude doesn't pause to ask on common operations
                          - 15+ plugins enabled (see Plugin List below)
                          - RTK pre-tool hook (token savings on every bash call)
                          - GSD session/context hooks + status line
                          - Extra plugin marketplaces registered

  settings.local.json   Machine-specific overrides:
                          - ANTHROPIC_BASE_URL → http://127.0.0.1:8787 (Headroom proxy)
                          - Routes all Claude Code traffic through Headroom, enabling
                            provider switching via shell aliases

  .mcp.json             Ruflo MCP server:
                          - Mode: v3, topology: hierarchical-mesh, max agents: 15
                          - Downloads automatically on first use via npx

  CLAUDE.md             Global rules loaded at every Claude session:
                          - Project workflow reference
                          - Frontend design system defaults (Tailwind, shadcn/ui, Lucide)
                          - Document template rules (letter paper, PDF generation)
                          - RTK and Ruflo usage guidance

  RTK.md                RTK quick reference (loaded via @RTK.md in CLAUDE.md)

docs/
  project-workflow.md   Full Phalkon project lifecycle guide:
                          - Repo creation from templates
                          - Docs structure per project
                          - Session start/end protocols
                          - Template sync workflow
                          - GSD command cheatsheet

zsh/
  aliases.zsh           Shell aliases for zsh → installed to ~/.zsh_aliases

bash/
  aliases.bash          Shell aliases for bash → installed to ~/.bash_aliases
```

---

## Provider Switching (Headroom + DeepSeek)

Headroom runs as a local proxy on port 8787. `settings.local.json` points Claude Code at it. This lets you switch AI providers with a single alias:

```bash
claude-default           # Claude Code → Headroom → Anthropic API
claude-default-continue  # same, resumes last session

claude-deepseek          # Claude Code → Headroom → DeepSeek API  (cheaper)
claude-deepseek-continue # same, resumes last session
```

**When to use DeepSeek**: boilerplate generation, simple refactors, documentation, anything where you don't need Anthropic-level quality. DeepSeek is significantly cheaper per token.

**Getting a DeepSeek key**: [platform.deepseek.com](https://platform.deepseek.com)

---

## Plugin List

### Official (`claude-plugins-official`)

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

### Third-party (marketplaces registered in `settings.json`)

| Plugin | Source | Purpose |
|--------|--------|---------|
| `claude-mem` | `thedotmack/claude-mem` | Semantic search over conversation history |
| `andrej-karpathy-skills` | `forrestchang/andrej-karpathy-skills` | Karpathy coding guidelines |
| `cc-fleet` | `ethanhq/cc-fleet` | Coordinate multiple Claude instances |

Install all of these inside Claude Code with `/plugins`.

---

## Hooks Explained

| Hook | Trigger | Command | Effect |
|------|---------|---------|--------|
| **PreToolUse** | Before every Bash call | `rtk hook claude` | Strips noise from command output — 60–90% token savings |
| **PostToolUse** | After every tool call | `gsd-context-monitor.js` | Tracks context window usage, warns before overflow |
| **SessionStart** | When Claude opens | `gsd-check-update.js` | Checks for GSD updates |
| **StatusLine** | Always visible | `gsd-statusline.js` | Shows context usage, active tasks, session info |

---

## GSD Workflow Commands

```
/gsd:new-project        Create roadmap for a new project
/gsd:plan-phase         Plan a single milestone in detail
/gsd:execute-phase      Execute a planned milestone
/gsd:progress           Show current milestone status
/gsd:check-todos        Review open tasks
/gsd:debug              Systematic debugging session
/gsd:add-tests          Generate tests for a feature
/gsd:health             Project health check
```

---

## Multi-Agent Quick Reference

```javascript
// Spawn a pipeline — all agents in ONE message
Agent({ name: "researcher", subagent_type: "researcher",  run_in_background: true,
  prompt: "Research codebase. SendMessage findings to 'architect'." })
Agent({ name: "architect",  subagent_type: "system-architect", run_in_background: true,
  prompt: "Wait for 'researcher'. Design solution. SendMessage to 'coder'." })
Agent({ name: "coder",      subagent_type: "coder",        run_in_background: true,
  prompt: "Wait for 'architect'. Implement it. SendMessage to 'tester'." })

SendMessage({ to: "researcher", message: "[task context]" })
```

Rules: always name agents, spawn all in one message, wait for results — never poll.

---

## Troubleshooting

**`rtk gain` fails** — you may have the wrong `rtk` binary (`reachingforthejack/rtk` is a different tool with the same name). Check `which rtk` and verify it's the token-killer version.

**`claude-deepseek` not working** — Headroom must be running (`headroom version` to verify) and `DEEPSEEK_API_KEY` must be set (`source ~/.claude/deepseek_env`).

**GSD hooks not running** — hooks live in `~/.claude/hooks/`. They're installed by the `claude-code-setup` plugin. Reinstall via `/plugins` if missing.

**Ruflo MCP not connecting** — run `npx ruflo@latest doctor --fix`.

**Plugin not appearing** — verify `extraKnownMarketplaces` is in `settings.json`, then restart Claude Code and go to `/plugins`.
