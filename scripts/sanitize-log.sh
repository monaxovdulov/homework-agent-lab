#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/sanitize-log.sh [INPUT_LOG] [OUTPUT_LOG]

Reads a session log, redacts secrets, personal data, profanity, and excessive
spacing. If INPUT_LOG is omitted, reads stdin. If OUTPUT_LOG is omitted, writes
stdout.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

INPUT="${1:-}"
OUTPUT="${2:-}"

sanitize() {
  perl -Mutf8 -CSDA -pe '
    s/sk-[A-Za-z0-9_-]{10,}/[SECRET]/g;
    s/gh[pousr]_[A-Za-z0-9_]{20,}/[SECRET]/g;
    s/xox[baprs]-[A-Za-z0-9-]{10,}/[SECRET]/g;
    s/-----BEGIN [A-Z ]*PRIVATE KEY-----/[SECRET]/g;
    s/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/[PERSONAL_DATA]/g;
    s/\+?[0-9][0-9 ()-]{8,}[0-9]/[PERSONAL_DATA]/g;
    s/(?<!\p{L})(бля[дт]ь?|сука|хуй|хуе\p{L}*|пизд\p{L}*|еба\p{L}*|ёба\p{L}*|чмо|педик|тварь|дебил|идиот)(?!\p{L})/[цензура]/giu;
    s/[ \t]{3,}/ /g;
  '
}

if [[ -n "$INPUT" && -n "$OUTPUT" ]]; then
  sanitize < "$INPUT" > "$OUTPUT"
elif [[ -n "$INPUT" ]]; then
  sanitize < "$INPUT"
else
  sanitize
fi
