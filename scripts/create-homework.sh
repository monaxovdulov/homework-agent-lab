#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/create-homework.sh --callsign CALLSIGN --title TITLE --body BODY [options]

Options:
  --goal TEXT        Learning goal.
  --pre-code TEXT    What the student must do before writing code.
  --checks TEXT      How the student should verify the result.
  --reflection TEXT  What the student should explain at the end.
  --mode MODE        hints-only|debug|review|example|reference. Default: hints-only

Creates a public-safe homework issue for one student callsign.
CALLSIGN is a public pseudonym, not an authentication secret.
USAGE
}

CALLSIGN=""
TITLE=""
BODY=""
GOAL=""
PRE_CODE=""
CHECKS=""
REFLECTION=""
MODE="hints-only"

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
    --goal)
      GOAL="${2:-}"
      shift 2
      ;;
    --pre-code)
      PRE_CODE="${2:-}"
      shift 2
      ;;
    --checks)
      CHECKS="${2:-}"
      shift 2
      ;;
    --reflection)
      REFLECTION="${2:-}"
      shift 2
      ;;
    --mode)
      MODE="${2:-}"
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

case "$MODE" in
  hints-only|debug|review|example|reference) ;;
  *)
    echo "--mode must be one of: hints-only, debug, review, example, reference" >&2
    exit 1
    ;;
esac

if [[ -z "$GOAL" ]]; then
  GOAL="Учитель не указал отдельную цель. Ориентируйтесь на тему домашки."
fi

if [[ -z "$PRE_CODE" ]]; then
  PRE_CODE="$(cat <<'TEXT'
1. Объясни задачу своими словами.
2. Напиши план из 3-5 шагов.
3. Придумай 2-3 примера входа и ожидаемого выхода.
TEXT
)"
fi

if [[ -z "$CHECKS" ]]; then
  CHECKS="Придумай и запусти проверки на обычном, пустом и пограничном примере."
fi

if [[ -z "$REFLECTION" ]]; then
  REFLECTION="В конце напиши, что получилось, где была сложность, как проверял решение и что сможешь повторить сам."
fi

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
  printf 'tutor_mode: %s\n' "$MODE"
  printf 'requires_plan: true\n'
  printf 'requires_attempt: true\n'
  printf 'requires_checks: true\n'
  printf 'requires_reflection: true\n'
  printf 'created_at: %s\n\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '## Цель обучения\n\n%s\n\n' "$GOAL"
  printf '## Задание\n\n%s\n\n' "$BODY"
  printf '## Перед кодом\n\n%s\n\n' "$PRE_CODE"
  printf '## Проверка\n\n%s\n\n' "$CHECKS"
  printf '## Рефлексия\n\n%s\n\n' "$REFLECTION"
  printf '## Правила\n\n'
  printf '%s\n' "- Codex работает в режиме mode:$MODE."
  printf '%s\n' '- Codex помогает как наставник, а не сдает домашку вместо ученика.'
  printf '%s\n' '- До первой попытки ученика нельзя выдавать полное финальное решение.'
  printf '%s\n' '- Перед завершением нужна короткая рефлексия ученика.'
  printf '%s\n' '- Позывной является публичным псевдонимом, не паролем.'
  printf '%s\n' '- Не добавлять секреты, личные данные или скрытые ответы.'
} > "$tmp"

gh issue create \
  --title "[homework][$CALLSIGN] $TITLE" \
  --body-file "$tmp" \
  --label role:student \
  --label kind:homework \
  --label "статус:ждет-ученика 🕯️" \
  --label help:tutor \
  --label privacy:public-safe \
  --label "mode:$MODE" \
  --label plan:required \
  --label attempt:required \
  --label checks:required \
  --label reflection:required \
  --label "$student_label"
