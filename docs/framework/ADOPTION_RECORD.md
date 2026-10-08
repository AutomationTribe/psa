# Framework adoption record — Personal Safety App (PSA)

| Field | Value |
|---|---|
| Framework version | 1.1.0 |
| Framework source | `https://github.com/AutomationTribe/ai-software-delivery-framework.git`, tag `v1.1.0` (annotated tag object `8c3daf488c14faac6b1a8f98edc801cd7bb212a2`), commit `31dd835e4854418a67b0e13b020b0a7b79c84cd2` |
| Adopted on | 2026-10-08 |
| Adoption status | Adopted (forward-only; authorised by the Product Owner during an in-progress task, 2026-10-08) |
| Previous framework version | None (PSA had no earlier framework adoption; it ran under its own stage-gate process) |
| Applicable agents | `design`, `database-architect`, `backend`, `backend-reviewer`, `frontend`, `frontend-reviewer`, `reviewer`, `qa`, `security`, `devops` — all ten installed unmodified; each is invoked only for the layers a task touches |
| Previously completed work | Not reopened; no retrospective reviews required. |
| Work in progress at adoption | Database slice: `V3__least_privilege_runtime_roles.sql`, its tests and the read-only database-review tooling were uncommitted and awaiting Product Owner review. The Product Owner explicitly authorised adopting during this task; that work continues unchanged and is not part of the adoption commit. |
| Automated enforcement actually in place | None added by this adoption. The optional status-log Stop hook is not installed. An unverified hook exists in the uncommitted database-review tooling (it did not run when tested on 2026-10-08) and is not relied on. |
| Verification | `scripts/validate.py` from the v1.1.0 checkout: 122 passed, 0 failed on the framework itself; `--project` results recorded in `docs/PROJECT_STATUS.md`. |

## Project rules preserved (not exceptions)

- PSA's stage gates in `CLAUDE.md` (produce drafts, internal review, wait for the user's explicit `APPROVE` / `MODIFY` / `PAUSE`, no commit/push/publish before approval) stay in force. Framework step 16 ("commit/push according to repository policy") means this policy; the framework adds no weaker rule.
- Profiles: criticality `HIGH-CRITICALITY` and readability `SENIOR` per Stage 4; Stage 4 mandatory release gates remain in force.
- USSD stays paused; the `USSD` tag behaviour is unchanged.
- Project status log keeps PSA's own format (`docs/PROJECT_STATUS.md`: date, branch/commit, work, tests actually run, deployment, blockers, exactly three next tasks), which meets the framework's content requirements.

## Compatibility exceptions

Each deliberate difference between this project and the canonical framework files (never an edit to the
canonical files themselves).

| Exception | Reason | Accepted by | Date |
|---|---|---|---|
| **Database Architect project overlay (proposed, not yet in force).** PSA drafted a stricter reviewer in the uncommitted working tree: read-only (`Read`, `Grep`, `Glob`; no `Bash`), judges evidence supplied by the parent session, mandatory for every database-affecting task and for pre/post-deployment reviews per environment, with its own report template. Until the Product Owner approves it, the canonical agent applies unmodified. When approved, its differences from the canonical `database-architect` (tool list, invocation breadth, evidence protocol, report vocabulary mapped to the Standard Review Report) are recorded here. | Safety-sensitive, high-criticality profile; the hook-based guard could not be verified, so tool removal is the enforced control. | **Pending Product Owner approval** | 2026-10-08 |
| **Native mobile UI.** PSA's clients are native Android (Kotlin) and iPhone (Swift) plus a React/Next.js dashboard. The framework's `frontend`/`frontend-reviewer` are web- and design-tool-oriented; no dedicated native-mobile reviewer exists. | Framework limitation; no mobile code exists yet. To be revisited before the first mobile slice (use the generic reviewer standards and real-device evidence required by Stage 4). | Pending Product Owner decision | 2026-10-08 |
| **No design tool configured.** `design` and `frontend-reviewer` design conformance need a design integration and registry; PSA has none yet. | No UI has been designed. Fill the design fields in `docs/framework/PROJECT_PROFILE.md` before the first UI slice. | Noted | 2026-10-08 |
| **Status log format.** PSA keeps its own `docs/PROJECT_STATUS.md` layout instead of the template's "Latest entry" layout. | Preserves the existing handoff record; content requirements are met. | Noted | 2026-10-08 |

## Upgrade history

| Date | From | To | Commit | Notes |
|---|---|---|---|---|
| 2026-10-08 | — | 1.1.0 | `018f17fcbde1db58cec0daf54a089242de402def` | Initial adoption, forward-only, authorised mid-task by the Product Owner. |
