#!/usr/bin/env bash
# uninstall.sh — Remove Cognia agents and skills
# Usage: bash scripts/uninstall.sh [--global | --local] [--claude] [--codex] [--all]

# This script delegates to bin/install.js so uninstall behaviour stays aligned
# with the installer, including preserving user-owned .github/.claude/.codex folders.

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if command -v node >/dev/null 2>&1; then
  node "$REPO_DIR/bin/install.js" --uninstall "$@"
else
  echo "ERROR: Node.js is required but not found in PATH." >&2
  echo "Install Node.js (https://nodejs.org) and retry." >&2
  exit 1
fi
