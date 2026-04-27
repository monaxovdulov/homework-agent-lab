#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/complete-homework.sh ISSUE_NUMBER --summary SUMMARY

Marks homework as ready for teacher review.
Use only after the learner says the assignment is ready.
USAGE
}

ISSUE="${1:-}"
if [[ -n "$ISSUE" ]]; then
  shift
fi

SUMMARY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --summary)
      SUMMARY="${2:-}"
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

gh issue comment "$ISSUE" --body "Готово к проверке учителем.

Итог: $SUMMARY

host: $(hostname 2>/dev/null || echo unknown)
completed_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
gh issue edit "$ISSUE" \
  --remove-label "статус:ожидает" \
  --remove-label "статус:в-работе" \
  --remove-label "статус:заблокировано" \
  --remove-label "статус:нужны-правки" \
  --add-label "статус:на-проверке"
