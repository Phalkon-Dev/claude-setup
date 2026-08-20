# Claude Code Power User Guide

> Everything installed by this setup, explained — what each tool does, when to use it, and why.

**Platform note** — This guide uses bash syntax throughout. On Windows 10/11, run `.\install.ps1` instead of `bash install.sh`, and source `powershell\aliases.ps1` from `$PROFILE` instead of the bash aliases file. Everything else — alias names, Claude commands, GSD workflows, plugins — is identical across platforms.

---

## 0. Installing Dependencies

The install scripts detect missing prerequisites and offer to install them automatically (with a [Y/n] prompt per tool). If you prefer to install manually first, the per-OS commands are listed below.

The scripts check for:

| Tool | Minimum | Required by |
|------|---------|------------|
| Node.js | 18+ | Claude Code (and GSD, which runs inside Claude Code) |
| npm / npx | ships with Node | Claude Code install, plugin resolution |
| Python 3 + pip | 3.9+ | Headroom (`pip install "headroom-ai[all]"`) |
| Git | any | cloning this repo, commit aliases |

### Ubuntu / Debian

```bash
# Node.js 20 LTS (choose one)
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs
# or via nvm (no sudo required):
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
source ~/.bashrc && nvm install --lts

# Python 3 + pip, git, curl
sudo apt-get install -y python3 python3-pip git curl
```

### Fedora / RHEL / CentOS

```bash
# Node.js 20 LTS (choose one)
curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
sudo dnf install -y nodejs
# or via nvm:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
source ~/.bashrc && nvm install --lts

# Python 3 + pip, git, curl
sudo dnf install -y python3 python3-pip git curl
```

### macOS

```bash
# Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Node.js, Python, Git
brew install node python
xcode-select --install   # installs git + command-line tools

# Or use nvm for Node.js:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
source ~/.zshrc && nvm install --lts
```

### Windows 10 / 11 (PowerShell)

```powershell
# All three via winget (pre-installed on modern Windows)
winget install OpenJS.NodeJS.LTS   # Node.js 20 LTS + npm/npx
winget install Python.Python.3     # Python 3 + pip
winget install Git.Git             # Git for Windows

# Restart PowerShell after — PATH doesn't update in the current session
```

Manual installers if winget is unavailable:
- Node.js LTS `.msi`: [nodejs.org/en/download](https://nodejs.org/en/download) — check "Add to PATH"
- Python `.exe`: [python.org/downloads](https://python.org/downloads) — check "Add Python to PATH"
- Git: [git-scm.com/download/win](https://git-scm.com/download/win)

### About GSD and Node.js

GSD (`/gsd:*` commands) is installed as part of the `claude-code-setup` plugin inside Claude Code. It does not require a separate Node.js install — it runs entirely within Claude Code, which already requires Node.js 18+. Once Node.js is installed for Claude Code, GSD will work without any additional setup.

---

## How It All Fits Together

When you run `claude-default` or `claude-deepseek`, this is what happens:

```
You
 └─▶ Shell alias (claude-default / claude-deepseek)
       └─▶ Headroom proxy (127.0.0.1:8787)
             └─▶ AI provider (Anthropic or DeepSeek)
                   └─▶ Claude Code session
                         ├─▶ RTK hook       (every bash command, automatic)
                         ├─▶ GSD hooks      (context monitor + status line)
                         ├─▶ Ruflo MCP      (memory, multi-agent, hooks)
                         └─▶ Plugins        (invoked via /commands)
```

None of this requires you to do anything differently from a normal Claude session — it all runs in the background. The only active choice you make is **which alias to launch with**.

---

## 1. Launching Claude Code — The Aliases

Claude Code is available as a web app at [claude.ai/code](https://claude.ai/code), a CLI (`npm install -g @anthropic-ai/claude-code`), and extensions for VS Code / VSCodium and JetBrains IDEs. This setup configures the CLI; the aliases below apply regardless of which interface you prefer.

These are your entry points. Open a terminal and type one of these instead of `claude`.

| Alias | Provider | When to use |
|-------|----------|-------------|
| `claude-default` | Anthropic | Your main daily driver. Full Claude quality. |
| `claude-default-continue` | Anthropic | Resume where your last session left off. |
| `claude-deepseek` | DeepSeek | Cheaper tasks that don't need full quality. |
| `claude-deepseek-continue` | DeepSeek | Resume last session on DeepSeek. |

### When to use DeepSeek (`claude-deepseek`)

Use DeepSeek when the task is mechanical and you don't need Claude's full reasoning:

- Generating boilerplate (CRUD endpoints, form components, migrations)
- Writing or updating documentation
- Simple refactors (rename variables, extract functions)
- Formatting / linting fixes
- Translating code between similar languages

Use Anthropic (`claude-default`) when the task requires judgment:

- Architecture decisions
- Debugging complex logic
- Security review
- Anything that needs careful reasoning or creative problem-solving

### What `...-continue` does

The `-continue` variants pass the `-c` flag to Claude Code, which resumes your previous conversation in that directory. Use it when you're picking up a task you left mid-session.

---

## 2. RTK — Rust Token Killer

RTK runs **automatically** on every bash command Claude executes. You don't invoke it — it's a background hook.

### What it does

Every time Claude runs a command like `git log` or `ls -la`, the raw terminal output gets sent back to Claude as tokens. RTK intercepts that output and strips everything that isn't useful: decorations, padding, blank lines, progress bars. This cuts token usage by **60–90%** per command, which means longer sessions before hitting limits, and lower API costs.

### Manual commands

Use these directly in your terminal (outside of Claude):

```bash
rtk gain                # Show total tokens saved across all sessions
rtk gain --history      # Show savings broken down by command and date
rtk discover            # Analyze your Claude history for missed savings opportunities
rtk proxy <command>     # Run a command through RTK manually (for debugging)
```

Run `rtk gain` after a heavy coding session — the savings are usually significant.

### One caveat

RTK filters output before Claude sees it. If Claude seems to be missing context from a command's output, you can run the command with `rtk proxy` disabled temporarily:

```bash
# inside a Claude session, if a command isn't giving Claude enough context:
# ask Claude to run: rtk proxy git log --oneline -20
```

---

## 3. Headroom — Context Compression Proxy

Headroom runs silently as a local proxy. `settings.local.json` points all Claude Code traffic through it at `127.0.0.1:8787`. You don't interact with Headroom directly — the aliases handle it.

### What it gives you

**Context compression** — Headroom intercepts every API request and compresses the context window by stripping redundant or low-value content before it is sent. This reduces token usage by 60-95% per session — longer sessions before hitting limits, lower API costs.

**Provider switching** — the `claude-default` and `claude-deepseek` aliases route through Headroom to different AI providers. No config editing needed.

### If Headroom isn't running

If you see API connection errors after running a `claude-*` alias, Headroom may have crashed. The aliases start it automatically via `headroom wrap`, but if something goes wrong:

```bash
headroom --version      # check it's installed
headroom wrap claude    # start manually (same as the alias does)
```

---

## 4. GSD — Get Shit Done Workflow

GSD adds structured project management slash commands to Claude Code. Type these inside a Claude session.

### Starting a new project

```
/gsd:new-project
```
Use this at the very beginning of a new repo. GSD will interview you about what you're building, then generate a phased roadmap in `docs/planning.md` and a task backlog in `docs/tasks.md`. Takes about 5 minutes but saves hours of drift later.

### Planning and executing work

```
/gsd:plan-phase
```
Use before tackling a significant feature or milestone. GSD breaks it into concrete tasks, identifies files to touch, and flags dependencies. Creates a plan you review before anything gets built.

```
/gsd:execute-phase
```
Runs the plan created by `/gsd:plan-phase`. Claude works through the tasks in order, checking each one off. Use this for planned milestones, not quick one-off fixes.

### Tracking and checking in

```
/gsd:progress           Show current milestone status and what's left
/gsd:check-todos        List all open tasks from docs/tasks.md
/gsd:health             Full project health check (tests, coverage, TODOs, docs)
```

### Debugging

```
/gsd:debug
```
Structured debugging session. GSD applies a scientific method: reproduces the bug, forms hypotheses, tests them in order, and documents what it found. More systematic than asking Claude to "fix this bug."

### Other useful commands

```
/gsd:add-tests          Generate tests for a feature you just built
/gsd:map-codebase       Index the codebase (run at the start of sessions on large repos)
```

### When NOT to use GSD commands

GSD is for structured, multi-step work. For quick one-liners, just talk to Claude normally:

- "Fix this typo" → just say it
- "Explain what this function does" → just ask
- "Add a console.log here" → just ask

GSD adds overhead that's only worth it for tasks with multiple steps or moving parts.

---

## 5. Plugins

Plugins are invoked inside Claude Code via slash commands. Most activate automatically when relevant — you don't need to explicitly call them unless you want to trigger a specific workflow.

### Code quality

**`/code-review`** — Full code review of recent changes. Run before opening a PR.
Use when: you've finished a feature and want Claude to check for bugs, security issues, and style problems.

**`/pr-review-toolkit`** — Suite of specialized reviewers:
- Reviews type design, test coverage, silent failures, and comment accuracy
- Use when: doing a thorough pre-merge review

**`/simplify`** — Simplifies code you just wrote — removes duplication, improves readability.
Use when: you feel like the code works but is messier than it should be.

### Building features

**`/feature-dev`** — End-to-end feature implementation with planning, coding, and testing.
Use when: building something non-trivial that spans multiple files.

**`/frontend-design`** — UI component guidance following the Phalkon design system.
Use when: building any React component — ensures correct token usage, shadcn patterns, and Lucide icons.

### Git and PRs

**`/commit`** — Generates a conventional commit message from your staged changes.
Use when: you're ready to commit and want a clean, consistent message.

**`/commit-push-pr`** — Commits, pushes, and opens a PR in one go.
Use when: you're done with a feature and want to ship it quickly.

### Testing

**`/gsd:add-tests`** — Generates tests for code you just wrote.
Use when: you built something and haven't written tests yet.


**Testing infrastructure prompt** (`docs/testing-infrastructure-prompt.md`) — Fill-in-the-blank prompt template for wiring the full Phalkon test stack onto any repo.
Fill in the `CONFIG` block at the top (repo name, archetype, layout), delete the archetype sections that do not apply, then paste the rest into Claude Code from the repo root.
Covers: Phase 0 audit (stops for confirmation), Phase 1 backend pytest with real Postgres, Phase 2 Vitest + MSW, Phase 3 openapi contract check, Phase 4 three-tier CI.
Archetypes: `library`, `service`, `deploy`, `greenfield`.

### Memory

**`/remember`** — Saves something to Claude's persistent memory.
Use when: you want Claude to remember a preference, rule, or fact across all future sessions.

Example: `/remember Always use uv instead of pip for Python package management in this project.`

**`/mem-search`** (claude-mem) — Searches past conversation history semantically.
Use when: you know you discussed something in a previous session but can't remember exactly what.

### Browser automation

**Playwright plugin** — Activated automatically when Claude needs to interact with a browser.
Use when: testing UI flows, scraping, or automating web interactions. Just describe what you want Claude to do in the browser.

### Integrations

**`/atlassian`** — Jira/Confluence integration.
Use when: you want Claude to create Jira tickets, update issue status, or write to Confluence from a session.

**`/circleback`** — Paste meeting notes and Claude turns them into Jira tickets and Confluence docs.
Use when: after a meeting where tasks were discussed.

---

## 6. Ruflo / claude-flow — Multi-Agent Orchestration

Ruflo is the MCP server that powers multi-agent workflows. You don't interact with it directly — Claude uses it when spawning sub-agents or storing memory.

### When Claude uses it automatically

- When you ask Claude to do something large enough that it spawns helper agents
- When Claude saves or recalls session memory between conversations
- When the GSD hooks fire (context monitoring, status line updates)

### When to ask Claude to use it explicitly

For large tasks, you can ask Claude to parallelize work:

> "Use multiple agents to research the codebase in parallel — one for the frontend, one for the backend — then combine the findings."

> "Spawn an agent to write tests while you implement the feature."

Claude will coordinate the agents and report back when done.

### Memory

Ruflo provides persistent vector memory across sessions. Claude automatically stores and retrieves relevant context. If Claude seems to have forgotten something from a previous session, try:

> "Search your memory for what we decided about [topic]."

---

## 7. Shell Aliases — Quick Reference

### Git

```bash
gst          git status
ga .         git add .
gc "message" git commit -m "message"
gp           git push
gpl          git pull
gcb name     git checkout -b name   (new branch)
gco name     git checkout name
gl           git log --oneline --graph
gd           git diff
gs           git stash
gsp          git stash pop
```

> **PowerShell name differences** — three aliases conflict with PS built-ins and are renamed in `powershell\aliases.ps1`:
> - `gc` → `git-commit` (PS built-in: `Get-Content`)
> - `gm` → `git-merge` (PS built-in: `Get-Member`)
> - `gs` → `git-stash` (PS built-in: `Get-Service`)
>
> All other alias names are identical.

### Python / virtualenv

```bash
create-venv  python3 -m venv .venv
a            source .venv/bin/activate   # Windows: .\.venv\Scripts\Activate.ps1
d            deactivate
pip-install  pip install -r requirements.txt
```

### Docker

```bash
dps          docker ps
dcup         docker-compose up -d
dcdown       docker-compose down
dclogs       docker-compose logs -f
dex name sh  docker exec -it name sh
```

### System

```bash
ll           ls -alF  (detailed listing)
listen       show all listening ports
myip         show your public IP
genpass      generate a random password
http-server  start a local HTTP server in current directory
```

---

## 8. Common Workflows

### Starting your day on an existing project

```bash
cd ~/dev/Phalkon-Dev/my-project
claude-default-continue          # resume where you left off
# inside Claude:
/gsd:check-todos                 # see what's pending
/gsd:progress                    # see milestone status
```

### Starting a brand new project

```bash
cd ~/dev/Phalkon-Dev
git clone git@github.com:Phalkon-Dev/ui-app-template.git my-project-ui
cd my-project-ui
claude-default
# inside Claude:
/gsd:new-project                 # build the roadmap
```

### Tackling a feature

```bash
claude-default
# inside Claude:
/gsd:plan-phase                  # plan the milestone
# review the plan, then:
/gsd:execute-phase               # build it
# when done:
/commit-push-pr                  # ship it
```

### Cost-saving session (docs, boilerplate, simple tasks)

```bash
claude-deepseek                  # cheaper provider
# work normally — same interface, lower cost
```

### Debugging something tricky

```bash
claude-default                   # use full Anthropic quality
# inside Claude:
/gsd:debug                       # structured debug session
```

### After a meeting

```bash
claude-default
# inside Claude:
/circleback                      # paste meeting notes → Jira tickets + Confluence
```

---

## 9. Tips

**Context window** — The GSD status line at the bottom shows context usage. When it hits ~75%, start a new session with `-continue` to avoid running out mid-task.

**DeepSeek for first drafts, Anthropic for review** — A common pattern: use `claude-deepseek` to generate a first draft of a feature, then switch to `claude-default` to review and refine it.

**Check token savings weekly** — Run `rtk gain --history` on Fridays to see how much RTK saved that week. It's a good way to validate the setup is working.

**Memory is per-machine** — Claude's memory (via Ruflo and `/remember`) is stored locally. If you move to a new machine, re-run the setup but note that conversation history and saved memories won't carry over.

---

## 10. Windows Troubleshooting

**Script won't run — "running scripts is disabled on this system"**

PowerShell's default execution policy blocks unsigned scripts. Fix it once with:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Then re-run `.\install.ps1`.

**Aliases not loading in new terminals**

The installer appends a dot-source line to your `$PROFILE`. If aliases aren't available, check that the line exists:

```powershell
Get-Content $PROFILE
# Should contain: . "$env:USERPROFILE\.claude\aliases.ps1"
```

If missing, add it manually:

```powershell
Add-Content $PROFILE '. "$env:USERPROFILE\.claude\aliases.ps1"'
```

**RTK download failed during install**

The installer downloads RTK from GitHub Releases as a `.zip`. If it failed, try manually:

```powershell
# Check architecture first
[System.Environment]::Is64BitOperatingSystem    # True = x64
$env:PROCESSOR_ARCHITECTURE                      # AMD64 or ARM64
```

Download `rtk-x86_64-pc-windows-msvc.zip` (or `aarch64` for ARM64) from the RTK releases page, extract `rtk.exe`, and place it at `%USERPROFILE%\.claude\bin\rtk.exe`. Add that directory to your PATH if it is not already there.

**Headroom not found after install**

Headroom is a Python pip package — there is no `headroom.exe` binary. If the `headroom` command is not found:

```powershell
# Install or reinstall
pip install "headroom-ai[all]"

# If still not found, the pip Scripts directory may not be in PATH
# Add it (replace PythonXY with your version, e.g. Python312):
$env:PATH += ";$env:APPDATA\Python\Python312\Scripts"

# Or try invoking directly via python -m
python -m headroom --version
```
