#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/claim-homework.sh ISSUE_NUMBER [--repo OWNER/REPO]

Marks a homework issue as статус:ученик-работает ✏️.
USAGE
}

ISSUE="${1:-}"
REPO="monaxovdulov/homework-agent-lab"

if [[ -n "$ISSUE" ]]; then
  shift
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$ISSUE" || "$ISSUE" == "-h" || "$ISSUE" == "--help" ]]; then
  usage
  exit 0
fi

command -v gh >/dev/null 2>&1 || {
  echo "Missing required command: gh" >&2
  exit 1
}

gh issue edit "$ISSUE" --repo "$REPO" --remove-label "статус:ждет-ученика 🕯️" --add-label "статус:ученик-работает ✏️"
gh issue comment "$ISSUE" --repo "$REPO" --body "Домашка взята в работу Codex-наставником ученика.

claimed_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
