#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/preflight-homework.sh --callsign CALLSIGN --issue ISSUE_NUMBER [--repo OWNER/REPO]

Checks that a homework submission is in the expected public-safe folder and
does not contain obvious secrets or personal data.
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

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

DIR="submissions/$CALLSIGN/issue-$ISSUE"
FAILED=0

fail() {
  echo "FAIL: $*" >&2
  FAILED=1
}

warn() {
  echo "WARN: $*"
}

ok() {
  echo "OK: $*"
}

if [[ ! -d "$DIR" ]]; then
  fail "submission directory not found: $DIR"
else
  ok "submission directory exists: $DIR"
fi

if [[ -d "$DIR" ]]; then
  FILE_COUNT="$(find "$DIR" -type f | wc -l | tr -d ' ')"
  if [[ "$FILE_COUNT" == "0" ]]; then
    fail "submission directory has no files"
  else
    ok "files in submission directory: $FILE_COUNT"
  fi

  if [[ ! -f "$DIR/README.md" && ! -f "$DIR/reflection.md" ]]; then
    warn "no README.md or reflection.md found; teacher review may ask for explanation"
  else
    ok "README.md or reflection.md found"
  fi
fi

if command -v gh >/dev/null 2>&1; then
  labels_file="$(mktemp)"
  if ! gh issue view "$ISSUE" --repo "$REPO" --json labels --jq '.labels[].name' > "$labels_file" 2>/dev/null; then
    warn "could not read Issue labels through gh"
  else
    if ! grep -Fxq "student:$CALLSIGN" "$labels_file"; then
      fail "Issue #$ISSUE does not have label student:$CALLSIGN"
    else
      ok "Issue has label student:$CALLSIGN"
    fi

    if ! grep -Fxq "kind:homework" "$labels_file"; then
      fail "Issue #$ISSUE does not have label kind:homework"
    else
      ok "Issue has label kind:homework"
    fi
  fi
  rm -f "$labels_file"
else
  warn "gh is not installed; skipped Issue label checks"
fi

if [[ -d "$DIR" ]]; then
  RISKY_FILES="$(
    find "$DIR" -type f \
      \( -name '.env' -o -name '*.pem' -o -name '*.key' -o -name 'id_rsa' -o -name 'id_ed25519' \) \
      -print
  )"

  if [[ -n "$RISKY_FILES" ]]; then
    fail "risky secret-like file names found:"
    printf '%s\n' "$RISKY_FILES" >&2
  else
    ok "no risky secret-like file names found"
  fi

  if command -v rg >/dev/null 2>&1; then
    SECRET_FILES="$(
      rg -l --hidden \
        -e 'sk-[A-Za-z0-9_-]{10,}' \
        -e 'gh[pousr]_[A-Za-z0-9_]{20,}' \
        -e '-----BEGIN [A-Z ]*PRIVATE KEY-----' \
        -e 'xox[baprs]-[A-Za-z0-9-]{10,}' \
        "$DIR" || true
    )"
  else
    SECRET_FILES="$(
      grep -RIlE \
        'sk-[A-Za-z0-9_-]{10,}|gh[pousr]_[A-Za-z0-9_]{20,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|xox[baprs]-[A-Za-z0-9-]{10,}' \
        "$DIR" || true
    )"
  fi

  if [[ -n "$SECRET_FILES" ]]; then
    fail "possible secret found in these files:"
    printf '%s\n' "$SECRET_FILES" >&2
  else
    ok "no obvious API keys or private keys found"
  fi

  if command -v rg >/dev/null 2>&1; then
    PERSONAL_DATA_FILES="$(
      rg -l --hidden \
        -e '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' \
        -e '\+?[0-9][0-9 ()-]{8,}[0-9]' \
        "$DIR" || true
    )"
  else
    PERSONAL_DATA_FILES="$(
      grep -RIlE \
        '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}|\+?[0-9][0-9 ()-]{8,}[0-9]' \
        "$DIR" || true
    )"
  fi

  if [[ -n "$PERSONAL_DATA_FILES" ]]; then
    warn "possible email or phone-like personal data found in these files:"
    printf '%s\n' "$PERSONAL_DATA_FILES"
  else
    ok "no obvious email or phone-like data found"
  fi
fi

if [[ "$FAILED" -ne 0 ]]; then
  exit 1
fi

ok "preflight passed"
