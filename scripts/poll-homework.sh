#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/poll-homework.sh [--callsign CALLSIGN] [--json]

Lists queued homework issues for the student tutor workflow.
USAGE
}

JSON=0
CALLSIGN=""

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

args=(
  --label role:student
  --label kind:homework
  --label status:queued
)

if [[ -n "$CALLSIGN" ]]; then
  student_label="student:$CALLSIGN"
  if ! gh label list --search "$student_label" | cut -f1 | grep -Fxq "$student_label"; then
    if [[ "$JSON" -eq 1 ]]; then
      printf '[]\n'
    else
      printf 'No queued homework for callsign %s.\n' "$CALLSIGN"
    fi
    exit 0
  fi
  args+=(--label "$student_label")
fi

if [[ "$JSON" -eq 1 ]]; then
  gh issue list "${args[@]}" --json number,title,url,labels,updatedAt
else
  gh issue list "${args[@]}"
fi
