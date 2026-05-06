# Praxis — Agent Executer

> **Single source of truth**: All agent definitions live in `.github/agents/*.agent.md`.
> This file is the discovery index for OpenAI Codex. Before executing any agent task, read the
> corresponding `.github/agents/<name>.agent.md` file and follow every instruction defined there.

---

## Praxia Agent Index

> **Praxia agents are the action counterparts to Cognia agents.** Each praxia agent reads the corresponding cognia report, proposes concrete fixes or improvements, and applies them **only after explicit human approval**. Without approval, nothing is changed.
>
> **Output file naming**:
> - Code or files were changed → `praxia/{project-name}-praxia-{agent-name}-applied.md`
> - No changes made (suggestions only) → `praxia/{project-name}-praxia-{agent-name}-suggestions.md`

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

## Cognia Input → Praxia Agent Map

Most Cognia reports follow `cognia/{project_name}-{domain}-analysis.md`. Three domains use non-standard names — agents must use the exact paths below:

| Praxia Agent | Cognia Input File(s) |
|---|---|
| praxia-android | `cognia/{project_name}-android-analysis.md` |
| praxia-arch | `cognia/{project_name}-architecture.md` · `cognia/{project_name}-architecture.html` (if present) |
| praxia-backend | `cognia/{project_name}-backend-analysis.md` |
| praxia-frontend | `cognia/{project_name}-frontend-analysis.md` |
| praxia-ios | `cognia/{project_name}-ios-analysis.md` |
| praxia-perf | `cognia/{project_name}-perf-analysis.md` |
| praxia-po | `cognia/{project_name}-po-analysis.md` |
| praxia-reverse | `cognia/{project_name}-reverse-analysis.md` |
| praxia-sec | `cognia/{project_name}-sec-analysis.md` |
| praxia-tech | `cognia/{project_name}-technical-analysis.md` |
| praxia-test | `cognia/{project_name}-test-analysis.md` |
| praxia-ux | `cognia/{project_name}-ui-ux-analysis.md` |

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
4. **Output files are mandatory**: Every agent run has two phases. Phase 1 (proposal) pauses for human approval — no output file is written yet. Phase 2 (outcome) must always write the output file regardless of the approval result: approved changes → applied report; partial or full rejection → suggestions report. Do NOT return the report in chat as a substitute for writing the file.
5. **No domain creep**: Respect each agent's scope boundaries; cross-domain observations belong in a handoff note, not the report body.
6. **Missing Cognia report**: Search only the exact path listed in the agent's Input Source section (see the Cognia Input → Praxia Agent Map above). If the file is absent, renamed, or malformed: state `Cognia report not found at expected path`, do not re-run a full audit, do not invent findings, and ask the human for the correct report path before proceeding.
7. **Shared proposal schema**: Every code-change agent must present each proposed item using the shared format below. Do not invent a local format.

---

## Shared Change Proposal Schema

All code-change agents (android, backend, frontend, ios, perf, sec, tech, test, ux) must present every proposed item in this format during Phase 1. Suggestions-only agents (arch, po, reverse) use their own document-level proposal format but must apply this schema to any individual code-touching items they surface.

```
**[ID] [Short title]**
- **Source finding**: [Section or finding reference from the Cognia report]
- **Confidence**: Confirmed / Inferred
- **Severity**: Critical / High / Medium / Low
- **Files**: `path/to/file`
- **Change**: [Exact description of what will be modified — specific enough to apply without ambiguity]
- **Risk**: Low / Medium / High
- **Rollback**: [How to undo this change if it causes a regression]
- **Validation**: [How to verify the fix is correct — test to run, behaviour to observe, or metric to check]
```

**Field rules:**
- `ID` — sequential number within the proposal (used in approval signals: "approve 1, 3").
- `Source finding` — must reference a specific section or item in the Cognia report; never leave blank.
- `Confidence` — `Confirmed` if the finding is directly evidenced in source files; `Inferred` if derived from context.
- `Severity` — matches the Cognia finding severity; agents may not downgrade severity without noting the reason.
- `Risk` — assessed by the Praxia agent based on blast radius of the change, not the original vulnerability severity.
- `Rollback` — must be actionable (e.g. "revert commit", "restore original middleware order"); never "N/A".
- `Validation` — must be specific (e.g. "run `npm test auth`", "confirm 401 on unauthenticated request"); never "test it".
