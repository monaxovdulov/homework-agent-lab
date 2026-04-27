#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  inbox.sh --callsign CALLSIGN [--repo PATH]

Checks homework for a public student callsign without relying on GitHub Issues
search filters. Prints poll-homework.sh results, or falls back to HOMEWORK.md.
USAGE
}

CALLSIGN=""
REPO=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --callsign)
      CALLSIGN="${2:-}"
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

if [[ -z "$CALLSIGN" ]]; then
  usage >&2
  exit 1
fi

case "$CALLSIGN" in
  *[!a-zA-Z0-9._-]*)
    echo "--callsign may contain only letters, numbers, dot, underscore, and dash" >&2
    exit 1
    ;;
esac

is_homework_repo() {
  [[ -f "$1/HOMEWORK.md" && -x "$1/scripts/poll-homework.sh" ]]
}

find_repo() {
  local candidate

  if [[ -n "$REPO" ]]; then
    printf '%s\n' "$REPO"
    return 0
  fi

  if [[ -n "${HOMEWORK_AGENT_LAB:-}" ]]; then
    printf '%s\n' "$HOMEWORK_AGENT_LAB"
    return 0
  fi

  if candidate="$(git rev-parse --show-toplevel 2>/dev/null)" && is_homework_repo "$candidate"; then
    printf '%s\n' "$candidate"
    return 0
  fi

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  for candidate in \
    "$script_dir/../../../.." \
    "$HOME/homework-agent-lab" \
    "/home/devuser/homework-agent-lab"
  do
    if [[ -n "$candidate" ]] && candidate="$(cd "$candidate" 2>/dev/null && pwd)" && is_homework_repo "$candidate"; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

repo="$(find_repo)" || {
  cat >&2 <<'ERROR'
Could not find homework-agent-lab.
Run from the repository root, pass --repo PATH, or set HOMEWORK_AGENT_LAB.
ERROR
  exit 1
}

cd "$repo"

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git pull --ff-only >/dev/null 2>&1 || {
    echo "Warning: git pull --ff-only failed; continuing with local files." >&2
  }
fi

poll_output="$(scripts/poll-homework.sh --callsign "$CALLSIGN" || true)"
if [[ -n "$poll_output" ]]; then
  printf '%s\n' "$poll_output"
  exit 0
fi

echo "No open queued homework returned by poll-homework.sh for callsign: $CALLSIGN"

if [[ ! -f HOMEWORK.md ]]; then
  echo "HOMEWORK.md not found." >&2
  exit 0
fi

section="$(
  awk -v section="## ${CALLSIGN}" '
    $0 == section { in_section = 1; print; next }
    in_section && /^## / { exit }
    in_section { print }
  ' HOMEWORK.md
)"

if [[ -n "$section" ]]; then
  echo
  echo "Fallback from HOMEWORK.md:"
  printf '%s\n' "$section"
else
  echo "No HOMEWORK.md section found for callsign: $CALLSIGN"
fi
