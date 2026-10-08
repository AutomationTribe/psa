# Prompt — adopt the framework in an existing project

Give this to Claude Code **inside the project that is adopting the framework**. Replace the bracketed
source path. It modifies only that project and never touches another repository.

```text
Adopt AI Software Delivery Framework version 1.1.0 in THIS project, forward-only and without disrupting
existing work. This is a framework-only change: do not implement or modify product functionality.

SOURCE: a checkout of the framework at <PATH-TO-FRAMEWORK-CHECKOUT> (tag v1.1.0). Read, in this order:
docs/ADOPTION.md, docs/PROJECT-CONFIGURATION.md, docs/VERSIONING.md, docs/POLICY.md; then agents/ and
templates/. Treat docs/ and agents/ as canonical (do not edit their content when installing them);
templates/ are the starting point for this project's own configuration.

FIRST, READ THIS PROJECT (change nothing yet): CLAUDE.md, its agent definitions, its engineering/workflow
documentation, coding standards, review gates, Definition of Ready/Done, and its status log (or the
equivalents). Establish: the project's current framework version (an unnumbered earlier adoption counts as
1.0.0), its criticality and code-readability profiles (do NOT choose or change them - if unset, ask me), its
customised agents/gates/approval steps, where it keeps requirements/decisions/API contract/design
registry/tests/deployment, and whether any implementation task is in progress.

TIMING: if an implementation task is in progress, do NOT interrupt it. Report that and stop unless I
explicitly authorise adopting mid-task. Otherwise proceed.

PRESERVE: project-specific requirements, agents, approval gates, engineering profiles and architecture
decisions; the existing division of responsibility (orchestrator = process; design tool = UI/UX design;
Claude Code = implementation; specialist agents = independent review and verification); completed work (do
not reopen it, refactor it or require retrospective reviews). Integrate the framework without silently
replacing any project rule; record any conflict as a compatibility exception instead of resolving it
unilaterally.

DO: (1) install agents/*.md into .claude/agents/, adapting only project-specific names/paths and keeping any
project-specific agents; where an agent of the same name already exists, merge rather than overwrite and list
what differs; (2) install docs/POLICY.md and docs/VERSIONING.md into docs/framework/ and write the version to
docs/framework/FRAMEWORK_VERSION; (3) create docs/framework/PROJECT_PROFILE.md from the template, filled with
what you found (leave unknown fields blank and list them for me); (4) reconcile CLAUDE.md additively with
templates/CLAUDE.md.template - add or reword only the framework rules, keep the project's own rules and
numbering; (5) record the adoption in docs/framework/ADOPTION_RECORD.md (version, date, status, applicable
agents, compatibility exceptions); (6) verify: agent frontmatter valid, reviewer agents have no file-writing
tools, references resolve, wording consistent, QA/Security/human-acceptance/deployment gates intact, any edited
config still parses (run scripts/validate.py --project . if available); (7) update the project's status log per
its own rules with what you actually ran; (8) commit and push per this project's established workflow.

Do not claim automated enforcement that was not actually implemented and tested. Do not deploy. Do not touch
any other repository. STOP afterwards and report: version, files changed, verification performed,
compatibility exceptions, commit SHA and push status, remaining issues.
```
