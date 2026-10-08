# Project profile — Personal Safety App (PSA)

The framework's agents read this file to learn the project's choices and where its documents live. If a
field is blank, agents say so rather than guess. This file is project-specific configuration; a framework
upgrade never overwrites it.

## Profiles (chosen by the human — agents never choose these)

| Profile | Selected | Decided by / date |
|---|---|---|
| Project criticality (`PROTOTYPE` / `MVP` / `PRODUCTION` / `HIGH-CRITICALITY`) | `HIGH-CRITICALITY` | Founder / Product Owner, 2026-10-06 (Stage 4 "safety-sensitive, high-criticality" classification, approved). **Mapping of that wording onto the framework enum is recorded here from the approved Stage 4 text; the Product Owner should confirm it.** |
| Code readability (`MID-LEVEL` / `SENIOR`) | `SENIOR` | Founder / Product Owner, 2026-10-06 (Stage 4 "Senior code-readability profile", approved) |

Meanings of the options are defined in `docs/framework/POLICY.md` ("Project profiles"). Authoritative source for
both decisions: `docs/engineering/STAGE_4_ENGINEERING_PROFILE.md` (including its mandatory release gates, which
remain in force and are stricter than the framework baseline).

## Where things live

| What | Location |
|---|---|
| Requirements | `docs/requirements/FUNCTIONAL_REQUIREMENTS.md`, `NON_FUNCTIONAL_REQUIREMENTS.md`, `USER_STORIES.md`, `TRACEABILITY.md` |
| Product decisions | `docs/product/PRODUCT_DEFINITION.md` (approved Stage 2); USSD scope in `docs/tags/USSD.md` (paused) |
| Architecture / technology decisions | `docs/architecture/STAGE_6_ARCHITECTURE.md`, `docs/engineering/STAGE_5_TECHNOLOGY_SELECTION.md` (no separate ADR directory yet) |
| Database design and decisions; schema | `docs/database/STAGE_8_DATABASE_DESIGN.md`; schema = Flyway migrations in `database/migrations/`; `database/README.md` |
| API conventions and decisions | _blank_ — the Stage 6 architecture states OpenAPI is the contract; no API decision log exists yet |
| API contract file (e.g. OpenAPI) | _blank_ — not created yet (no API implemented) |
| Security documentation | _blank_ — security controls are in `docs/engineering/STAGE_7_ENGINEERING_STANDARDS.md` section 5 and the Stage 6 architecture; no dedicated security document yet |
| Coding standards (readability profile) | `docs/engineering/STAGE_7_ENGINEERING_STANDARDS.md` and `docs/engineering/STAGE_4_ENGINEERING_PROFILE.md` |
| ADR directory | _blank_ — none yet |
| Technical-debt register | _blank_ — none yet |
| Status log | `docs/PROJECT_STATUS.md` |
| Design tool (e.g. Stitch) and project/space ID | _blank_ — no design tool is configured for PSA yet |
| Design registry (approved screen names ↔ screen IDs) | _blank_ |
| Saved reference images of approved designs | _blank_ |
| Design handoffs | _blank_ |
| Design system / shared components / tokens | _blank_ |

## How things run

| What | Command / procedure |
|---|---|
| Install dependencies | _blank_ — no application code yet |
| Typecheck / lint | _blank_ |
| Unit / integration tests | _blank_ for application code. Database tests (Local, disposable only): `database/tests/*.sh` and `database/tests/*.sql` (see `database/README.md`) |
| End-to-end tests (and tags/classifications used) | _blank_ |
| Run the app locally (for screenshots) | _blank_ |
| Build | _blank_ |
| Deploy (provider, procedure, who authorises) | _blank_ — no deployment yet. Planned hosting and the deployment rules are in the Stage 6 architecture (Railway, Neon); every deployment needs the Product Owner's explicit authorisation |

## Stack (informational — agents inspect the repository rather than trust this)

Planned/approved (Stage 5): native Kotlin (Android), native Swift (iPhone), Kotlin/Spring Boot backend,
React/Next.js dashboard, PostgreSQL + PostGIS (Flyway migrations), Railway and Neon. Implemented so far:
the PostgreSQL/PostGIS schema, Flyway migrations and Local Docker Compose setup under `database/` only.

## Unknown / blank fields to fill later

API decision log and contract file, security document, ADR directory, technical-debt register, design tool,
registry and reference images, build/test/run/deploy commands for application code, and Product Owner
confirmation of the criticality mapping above.
