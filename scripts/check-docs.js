#!/usr/bin/env node
/**
 * check-docs.js — Verify that AGENTS.md and README.md are consistent
 * with the canonical agent roster in .github/roster.json.
 *
 * Checks:
 *   1. Every active roster entry is mentioned in AGENTS.md
 *   2. Every active roster entry is mentioned in README.md
 *   3. Every active agent's inputs[] path is mentioned in AGENTS.md
 *   4. Non-standard Cognia input paths appear in README or README links to the canonical map
 *   5. README layout mentions roster.json and runtime wrapper directories
 *
 * Usage:
 *   node scripts/check-docs.js         # report issues, exit 1 if any
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');

const roster = JSON.parse(
  fs.readFileSync(path.join(ROOT, '.github', 'roster.json'), 'utf8'),
);

const activeEntries = roster.skills.filter(e => e.status === 'active');
const activeAgents  = activeEntries.map(e => e.name);

const agentsMd = fs.readFileSync(path.join(ROOT, 'AGENTS.md'), 'utf8');
const readmeMd = fs.readFileSync(path.join(ROOT, 'README.md'), 'utf8');

let issues = 0;

// ── Check 1 & 2: every agent name present in both docs ───────────────────────
for (const name of activeAgents) {
  if (!agentsMd.includes(name)) {
    console.error(`MISSING in AGENTS.md  : ${name}`);
    issues++;
  }
  if (!readmeMd.includes(name)) {
    console.error(`MISSING in README.md  : ${name}`);
    issues++;
  }
}

// ── Check 3: every active inputs[] path is mentioned in AGENTS.md ────────────
for (const entry of activeEntries) {
  for (const inputPath of (entry.inputs || [])) {
    if (!agentsMd.includes(inputPath)) {
      console.error(`INPUT path missing in AGENTS.md  : ${entry.name} → ${inputPath}`);
      issues++;
    }
  }
}

// ── Check 4: non-standard inputs appear in README or README links to map ──────
// Standard pattern: cognia/{project_name}-{domain}-analysis.md
// where domain = agent name without the "praxia-" prefix.
const README_HAS_MAP_POINTER = readmeMd.includes('AGENTS.md');

for (const entry of activeEntries) {
  const domain = entry.name.replace(/^praxia-/, '');
  const standardInput = `cognia/{project_name}-${domain}-analysis.md`;

  for (const inputPath of (entry.inputs || [])) {
    if (inputPath === standardInput) continue;  // standard — no special check needed

    // Non-standard path: README must either mention it directly or link to AGENTS.md
    const filenamePart = path.basename(inputPath);
    const readmeMentions = readmeMd.includes(filenamePart) || readmeMd.includes(inputPath);

    if (!readmeMentions && !README_HAS_MAP_POINTER) {
      console.error(
        `NON-STANDARD input not covered in README  : ${entry.name} → ${inputPath}` +
        `\n  Fix: add the path to README.md or add a pointer to the AGENTS.md canonical map.`,
      );
      issues++;
    }
  }
}

// ── Check 5: README layout mentions roster and runtime wrapper directories ────
const LAYOUT_CHECKS = [
  { token: 'roster.json',  label: 'roster.json in README layout' },
  { token: '.claude/',     label: '.claude/ directory in README layout' },
  { token: '.codex/',      label: '.codex/ directory in README layout' },
];

for (const { token, label } of LAYOUT_CHECKS) {
  if (!readmeMd.includes(token)) {
    console.error(`MISSING in README layout  : ${label}`);
    issues++;
  }
}

console.log('');

if (issues === 0) {
  console.log(
    `OK  ${activeAgents.length} agents checked — names, input paths, non-standard exceptions, and layout all consistent.`,
  );
  process.exit(0);
}

console.error(
  `FAIL  ${issues} inconsistency(ies) found. Update AGENTS.md and/or README.md to match .github/roster.json.`,
);
process.exit(1);
