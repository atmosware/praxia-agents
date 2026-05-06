# Contributing to Praxia

Thank you for contributing. This document covers everything you need to add, edit, validate, or deprecate agents in the framework.

---

## Prerequisites

- **Node.js ≥ 18** (for the installer and validator scripts)
- **bash** (for the agent scaffold generator)
- Git — clone the repo and work on a feature branch

```bash
git clone https://github.com/atesibrahim/praxia-agents.git
cd praxia-agents
```

---

## Repository Layout

```
.github/
  agents/       ← Canonical agent definitions (*.agent.md) — one per agent
  skills/       ← Optional per-agent engineering standards (STANDARDS.md)
                   Present for: android, backend, frontend, ios, perf, sec, tech, test, ux
  roster.json   ← Single source of truth for all agents

.claude/agents/    ← Claude Code agent wrappers (frontmatter + canonical reference)
.claude/skills/    ← Claude Code skill wrappers (description + argument-hint)
.codex/skills/     ← Codex CLI skill wrappers (description + argument-hint)

bin/install.js     ← npm package installer (reads roster.json — no manual AGENTS list)
scripts/           ← Developer tooling
```

---

## Running Validators

Always run both validators before opening a PR:

```bash
# Check that runtime wrapper descriptions/hints match canonical definitions
npm run check:wrappers   # exit 0 = in sync, exit 1 = drift detected

# Check that AGENTS.md and README.md are consistent with roster.json
npm run check:docs       # exit 0 = consistent, exit 1 = missing entries
```

Or run both at once:

```bash
npm run check:wrappers && npm run check:docs
```

Fix any reported failures **before** pushing. The PR checklist below requires both to pass.

---

## Understanding the Praxia Model

Praxia is the **action layer** for Cognia reports:

1. **Cognia** audits your codebase and writes a report to `cognia/<project>-<domain>-analysis.md`.
2. **Praxia** reads that report, proposes concrete fixes or improvements, and waits for your go-ahead.
3. After approval, Praxia applies the approved changes and writes its outcome to `praxia/`.

Every Praxia agent run has two phases:

- **Phase 1 — Proposal**: the agent presents proposed changes and pauses. No files are written or modified. This pause is intentional.
- **Phase 2 — Outcome**: after the human responds, the agent writes the output report regardless of the result.
  - Approved changes → `praxia/{project}-praxia-{domain}-applied.md`
  - Partial or full rejection → `praxia/{project}-praxia-{domain}-suggestions.md`

---

## Adding a New Agent

### 1 — Scaffold the files

Use the generator script — it creates all required stubs and prints the registration steps:

```bash
bash scripts/new-skill.sh <agent-name>                    # code-change agent (default)
bash scripts/new-skill.sh <agent-name> --suggestions-only # suggestions-only agent (no STANDARDS.md)
```

`<agent-name>` must start with `praxia-` and use lowercase letters and hyphens (e.g. `praxia-graphql`, `praxia-infra`).

The script creates:

| File | Always? |
|---|---|
| `.github/agents/<name>.agent.md` | Yes |
| `.github/skills/<name>/STANDARDS.md` | Code-change agents only |
| `.claude/agents/<name>.md` | Yes |
| `.claude/skills/<name>/SKILL.md` | Yes |
| `.codex/skills/<name>/SKILL.md` | Yes |

### 2 — Fill in the stubs

Replace every `TODO:` placeholder in each generated file:

| File | Key sections to fill |
|---|---|
| `.github/agents/<name>.agent.md` | `description`, `argument-hint`, Role, When to Use, Change Catalogue, Constraints, Output File |
| `.github/skills/<name>/STANDARDS.md` | Domain-specific Hard Gate rules and Guidance heuristics *(code-change agents only)* |
| `.claude/agents/<name>.md` | `description` (paste from canonical agent) |
| `.claude/skills/<name>/SKILL.md` | `description`, `argument-hint` (paste from canonical agent) |
| `.codex/skills/<name>/SKILL.md` | `description`, `argument-hint` (paste from canonical agent) |

**Required frontmatter for every canonical agent (`.github/agents/<name>.agent.md`):**

```yaml
name: praxia-<name>
description: 'Use after cognia-<name> has produced its report. ...'
argument-hint: 'Provide the project name so the agent can locate the cognia-<name> report, or ...'
```

**STANDARDS.md preamble (required for code-change agents):**

Every `STANDARDS.md` must open with the two-tier preamble:

```markdown
> Standards are divided into two tiers:
> - **Hard Gate** — a change that violates this must be flagged as a suggestion instead of applied.
> - **Guidance** — apply when reasonable; note the violation but do not block the fix.
>
> Items marked `[Guidance]` are heuristics. All unmarked items are Hard Gates.
```

All agent definitions must follow the cross-agent rules and shared schema defined in [`AGENTS.md`](AGENTS.md):

- Every proposed item uses the **Shared Change Proposal Schema** (ID, source finding, confidence, severity, files, change, risk, rollback, validation).
- Missing Cognia reports are reported as `Cognia report not found` — never invent findings.
- Output files are always written at Phase 2 completion, regardless of approval outcome.

### 3 — Register the agent

Add an entry to **`.github/roster.json`**. The scaffold prints a ready-to-paste snippet. Template:

**Code-change agent (tier 1):**

```json
{
  "name": "praxia-<name>",
  "phase": "remediation",
  "tier": "1",
  "agent_path": ".github/agents/praxia-<name>.agent.md",
  "standards_path": ".github/skills/praxia-<name>/STANDARDS.md",
  "inputs": ["cognia/{project_name}-<name>-analysis.md"],
  "outputs": [
    "praxia/{project_name}-praxia-<name>-applied.md",
    "praxia/{project_name}-praxia-<name>-suggestions.md"
  ],
  "installer": true,
  "status": "active"
}
```

**Suggestions-only agent (tier 2):**

```json
{
  "name": "praxia-<name>",
  "phase": "remediation",
  "tier": "2",
  "agent_path": ".github/agents/praxia-<name>.agent.md",
  "inputs": ["cognia/{project_name}-<name>-analysis.md"],
  "outputs": ["praxia/{project_name}-praxia-<name>-suggestions.md"],
  "installer": true,
  "status": "active"
}
```

> **Non-standard Cognia report names**: three existing domains use filenames that differ from the `<domain>-analysis.md` pattern (`architecture.md`, `technical-analysis.md`, `ui-ux-analysis.md`). If your agent reads a non-standard Cognia report, match the exact filename in the `inputs[]` array and update the Cognia Input → Praxia Agent Map table in `AGENTS.md`.

`bin/install.js` and `check:wrappers` read the roster automatically — no other scripts need editing.

### 4 — Sync and validate

```bash
npm run sync:wrappers    # propagate description/argument-hint from canonical → wrappers
npm run check:wrappers   # must exit 0
npm run check:docs       # must exit 0
```

If `check:wrappers` reports DRIFT, run `npm run sync:wrappers` first, then re-check.

### 5 — Update documentation

Add the new agent to:
- `AGENTS.md` — agent index table and Cognia Input → Praxia Agent Map
- `README.md` — agent catalogue table

`npm run check:docs` will tell you exactly which entries are missing.

---

## Editing an Existing Agent

1. Edit the canonical file: `.github/agents/<name>.agent.md` (and `.github/skills/<name>/STANDARDS.md` if it exists).
2. If `description` or `argument-hint` changed, run `npm run sync:wrappers` to propagate to all runtime wrappers.
3. If you changed `inputs[]` or `outputs[]` in `.github/roster.json`, update the Cognia Input → Praxia Agent Map in `AGENTS.md` and run `npm run check:docs`.
4. Run both validators — exit 0 required for both before PR.

---

## Deprecating an Agent

1. Set `"status": "deprecated"` in `.github/roster.json` for the entry.
2. Add a deprecation notice to the top of the `.github/agents/<name>.agent.md` body.
3. Update `AGENTS.md` and `README.md` to remove or mark the entry.
4. Run `npm run check:docs` to confirm consistency.

Deprecated agents are excluded from installation and wrapper validation automatically — both scripts filter on `status === "active"`.

---

## Commit Conventions

Use conventional commit format:

| Type | Use for |
|---|---|
| `feat` | New agent, new script, new section in an agent definition |
| `fix` | Bug fix in a procedure, wrong output path, broken validator |
| `docs` | README, CONTRIBUTING, AGENTS.md, comment-only changes |
| `refactor` | Restructuring an existing agent without changing behaviour |
| `chore` | Dependency updates, version bumps, config changes |

Examples:

```
feat: add praxia-graphql agent (code-change, tier 1)
fix: praxia-tech input path aligned with cognia-tech output (technical-analysis.md)
docs: update README agent catalogue and repository layout
chore: bump version to 1.1.0
```

---

## PR Checklist

Before requesting review, confirm all of these:

- [ ] `npm run check:wrappers` exits 0
- [ ] `npm run check:docs` exits 0
- [ ] New agent registered in `.github/roster.json` with `installer: true` and `status: "active"`
- [ ] All `TODO:` placeholders replaced in every generated file
- [ ] `description` and `argument-hint` accurately describe the agent's trigger and outputs
- [ ] New agent appears in `AGENTS.md` (index table + Cognia Input → Praxia Agent Map) and `README.md`
- [ ] `inputs[]` paths in roster match the exact Cognia output filenames
- [ ] `outputs[]` paths in roster match the output paths stated in the canonical agent file
- [ ] STANDARDS.md (if present) uses the two-tier Hard Gate / Guidance preamble
- [ ] Canonical agent uses the Shared Change Proposal Schema reference in Phase 1
- [ ] Output template uses `Approval status` and `Approval details` fields (not `Approval received`)
