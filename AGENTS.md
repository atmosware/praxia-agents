# Praxis — Agent Executer

> **Single source of truth**: All agent definitions live in `.github/agents/*.agent.md`.
> This file is the discovery index for OpenAI Codex. Before executing any agent task, read the
> corresponding `.github/agents/<name>.agent.md` file and follow every instruction defined there.

---

## Praxia Agent Index

> **Praxia agents are the action counterparts to Cognia agents.** Each praxia agent reads the corresponding cognia report, proposes concrete fixes or improvements, and applies them **only after explicit human approval**. Without approval, nothing is changed.
>
> **Output file naming**:
> - Code or files were changed → `cognia/{project-name}-{agent-name}-applied.md`
> - No changes made (suggestions only) → `cognia/{project-name}-{agent-name}-suggestions.md`

| Agent | Reads From | Can Change Code? | Domain | Trigger |
|-------|-----------|-----------------|--------|---------|
| praxia-android | `cognia-android` report | Yes | Android fixes | Apply Android audit findings |
| praxia-arch | `cognia-arch` report | No (suggestions only) | Architecture redesign | Propose target architecture |
| praxia-backend | `cognia-backend` report | Yes | Backend fixes | Apply backend audit findings |
| praxia-frontend | `cognia-frontend` report | Yes | Frontend fixes | Apply frontend audit findings |
| praxia-ios | `cognia-ios` report | Yes | iOS fixes | Apply iOS audit findings |
| praxia-perf | `cognia-perf` report | Yes | Performance fixes | Apply performance bottleneck fixes |
| praxia-po | `cognia-po` report | No (suggestions only) | Product backlog | Produce refined backlog & user stories |
| praxia-reverse | `cognia-reverse` report | No (suggestions only) | Documentation | Produce formal requirements & domain docs |
| praxia-sec | `cognia-sec` report | Yes | Security fixes | Remediate security vulnerabilities |
| praxia-tech | `cognia-tech` report | Yes | Tech debt fixes | Apply technical quality improvements |
| praxia-test | `cognia-test` report | Yes (test files) | Test writing | Write missing tests |
| praxia-ux | `cognia-ux` report | Yes (a11y/CSS) | UX fixes & specs | Apply UX fixes; produce design specs |

---

## How to Use

When a task matches one of the agents above:

1. Read the canonical `.github/agents/<name>.agent.md` file.
2. Follow every instruction — role, responsibilities, constraints, approach, output format — exactly as written there.
3. Do not skip, reorder, or summarise any steps.

---

## Cross-Agent Rules

1. **Evidence first**: Every material finding must cite at least one concrete file path.
2. **Tag confidence**: Mark claims as `Confirmed` (directly evidenced) or `Inferred` (best-fit interpretation).
3. **Missing evidence**: State `Not found in scanned files` rather than guessing.
4. **Output files are mandatory**: The analysis is not complete until the designated output file is written. Do NOT return the full report in chat as a substitute.
5. **No domain creep**: Respect each agent's scope boundaries; cross-domain observations belong in a handoff note, not the report body.
