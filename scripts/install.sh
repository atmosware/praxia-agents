#!/usr/bin/env bash
# install.sh — Install Cognia agents and skills
# Usage: bash scripts/install.sh [--global | --local] [--claude] [--codex] [--all]
#
# This script delegates to bin/install.js, which handles path-patching of
# .github/skills/ references. Do NOT bypass it with plain cp commands.

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if command -v node >/dev/null 2>&1; then
  node "$REPO_DIR/bin/install.js" "$@"
else
  echo "ERROR: Node.js is required but not found in PATH." >&2
  echo "Install Node.js (https://nodejs.org) and retry." >&2
  exit 1
fi
