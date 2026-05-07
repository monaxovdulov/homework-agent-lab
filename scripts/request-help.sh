#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/request-help.sh ISSUE_NUMBER --message MESSAGE [--repo OWNER/REPO]

Marks a homework issue as статус:нужна-помощь ❓ and leaves a public-safe
question for the teacher.
USAGE
}

ISSUE="${1:-}"
if [[ "$ISSUE" == "-h" || "$ISSUE" == "--help" ]]; then
  usage
  exit 0
fi

if [[ -n "$ISSUE" ]]; then
  shift
fi

MESSAGE=""
REPO="monaxovdulov/homework-agent-lab"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --message)
      MESSAGE="${2:-}"
      shift 2
      ;;
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

if [[ -z "$ISSUE" || -z "$MESSAGE" ]]; then
  usage >&2
  exit 1
fi

command -v gh >/dev/null 2>&1 || {
  echo "Missing required command: gh" >&2
  exit 1
}

gh issue edit "$ISSUE" --repo "$REPO" \
  --remove-label "статус:ждет-ученика 🕯️" \
  --remove-label "статус:ученик-работает ✏️" \
  --remove-label "статус:ждет-проверки 🔍" \
  --remove-label "статус:нужны-правки 📝" \
  --add-label "статус:нужна-помощь ❓"

gh issue comment "$ISSUE" --repo "$REPO" --body "Нужна подсказка учителя: $MESSAGE

requested_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
