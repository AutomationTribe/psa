# Project working instructions

Before planning an implementation task, read `docs/PROJECT_STATUS.md` together with the relevant requirements, architecture, ADRs, product decisions and technical documentation. The status file is a concise handoff, not a replacement for those documents.

After every coding task, update `docs/PROJECT_STATUS.md` with:

- Date and current branch/commit (say `none` if there is no commit)
- Work actually completed
- Tests actually executed and their results (say `not run` and why when applicable)
- Deployment/demo URL when applicable
- Current blockers
- Exactly three recommended next tasks

Never mark untested work complete. Report unverified implementation separately. Do not claim tests passed unless they were executed.

Follow the project's approved stage gates. For every stage:

1. Produce the stage outputs as local drafts.
2. Run the required internal review and present a concise summary, artifacts and open decisions to the user.
3. Wait for the user's explicit `APPROVE`, `MODIFY` or `PAUSE` decision.
4. Do not commit, push, publish or start the next stage before explicit approval.
5. After approval, mark the artifacts approved, update `docs/PROJECT_STATUS.md`, commit and publish them, then verify the remote state.

If an unapproved stage was published accidentally, report it immediately. Do not rewrite or remove remote history without explicit user instruction.

## AI Software Delivery Framework (version 1.1.0)

PSA follows the AI Software Delivery Framework **1.1.0** (`docs/framework/FRAMEWORK_VERSION`; policy in
`docs/framework/POLICY.md`; adoption record and compatibility exceptions in `docs/framework/ADOPTION_RECORD.md`; project
profile in `docs/framework/PROJECT_PROFILE.md`; agents in `.claude/agents/`). It was adopted forward-only on 2026-10-08:
completed work is not reopened, and the project's own rules elsewhere in this file (stage gates, USSD, status-log rules) are preserved.
Where a project rule is stricter than the framework it wins; a mismatch is recorded as a compatibility exception, never
resolved silently. PSA's stage gates (explicit `APPROVE` / `MODIFY` / `PAUSE` before any commit, push or publication) are
what "commit/push according to repository policy" means in workflow step 16. The framework rules are numbered 1-16 below
and are referred to as framework rules; the project's own rules are the unnumbered sections of this file.

1. Requirements are the source of truth for what the system should do. Never invent requirements.
2. Before implementing a feature, read the relevant requirements, decisions and technical documentation
   (their locations are in `docs/framework/PROJECT_PROFILE.md`).
3. New or changed requirements get an impact analysis (data, APIs, backend, frontend, security,
   permissions, tests, documentation) before implementation. Do not implement a new or changed requirement
   immediately.
4. Keep documentation synchronised with approved changes. Record significant architecture and technology
   decisions (ADR/RFC) — do not make them silently.
5. **Independent Judgment — Evidence Over Agreement:** agents do not agree with the user or the implementer
   by default. They independently evaluate decisions and implementation; prioritise correctness, evidence,
   requirements and engineering principles; raise justified concerns; recommend better alternatives; avoid
   inventing defects; explain concisely; and respect the human's final decision authority. Reviewers never
   rubber-stamp. (`docs/framework/POLICY.md`.)
6. Developer tests are required for all new functionality, modified functionality and bug fixes (a bug
   fix's test must catch the original bug). Work is not complete until its tests have been **run** and the
   results reported (pass/fail/count) — "tests added" is not enough.
7. The normal path from requirements to deployment is the 20-step vertical slice in
   `docs/framework/POLICY.md` ("Engineering workflow"): Feature Selection → Requirements Checkpoint → Risk
   Classification → Definition of Ready → Approved UI/UX Design (when applicable) → Design Handoff (`design`)
   → Database Architect Review (`database-architect`, when database structures are introduced or materially
   changed — before any code) → Backend Implementation + Developer Tests → Backend Engineer Reviewer
   (`backend-reviewer`) → Frontend Implementation + Developer Tests → Frontend Engineer Reviewer, including
   Design Conformance (`frontend-reviewer`) → Cross-Cutting/Integration Review (`reviewer`, when necessary)
   → Independent QA (`qa`) → Security Review (`security`, risk-based) → Definition of Done → Commit/Push per
   repository policy → Human/Product Owner Acceptance → DevOps/Deployment after authorization → Production
   Smoke Verification → Monitoring. Do not invoke agents for layers a task does not touch. There is no
   separate design-conformance gate: the `frontend-reviewer` verifies conformance with the approved designs.
8. Implementation agents (`backend`, `frontend`) never self-certify their work. Independent review belongs to
   the `backend-reviewer`, the `frontend-reviewer` (engineering review and design conformance), the
   `database-architect` (database design, before implementation), the `reviewer` (cross-cutting only) and
   `qa` (functional correctness). Reviewers return a Standard Review Report and never modify implementation
   code.
9. Review standards (`docs/framework/POLICY.md`, "Review standards"): findings are HIGH / MEDIUM / LOW. HIGH
   blocks progression and commit; MEDIUM must be resolved before commit unless the authorised human
   explicitly accepts it as an exception (recorded in the status log); LOW may be fixed or logged as
   technical debt. A PASS WITH CHANGES verdict does not by itself authorise a commit. All mandatory reviews
   happen before the implementation is committed, and corrections are re-reviewed by the same specialist
   role. Reviewers do not certify tests they did not execute and do not inflate severity.
10. If a reviewer, QA or Security reports a failure (a HIGH finding, a BLOCKED review, a MATERIAL
    difference or PRODUCT CONFLICT, a failed test, a security finding), explain exactly what failed, the
    risk and a recommendation, then explicitly ask the human whether to proceed anyway. Never silently skip a
    gate, auto-override a reported failure, or let an agent silently resolve a design/requirement conflict.
11. The human is the final decision-maker: acceptance and deployment require explicit human authorisation.
    The `devops` agent stops for approval on test failures, destructive operations, production-data risk and
    cost increases.
12. Every implementation is classified LOW / MEDIUM / HIGH risk before work begins; a Definition of Ready is
    checked before implementation and a Definition of Done before it is considered complete
    (`docs/framework/POLICY.md`). Depth scales with risk and the project's criticality profile.
13. Project criticality and code readability are the **human's** decisions, recorded in
    `docs/framework/PROJECT_PROFILE.md`: criticality = `HIGH-CRITICALITY`; readability =
    `SENIOR`. Apply them; never choose or change them. Until chosen, state the assumed
    default and ask.
14. New technology, meaningful dependencies and hard-to-reverse technical decisions need evidence-based
    justification and a recorded decision; do not add architecture components (caches, queues, search
    engines, extra datastores, extra runtimes) without one.
15. Update the project status log (`docs/PROJECT_STATUS.md`) after every task: date, commit, completed work,
    tests actually run and results, deployment/demo link, blockers, next three tasks. Never mark untested
    work complete. (An automated hook for this is optional — see `templates/claude-settings.stop-hook.example.json`
    and `docs/VALIDATION.md`; do not claim enforcement that has not been tested.)
16. Framework upgrades are adopted forward-only at the next safe task boundary; work in progress finishes
    under the workflow it started with; completed work is never reopened (`docs/framework/POLICY.md`,
    `docs/framework/VERSIONING.md`).

When the user enters `USSD`, read `docs/tags/USSD.md` and return its last known work completed, current blockers and next steps. Keep USSD paused unless the user explicitly resumes it.
