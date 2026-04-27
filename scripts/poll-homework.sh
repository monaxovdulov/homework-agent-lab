#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/poll-homework.sh [--json]

Lists queued homework issues for the student tutor workflow.
USAGE
}

JSON=0

while [[ $# -gt 0 ]]; do
  case "$1" in
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

if [[ "$JSON" -eq 1 ]]; then
  gh issue list \
    --label role:student \
    --label kind:homework \
    --label status:queued \
    --json number,title,url,labels,updatedAt
else
  gh issue list \
    --label role:student \
    --label kind:homework \
    --label status:queued
fi

