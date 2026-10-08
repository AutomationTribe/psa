# AI Software Delivery Framework — Policy

**Framework version: 1.1.0** (see `VERSIONING.md` for history, compatibility and update/rollback).

This is the **canonical, project-independent policy**. It governs how work is planned, built,
reviewed and released when AI agents do the engineering. It contains no product requirements, no
technology choices and no project decisions — those live in each adopting project's own files (see
`PROJECT-CONFIGURATION.md`). In an adopting project this file is installed as
`docs/framework/POLICY.md` and is not edited locally; propose changes upstream instead.

## Roles and division of responsibility

| Role | Responsibility |
|---|---|
| ChatGPT (or another orchestrator) | **Process Orchestrator** — shapes the process, prompts and decisions around the work |
| Stitch (or the project's design tool) | **Primary UI/UX Designer** — the source of approved designs |
| Claude Code | **Engineering Implementor** — implements, tests and documents the work |
| Specialist agents | **Independent review and verification** — never the implementer of the thing they review |
| The human (Product Owner) | **Final decision authority** — approvals, acceptance, deployment authorisation |

## Independent Judgment — Evidence Over Agreement

AI agents must not agree with the user or with implementers by default. Every agent, and every
reviewer in particular, must:

1. **Independently evaluate** decisions and implementation.
2. **Prioritise correctness, evidence, requirements and engineering principles** over agreement.
3. **Raise concerns** when they are justified.
4. **Recommend better alternatives** where appropriate.
5. **Avoid inventing defects** or disagreeing merely to appear critical.
6. **Explain concerns concisely.**
7. **Respect the human's final decision authority.**

Reviewers must not rubber-stamp work. In practice:

- Verify claims against primary evidence before relying on them — the actual file, screenshot, test
  output or API response. A statement in a prompt such as "the gate passes" is a hypothesis to
  check, not an input to assume.
- When evidence contradicts an instruction or an earlier statement (including the agent's own), say
  so plainly, show the evidence and recommend a course of action. Do not quietly comply, and do not
  quietly substitute the agent's own preference either.
- Disagreement is reported, then the human decides. An agent does not override a decision it
  disagrees with, and does not defer silently to one the evidence says is wrong.
- Never soften, omit or reword a failing result to fit what the reader expects: failing tests,
  skipped steps, unreadable designs and unverifiable claims are reported as such.
- Agreement is earned by evidence: do not praise, confirm or "pass" work to be agreeable. Reviewers
  apply the same standard to each other's and the implementer's output.

## Project profiles (configurable per project)

Two profiles are chosen **by the human** for each project and recorded in the project's profile file
(`docs/framework/PROJECT_PROFILE.md`). The framework fixes the meanings, never the selection.

**Project criticality** — one of `PROTOTYPE` / `MVP` / `PRODUCTION` / `HIGH-CRITICALITY`:

| Profile | What it changes |
|---|---|
| PROTOTYPE | Minimal documentation/testing/review; speed over rigour; not suitable for real user data. |
| MVP | Core flows tested and reviewed; documentation covers real decisions; moderate rigour. |
| PRODUCTION | Full Definition of Done applies broadly; stronger security/observability/rollback expectations. |
| HIGH-CRITICALITY | Maximum rigour — formal review, strong rollback/observability/SLO discipline, minimal risk tolerance. |

**Code readability** — one of `MID-LEVEL` / `SENIOR`:

- **MID-LEVEL** — explicit, straightforward, easy to follow and debug, conservative with abstraction,
  understandable by a competent mid-level developer.
- **SENIOR** — may use stronger abstractions and patterns, but only when justified; readability and
  maintainability remain mandatory, and cleverness or needless abstraction stay prohibited under both.

Reviewer expertise is always senior-level, but reviews are made against the **selected** readability
profile. Until a profile is selected, agents state the default they are assuming (criticality at
least `MVP` for anything with real users or data; readability `MID-LEVEL`) and ask the human to
decide. Agents never choose a profile for the project.

## Definition of Ready

Before implementation begins on a feature or change, verify as applicable (depth scales with change
risk and project criticality):

- the requirement is approved and sufficiently clear (never invent one)
- relevant dependencies on other modules/features are understood
- affected approved product decisions are known
- a risk classification has been assigned (see Change-risk classification)
- relevant API/database impact is understood; where the feature introduces or materially changes
  database structures, the proposed schema and migration plan are ready to go to the
  `database-architect` before any code is written
- required design exists and is approved, where UI is involved
- the `design` agent handoff is complete, where UI is involved
- acceptance criteria are testable
- unresolved blockers are identified and surfaced, not silently worked around
- required technical decisions have been made (recorded as an ADR/RFC if significant)

## Definition of Done

A feature or change is not complete merely because code was written. As applicable, completion
requires:

- implementation completed
- developer tests added where required (new functionality, modified functionality, and bug fixes — a
  bug fix's test must be one that would have caught the original bug)
- tests **actually executed** and results recorded (pass/fail/count) — never "tests added" as a
  substitute for "tests run"
- every mandatory specialist review completed **before commit**, with no unresolved HIGH finding and
  no unresolved MEDIUM finding unless the authorised human explicitly accepted it as an exception:
  `database-architect` for material database changes, `backend-reviewer` for backend work,
  `frontend-reviewer` for frontend work (which includes design conformance against the approved
  designs), and the general `reviewer` for cross-cutting/integration concerns where needed
- corrections made and **re-reviewed** by the same specialist role; no implementation is declared
  complete while a blocking finding remains
- relevant API/integration, UI/end-to-end and regression tests completed (independent `qa`)
- accessibility checked, where frontend work is involved
- `security` review completed where required (see Change-risk classification)
- the API contract updated when APIs change
- migrations reviewed/tested when applicable
- observability added where applicable
- documentation synchronised with the approved change
- human acceptance obtained where required — the human remains the final authority
- the project status log updated

**Never mark untested implementation as complete.** Scale the depth of each item to the change's risk
level and the project's criticality profile — do not manufacture ceremony for genuinely low-risk work,
and do not skip a gate that a high-risk change needs.

## Change-risk classification

Every implementation/change is LOW, MEDIUM or HIGH risk. Classify by considering: user/business
impact, data impact, authentication/authorisation impact, tenant-isolation impact, financial/payment
impact, security impact, migration impact, backward compatibility, external integrations,
architectural impact, operational impact, and rollback difficulty.

| Risk | Typical example | Review/testing depth |
|---|---|---|
| LOW | A copy change, a read-only endpoint, an internal refactor with full coverage and no API/schema change | Standard specialist review (backend/frontend as applicable); developer tests; no mandatory `security` pass unless something above still applies |
| MEDIUM | A new feature screen with backend support, a non-destructive migration, a new endpoint affecting existing data | Full specialist reviews + `qa`; `security` review if auth/tenant/data boundaries are touched; migration reviewed per the Migrations section |
| HIGH | Anything touching authentication/sessions, tenant isolation, payments/webhooks, a destructive or hard-to-reverse migration, a new external integration, an architecture change | Full specialist reviews + `qa` + mandatory `security` review with lightweight threat modelling; explicit rollback plan; human acceptance required before deployment |

Right-size rigour; do not add ceremony to genuinely low-risk work.

## Engineering workflow

Each feature follows this vertical slice. **Do not invoke agents for layers a task does not touch**
(no database change → no `database-architect`; no backend change → no `backend-reviewer`; no UI → no
design handoff or `frontend-reviewer`). Frontend/backend ordering may change when technically
appropriate. Human approval gates and deployment controls are fixed by this policy.

```
 1. Feature Selection
 2. Requirements Checkpoint
 3. Risk Classification
 4. Definition of Ready
 5. Approved UI/UX Design (when applicable)
 6. Design Handoff                       — `design` agent
 7. Database Architect Review            — `database-architect`, when database changes are required
 8. Backend Implementation + Developer Tests (when applicable)   — `backend` agent
 9. Backend Engineer Reviewer            — `backend-reviewer`
10. Frontend Implementation + Developer Tests (when applicable)  — `frontend` agent
11. Frontend Engineer Reviewer, including Design Conformance     — `frontend-reviewer`
12. Cross-Cutting / Integration Review (when necessary)          — `reviewer`
13. Independent QA                       — `qa`
14. Security Review (risk-based)         — `security`
15. Definition of Done
16. Commit / Push according to repository policy
17. Human / Product Owner Acceptance
18. DevOps / Deployment after authorization                      — `devops`
19. Production Smoke Verification
20. Monitoring
```

There is no separate, mandatory design-conformance gate: conformance with the approved designs is
verified inside step 11 by the `frontend-reviewer`. The `design` agent is for design consultation,
interpretation and handoff (step 6).

### Review and correction loops

- **Backend:** Backend Engineer → Developer Tests → Backend Reviewer → Backend Corrections → Re-review.
- **Frontend:** Frontend Engineer → Developer Tests → Frontend Reviewer (Engineering + Design
  Conformance) → Frontend Corrections → Re-review. The Frontend Engineer fixes; the Frontend Reviewer
  independently verifies the corrections.
- **Database:** Proposed Schema/Migration → Database Architect → Approved Design → Implementation →
  Database Verification (re-review by the Database Architect when the implemented change is material
  or the first review identified risks).
- If a finding affects another layer, coordinate the necessary changes and **re-run the affected
  reviews and tests**. No implementation is declared complete while blocking findings remain, and
  **all mandatory reviews happen before the implementation is committed**.
- The general `reviewer` handles cross-cutting or integration concerns (anything spanning layers, or
  not owned by a specialist) and must not duplicate the specialist reviews unnecessarily.

## Review standards

Applies to `database-architect`, `backend-reviewer` and `frontend-reviewer`, and is the format the
general `reviewer` uses as well. Their agent files carry the report skeleton; the rules below are
defined **only here**.

**Standard Review Report** — concise and identical in shape for every reviewer:

```
Review Scope:          what was reviewed
Verdict:               PASS | PASS WITH CHANGES | BLOCKED
Findings:              each with Severity (HIGH | MEDIUM | LOW), File and location, Issue, Impact,
                       Recommended correction
Verification:          what was inspected or tested, and what remains unverified
Final Recommendation:  Proceed | Fix and Re-review | Escalate
```

**Severity rules**

- **HIGH** — blocks progression and commit.
- **MEDIUM** — must be resolved before commit unless the authorised human explicitly accepts it as an
  exception (record the exception in the project status log).
- **LOW** — may be fixed immediately or recorded as technical debt.

**Verdicts:** BLOCKED when any HIGH finding exists (or something essential could not be verified);
PASS WITH CHANGES when only MEDIUM/LOW findings exist; PASS when there is nothing to change. **A PASS
WITH CHANGES verdict does not automatically authorise a commit — the severity rules still apply.**

**Reviewer conduct**

- Do not inflate severity, and do not confuse cosmetic preferences with functional defects.
- Do not certify tests you did not execute: say what you ran and the result; list the rest under
  Verification as unverified.
- Be independent — never the same invocation that implemented the change — and follow
  *Independent Judgment — Evidence Over Agreement*.
- Reviewer expertise is always senior-level, but review against the project's selected readability
  profile; do not demand needless abstraction to show seniority. Preserve project-specific profiles
  and decisions.
- Reviewers never modify implementation code (or designs); the implementing agent corrects and the
  reviewer re-verifies.

## Release workflow

After commit and human acceptance (workflow steps 16–20):

```
Commit / Push
  → Human / Product Owner Acceptance
  → DevOps Agent (only after explicit authorization)
  → Deployment
  → Production Smoke Verification
  → Monitoring
```

The human remains the final authority for acceptance and deployment. The `devops` agent stops for
explicit approval on test failures, destructive operations, production-data risk and cost increases.

## Agent registry

The canonical agent definitions are in `agents/` (installed as `.claude/agents/` in a project).

| Agent | Owns | Invoked |
|---|---|---|
| `design` | design consultation, interpretation and handoff (and the visual-conformance *method* the frontend reviewer follows) | step 6, and on request |
| `database-architect` | independent review of proposed schema/migration designs: normalisation, constraints, indexes, concurrency, tenant isolation, migration safety | step 7, **before** implementation, when the feature introduces or materially changes database structures; re-review after implementation if material or risks were flagged; never for tasks without meaningful database changes |
| `backend` | backend implementation, migrations, API implementation, backend developer tests | step 8 |
| `backend-reviewer` | independent review of backend output before commit — Standard Review Report | step 9 (and re-review after corrections) |
| `frontend` | frontend implementation, frontend developer tests, accessibility, design-system adherence | step 10 |
| `frontend-reviewer` | independent review of frontend output before commit: (A) engineering review and (B) **design conformance** against the approved designs — one report, results kept separate | step 11 (and re-review after corrections) |
| `reviewer` | cross-cutting / integration review; must not duplicate specialist reviews | step 12, when necessary |
| `qa` | API/integration/UI/end-to-end/smoke/critical-journey/regression testing (independent functional validation) | step 13 |
| `security` | security review and lightweight threat modelling, risk-based | step 14 |
| `devops` | deployment and deployment verification | step 18, after authorization |

Implementation agents (`backend`, `frontend`) never self-certify their work as correct or complete —
that determination belongs to the specialist reviewers (and `database-architect` for database design),
`qa`, and ultimately the human. `qa` and `security` retain their own independent responsibilities and
are not replaced by any reviewer.

## Output review

Major technical outputs require independent review before being treated as final — architecture,
technology decisions, database/schema changes, API contracts, backend code, frontend code. The
specialist reviewers perform this; an implementing agent is never the sole authority declaring its own
work correct. Review checks correctness, maintainability, unnecessary complexity, contradictions with
approved decisions, security implications and performance implications, and is reported in the
Standard Review Report.

## Technology decisions

Technology decisions are evidence-based, not adopted because a technology is popular or familiar.
Before introducing a new technology, evaluate as applicable: product requirements, platform
requirements, existing architecture, team capability, ecosystem maturity, scale, performance, cost,
deployment constraints, security, maintainability and operational complexity.

Do not introduce, without a justified requirement and a recorded decision: microservices,
orchestration platforms, message queues, caches, search engines, additional databases,
distributed-systems patterns, or additional language runtimes. A project's existing approved stack and
architecture are preserved unless a future approved decision changes them.

## ADR / RFC process

A lightweight record of meaningful technical decisions (template: `templates/adr-template.md`). Use an
ADR for significant architecture changes, major technology adoption, important data-model decisions,
significant integration decisions, major deployment/infrastructure changes, and decisions that are
difficult or expensive to reverse. Do not require one for trivial details or anything already covered by
an approved decision. When a decision fits cleanly into one of the project's existing decision logs,
record it there instead, to avoid two competing sources of truth.

## Dependency governance

Before adding a meaningful new dependency, consider: why it is actually required, whether existing
project capability already solves the problem, its maintenance health, security risk, licensing (where
relevant), bundle/runtime impact, operational impact and long-term maintainability. Avoid unnecessary
dependencies; do not casually reverse a deliberate "we avoid X" decision without the evaluation that
produced it.

## Accessibility

A normal frontend quality concern, not a pass bolted on at the end. Where applicable verify: semantic
HTML, keyboard usability, form labels, focus management, contrast, accessible error states,
screen-reader compatibility, and the appropriate accessibility standard for the feature. Depth scales
with the product and feature.

## Observability

Introduced by design where appropriate, not bolted on after an incident. Consider: structured logging,
metrics, traces, health checks, audit events, dashboards and alerts. Never log secrets or sensitive
data. Do not create fake observability or unnecessary infrastructure — right-size to the criticality
profile.

## Performance

Introduce review/budgets where the feature or product actually requires them: frontend performance, API
latency, database query performance, resource usage, concurrency, scalability. Do not optimise
prematurely.

## Security / threat modelling

For higher-risk functionality (see Change-risk classification), introduce lightweight threat modelling
before or during implementation, considering as applicable: authentication, authorisation, tenant
isolation, sessions/cookies, validation, injection, XSS, CSRF, CORS, secrets, sensitive data,
dependencies, APIs, payments, webhooks, file handling, configuration and relevant OWASP risks. Depth
scales with actual risk.

## Migrations / backward compatibility

A feature that introduces or materially changes database structures has its proposed schema and
migration plan reviewed by the `database-architect` **before implementation** (workflow step 7). For
relevant database or API changes, explicitly consider: the forward migration, rollback/recovery if it
fails partway or must be reverted, effect on existing data, backward compatibility with clients/code
that have not redeployed yet, deployment ordering, and failure recovery. **Destructive migrations
(dropping/renaming a column or table, narrowing a type) require explicit review** before merging. Do not
build an elaborate process for trivial additive changes.

## Feature flags

Use feature flags when they provide a real, specific benefit: controlled rollout, isolating a risky
feature, a gradual migration, or operational rollback. Do not add one reflexively.

## Reliability / SLIs / SLOs

For production-relevant capabilities consider: service health, failure handling, retries, timeouts,
graceful degradation, and — only where the product needs them — SLIs and SLOs. Do not invent enterprise
reliability requirements the project's criticality profile does not call for.

## Technical debt register

Keep a lightweight register of meaningful gaps (template: `templates/technical-debt.md.template`),
updated when debt is knowingly incurred or resolved. It is not a dumping ground for cosmetic nitpicks,
and an entry is not an instruction to fix it immediately — existing code is revisited when touched by
new work, a defect, a security issue, a material architecture problem or an explicit request. LOW review
findings may be recorded here.

## Project status log

Each project keeps a concise status log (template: `templates/PROJECT_STATUS.md.template`) updated after
every task: date, branch/commit, completed work, tests actually run and their results, deployment/demo
link, blockers, next three tasks, and any MEDIUM-finding exceptions the human accepted. Work is never
marked complete in it unless its tests were actually run and passed. Enforcement by an automated hook is
optional and, where used, is a project-local choice (see `VALIDATION.md` for what is and is not verified).

## Production verification

After a deployment verify as appropriate: application health, critical smoke journeys, migrations
applied cleanly, integrations, monitoring/alerts if configured, and major user-facing functionality. A
successful deploy process is necessary but not sufficient for calling a release successful.

## Incident / postmortem practices

For a production incident: **Stabilise → Determine impact → Identify root cause → Fix → Verify →
Document → Track follow-up actions.** Use blameless postmortems where appropriate. A formal postmortem
is not required for a trivial development-time issue; it is appropriate for anything that affected real
users or real data.

## Adopting framework upgrades (forward-only)

Framework versions are adopted **forward-only** at the next safe task or feature boundary; work in
progress may finish under the previously approved workflow unless the human explicitly authorises
adoption mid-task; completed work is never reopened or retroactively reviewed; project-specific agents,
approval gates, engineering profiles and architecture decisions are preserved. Details: `ADOPTION.md`
and `VERSIONING.md`.

## What the framework does not do

It does not restart a project, repeat completed stages, redo existing architecture without cause,
rewrite working code for style conformity, redesign accepted screens, rewrite existing tests
unnecessarily, refactor unrelated code, change approved business rules, implement any feature, or choose
a project's criticality or readability profile.
