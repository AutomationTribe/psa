# Canonical framework vs project configuration

The framework is split cleanly in two so that a project can adopt it, stay current with it, and still
keep its own rules.

## 1. Canonical (owned by the framework — do not edit in a project)

| In this repository | Installed in a project as | What it is |
|---|---|---|
| `agents/*.md` (10 agents) | `.claude/agents/*.md` | Agent definitions: role, invocation rules, independence, report format |
| `docs/POLICY.md` | `docs/framework/POLICY.md` | The policy: judgment principle, profiles' meanings, DoR/DoD, workflow, review standards, registry, practices |
| `docs/VERSIONING.md` | `docs/framework/VERSIONING.md` | Version rule, history, compatibility, update and rollback |
| `docs/ADOPTION.md`, `prompts/*.md` | `docs/framework/` (optional) | Adoption guide and reusable prompts |
| `VERSION` | `docs/framework/FRAMEWORK_VERSION` | The version the project is on |

A project that needs different behaviour does **not** edit these files; it records a *compatibility
exception* in its adoption record (and proposes the change upstream). That keeps every project
upgradeable.

## 2. Project-specific configuration (owned by the project)

Created from `templates/` and filled in by the project. Nothing here is overwritten by an upgrade.

| Project file (suggested path) | From template | Holds |
|---|---|---|
| `CLAUDE.md` | `CLAUDE.md.template` | The project's enforceable rules: the framework rules plus the project's own |
| `docs/framework/PROJECT_PROFILE.md` | `PROJECT_PROFILE.md.template` | **Criticality and readability profiles**, and where every project document lives |
| `docs/framework/ADOPTION_RECORD.md` | `ADOPTION_RECORD.md.template` | Framework version, adoption date and status, applicable agents, compatibility exceptions |
| `docs/PROJECT_STATUS.md` | `PROJECT_STATUS.md.template` | The status log |
| coding standards document | `coding-standards.md.template` | The selected readability profile and the project's conventions |
| `docs/technical-debt.md` | `technical-debt.md.template` | The debt register |
| `docs/decisions/NNNN-*.md` | `adr-template.md` | Architecture/technology decision records |
| `.claude/settings.json` (optional) | `claude-settings.stop-hook.example.json` | Optional status-log hook |

## The project profile is the agents' map

The agents never assume where a project keeps things. They read `docs/framework/PROJECT_PROFILE.md`,
which names (at minimum): the project's requirements and product decisions; architecture, database and
API decision logs; the API contract file; the database schema/documentation; security documentation; the
design tool, design registry (approved screen names and IDs) and saved reference images; the test
commands; the deployment procedure; the status log, debt register and ADR directory; the technology
stack; and the two selected profiles. If a location is blank the agent says so rather than guessing.
