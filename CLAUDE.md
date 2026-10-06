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

When the user enters `USSD`, read `docs/tags/USSD.md` and return its last known work completed, current blockers and next steps. Keep USSD paused unless the user explicitly resumes it.
