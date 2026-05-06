# Praxia Agents

> The action layer of the Cognia + Praxia agent system. Praxia agents read audit reports produced by [Cognia](https://github.com/atesibrahim/cognia-agents), propose concrete fixes, and apply them **only after explicit human approval**.

---

## Overview

Praxia is a collection of 12 specialised AI agents for GitHub Copilot that cover every major engineering and product domain. Each agent is paired with a corresponding **Cognia** audit agent:

1. **Cognia** analyses your codebase and produces a detailed report.
2. **Praxia** reads that report, proposes targeted changes, and waits for your go-ahead before touching any file.

This two-step model keeps humans in the loop while eliminating the manual effort of translating audit findings into actual code changes.

---

## Agent Catalogue

| Agent | Reads From | Changes Code? | Domain |
|-------|-----------|:---:|--------|
| `praxia-android` | `cognia-android` report | ✅ | Kotlin/Android fixes |
| `praxia-arch` | `cognia-arch` report | ❌ suggestions only | Architecture redesign |
| `praxia-backend` | `cognia-backend` report | ✅ | Backend / API fixes |
| `praxia-frontend` | `cognia-frontend` report | ✅ | Frontend fixes |
| `praxia-ios` | `cognia-ios` report | ✅ | Swift/iOS fixes |
| `praxia-perf` | `cognia-perf` report | ✅ | Performance fixes |
| `praxia-po` | `cognia-po` report | ❌ suggestions only | Product backlog & user stories |
| `praxia-reverse` | `cognia-reverse` report | ❌ suggestions only | Formal requirements & domain docs |
| `praxia-sec` | `cognia-sec` report | ✅ | Security vulnerability remediation |
| `praxia-tech` | `cognia-tech` report | ✅ | Technical debt fixes |
| `praxia-test` | `cognia-test` report | ✅ test files | Missing test coverage |
| `praxia-ux` | `cognia-ux` report | ✅ a11y/CSS | UX fixes & design specs |

---

## How It Works

```
cognia-<domain>  →  produces  →  cognia/<project>-<domain>-analysis.md
                                          ↓
praxia-<domain>  →  reads report, proposes changes
                                          ↓
                          human approves / rejects
                                          ↓
             praxia/<project>-praxia-<domain>-applied.md     (changes made)
             praxia/<project>-praxia-<domain>-suggestions.md  (no changes)
```

> **Note — three domains use non-standard Cognia report names:**
>
> | Praxia Agent | Cognia report file |
> |---|---|
> | `praxia-arch` | `cognia/<project>-architecture.md` (+ `architecture.html`) |
> | `praxia-tech` | `cognia/<project>-technical-analysis.md` |
> | `praxia-ux` | `cognia/<project>-ui-ux-analysis.md` |
>
> All other agents follow the `cognia/<project>-<domain>-analysis.md` pattern. See the full map in [`AGENTS.md`](AGENTS.md#cognia-input--praxia-agent-map).

---

## Prerequisites — Install Cognia First

Praxia agents are the **action layer**. They depend on audit reports produced by [Cognia](https://github.com/atesibrahim/cognia-agents). To use Praxia properly you must install and run Cognia first:

```bash
# 1. Install Cognia (the audit layer)
npm install -g cognia

# 2. Install Praxia (the action layer)
npm install -g praxia
```

> **Why both?** Cognia scans your codebase and writes a structured report to `cognia/<project>-<domain>-analysis.md`. Praxia reads that report to know exactly what to fix. Without a Cognia report, Praxia has nothing to act on.

See the [Cognia README](https://github.com/atesibrahim/cognia-agents) for full usage instructions for the audit agents.

---

## Installation

### Global install (recommended)

Installing globally makes all agents available in every project on your machine:

```bash
npm install -g praxia
```

The installer runs automatically after `npm install -g` and copies the agent definitions to the correct locations for GitHub Copilot, Claude Code, and Codex CLI.

### Manual / local install

If you prefer to scope agents to a single project, run the installer with the `--local` flag from inside your project directory:

```bash
cd /path/to/your-project
npm install praxia
npx praxia --local
```

### Runtime-specific install

```bash
npx praxia --global --claude    # GitHub Copilot + Claude Code only
npx praxia --global --codex     # Codex CLI only
npx praxia --global --all       # All runtimes (default)
```

### Uninstall

```bash
npx praxia --uninstall           # remove global install
npx praxia --uninstall --local   # remove local install
```

### Manual copy (no Node.js)

Copy the `.github/agents/` directory into your own repository — Copilot will automatically discover the `*.agent.md` files:

```bash
cp -r node_modules/praxia/.github/agents .github/agents
```

---

## Usage

### Recommended two-step workflow

Always run the paired Cognia agent first to generate the audit report, then invoke the corresponding Praxia agent to apply the fixes:

```bash
# Step 1 — audit with Cognia
@cognia-backend analyse my-app

# Step 2 — apply findings with Praxia
@praxia-backend apply backend fixes for my-app
```

### In GitHub Copilot Chat

Invoke any agent by name in chat:

```
@praxia-sec apply security fixes for my-app
@praxia-backend apply backend fixes for my-app
@praxia-test write missing tests for my-app
```

Each agent will:
1. Locate the corresponding Cognia report under `cognia/`.
2. Present a prioritised list of proposed changes.
3. Wait for your explicit approval before modifying any file.

---

## Output Files

| Outcome | File written |
|---------|-------------|
| Changes were applied | `praxia/{project}-praxia-{agent}-applied.md` |
| Suggestions only (no code changed) | `praxia/{project}-praxia-{agent}-suggestions.md` |

---

## Agent Rules

All Praxia agents follow these cross-cutting constraints:

- **Evidence first** — every finding cites at least one concrete file path.
- **Confidence tags** — claims are marked `Confirmed` (directly evidenced) or `Inferred` (best-fit interpretation).
- **No guessing** — missing evidence is reported as `Not found in scanned files`.
- **Two-phase lifecycle** — every agent run has two phases. **Phase 1 (proposal)**: the agent presents its proposed changes and pauses — no output file is written yet, and no files are modified. This pause is intentional; the agent is waiting for your approval. **Phase 2 (outcome)**: after you respond, the agent writes the output file regardless of the result — approved changes produce an applied report; partial or full rejection produces a suggestions report.
- **No domain creep** — each agent stays within its own scope; cross-domain observations go into a handoff note.

---

## Repository Layout

```
.github/
  agents/            # *.agent.md — canonical definition for each Praxia agent
  skills/            # STANDARDS.md per agent (engineering standards and hard gates)
  roster.json        # Single source of truth: active agents, input/output paths, install flags

.claude/
  agents/            # Thin Claude Code agent wrappers (description + canonical reference)
  skills/            # Claude Code skill wrappers (description + argument-hint)

.codex/
  skills/            # Codex CLI skill wrappers (description + argument-hint)

bin/
  install.js         # Installer — derives agent list from roster.json at runtime

scripts/
  sync-wrappers.js   # Sync description/argument-hint from canonical agents to all wrappers
  check-docs.js      # Validate AGENTS.md and README.md mention every active roster entry
  new-skill.sh       # Scaffold a new Praxia agent (files + roster entry snippet)
  install.sh         # Thin shell wrapper for bin/install.js
  uninstall.sh       # Thin shell wrapper for bin/install.js --uninstall

AGENTS.md            # Discovery index (OpenAI Codex / Copilot) + cross-agent rules + shared schemas
package.json
```

**Key maintenance commands:**

```bash
npm run sync:wrappers   # propagate description/argument-hint changes to all wrapper files
npm run check:wrappers  # verify all 36 wrapper files are in sync (use as release gate)
npm run check:docs      # verify AGENTS.md and README.md cover all active roster entries
```

---

## License

MIT
