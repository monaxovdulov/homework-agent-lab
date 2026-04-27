#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/claim-homework.sh ISSUE_NUMBER

Marks a queued homework issue as claimed.
USAGE
}

ISSUE="${1:-}"

if [[ -z "$ISSUE" || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

command -v gh >/dev/null 2>&1 || {
  echo "Missing required command: gh" >&2
  exit 1
}

gh issue edit "$ISSUE" --remove-label status:queued --add-label status:claimed
gh issue comment "$ISSUE" --body "Домашка взята в работу Codex-наставником ученика.

host: $(hostname 2>/dev/null || echo unknown)
claimed_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
