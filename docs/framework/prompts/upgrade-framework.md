# Prompt — upgrade a project to a newer framework version

Give this to Claude Code **inside the project being upgraded**. Replace the bracketed items.

```text
Upgrade THIS project's AI Software Delivery Framework from its current version to <TARGET-VERSION>,
forward-only. This is a framework-only change: do not implement or modify product functionality.

SOURCE: a checkout of the framework at <PATH-TO-FRAMEWORK-CHECKOUT>, tag v<TARGET-VERSION>. Read
docs/VERSIONING.md (the history between this project's version and the target, the compatibility rules and the
update procedure) and docs/ADOPTION.md first.

FIRST (change nothing yet): read docs/framework/FRAMEWORK_VERSION, docs/framework/ADOPTION_RECORD.md,
docs/framework/PROJECT_PROFILE.md, CLAUDE.md and the project's status log. List every compatibility exception
already recorded and confirm none is invalidated by the new version. Establish whether an implementation task
is in progress.

TIMING: if a task is in progress, do NOT interrupt it - report and stop unless I explicitly authorise adoption
mid-task.

PRESERVE: all project-specific configuration (project profile, profiles chosen by the human, CLAUDE.md's
project rules and numbering, coding standards, decisions, design registry, status log, debt register). Replace
only the canonical files: .claude/agents/*.md (merge in any project-specific agents, never delete them),
docs/framework/POLICY.md, docs/framework/VERSIONING.md. Do not reopen completed work or require retrospective
reviews.

DO: (1) replace the canonical files with the target tag's versions; (2) reconcile CLAUDE.md additively with the
target's templates/CLAUDE.md.template; (3) update docs/framework/FRAMEWORK_VERSION and the adoption record
(new version, date, status, applicable agents, exceptions); (4) verify (run scripts/validate.py --project . if
available; otherwise the checklist in docs/ADOPTION.md); (5) update the status log with what you actually ran;
(6) commit and push per this project's workflow, as ONE commit so it can be reverted as a unit.

Do not claim automated enforcement that was not tested. Do not deploy. Do not touch any other repository. STOP
afterwards and report: from/to versions, files changed, verification, exceptions, commit SHA and push status,
rollback command (git revert <sha>), remaining issues.
```
