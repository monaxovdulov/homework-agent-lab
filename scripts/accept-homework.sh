#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/accept-homework.sh ISSUE_NUMBER --summary SUMMARY [--repo OWNER/REPO] [--close]

Marks a homework issue as статус:зачтено ✅. Closing is optional and requires
explicit --close because only the teacher should close Issues.
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

SUMMARY=""
REPO="monaxovdulov/homework-agent-lab"
CLOSE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --summary)
      SUMMARY="${2:-}"
      shift 2
      ;;
    --repo)
      REPO="${2:-}"
      shift 2
      ;;
    --close)
      CLOSE=1
      shift
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

if [[ -z "$ISSUE" || -z "$SUMMARY" ]]; then
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
  --remove-label "статус:нужна-помощь ❓" \
  --remove-label "статус:нужны-правки 📝" \
  --add-label "статус:зачтено ✅"

gh issue comment "$ISSUE" --repo "$REPO" --body "Зачтено.

Итог проверки: $SUMMARY

accepted_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

if [[ "$CLOSE" -eq 1 ]]; then
  gh issue close "$ISSUE" --repo "$REPO" --comment "Issue закрыт учителем после зачета."
fi
