# Prompt — bootstrap a new project on the framework

Give this to Claude Code **inside the new project's repository**. Replace the bracketed items.

```text
Set up THIS new project on AI Software Delivery Framework version 1.1.0. This is a setup-only task: do not
implement any product functionality.

SOURCE: a checkout of the framework at <PATH-TO-FRAMEWORK-CHECKOUT> (tag v1.1.0). Read docs/ADOPTION.md
("New-project bootstrap"), docs/PROJECT-CONFIGURATION.md and docs/POLICY.md first.

PROJECT: <NAME> - <one-line description> - stack (if known): <STACK> - hosting (if known): <HOSTING>.

DO: (1) copy agents/*.md into .claude/agents/ unchanged; (2) install docs/POLICY.md and docs/VERSIONING.md into
docs/framework/ and write 1.1.0 to docs/framework/FRAMEWORK_VERSION; (3) from templates/, create CLAUDE.md,
docs/framework/PROJECT_PROFILE.md, docs/framework/ADOPTION_RECORD.md, docs/PROJECT_STATUS.md, a coding
standards document, docs/technical-debt.md and docs/decisions/ (with the ADR template), filling in only what
is known; (4) ASK ME to choose the criticality profile (PROTOTYPE / MVP / PRODUCTION / HIGH-CRITICALITY) and
the readability profile (MID-LEVEL / SENIOR) - do not choose for me, and leave them marked "pending" until I
answer; (5) leave every unknown path in PROJECT_PROFILE.md blank and list the blanks for me; (6) run
scripts/validate.py --project . if available and fix anything it reports in the installed files; (7) record
the adoption and what you ran in docs/PROJECT_STATUS.md; (8) commit and push per this project's workflow.

Do not deploy. Do not touch any other repository. STOP afterwards and report what you created, the profile
questions still open, the blanks to fill, verification performed, and the commit SHA.
```
