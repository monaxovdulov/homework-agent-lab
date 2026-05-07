#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/update-homework-index.sh [--repo OWNER/REPO]

Regenerates HOMEWORK.md from open homework Issues. This is a stable fallback
index for students when GitHub label search is delayed.
USAGE
}

REPO="monaxovdulov/homework-agent-lab"

while [[ $# -gt 0 ]]; do
  case "$1" in
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

command -v gh >/dev/null 2>&1 || {
  echo "Missing required command: gh" >&2
  exit 1
}

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

# shellcheck disable=SC2016
rows="$(gh issue list \
  --repo "$REPO" \
  --state open \
  --limit 200 \
  --json number,title,url,labels \
  --jq '
    .[]
    | [.labels[].name] as $labels
    | select($labels | index("kind:homework"))
    | ($labels | map(select(startswith("student:"))) | .[0] // "student:unknown" | sub("^student:"; "")) as $callsign
    | ($labels | map(select(startswith("статус:"))) | .[0] // "статус:неизвестно" | sub("^статус:"; "")) as $status
    | [$callsign, (.number | tostring), .url, .title, $status, ("submissions/" + $callsign + "/issue-" + (.number | tostring) + "/")]
    | @tsv
  ' | sort -t $'\t' -k1,1 -k2,2n)"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

cat > "$tmp" <<'HEADER'
# Домашки

Публичный индекс домашних заданий по позывным.

Этот файл нужен как устойчивый вход для учеников, потому что GitHub label-фильтры
могут показывать пустой список до обновления поискового индекса. Источник
задания все равно находится в GitHub Issue; здесь лежат только прямые ссылки.

## Как проверять входящие

Основной способ для Codex-наставника:

```bash
scripts/poll-homework.sh --callsign diogen
```

На Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/poll-homework.ps1 -Callsign diogen
```

Если GitHub Issues или label-фильтр показывают пусто, сначала открой этот файл,
а потом переходи по прямой ссылке на Issue.
HEADER

if [[ -z "$rows" ]]; then
  cat >> "$tmp" <<'TEXT'

_Открытых домашних заданий не найдено._
TEXT
else
  awk '
    BEGIN { FS = "\t"; current = "" }
    {
      callsign = $1
      issue = $2
      url = $3
      title = $4
      status = $5
      path = $6
      gsub(/\|/, "\\|", title)
      gsub(/\|/, "\\|", status)
      if (callsign != current) {
        if (current != "") {
          print ""
        }
        print ""
        print "## " callsign
        print ""
        print "| Issue | Тема | Статус | Сдача |"
        print "| --- | --- | --- | --- |"
        current = callsign
      }
      printf "| [#%s](%s) | %s | %s | `%s` |\n", issue, url, title, status, path
    }
  ' <<< "$rows" >> "$tmp"
fi

mv "$tmp" HOMEWORK.md
trap - EXIT

echo "Updated HOMEWORK.md from $REPO"
