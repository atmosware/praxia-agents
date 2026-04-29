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
cognia-<domain>  →  produces  →  cognia/<project>-<domain>-report.md
                                          ↓
praxia-<domain>  →  reads report, proposes changes
                                          ↓
                          human approves / rejects
                                          ↓
             cognia/<project>-<domain>-applied.md   (changes made)
             cognia/<project>-<domain>-suggestions.md  (no changes)
```

---

## Prerequisites — Install Cognia First

Praxia agents are the **action layer**. They depend on audit reports produced by [Cognia](https://github.com/atesibrahim/cognia-agents). To use Praxia properly you must install and run Cognia first:

```bash
# 1. Install Cognia (the audit layer)
npm install -g cognia

# 2. Install Praxia (the action layer)
npm install -g praxia
```

> **Why both?** Cognia scans your codebase and writes a structured report to `cognia/<project>-<domain>-report.md`. Praxia reads that report to know exactly what to fix. Without a Cognia report, Praxia has nothing to act on.

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
| Changes were applied | `cognia/{project}-{agent}-applied.md` |
| Suggestions only (no code changed) | `cognia/{project}-{agent}-suggestions.md` |

---

## Agent Rules

All Praxia agents follow these cross-cutting constraints:

- **Evidence first** — every finding cites at least one concrete file path.
- **Confidence tags** — claims are marked `Confirmed` (directly evidenced) or `Inferred` (best-fit interpretation).
- **No guessing** — missing evidence is reported as `Not found in scanned files`.
- **Output files are mandatory** — the task is not complete until the output file is written.
- **No domain creep** — each agent stays within its own scope; cross-domain observations go into a handoff note.

---

## Repository Layout

```
.github/
  agents/          # *.agent.md — one file per Praxia agent
  skills/          # Shared skill definitions
AGENTS.md          # Discovery index (used by OpenAI Codex / Copilot)
package.json
```

---

## License

MIT
