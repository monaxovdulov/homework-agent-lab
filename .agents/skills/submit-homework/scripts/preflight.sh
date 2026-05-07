#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  .agents/skills/submit-homework/scripts/preflight.sh --callsign CALLSIGN --issue ISSUE_NUMBER

Checks that a homework submission is in the expected public-safe folder and
does not contain obvious secrets.
USAGE
}

CALLSIGN=""
ISSUE=""
REPO="monaxovdulov/homework-agent-lab"

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

if [[ -z "$CALLSIGN" || -z "$ISSUE" ]]; then
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

command -v rg >/dev/null 2>&1 || {
  echo "FAIL: missing required command: rg" >&2
  exit 1
}

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

DIR="submissions/$CALLSIGN/issue-$ISSUE"
FAILED=0

if [[ ! -d "$DIR" ]]; then
  echo "FAIL: submission directory not found: $DIR" >&2
  FAILED=1
else
  echo "OK: submission directory exists: $DIR"
fi

if [[ -d "$DIR" ]]; then
  FILE_COUNT="$(find "$DIR" -type f | wc -l | tr -d ' ')"
  if [[ "$FILE_COUNT" == "0" ]]; then
    echo "FAIL: submission directory has no files" >&2
    FAILED=1
  else
    echo "OK: files in submission directory: $FILE_COUNT"
  fi
fi

if command -v gh >/dev/null 2>&1; then
  if ! gh issue view "$ISSUE" --repo "$REPO" --json labels --jq '.labels[].name' >/tmp/homework-labels.$$ 2>/dev/null; then
    echo "WARN: could not read Issue labels through gh"
  else
    if ! grep -Fxq "student:$CALLSIGN" /tmp/homework-labels.$$; then
      echo "FAIL: Issue #$ISSUE does not have label student:$CALLSIGN" >&2
      FAILED=1
    else
      echo "OK: Issue has label student:$CALLSIGN"
    fi

    if ! grep -Fxq "kind:homework" /tmp/homework-labels.$$; then
      echo "FAIL: Issue #$ISSUE does not have label kind:homework" >&2
      FAILED=1
    else
      echo "OK: Issue has label kind:homework"
    fi

    rm -f /tmp/homework-labels.$$
  fi
else
  echo "WARN: gh is not installed; skipped Issue label checks"
fi

if [[ -d "$DIR" ]]; then
  SECRET_MATCHES="$(
    rg -n --hidden \
      -e 'sk-[A-Za-z0-9_-]{10,}' \
      -e 'gh[pousr]_[A-Za-z0-9_]{20,}' \
      -e '-----BEGIN [A-Z ]*PRIVATE KEY-----' \
      -e 'xox[baprs]-[A-Za-z0-9-]{10,}' \
      "$DIR" || true
  )"

  if [[ -n "$SECRET_MATCHES" ]]; then
    echo "FAIL: possible secret found in submission files:" >&2
    echo "$SECRET_MATCHES" >&2
    FAILED=1
  else
    echo "OK: no obvious API keys or private keys found"
  fi

  PERSONAL_DATA_MATCHES="$(
    rg -n --hidden \
      -e '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' \
      -e '\+?[0-9][0-9 ()-]{8,}[0-9]' \
      "$DIR" || true
  )"

  if [[ -n "$PERSONAL_DATA_MATCHES" ]]; then
    echo "WARN: possible email or phone-like personal data found:"
    echo "$PERSONAL_DATA_MATCHES"
  else
    echo "OK: no obvious email or phone-like data found"
  fi
fi

if [[ "$FAILED" -ne 0 ]]; then
  exit 1
fi

echo "OK: preflight passed"
