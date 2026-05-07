#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/submit-homework.sh --callsign CALLSIGN --issue ISSUE_NUMBER --summary SUMMARY [--repo OWNER/REPO] [--draft]

Runs preflight checks, creates or reuses branch student/<callsign>/issue-<number>,
commits the student's submission folder, pushes it, opens a PR, and moves the
Issue to статус:ждет-проверки 🔍.
USAGE
}

CALLSIGN=""
ISSUE=""
SUMMARY=""
REPO="monaxovdulov/homework-agent-lab"
DRAFT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --callsign)
      CALLSIGN="${2:-}"
      shift 2
      ;;
    --issue)
      ISSUE="${2:-}"
      shift 2
      ;;
    --summary)
      SUMMARY="${2:-}"
      shift 2
      ;;
    --repo)
      REPO="${2:-}"
      shift 2
      ;;
    --draft)
      DRAFT=1
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

if [[ -z "$CALLSIGN" || -z "$ISSUE" || -z "$SUMMARY" ]]; then
  usage >&2
  exit 1
fi

case "$CALLSIGN" in
  *[!a-zA-Z0-9._-]*)
    echo "FAIL: callsign may contain only letters, numbers, dot, underscore, and dash" >&2
    exit 1
    ;;
esac

case "$ISSUE" in
  *[!0-9]*)
    echo "FAIL: issue must be a number" >&2
    exit 1
    ;;
esac

command -v git >/dev/null 2>&1 || {
  echo "FAIL: missing required command: git" >&2
  exit 1
}

command -v gh >/dev/null 2>&1 || {
  echo "FAIL: missing required command: gh" >&2
  exit 1
}

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

DIR="submissions/$CALLSIGN/issue-$ISSUE"
BRANCH="student/$CALLSIGN/issue-$ISSUE"

scripts/preflight-homework.sh --callsign "$CALLSIGN" --issue "$ISSUE" --repo "$REPO"

current_branch="$(git branch --show-current)"
if [[ "$current_branch" != "$BRANCH" ]]; then
  if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
    git switch "$BRANCH"
  else
    git switch -c "$BRANCH"
  fi
fi

git add "$DIR/"

if ! git diff --cached --quiet -- "$DIR/"; then
  git commit -m "[$CALLSIGN][#$ISSUE] Submit homework"
else
  echo "No new staged changes in $DIR; reusing existing branch state."
fi

git push -u origin "$BRANCH"

existing_pr="$(gh pr list --repo "$REPO" --head "$BRANCH" --state open --json url --jq '.[0].url // empty')"

if [[ -n "$existing_pr" ]]; then
  pr_url="$existing_pr"
  echo "Reusing existing PR: $pr_url"
else
  pr_body="$(mktemp)"
  trap 'rm -f "$pr_body"' EXIT
  cat > "$pr_body" <<PR_BODY
Refs #$ISSUE

## Что сделал

$SUMMARY

## Как проверил

- Ученик приложил проверки или примеры запуска в \`$DIR/\`.
- Автоматически запущен \`scripts/preflight-homework.sh --callsign $CALLSIGN --issue $ISSUE\`.

## Что понял

- См. рефлексию ученика в \`$DIR/\`.

## Где лежит решение

\`\`\`text
$DIR/
\`\`\`

## Что проверить учителю

- Соответствие Issue #$ISSUE.
- Корректность решения и проверок.
PR_BODY

  create_args=(
    --repo "$REPO"
    --title "[$CALLSIGN][#$ISSUE] Решение домашки"
    --body-file "$pr_body"
  )
  if [[ "$DRAFT" -eq 1 ]]; then
    create_args+=(--draft)
  fi

  pr_url="$(gh pr create "${create_args[@]}")"
fi

scripts/complete-homework.sh "$ISSUE" --summary "$SUMMARY PR: $pr_url" --repo "$REPO"

echo "$pr_url"
