# Adopting the framework

Forward-only and non-disruptive: **adopting the framework never asks a project to redo completed work,
change application code, or interrupt a task in progress.** Policy is in `POLICY.md`; the canonical /
project split is in `PROJECT-CONFIGURATION.md`; versions, update and rollback are in `VERSIONING.md`.

## When to adopt

| Situation | What to do |
|---|---|
| **New project** | Bootstrap on the current version (below). |
| **Existing project, between tasks** | Adopt now, at the next safe task or feature boundary. |
| **Work in progress** | Do **not** interrupt it. The task finishes under the previously approved workflow. Adopt at its end — unless the Product Owner explicitly authorises adopting mid-task. |
| **Previously completed work** | Leave it alone: no reopening, no refactoring, no retrospective reviews. |
| **Customised workflow** | Keep every project-specific requirement, agent, approval gate, engineering profile and architecture decision. Merge the new agents in; never silently replace project rules. Record any mismatch as a compatibility exception. |

## New-project bootstrap

1. Copy `agents/*.md` into the project's `.claude/agents/`.
2. Copy `docs/POLICY.md` and `docs/VERSIONING.md` into `docs/framework/`; write the version from `VERSION` into
   `docs/framework/FRAMEWORK_VERSION`.
3. From `templates/`, create the project's own files (see `PROJECT-CONFIGURATION.md`): `CLAUDE.md`,
   `docs/framework/PROJECT_PROFILE.md`, `docs/framework/ADOPTION_RECORD.md`, `docs/PROJECT_STATUS.md`, the coding
   standards, `docs/technical-debt.md`, and the ADR directory.
4. **Ask the human to choose** the criticality profile and the readability profile and record them in
   `PROJECT_PROFILE.md` (and the coding standards). Never choose them for the project.
5. Fill in where the project keeps its requirements, decisions, API contract, design registry, test
   commands and deployment procedure.
6. Optionally add the status-log hook (`templates/claude-settings.stop-hook.example.json`) — see the
   enforcement notes in `VALIDATION.md`.
7. Commit. Use `prompts/bootstrap-new-project.md` to have Claude Code do steps 1–7 safely.

## Existing-project adoption (summary)

Use `prompts/adopt-existing-project.md`. In outline the agent: (1) reads the project first and changes
nothing; (2) establishes the current framework version (an unnumbered earlier adoption counts as 1.0.0),
the project's profiles, customised agents/gates, and whether a task is in progress — stopping if one is;
(3) adds the agent files and installs the policy; (4) reconciles `CLAUDE.md` and the existing agents'
hand-off wording additively; (5) records the adoption; (6) verifies; (7) updates the status log and
commits per the project's policy. It modifies only the adopting project.

## Adoption record

Each adopting project records, in `docs/framework/ADOPTION_RECORD.md`: framework version, adoption date,
adoption status (`Adopted` / `In progress` / `Deferred`), applicable agents, and any compatibility
exceptions (with the reason and the owner who accepted them).

## Verification checklist (manual or via `scripts/validate.py --project`)

- All agent files exist with valid frontmatter (`name` matching the filename, `description`, `tools`,
  `model`).
- Invocation rules are stated in each agent and in the registry; reviewers are independent of the
  implementer and cannot modify code (reviewer tool allowlists contain no file-writing tool).
- Design conformance is owned by the `frontend-reviewer`; no separate mandatory conformance gate remains.
- `qa`, `security`, human acceptance and deployment gates are unchanged.
- The workflow wording is the same in every document that restates it, or each points at the policy.
- Any edited JSON/config still parses.
- No claim of automated enforcement unless a hook or check was actually added **and tested**.
