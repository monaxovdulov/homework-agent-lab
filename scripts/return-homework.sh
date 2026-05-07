#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/return-homework.sh ISSUE_NUMBER --summary SUMMARY [--repo OWNER/REPO]

Marks a homework issue as статус:нужны-правки 📝.
Use by teacher or teacher-directed agent after review.
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
  --remove-label "статус:зачтено ✅" \
  --add-label "статус:нужны-правки 📝"

gh issue comment "$ISSUE" --repo "$REPO" --body "Нужны правки.

Итог проверки: $SUMMARY

reviewed_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
