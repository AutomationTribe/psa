# Validation and honest limits

Framework version 1.1.0. This document records what was checked, how, and — equally important — what is
**not** enforced or was **not** verified. Do not claim more than this in a project.

## 1. Automated structural validation — `python3 scripts/validate.py`

Standard library only. Run it before every release and after every change. `--project PATH` validates an
adopting project's installed copy (agents, installed docs, resolvable references, no unfilled profile
placeholders).

| Check | Result at 1.1.0 |
|---|---|
| All 10 agents present; frontmatter has name/description/tools/model; name equals filename | Pass |
| Reviewer-type agents (`database-architect`, `backend-reviewer`, `frontend-reviewer`, `reviewer`, `security`) list no Write/Edit/NotebookEdit tool | Pass |
| Every `docs/framework/...` reference in agents resolves (mapped to the repository's file) | Pass |
| Workflow steps 1–20 present; every agent named in the registry | Pass |
| Version consistent across `VERSION`, `CHANGELOG.md`, `docs/POLICY.md`, `docs/VERSIONING.md` | Pass |
| Templates, prompts and hook example present; hook example is valid JSON | Pass |
| Relative Markdown links resolve | Pass |
| No application-specific terms (product/company/vendor names), no secret patterns, no absolute user paths, no e-mail addresses, no unexpected URLs | Pass |

The validator checks structure and consistency only. It cannot tell whether an agent *behaves* well.

## 2. Fresh-session permission verification (Claude Code 2.1.259)

Agents were copied into an empty temporary git repository and each started in a new headless session
(`claude -p --agent <name>`), asked to list its available tools. Observed:

| Agent | Tools reported | Write/Edit available |
|---|---|---|
| `backend-reviewer` | Bash, Read | No |
| `frontend-reviewer` | Bash, Read, Stitch read tools (get_screen, list_screens, get_project) | No |
| `reviewer` | Bash, Read | No |
| `database-architect` | Bash, Read | No |
| `security` | Bash, Read, WebFetch | No |
| `backend` (control) | Bash, Read, Write, Edit | Yes |

Notes: the sessions did not report Grep, Glob or TodoWrite although the files list them — the reason (tool
names differing in this CLI version, or deferred tools) was not investigated. This was a self-report by the
model in each session, corroborated by the allowlists; it is not an adversarial test.

## 3. Stop-hook example (`templates/claude-settings.stop-hook.example.json`)

The command was executed in a temporary git repository: clean tree → `{}`; changes without the status file →
block decision; changes including the status file (including a newly created directory) → `{}`; only
`.DS_Store` changed → `{}`. Testing found and fixed one defect (untracked directories collapsing to a single
path; fixed with `git status -uall`). **Not verified:** that Claude Code actually invokes this hook and honours
the block in a live session of your project. Verify it in your project before relying on it.

## 4. What is NOT technically enforced

- **Review gates, the 20-step workflow, severity rules, risk classification, Definition of Ready/Done, human
  acceptance and deployment authorisation are process rules.** Nothing blocks a session from skipping them;
  they work because the agents and `CLAUDE.md` instruct it and the human insists. A status-log hook is the
  only mechanical check offered, and it is optional.
- **Reviewers are read-only by tool allowlist only.** They keep `Bash` (needed to run tests and inspect
  state), and a shell can write files. "Reviewers never modify implementation code" is therefore an
  instruction, not a technical guarantee. For a hard guarantee, restrict `Bash` with permission rules in the
  project's settings, or run reviewers in a read-only checkout.
- **Independent judgment** is a behavioural instruction; it is not testable by this repository's validator.
- **Frontend-reviewer design conformance** needs access to the approved design (saved reference images or a
  design-tool MCP). The Stitch tool names in its frontmatter assume that MCP server; if you use another
  design tool, edit the project copy and record it as a compatibility exception. The agent's behaviour
  against a real design was not exercised in this repository.
- `devops` approval gates (failed tests, destructive operations, cost) are instructions; nothing prevents
  deployment commands from running if the human has permitted them in settings.

## 5. Not verified

- Behaviour of each agent on a real task (only tool availability was observed).
- The adoption and upgrade prompts were reviewed for consistency but not executed against a real project in
  this repository.
- Behaviour on Claude Code versions other than 2.1.259.

## 6. Re-validation procedure

1. `python3 scripts/validate.py` must exit 0.
2. Re-run the section 2 fresh-session check if any agent's `tools` line changed.
3. Re-run the section 3 hook test if the hook example changed.
4. Update this file with the date, version and any changed result before tagging.
