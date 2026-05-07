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
STORAGE="lab-public"

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
MANIFEST="$DIR/submission.md"
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
    ok "README.md/reflection.md not found; submission.md is the required manifest"
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

    storage_labels="$(grep -E '^storage:' "$labels_file" || true)"
    storage_count="$(printf '%s\n' "$storage_labels" | sed '/^$/d' | wc -l | tr -d ' ')"
    if [[ "$storage_count" == "0" ]]; then
      warn "Issue has no storage:* label; assuming storage:lab-public"
    elif [[ "$storage_count" != "1" ]]; then
      fail "Issue must have exactly one storage:* label"
      printf '%s\n' "$storage_labels" >&2
    else
      STORAGE="${storage_labels#storage:}"
    fi
  fi
  rm -f "$labels_file"
else
  warn "gh is not installed; skipped Issue label checks"
fi

case "$STORAGE" in
  lab-public|student-public-repo|student-private-repo|external-link|no-code)
    ok "storage mode: storage:$STORAGE"
    ;;
  *)
    fail "unknown storage mode: storage:$STORAGE"
    ;;
esac

if [[ -d "$DIR" ]]; then
  if [[ ! -f "$MANIFEST" ]]; then
    fail "missing required manifest: $MANIFEST"
  else
    ok "submission manifest found: $MANIFEST"

    if ! grep -Eiq "^Issue:[[:space:]]*#?${ISSUE}([[:space:]]|$)" "$MANIFEST"; then
      fail "manifest must contain: Issue: #$ISSUE"
    else
      ok "manifest references Issue #$ISSUE"
    fi

    if ! grep -Eiq "^Callsign:[[:space:]]*${CALLSIGN}([[:space:]]|$)" "$MANIFEST"; then
      fail "manifest must contain: Callsign: $CALLSIGN"
    else
      ok "manifest references callsign $CALLSIGN"
    fi

    if ! grep -Eiq "^Storage:[[:space:]]*(storage:)?${STORAGE}([[:space:]]|$)" "$MANIFEST"; then
      fail "manifest must contain: Storage: $STORAGE"
    else
      ok "manifest storage matches storage:$STORAGE"
    fi

    if ! grep -Eiq '^(Checks|Проверки|Проверка):|^##[[:space:]]*(Checks|Проверки|Проверка)' "$MANIFEST"; then
      fail "manifest must describe checks"
    else
      ok "manifest describes checks"
    fi

    if ! grep -Eiq '^(Reflection|Рефлексия):|^##[[:space:]]*(Reflection|Рефлексия)' "$MANIFEST"; then
      fail "manifest must include reflection"
    else
      ok "manifest includes reflection"
    fi

    case "$STORAGE" in
      student-public-repo|external-link)
        if ! grep -Eiq '^(Submission URL|URL|Repo|PR|Link|Ссылка):[[:space:]]*https?://' "$MANIFEST"; then
          fail "manifest for storage:$STORAGE must include a public-safe Submission URL/Repo/PR/Link"
        else
          ok "manifest includes public-safe external URL"
        fi
        ;;
      student-private-repo)
        if ! grep -Eiq '^(Access|Доступ):' "$MANIFEST"; then
          fail "manifest for storage:student-private-repo must describe teacher access without exposing secrets"
        else
          ok "manifest describes private repo access"
        fi
        ;;
      lab-public)
        non_manifest_count="$(find "$DIR" -type f ! -name 'submission.md' | wc -l | tr -d ' ')"
        if [[ "$non_manifest_count" == "0" ]]; then
          warn "storage:lab-public usually includes code or answer files next to submission.md"
        fi
        ;;
      no-code)
        if [[ ! -f "$DIR/answer.md" ]] && ! grep -Eiq '^(Answer|Ответ):|^##[[:space:]]*(Answer|Ответ)' "$MANIFEST"; then
          warn "storage:no-code usually includes answer.md or an Answer section in submission.md"
        fi
        ;;
    esac
  fi
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
