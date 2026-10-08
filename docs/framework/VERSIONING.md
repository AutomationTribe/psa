# Versioning, compatibility, updates and rollback

**Current version: 1.1.0.** The git tag for it is `v1.1.0`. The `VERSION` file, the top entry of
`CHANGELOG.md`, the header of `docs/POLICY.md` and this file must always agree (`scripts/validate.py`
checks this).

## Versioning rule

`MAJOR.MINOR.PATCH`.

- **MINOR** — adds or reassigns agents, gates or policies **without removing any control**; fully
  backward compatible; adopted forward-only at the next safe boundary.
- **MAJOR** — removes or weakens a control, or changes something existing projects must re-approve.
- **PATCH** — wording or clarification only; no behavioural change.

## Version history

### 1.1.0 — 2026-10-08 (minor, backward compatible)

**Change summary:** three specialist review agents are added; design conformance moves from a separate
mandatory gate into the frontend review; review reporting and severity rules are standardised; all
mandatory reviews must complete before commit; the workflow is restated as a 20-step vertical slice.
This release is also the first standalone release of the framework (extracted from the project in which
1.0 and 1.1 were developed), with project-specific content removed and project configuration moved into
templates.

**New agents:** `database-architect` (reviews proposed schema/migration designs *before* implementation,
only when database structures are introduced or materially changed); `backend-reviewer` (independent
review of Backend Engineer output before commit); `frontend-reviewer` (independent review of Frontend
Engineer output before commit; owns **both** the frontend engineering review and the design conformance
review, MATCH / MINOR / MATERIAL / PRODUCT CONFLICT).

**Updated workflow:** the 20-step vertical slice in `POLICY.md`; layers a task does not touch are
skipped; the separate Design Conformance gate is removed (the `design` agent stays for consultation,
interpretation and handoff); the general `reviewer` handles cross-cutting/integration concerns only;
review-and-correction loops per layer.

**Review policies:** Standard Review Report; severity rules (HIGH blocks progression and commit; MEDIUM
must be resolved before commit unless the authorised human explicitly accepts an exception; LOW may be
fixed or logged as technical debt); PASS WITH CHANGES does not by itself authorise commit; reviewers must
not certify tests they did not execute; senior-level reviewer expertise applied against the project's
selected readability profile; "Independent Judgment — Evidence Over Agreement" (seven points) for every
agent.

**Unchanged (explicitly):** `qa` still independently validates functionality; `security` keeps its
responsibility (risk-based); human acceptance and deployment-authorisation gates; criticality and
readability profiles (configurable per project); project-specific decisions and rules.

### 1.0.0 — 2026-10-07 (baseline, numbered retroactively)

Initial adoption of the framework: Frontend/Backend/Reviewer agents alongside the Design/QA/Security/
DevOps agents, Definition of Ready/Done, change-risk classification, technology and dependency
governance, the ADR/RFC process, migration and observability guidance, the technical-debt register, the
project status log, and forward-only adoption. No version number was recorded when it was first adopted;
it was named 1.0 only so that 1.1 has a baseline. A project that adopted the framework from that
unnumbered baseline is treated as 1.0.0.

## Compatibility rules

- A project on 1.0.x can adopt 1.1.0 without redoing anything: add the three agents, merge the changed
  policy sections, reword the hand-off wording of the existing agents, record the adoption.
- A MINOR upgrade never removes a control a project relied on; if a gate is reassigned (as design
  conformance was in 1.1) the control still exists, in a new place.
- Projects keep their own rules, agents, approval gates and profiles; a mismatch with the canonical files
  is a recorded **compatibility exception**, not a local edit of canonical files.
- Requirements for the host: Claude Code's `.claude/agents/` convention (markdown with YAML frontmatter
  `name`, `description`, `tools`, `model`) and a project `CLAUDE.md`. Design conformance uses the project's
  design integration where one exists (e.g. Stitch MCP) and falls back to saved reference images.
- No application code, schema or configuration change is ever required by a framework upgrade.

## Update procedure (adopting a newer version)

1. Check the project's `docs/framework/FRAMEWORK_VERSION` and adoption record; read this file's history
   between that version and the target.
2. **Timing:** if an implementation task is in progress, do not interrupt it — it finishes under the
   workflow it started with, unless the human explicitly authorises adopting mid-task. Otherwise adopt at
   the next safe task or feature boundary.
3. Copy the canonical files for the target tag (`agents/`, `docs/POLICY.md`, `docs/VERSIONING.md`) over
   the installed copies; do **not** touch project-specific configuration.
4. Reconcile `CLAUDE.md` additively with `templates/CLAUDE.md.template` (new or reworded framework rules;
   keep the project's own rules and numbering).
5. Update the adoption record (new version, date, status, applicable agents, exceptions) and the status
   log; commit and push per the project's own policy.
6. Run `scripts/validate.py --project <path>` if you have the framework checked out, or the manual
   checklist in `ADOPTION.md`.
7. Never reopen completed work or require retrospective reviews because of an upgrade.

The reusable prompt for steps 1–7 is `prompts/upgrade-framework.md`.

## Rollback

Everything in an adoption or upgrade is documentation and agent files, normally in one commit: revert
that commit (`git revert <sha>`) and restore the previous `FRAMEWORK_VERSION`/adoption record. Nothing at
runtime depends on the framework, so rollback needs no application change. To return to a specific
framework release, copy the files from that tag (`git checkout v1.1.0 -- agents docs/POLICY.md ...`).
