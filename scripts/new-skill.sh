#!/usr/bin/env bash
# new-skill.sh — Scaffold a new Praxia agent
#
# Usage:
#   bash scripts/new-skill.sh <agent-name>
#   bash scripts/new-skill.sh <agent-name> --suggestions-only   # no code changes, no STANDARDS.md (tier 2)
#   bash scripts/new-skill.sh <agent-name> --phase <phase>      # override phase (default: remediation)
#
# Examples:
#   bash scripts/new-skill.sh praxia-graphql
#   bash scripts/new-skill.sh praxia-infra --suggestions-only
#   bash scripts/new-skill.sh praxia-mobile --phase remediation
#
# Files created:
#   .github/agents/<name>.agent.md         canonical agent definition (always)
#   .github/skills/<name>/STANDARDS.md     engineering standards     (code-change agents only)
#   .claude/agents/<name>.md               Claude Code agent wrapper (always)
#   .claude/skills/<name>/SKILL.md         Claude Code skill wrapper (always)
#   .codex/skills/<name>/SKILL.md          Codex CLI skill wrapper   (always)

set -euo pipefail

# ── Argument parsing ──────────────────────────────────────────────────────────
AGENT_NAME=""
SUGGESTIONS_ONLY=false
PHASE="remediation"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --suggestions-only) SUGGESTIONS_ONLY=true; shift ;;
    --phase)            PHASE="$2"; shift 2 ;;
    --*)                echo "Unknown option: $1"; exit 1 ;;
    *)
      if [[ -z "$AGENT_NAME" ]]; then
        AGENT_NAME="$1"
      else
        echo "Unexpected argument: $1"; exit 1
      fi
      shift ;;
  esac
done

if [[ -z "$AGENT_NAME" ]]; then
  echo "Usage: bash scripts/new-skill.sh <agent-name> [--suggestions-only] [--phase <phase>]"
  exit 1
fi

# Validate name: must start with praxia- and use lowercase letters, digits, hyphens only
if [[ ! "$AGENT_NAME" =~ ^praxia-[a-z0-9][a-z0-9-]*$ ]]; then
  echo "Error: agent name must start with 'praxia-' and use lowercase letters, digits, and hyphens."
  echo "       Example: praxia-graphql"
  exit 1
fi

TIER=$( [[ "$SUGGESTIONS_ONLY" == true ]] && echo "2" || echo "1" )
DOMAIN="${AGENT_NAME#praxia-}"   # strip the praxia- prefix for use in file paths
TODAY=$(date +%Y-%m-%d)
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

AGENT_FILE="$ROOT/.github/agents/$AGENT_NAME.agent.md"
STANDARDS_FILE="$ROOT/.github/skills/$AGENT_NAME/STANDARDS.md"
CLAUDE_AGENT_FILE="$ROOT/.claude/agents/$AGENT_NAME.md"
CLAUDE_SKILL_DIR="$ROOT/.claude/skills/$AGENT_NAME"
CODEX_SKILL_DIR="$ROOT/.codex/skills/$AGENT_NAME"

echo ""
echo "Scaffolding Praxia agent: $AGENT_NAME"
echo "  phase=$PHASE  tier=$TIER  suggestions-only=$SUGGESTIONS_ONLY"
echo "──────────────────────────────────────────────────────"

# Guard: abort if any target file already exists
GUARDS=("$AGENT_FILE" "$CLAUDE_AGENT_FILE" "$CLAUDE_SKILL_DIR/SKILL.md" "$CODEX_SKILL_DIR/SKILL.md")
[[ "$SUGGESTIONS_ONLY" == false ]] && GUARDS+=("$STANDARDS_FILE")
for f in "${GUARDS[@]}"; do
  if [[ -e "$f" ]]; then
    echo "Error: '$f' already exists. Remove it or choose a different name."
    exit 1
  fi
done

mkdir -p \
  "$(dirname "$AGENT_FILE")" \
  "$CLAUDE_SKILL_DIR" \
  "$CODEX_SKILL_DIR"

[[ "$SUGGESTIONS_ONLY" == false ]] && mkdir -p "$(dirname "$STANDARDS_FILE")"

# ── 1. .github/agents/<name>.agent.md ────────────────────────────────────────
cat > "$AGENT_FILE" << AGENT_EOF
---
name: $AGENT_NAME
description: 'TODO: one-line description. Use after cognia-$DOMAIN has produced its report. Proposes and (with human approval) applies ...'
argument-hint: 'Provide the project name so the agent can locate the cognia-$DOMAIN report, or describe the focus area (e.g. "TODO: example focus").'
---

# $AGENT_NAME

## Role
**TODO: Senior [Role Title] — Fixer** — Read the cognia-$DOMAIN analysis report, translate every finding into a concrete, scoped $( [[ "$SUGGESTIONS_ONLY" == true ]] && echo "proposal" || echo "code change" ), and present the full proposal for human approval. $( [[ "$SUGGESTIONS_ONLY" == true ]] && echo "This agent never touches source code; its output is a formal proposal document." || echo "Apply only the approved changes, then report what was done and what remains as suggestions." )

## When to Use
- After \`cognia-$DOMAIN\` has completed its analysis

---

## Input Source

1. Read \`cognia/{project_name}-$DOMAIN-analysis.md\` — the cognia-$DOMAIN report.
2. Read the source files cited in the report.
3. Do not re-run the full audit — build on the cognia report.
4. If the report is not found at the expected path, state \`Cognia report not found\`, do not invent findings, and ask the human for the correct path before proceeding.

---

## Human Approval Guardrail — MANDATORY

This agent proposes changes and STOPS until the human approves.

### Phase 1 — Propose (present and STOP)
1. List every proposed $( [[ "$SUGGESTIONS_ONLY" == true ]] && echo "item" || echo "change" ) as a numbered item using the **Shared Change Proposal Schema** defined in \`AGENTS.md\`$( [[ "$SUGGESTIONS_ONLY" == false ]] && echo ", grouped by type." || echo "." )
2. $( [[ "$SUGGESTIONS_ONLY" == true ]] && echo "For each: what the proposal covers and the trade-offs." || echo "Every item must include all schema fields: source finding, confidence, severity, files, change, risk, rollback, and validation plan." )
3. $( [[ "$SUGGESTIONS_ONLY" == true ]] && echo "**STOP. Do not write the output file until the human explicitly approves the proposal or requests modifications.**" || echo "**STOP. Make zero file changes until the human explicitly approves.**" )

### Phase 2 — $( [[ "$SUGGESTIONS_ONLY" == true ]] && echo "Finalise (after approval or rejection)" || echo "Execute (only approved items)" )
$( if [[ "$SUGGESTIONS_ONLY" == true ]]; then
echo "- On approval: incorporate any requested modifications, then write the final suggestions report."
echo "- On full rejection: write the suggestions report noting that the proposal was not accepted and recording the human's stated reasons or direction for a future attempt."
else
echo "- Apply each approved change to the source files."
echo "- Record the exact files and lines modified."
echo "- For unapproved or rejected items, write them into the suggestions section of the report."
fi )

### Approval signals
| Signal | Action |
|--------|--------|
$( if [[ "$SUGGESTIONS_ONLY" == true ]]; then
echo '| "approve" / "looks good" / "proceed" | Write the final report as presented |'
echo '| "approve with changes: [details]" | Incorporate changes, then write |'
echo '| "reject all" / "cancel" | Write suggestions report noting the proposal was not accepted |'
echo '| Silence or ambiguity | Ask for explicit confirmation before writing |'
else
echo '| "approve all" / "proceed" | Apply every proposed item |'
echo '| "approve 1, 3, 5" | Apply only the listed items |'
echo '| "reject N" / "skip N" | Record as suggestion; do not apply |'
echo '| "reject all" / "none" | Write suggestions report; do not touch any source file |'
echo '| Silence or ambiguity | Ask for explicit confirmation before touching any file |'
fi )

---
$( if [[ "$SUGGESTIONS_ONLY" == false ]]; then
echo ""
echo "## Engineering Principles — MANDATORY"
echo ""
echo "Read \`.github/skills/$AGENT_NAME/STANDARDS.md\` and apply every standard there before writing any code change. A change that violates a Hard Gate must be flagged as a suggestion instead of applied."
echo ""
echo "**Non-negotiable rules (apply to every single change)**:"
echo "- **No structural changes**: Fix in place. Do not rename files, reorganise modules, or change architectural layer boundaries unless explicitly instructed."
echo "- **SOLID / DRY / KISS / YAGNI**: Respect all principles as defined in STANDARDS.md."
echo "- Every applied change must build and pass existing tests."
echo ""
echo "---"
fi )

## Change Catalogue — TODO: Scope

TODO: List the categories of changes this agent makes. See existing agents for examples.

---

## Output File

**Writing the output file is mandatory. See Cross-Agent Rules in \`AGENTS.md\` for the two-phase lifecycle.**

$( if [[ "$SUGGESTIONS_ONLY" == true ]]; then
echo "- Always: \`praxia/{project_name}-$AGENT_NAME-suggestions.md\`"
else
echo "- If any source files were changed: \`praxia/{project_name}-$AGENT_NAME-applied.md\`"
echo "- If no source files were changed: \`praxia/{project_name}-$AGENT_NAME-suggestions.md\`"
fi )
- Write or overwrite the output file using the available file-writing mechanism. Ensure the parent directory exists. Do not append.
- Do NOT return the report in chat as a substitute for writing the file.

---

## Output Format

\`\`\`
# Praxia $( echo "$DOMAIN" | awk '{print toupper(substr($0,1,1)) substr($0,2)}' ) Report — [Project Name]

> **Status**: $( [[ "$SUGGESTIONS_ONLY" == true ]] && echo "[Suggestions only — no source files were modified.]" || echo "[N changes applied / Suggestions only]" )
> **Approval status**: Approved / Partially approved / Rejected / Pending
> **Approval details**: [approval phrase, approved item IDs, rejected item IDs, date]
> **Source report**: \`cognia/[project_name]-$DOMAIN-analysis.md\`

$( [[ "$SUGGESTIONS_ONLY" == false ]] && echo "## Applied Changes" || echo "## Proposed Changes" )

### [TODO: Section Title]
- **Files modified**: \`path/to/file\`
- **What changed**: [Before → After description]
- **Finding addressed**: [cognia report reference]

## Suggestions (Proposed — Not Applied)

### [Title]
- **Proposed change**: [Description]
- **Files affected**: \`path/to/file\`
- **Why not applied**: [Requires further investigation / Rejected by human / Out of scope]
\`\`\`
AGENT_EOF

echo "  created  .github/agents/$AGENT_NAME.agent.md"

# ── 2. .github/skills/<name>/STANDARDS.md (code-change agents only) ───────────
if [[ "$SUGGESTIONS_ONLY" == false ]]; then
  cat > "$STANDARDS_FILE" << STD_EOF
# Praxia $( echo "$DOMAIN" | awk '{print toupper(substr($0,1,1)) substr($0,2)}' ) — Engineering Standards

> Standards are divided into two tiers:
> - **Hard Gate** — a change that violates this must be flagged as a suggestion instead of applied. Covers: safety, security, data loss, buildability, and API compatibility.
> - **Guidance** — apply when reasonable; note the violation in the proposal but do not block the fix. Covers: style preferences, size heuristics, and design patterns.
>
> Items marked \`[Guidance]\` are heuristics. All unmarked items are Hard Gates.

---

## 1. Universal Principles

### No Structural Changes Without Explicit Instruction
- Do not rename or move files.
- Do not change directory structure or module boundaries.
- Fix the specific item — no "while I'm here" refactoring.

### SOLID / DRY / KISS / YAGNI
Apply all four principles. Refer to the praxia-tech or praxia-backend STANDARDS.md for full definitions.

---

## 2. TODO: Domain-Specific Standards

TODO: Add rules specific to this domain.

### Hard Gates
- TODO: Rule — rationale

### Guidance
- \`[Guidance]\` TODO: Heuristic — rationale

---

## 3. Code Quality Checklist

Before submitting any change:

- [ ] Every applied change builds and all existing tests pass
- [ ] No commented-out code
- [ ] No magic numbers or strings — use named constants
- [ ] TODO: domain-specific checklist item
STD_EOF
  echo "  created  .github/skills/$AGENT_NAME/STANDARDS.md"
fi

# ── 3. .claude/agents/<name>.md ──────────────────────────────────────────────
cat > "$CLAUDE_AGENT_FILE" << CLAUDE_AGENT_EOF
---
name: $AGENT_NAME
description: "TODO: paste the description from .github/agents/$AGENT_NAME.agent.md here."
---

> **Canonical definition**: Read \`.github/agents/$AGENT_NAME.agent.md\` and follow every instruction defined there exactly. This file exists only to register the agent — all role, responsibilities, constraints, approach, and output format are in the canonical file.
CLAUDE_AGENT_EOF

echo "  created  .claude/agents/$AGENT_NAME.md"

# ── 4. .claude/skills/<name>/SKILL.md ────────────────────────────────────────
cat > "$CLAUDE_SKILL_DIR/SKILL.md" << CLAUDE_SKILL_EOF
---
name: $AGENT_NAME
description: "TODO: paste the description from .github/agents/$AGENT_NAME.agent.md here."
argument-hint: "TODO: paste the argument-hint from .github/agents/$AGENT_NAME.agent.md here."
---

# $AGENT_NAME

Read \`.github/agents/$AGENT_NAME.agent.md\` and follow every instruction defined there exactly.
CLAUDE_SKILL_EOF

echo "  created  .claude/skills/$AGENT_NAME/SKILL.md"

# ── 5. .codex/skills/<name>/SKILL.md ─────────────────────────────────────────
cat > "$CODEX_SKILL_DIR/SKILL.md" << CODEX_SKILL_EOF
---
name: $AGENT_NAME
description: "TODO: paste the description from .github/agents/$AGENT_NAME.agent.md here."
argument-hint: "TODO: paste the argument-hint from .github/agents/$AGENT_NAME.agent.md here."
---

# $AGENT_NAME

Read \`.github/agents/$AGENT_NAME.agent.md\` and follow every instruction defined there exactly.
CODEX_SKILL_EOF

echo "  created  .codex/skills/$AGENT_NAME/SKILL.md"

# ── Next steps ────────────────────────────────────────────────────────────────
echo ""
echo "✓ Scaffold complete. Next steps:"
echo ""
echo "  1. Fill in every TODO placeholder in the generated files."
echo ""
echo "  2. Add an entry to .github/roster.json:"
echo '     {'
echo "       \"name\": \"$AGENT_NAME\","
echo "       \"phase\": \"$PHASE\","
echo "       \"tier\": \"$TIER\","
echo "       \"agent_path\": \".github/agents/$AGENT_NAME.agent.md\","
if [[ "$SUGGESTIONS_ONLY" == false ]]; then
echo "       \"standards_path\": \".github/skills/$AGENT_NAME/STANDARDS.md\","
fi
echo "       \"inputs\": [\"cognia/{project_name}-$DOMAIN-analysis.md\"],"
if [[ "$SUGGESTIONS_ONLY" == true ]]; then
echo "       \"outputs\": [\"praxia/{project_name}-$AGENT_NAME-suggestions.md\"],"
else
echo "       \"outputs\": ["
echo "         \"praxia/{project_name}-$AGENT_NAME-applied.md\","
echo "         \"praxia/{project_name}-$AGENT_NAME-suggestions.md\""
echo "       ],"
fi
echo "       \"installer\": true,"
echo '       "status": "active"'
echo '     }'
echo ""
echo "  3. Fill in the description and argument-hint TODOs in the wrapper files,"
echo "     then run: npm run sync:wrappers"
echo "     This propagates those values across .claude/agents/, .claude/skills/, and .codex/skills/."
echo ""
echo "  4. Run: npm run check:wrappers   (must exit 0)"
echo ""
echo "  5. Add '$AGENT_NAME' to the agent table in AGENTS.md and README.md."
echo "     Run: npm run check:docs       (must exit 0)"
echo ""
