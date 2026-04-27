#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/create-homework.sh --callsign CALLSIGN --title TITLE --body BODY

Creates a public-safe homework issue for one student callsign.
CALLSIGN is a public pseudonym, not an authentication secret.
USAGE
}

CALLSIGN=""
TITLE=""
BODY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --callsign)
      CALLSIGN="${2:-}"
      shift 2
      ;;
    --title)
      TITLE="${2:-}"
      shift 2
      ;;
    --body)
      BODY="${2:-}"
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

if [[ -z "$CALLSIGN" || -z "$TITLE" || -z "$BODY" ]]; then
  usage >&2
  exit 1
fi

case "$CALLSIGN" in
  *[!a-zA-Z0-9._-]*)
    echo "--callsign may contain only letters, numbers, dot, underscore, and dash" >&2
    exit 1
    ;;
esac

command -v gh >/dev/null 2>&1 || {
  echo "Missing required command: gh" >&2
  exit 1
}

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

student_label="student:$CALLSIGN"
gh label create "$student_label" \
  --color "ededed" \
  --description "Homework route for callsign $CALLSIGN" >/dev/null 2>&1 || true

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

{
  printf 'homework_schema: 1\n'
  printf 'visibility: public\n'
  printf 'callsign: %s\n' "$CALLSIGN"
  printf 'tutor_mode: hints_first\n'
  printf 'created_at: %s\n\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '## Задание\n\n%s\n\n' "$BODY"
  printf '## Правила\n\n'
  printf '- Codex помогает как наставник, а не сдает домашку вместо ученика.\n'
  printf '- Позывной является публичным псевдонимом, не паролем.\n'
  printf '- Не добавлять секреты, личные данные или скрытые ответы.\n'
} > "$tmp"

gh issue create \
  --title "[homework][$CALLSIGN] $TITLE" \
  --body-file "$tmp" \
  --label role:student \
  --label kind:homework \
  --label status:queued \
  --label help:tutor \
  --label privacy:public-safe \
  --label "$student_label"
