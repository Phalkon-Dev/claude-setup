# Claude Code Project Workflow

> Global reference for starting new projects and working with existing ones.
> GSD (`/gsd:*`) handles structured planning phases.

---

## Repo Naming Convention

| Scenario | Repo name(s) |
|----------|-------------|
| Frontend only | `{project-name}-ui` |
| Backend only | `{project-name}-api` |
| Both, separate repos | `{project-name}-ui` + `{project-name}-api` |
| Both, single repo | `{project-name}` |

---

## Part 1 — Starting a New Project

### Step 1 — Create the repos

**Frontend** (clone template, set upstream + new origin):
```bash
cd ~/dev/Phalkon-Dev
git clone git@github.com:Phalkon-Dev/ui-app-template.git {project-name}-ui
cd {project-name}-ui
git remote rename origin upstream
git remote add origin git@github.com:Phalkon-Dev/{project-name}-ui.git
git push -u origin main
```

**Backend** (clone template, set upstream + new origin):
```bash
cd ~/dev/Phalkon-Dev
git clone git@github.com:Phalkon-Dev/fastapi-app-backend-template.git {project-name}-api
cd {project-name}-api
git remote rename origin upstream
git remote add origin git@github.com:Phalkon-Dev/{project-name}-api.git
git push -u origin main
```

> **Why `upstream`?** Keeping the template as a remote lets you pull future improvements
> back into the project without manual copy-paste.

---

### Step 2 — Set up the docs structure

Each repo needs this layout (already present in the templates):

```
docs/
  PRD.md               ← What are we building and why
  planning.md          ← Milestones, approach, architecture decisions
  tasks.md             ← Backlog ([ ] todo, [-] in progress, [x] done)
  assistant_rules.md   ← How Claude should behave in this project
  sessions/            ← Dated work logs
CHANGELOG.md           ← Keep a Changelog format
CLAUDE.md              ← Claude instructions (auto-loaded each session)
```

Create a rough `docs/PRD.md` before opening Claude Code — even a paragraph is enough.

---

### Step 3 — Open Claude Code and initialize

Open the repo in Claude Code, then run:

```
/gsd:new-project
```

GSD will interview you about the project, generate a roadmap with phases, and populate `docs/planning.md` and `docs/tasks.md`.

---

### Step 4 — Customize the templates

**Frontend** — update these files for the new project:
- `.env` / `.env.example` — set `VITE_APP_NAME`, `VITE_API_URL`
- `frontend/index.html` — update `<title>`
- `public/` — replace logos
- `src/` — remove or adapt demo pages

**Backend** — update these files:
- `.env` / `.env.example` — set `DATABASE_URL`, secrets, app name
- `app/settings.py` — project-specific settings
- `api_info.toml` — update name/version
- `app/alembic/versions/` — delete initial migration, run `alembic revision --autogenerate -m "initial schema"` after defining your models

---

### Step 5 — Start developing

For each feature or milestone:

```
/gsd:plan-phase          # structured plan for a milestone
/gsd:execute-phase       # execute the plan
```

---

## Part 2 — Working with an Existing Project

### Session Start Protocol

1. Open the repo in Claude Code
2. Tell Claude to load context:
   _"Read docs/tasks.md, docs/planning.md, and the latest session file in docs/sessions/"_
3. Review open tasks:
   ```
   /gsd:check-todos
   ```

---

### Development Workflow

| Task type | Command |
|-----------|---------|
| New feature (complex) | `/gsd:plan-phase` → `/gsd:execute-phase` |
| Bug fix | `/gsd:debug` |
| Code review | Use the `code-review` plugin |
| Write tests | `/gsd:add-tests` |
| Check project progress | `/gsd:progress` |

---

### Working Across Two Repos Simultaneously

Open two terminal tabs or panes, each in their respective repo directory. Claude Code sessions are independent per directory.

When a backend API change requires a frontend update:
1. Complete and commit the backend change first
2. Switch to the frontend session
3. Describe what the backend now provides
4. Reference the backend's `docs/api_reference.md` if available

---

### Session End Protocol

1. Update `docs/tasks.md` with completed/remaining items
2. Update `CHANGELOG.md` with a brief entry (Added / Changed / Fixed / Removed)
3. Commit and push

---

## Template Updates — Propagating Changes from Templates

When a template gets improvements, use the `upstream` remote to selectively pull them.

### Check what changed in the template
```bash
git fetch upstream
git log upstream/main --oneline          # list template commits
git diff main upstream/main -- <file>    # diff a specific file
```

### Pull a specific commit (recommended)
```bash
git cherry-pick <commit-hash>
```

### Pull all template changes at once
```bash
git merge upstream/main
# resolve conflicts, then commit
```

### What is worth syncing vs. skipping

| Template change | Sync? |
|----------------|-------|
| Dependency version bumps | Yes |
| Design token / CSS updates | Yes — if project hasn't diverged |
| New shared component | Yes — if useful |
| Bug fix in shared utility | Yes |
| Demo page changes | No |
| Alembic initial migration | No |
| `docs/PRD.md` / `docs/planning.md` | No |

---

## GSD Command Reference

```
/gsd:new-project        Initialize roadmap for a new project
/gsd:plan-phase         Plan a milestone in detail
/gsd:execute-phase      Execute a planned milestone
/gsd:progress           Show current milestone status
/gsd:check-todos        Review open tasks
/gsd:debug              Systematic debugging session
/gsd:add-tests          Generate tests for a feature
/gsd:health             Project health check
```
