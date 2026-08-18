# Claude Code prompt — Phalkon test infrastructure (any repo)

Fill in the CONFIG block, delete the archetype sections that don't apply,
paste the rest into Claude Code from the repo root.

> **Phalkon Note — All repos are private**: The default `GITHUB_TOKEN` cannot
> read sibling `phalkon-*` repositories. The GitHub App token approach described
> in the service archetype section is **always required** for any workflow that
> installs packages from or communicates with another Phalkon repo — not only
> when `DEPENDS ON` is non-empty.

---

# CONFIG — fill this in before pasting

```
REPO:          phalkon-<name>
ARCHETYPE:     library | service | deploy | greenfield
DEPENDS ON:    none | phalkon-core@<version> | ...
CONSUMED BY:   none | phalkon-compliance, phalkon-rebalance, ...
LAYOUT:        backend/ + frontend/ | backend only | frontend only | other
HAS FRONTEND:  yes | no
```

Archetype picker, if you're unsure:

| Archetype | Test | Example |
|---|---|---|
| `library` | Other repos import it as a package | phalkon-core |
| `service` | Ships its own API + UI to clients | compliance, rebalance |
| `deploy` | Thin orchestrator, consumes versioned modules | phalkon-app |
| `greenfield` | New module, little or nothing built yet | future modules |

---

# TASK

Set up test infrastructure for this repo, matching the Phalkon standard so every
module works the same way. Stack: FastAPI + SQLModel + Alembic + Postgres managed
with uv on the backend; Vite + React + TailwindCSS on the frontend. Private repo
on a metered GitHub Actions plan.

## Phase 0 — Audit. Write nothing yet.

Report a table of what exists vs. what's missing:

**Backend**
- Is uv the package manager? Is there a `uv.lock`?
- Exact ASGI import path (`app.main:app` or otherwise)
- Postgres driver: `psycopg` v3 / `asyncpg` / `psycopg2`
- Health endpoint — exists? path?
- `tests/` layout — unit/integration split? `conftest.py`? registered markers?
- Alembic configured? Does `alembic upgrade head` work right now?

**Frontend** (skip if `HAS FRONTEND: no`)
- Package manager and lockfile
- Vitest installed and configured? What does `npm run test` actually run?
- Playwright installed? Config present? Existing specs?

**Repo-wide**
- Existing `.github/workflows/` — list them and note overlap with this task
- `Makefile`, `docker-compose*.yml`, `.env.example`?
- How is auth implemented? (determines the authenticated-client fixture)
- Confirm the declared ARCHETYPE matches what you actually see. If the CONFIG
  says `service` but this looks like a library, say so.

Then: state which of my assumptions are wrong and **stop for my confirmation**.
Do not guess, do not scaffold ahead.

## Phase 1 — Backend tests (all archetypes)

```
backend/tests/
  conftest.py
  unit/          # no DB, no network — whole dir must run in <10s
  integration/   # real Postgres via httpx.AsyncClient against the app
```

In `conftest.py`:
- Register the `integration` marker in `pyproject.toml` `[tool.pytest.ini_options]`
- Session fixture reading `DATABASE_URL` from env, running `alembic upgrade head`
- Per-test transaction rollback so tests don't leak state
- `httpx.AsyncClient` fixture bound to the app with DB session dependency override
- Authenticated-client fixture matching however auth actually works here

**Never use SQLite as a Postgres stand-in.** This platform relies on JSONB,
per-client schemas, and Postgres-specific constraints. SQLite gives false green.

## Phase 2 — Frontend tests

Skip entirely if `HAS FRONTEND: no`.

- Vitest + React Testing Library + `@testing-library/user-event`, wired through
  the existing `vite.config.ts`. Do not add a separate Jest pipeline.
- MSW for API mocking in `src/mocks/` — intercept at the network layer so
  components run their real fetch code paths
- 3 example component tests against **real components in this repo**, not
  placeholders. Assert on what a user sees, not on internals.

## Phase 3 — Contract check

- Script dumping `app.openapi()` to `backend/openapi.json`, sorted keys, stable
- Generate the typed frontend client via `openapi-typescript`, commit the output
- CI regenerates and fails on diff, so a renamed backend field can't silently
  become `undefined` in the UI

If `HAS FRONTEND: no` but `CONSUMED BY` is non-empty, still commit
`openapi.json` — downstream repos generate their clients from it.

## Phase 4 — CI, three tiers

- `test-unit.yml` — every push. `dorny/paths-filter` so a backend-only commit
  skips frontend. `concurrency` + `cancel-in-progress`.
- `test-integration.yml` — PRs to main. Postgres service container with
  `pg_isready` healthcheck. `alembic check` to catch model/migration drift.
  OpenAPI diff job.
- `test-e2e.yml` — merges to main + `workflow_dispatch` with optional `base_url`
  input. Cache `~/.cache/ms-playwright`. Upload report on failure.

Root `Makefile`: `test-unit`, `test-int`, `test-e2e`, `test-smoke URL=`,
`api-schema`. Test Postgres on **port 5433** so it never collides with my dev
instance on 5432. Identical target names across all Phalkon repos.

---

# ARCHETYPE SECTIONS — keep only the one that applies

## IF ARCHETYPE = library (phalkon-core)

Core is consumed by other repos, so a green test suite here is a promise to
downstream modules. Additionally:

- **Package it properly.** `pyproject.toml` builds a wheel, version is single-
  sourced (`__version__` or hatch-vcs). Add a CI job that builds the wheel and
  installs it into a clean venv — catches missing `__init__.py` and packaging
  bugs that never appear in editable installs.
- **Publish to GitHub Packages** on tag, not raw git URLs. Add a `release.yml`
  triggered on `v*` tags.
- **Public API surface test.** A test asserting the exported symbols downstream
  repos rely on still exist. This is your breaking-change alarm.
- **RBAC gets the deepest coverage in the repo.** RBAC lives exclusively in core;
  every other module trusts it. Test role/permission resolution, denial paths,
  and privilege escalation attempts explicitly — not just happy paths.
- **Migration tests** for the shared/public reference-data schema.
- No E2E tier. A library has no UI. Replace tier 3 with the wheel-build +
  clean-install job.

## IF ARCHETYPE = service (compliance, rebalance)

- 4–6 Playwright specs on real critical paths. Read the routes, pick them
  yourself, then tell me which you chose and why. Tag them `@smoke`.
- `backend/scripts/seed_e2e.py` — deterministic and idempotent.
- `playwright.config.ts` with `BASE_URL` env override, chromium only,
  `trace: 'on-first-retry'`, retries 2 in CI / 0 locally.
- If `DEPENDS ON` names phalkon-core: the default `GITHUB_TOKEN` cannot read
  another private repo. Use `actions/create-github-app-token` with a GitHub App
  scoped to the phalkon-* repos. **Do not use a long-lived PAT.** Tell me exactly
  which App permissions you need and I'll create it — don't try to.
- Pin the core version in the lockfile. Add a scheduled weekly job testing
  against core's `main` so upstream breakage surfaces on a schedule instead of
  mid-sprint.

## IF ARCHETYPE = deploy (phalkon-app)

This repo has little code of its own. Its test suite answers one question: **do
these versioned modules compose, migrate, and boot together?** Ignore the
unit-test tier — there's nothing to unit test.

- **Composition test.** Install the pinned module versions, boot the assembled
  app, assert every module's routes mount without collision and the OpenAPI
  schema generates cleanly.
- **Combined migration test.** Fresh Postgres, run every module's migrations in
  dependency order, assert the final schema is coherent. This is the single most
  valuable test in the repo — schema-per-module across one client DB is exactly
  where things break.
- **Multi-tenant isolation test.** Provision two client DBs, write to one, assert
  the other cannot see it. Given financial clients and CNBV exposure, this is a
  compliance artifact, not just a test.
- **Version matrix.** Test the pinned set plus each module's previous minor —
  catches modules that silently require a newer core.
- **Post-deploy smoke.** `BASE_URL` against a real deployment, `--grep @smoke`,
  under 60 seconds. This is the one that pages you.
- Needs cross-repo read on all phalkon-* repos. GitHub App, as above.

## IF ARCHETYPE = greenfield (new module)

Little exists yet, so you're setting the standard rather than retrofitting.

- Copy structure and conventions from the most mature sibling repo. Ask me which
  one to use as reference rather than inventing a new layout.
- Scaffold the full tree (`tests/unit`, `tests/integration`, `conftest.py`,
  workflows, Makefile) with **one real passing test per tier** as a template —
  not empty dirs, not placeholder assertions.
- Write `CLAUDE.md` documenting the test conventions so whoever picks this up
  next inherits the pattern.
- Set up all three CI tiers now even if thin. Retrofitting CI onto a repo with
  200 commits of untested code is significantly worse.
- Flag anything I'll need to decide before real work starts (auth approach,
  whether this depends on core, DB schema ownership).

---

# CONSTRAINTS (all archetypes)

- Metered Actions plan. **Never** trigger E2E on push to all branches. Every
  workflow gets `concurrency` and `paths-ignore` for markdown.
- No secrets in committed files. Test credentials are obviously-fake literals.
- `mypy` starts `continue-on-error: true`; tell me what strict would take.
- Match the existing conventions in this repo — imports, naming, layout. Don't
  import a different style.
- If this repo touches CNBV-regulated data, say which tests function as
  compliance evidence. I need to point auditors at them.

# DEFINITION OF DONE

- `make test-unit` passes locally
- `make test-int` passes locally with Docker running
- `make api-schema` produces stable committed output
- Every workflow validates as YAML
- Written summary: what you created, what you changed, what I do by hand, and
  anything broken you found independent of this task
