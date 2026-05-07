#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/sync-github-project.sh [--repo OWNER/REPO] [--owner OWNER] [--title TITLE] [--dry-run]

Creates or updates a GitHub Projects v2 table for homework Issues.

Required GitHub token scopes:
  gh auth refresh -s read:project -s project

The script adds homework Issues to the owner-level Project and fills text fields:
Callsign, Homework Status, Tutor Mode, Submission, Pull Request.
USAGE
}

REPO="monaxovdulov/homework-agent-lab"
OWNER="monaxovdulov"
TITLE="Homework Dashboard"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO="${2:-}"
      shift 2
      ;;
    --owner)
      OWNER="${2:-}"
      shift 2
      ;;
    --title)
      TITLE="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
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
  --json id,number,title,url,state,labels,updatedAt \
  > "$issues_json"

gh pr list \
  --repo "$REPO" \
  --state all \
  --limit 500 \
  --json number,title,url,state,body,headRefName \
  > "$prs_json"

python3 - "$issues_json" "$prs_json" "$REPO" "$OWNER" "$TITLE" "$DRY_RUN" <<'PY'
import json
import re
import subprocess
import sys

issues_path, prs_path, repo, owner, title, dry_run_raw = sys.argv[1:7]
dry_run = dry_run_raw == "1"

with open(issues_path, encoding="utf-8") as f:
    issues = json.load(f)

with open(prs_path, encoding="utf-8") as f:
    prs = json.load(f)


def run_graphql(query, **variables):
    cmd = ["gh", "api", "graphql", "-f", f"query={query}"]
    for key, value in variables.items():
        cmd.extend(["-F", f"{key}={value}"])
    result = subprocess.run(cmd, text=True, capture_output=True, check=False)
    if result.returncode != 0:
        message = result.stderr.strip() or result.stdout.strip()
        if "read:project" in message or "project" in message:
            raise SystemExit(
                "GitHub Projects scope is missing. Run:\n"
                "  gh auth refresh -s read:project -s project\n\n"
                f"Original error:\n{message}"
            )
        raise SystemExit(message)
    data = json.loads(result.stdout)
    if data.get("errors"):
        message = json.dumps(data["errors"], ensure_ascii=False, indent=2)
        if "read:project" in message or "project" in message:
            raise SystemExit(
                "GitHub Projects scope is missing. Run:\n"
                "  gh auth refresh -s read:project -s project\n\n"
                f"Original error:\n{message}"
            )
        raise SystemExit(message)
    return data["data"]


def labels(issue):
    return [label["name"] for label in issue.get("labels", [])]


def label_value(issue, prefix, default=""):
    for name in labels(issue):
        if name.startswith(prefix):
            return name[len(prefix):]
    return default


def submission_path(callsign, issue_number):
    return f"submissions/{callsign}/issue-{issue_number}/"


def pr_links_for_issue(issue_number):
    matched = []
    for pr in prs:
        body = pr.get("body") or ""
        pr_title = pr.get("title") or ""
        numbers = set(int(n) for n in re.findall(r"(?:Refs|refs)\s+#(\d+)", body))
        title_match = re.search(r"\[[a-zA-Z0-9._-]+\]\[#(\d+)\]", pr_title)
        if title_match:
            numbers.add(int(title_match.group(1)))
        if issue_number in numbers:
            matched.append(f"#{pr['number']} {pr['state'].lower()} {pr['url']}")
    return ", ".join(matched)


homework = [issue for issue in issues if "kind:homework" in labels(issue)]
print(f"Homework issues: {len(homework)}")

if dry_run:
    for issue in homework:
        callsign = label_value(issue, "student:", "unknown")
        status = label_value(issue, "статус:", "неизвестно")
        print(f"DRY-RUN #{issue['number']} {callsign} {status}")
    sys.exit(0)

owner_data = run_graphql(
    """
    query($login:String!) {
      user(login:$login) {
        id
        projectsV2(first:100) { nodes { id number title url } }
      }
    }
    """,
    login=owner,
)
owner_node = owner_data.get("user")
if not owner_node:
    owner_data = run_graphql(
        """
        query($login:String!) {
          organization(login:$login) {
            id
            projectsV2(first:100) { nodes { id number title url } }
          }
        }
        """,
        login=owner,
    )
    owner_node = owner_data.get("organization")
if not owner_node:
    raise SystemExit(f"Owner not found: {owner}")

project = None
for candidate in owner_node["projectsV2"]["nodes"]:
    if candidate["title"] == title:
        project = candidate
        break

if not project:
    created = run_graphql(
        """
        mutation($ownerId:ID!, $title:String!) {
          createProjectV2(input:{ownerId:$ownerId, title:$title}) {
            projectV2 { id number title url }
          }
        }
        """,
        ownerId=owner_node["id"],
        title=title,
    )
    project = created["createProjectV2"]["projectV2"]
    print(f"Created project: {project['url']}")
else:
    print(f"Using project: {project['url']}")

project_id = project["id"]

project_data = run_graphql(
    """
    query($projectId:ID!) {
      node(id:$projectId) {
        ... on ProjectV2 {
          fields(first:100) {
            nodes { ... on ProjectV2FieldCommon { id name dataType } }
          }
          items(first:100) {
            nodes {
              id
              content { ... on Issue { id number } }
            }
          }
        }
      }
    }
    """,
    projectId=project_id,
)
project_node = project_data["node"]
fields = {field["name"]: field for field in project_node["fields"]["nodes"] if field}
items_by_content = {}
for item in project_node["items"]["nodes"]:
    content = item.get("content")
    if content and content.get("id"):
        items_by_content[content["id"]] = item["id"]

required_fields = ["Callsign", "Homework Status", "Tutor Mode", "Submission", "Pull Request"]
for field_name in required_fields:
    if field_name in fields:
        continue
    created_field = run_graphql(
        """
        mutation($projectId:ID!, $name:String!) {
          createProjectV2Field(input:{projectId:$projectId, name:$name, dataType:TEXT}) {
            projectV2Field { ... on ProjectV2FieldCommon { id name dataType } }
          }
        }
        """,
        projectId=project_id,
        name=field_name,
    )
    field = created_field["createProjectV2Field"]["projectV2Field"]
    fields[field["name"]] = field
    print(f"Created field: {field_name}")


def set_text(item_id, field_name, value):
    value = value or ""
    field_id = fields[field_name]["id"]
    run_graphql(
        """
        mutation($projectId:ID!, $itemId:ID!, $fieldId:ID!, $value:String!) {
          updateProjectV2ItemFieldValue(input:{
            projectId:$projectId,
            itemId:$itemId,
            fieldId:$fieldId,
            value:{text:$value}
          }) {
            projectV2Item { id }
          }
        }
        """,
        projectId=project_id,
        itemId=item_id,
        fieldId=field_id,
        value=value,
    )


for issue in homework:
    content_id = issue["id"]
    if content_id in items_by_content:
        item_id = items_by_content[content_id]
    else:
        added = run_graphql(
            """
            mutation($projectId:ID!, $contentId:ID!) {
              addProjectV2ItemById(input:{projectId:$projectId, contentId:$contentId}) {
                item { id }
              }
            }
            """,
            projectId=project_id,
            contentId=content_id,
        )
        item_id = added["addProjectV2ItemById"]["item"]["id"]
        print(f"Added Issue #{issue['number']}")

    callsign = label_value(issue, "student:", "unknown")
    issue_number = int(issue["number"])
    set_text(item_id, "Callsign", callsign)
    set_text(item_id, "Homework Status", label_value(issue, "статус:", "неизвестно"))
    set_text(item_id, "Tutor Mode", label_value(issue, "mode:", "hints-only"))
    set_text(item_id, "Submission", submission_path(callsign, issue_number))
    set_text(item_id, "Pull Request", pr_links_for_issue(issue_number))

print(f"Project synced: {project['url']}")
PY
