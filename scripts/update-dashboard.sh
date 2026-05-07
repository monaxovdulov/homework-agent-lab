#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/update-dashboard.sh [--repo OWNER/REPO] [--output DASHBOARD.md]

Regenerates a public-safe visual dashboard of students, homework Issues, and PRs.
USAGE
}

REPO="monaxovdulov/homework-agent-lab"
OUTPUT="DASHBOARD.md"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO="${2:-}"
      shift 2
      ;;
    --output)
      OUTPUT="${2:-}"
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

command -v python3 >/dev/null 2>&1 || {
  echo "Missing required command: python3" >&2
  exit 1
}

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

issues_json="$(mktemp)"
prs_json="$(mktemp)"
trap 'rm -f "$issues_json" "$prs_json"' EXIT

gh issue list \
  --repo "$REPO" \
  --state all \
  --limit 500 \
  --json number,title,url,state,labels,updatedAt,createdAt \
  > "$issues_json"

gh pr list \
  --repo "$REPO" \
  --state all \
  --limit 500 \
  --json number,title,url,state,headRefName,body,updatedAt,createdAt \
  > "$prs_json"

python3 - "$issues_json" "$prs_json" "$OUTPUT" "$REPO" <<'PY'
import json
import re
import sys
from collections import Counter, defaultdict
from datetime import datetime, timezone

issues_path, prs_path, output_path, repo = sys.argv[1:5]

with open(issues_path, encoding="utf-8") as f:
    all_issues = json.load(f)

with open(prs_path, encoding="utf-8") as f:
    prs = json.load(f)


def labels(issue):
    return [label["name"] for label in issue.get("labels", [])]


def label_value(issue, prefix, default=""):
    for name in labels(issue):
        if name.startswith(prefix):
            return name[len(prefix):]
    return default


def md(text):
    return str(text).replace("|", "\\|").replace("\n", " ")


def short_date(value):
    return (value or "").split("T", 1)[0]


def clean_title(title):
    return re.sub(r"^\[homework\]\[[^\]]+\]\s*", "", title or "").strip()


def submission_path(callsign, issue_number):
    return f"submissions/{callsign}/issue-{issue_number}/"


homework = [
    issue for issue in all_issues
    if "kind:homework" in labels(issue)
]

prs_by_issue = defaultdict(list)
for pr in prs:
    title = pr.get("title") or ""
    body = pr.get("body") or ""
    matched_issues = set(int(n) for n in re.findall(r"(?:Refs|refs)\s+#(\d+)", body))
    title_match = re.search(r"\[[a-zA-Z0-9._-]+\]\[#(\d+)\]", title)
    if title_match:
        matched_issues.add(int(title_match.group(1)))
    for issue_number in matched_issues:
        prs_by_issue[issue_number].append(pr)


records = []
for issue in homework:
    issue_number = int(issue["number"])
    callsign = label_value(issue, "student:", "unknown")
    status = label_value(issue, "статус:", "неизвестно")
    mode = label_value(issue, "mode:", "hints-only")
    storage = label_value(issue, "storage:", "lab-public")
    issue_prs = prs_by_issue.get(issue_number, [])
    pr_links = ", ".join(f"[#{pr['number']}]({pr['url']}) {pr['state'].lower()}" for pr in issue_prs) or "-"
    checkpoint_labels = [name for name in labels(issue) if name.endswith(":required")]
    records.append({
        "callsign": callsign,
        "issue": issue_number,
        "issue_link": f"[#{issue_number}]({issue['url']})",
        "title": clean_title(issue.get("title", "")),
        "raw_title": issue.get("title", ""),
        "state": issue.get("state", ""),
        "status": status,
        "mode": mode,
        "storage": storage,
        "updated": short_date(issue.get("updatedAt")),
        "created": short_date(issue.get("createdAt")),
        "submission": submission_path(callsign, issue_number),
        "pr_links": pr_links,
        "checkpoints": ", ".join(sorted(checkpoint_labels)) or "-",
    })

records.sort(key=lambda row: (row["callsign"], row["issue"]))

status_order = [
    "ждет-ученика 🕯️",
    "ученик-работает ✏️",
    "нужна-помощь ❓",
    "нужны-правки 📝",
    "ждет-проверки 🔍",
    "зачтено ✅",
    "неизвестно",
]

status_counts = Counter(row["status"] for row in records)
storage_counts = Counter(row["storage"] for row in records)
student_rows = defaultdict(list)
for row in records:
    student_rows[row["callsign"]].append(row)

open_records = [row for row in records if row["state"] == "OPEN"]
open_prs = [pr for pr in prs if pr.get("state") == "OPEN"]
generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

lines = []
lines.append("# Дашборд домашних заданий")
lines.append("")
lines.append(f"Источник: `{repo}`")
lines.append(f"Обновлено: `{generated_at}`")
lines.append("")
lines.append("Этот файл публичный. В таблицах должны быть только позывные, Issue, PR и")
lines.append("технические статусы. Не добавляйте реальные имена, контакты или секреты.")
lines.append("")

lines.append("## Сводка")
lines.append("")
lines.append("| Метрика | Значение |")
lines.append("| --- | ---: |")
lines.append(f"| Всего домашних Issue | {len(records)} |")
lines.append(f"| Открытых домашних Issue | {len(open_records)} |")
lines.append(f"| Открытых PR | {len(open_prs)} |")
for status in status_order:
    if status_counts[status]:
        lines.append(f"| {md(status)} | {status_counts[status]} |")
for storage, count in sorted(storage_counts.items()):
    if count:
        lines.append(f"| storage:{md(storage)} | {count} |")
lines.append("")

lines.append("## Ученики")
lines.append("")
lines.append("| Позывной | Активные | Ждет ученика | В работе | Нужна помощь | Нужны правки | Ждет проверки | Зачтено | Issue |")
lines.append("| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |")
for callsign in sorted(student_rows):
    rows = student_rows[callsign]
    counts = Counter(row["status"] for row in rows)
    active = sum(1 for row in rows if row["state"] == "OPEN" and row["status"] != "зачтено ✅")
    issue_links = ", ".join(row["issue_link"] for row in rows)
    lines.append(
        f"| `{md(callsign)}` | {active} | "
        f"{counts['ждет-ученика 🕯️']} | "
        f"{counts['ученик-работает ✏️']} | "
        f"{counts['нужна-помощь ❓']} | "
        f"{counts['нужны-правки 📝']} | "
        f"{counts['ждет-проверки 🔍']} | "
        f"{counts['зачтено ✅']} | {issue_links} |"
    )
lines.append("")

lines.append("## Доска По Статусам")
for status in status_order:
    status_rows = [row for row in records if row["status"] == status]
    if not status_rows:
        continue
    lines.append("")
    lines.append(f"### {status}")
    lines.append("")
    lines.append("| Позывной | Issue | Задание | Storage | PR | Обновлено | Сдача |")
    lines.append("| --- | --- | --- | --- | --- | --- | --- |")
    for row in sorted(status_rows, key=lambda item: (item["updated"], item["callsign"], item["issue"]), reverse=True):
        lines.append(
            f"| `{md(row['callsign'])}` | {row['issue_link']} | {md(row['title'])} | `storage:{md(row['storage'])}` | "
            f"{row['pr_links']} | {row['updated']} | `{md(row['submission'])}` |"
        )
lines.append("")

review_rows = [row for row in records if row["status"] == "ждет-проверки 🔍"]
lines.append("## Очередь Проверки")
lines.append("")
if review_rows:
    lines.append("| Позывной | Issue | Storage | PR | Обновлено | Что открыть |")
    lines.append("| --- | --- | --- | --- | --- | --- |")
    for row in sorted(review_rows, key=lambda item: item["updated"]):
        lines.append(
            f"| `{md(row['callsign'])}` | {row['issue_link']} | `storage:{md(row['storage'])}` | {row['pr_links']} | "
            f"{row['updated']} | `{md(row['submission'])}` |"
        )
else:
    lines.append("_Сейчас нет домашних в статусе `статус:ждет-проверки 🔍`._")
lines.append("")

lines.append("## PR")
lines.append("")
if prs:
    lines.append("| PR | Статус | Branch | Обновлено |")
    lines.append("| --- | --- | --- | --- |")
    for pr in sorted(prs, key=lambda item: item.get("updatedAt", ""), reverse=True):
        lines.append(
            f"| [#{pr['number']}]({pr['url']}) {md(pr['title'])} | "
            f"{md(pr['state'])} | `{md(pr.get('headRefName', ''))}` | {short_date(pr.get('updatedAt'))} |"
        )
else:
    lines.append("_PR пока нет._")
lines.append("")

lines.append("## Обновление")
lines.append("")
lines.append("Bash:")
lines.append("")
lines.append("```bash")
lines.append("scripts/update-dashboard.sh")
lines.append("```")
lines.append("")
lines.append("Windows PowerShell:")
lines.append("")
lines.append("```powershell")
lines.append("powershell -ExecutionPolicy Bypass -File scripts/update-dashboard.ps1")
lines.append("```")

with open(output_path, "w", encoding="utf-8", newline="\n") as f:
    f.write("\n".join(lines) + "\n")
PY

echo "Updated $OUTPUT from $REPO"
