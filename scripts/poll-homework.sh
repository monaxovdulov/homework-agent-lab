#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/poll-homework.sh [--callsign CALLSIGN] [--json]

Lists homework issues with статус:ждет-ученика 🕯️ for the student tutor workflow.
USAGE
}

JSON=0
CALLSIGN=""
STATUS_LABEL="статус:ждет-ученика 🕯️"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --callsign)
      CALLSIGN="${2:-}"
      shift 2
      ;;
    --json)
      JSON=1
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

command -v gh >/dev/null 2>&1 || {
  echo "Missing required command: gh" >&2
  exit 1
}

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

jq_filter='map(select((.labels | map(.name) | index("role:student")) and (.labels | map(.name) | index("kind:homework")) and (.labels | map(.name) | index("'"$STATUS_LABEL"'"))'

if [[ -n "$CALLSIGN" ]]; then
  case "$CALLSIGN" in
    *[!a-zA-Z0-9._-]*)
      echo "--callsign may contain only letters, numbers, dot, underscore, and dash" >&2
      exit 1
      ;;
  esac

  student_label="student:$CALLSIGN"
  jq_filter+=' and (.labels | map(.name) | index("'"$student_label"'"))'
fi

jq_filter+='))'

if [[ "$JSON" -eq 1 ]]; then
  gh issue list --limit 100 --json number,title,url,labels,updatedAt --jq "$jq_filter"
else
  gh issue list --limit 100 --json number,title,url,labels,updatedAt \
    --jq "$jq_filter | .[] | \"#\\(.number)\t\\(.title)\t\\(.updatedAt)\t\\(.url)\""
fi
