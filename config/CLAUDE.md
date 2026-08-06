# Global Claude Instructions

## Project Workflow
Full guide for starting new projects and working with existing ones:
`~/.claude/project-workflow.md`

Repo naming: `{name}-ui` (frontend), `{name}-api` (backend), `{name}` (monorepo)
Templates: define `~/dev/Phalkon-Dev/ui-app-template` and `~/dev/Phalkon-Dev/fastapi-app-backend-template` for your organization.


## Documents HTML/PDF — Standard Template

**RULE**: For any HTML or PDF document, always start from your organization's standard template.

- Paper size: **always letter** (`@page { size: letter; }`) — never A4
- Accent color: per module (define per your design system)
- Logo: use your organization's SVG logo assets
- PDF rendering: `chromium --headless --print-to-pdf=out.pdf --print-to-pdf-no-header --no-margins file.html`


## Frontend UI — Default Design System

When working on any frontend project, default to your organization's design system.

### Defaults to apply to any new frontend project:
- **CSS framework**: Tailwind CSS v4 with CSS custom property tokens
- **Components**: shadcn/ui (Radix UI primitives) + class-variance-authority (cva)
- **Icons**: Lucide React only
- **Font**: Inter (`font-family: 'Inter', system-ui, sans-serif`)
- **Border radius**: `rounded-md` for controls, `rounded-xl` for cards, `rounded-full` for pills/avatars
- **Dark mode**: `.dark` class on `<html>`, preference in `localStorage['app_theme']`
- **Layout**: fixed sidebar (dark navy) + topbar shell, main content `p-6 bg-background`
- **Colors**: use semantic CSS tokens (`--primary`, `--background`, etc.) — no raw hex in components

### When scaffolding a new frontend project:
1. Copy your design token CSS file for token definitions
2. Copy your UI design system reference doc into the new project's `docs/` folder
3. Create a `CLAUDE.md` at the project root referencing the design system doc


# RTK — Rust Token Killer

**Usage**: Token-optimized CLI proxy (60-90% savings on dev operations)

## Meta Commands (always use rtk directly)

```bash
rtk gain              # Show token savings analytics
rtk gain --history    # Show command usage history with savings
rtk discover          # Analyze Claude Code history for missed opportunities
rtk proxy <cmd>       # Execute raw command without filtering (for debugging)
```

## Hook-Based Usage

All other commands are automatically rewritten by the Claude Code PreToolUse hook.
Example: `git status` → `rtk git status` (transparent, 0 tokens overhead)


# Ruflo Integration
When working on multi-file tasks or complex features, use ToolSearch to find and invoke ruflo MCP tools.
Key tools: memory_store, memory_search, hooks_route, swarm_init, agent_spawn.
Check system-reminder tags for [INTELLIGENCE] pattern suggestions before starting work.

# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, invoke the Skill tool with `skill: "graphify"` before doing anything else.
