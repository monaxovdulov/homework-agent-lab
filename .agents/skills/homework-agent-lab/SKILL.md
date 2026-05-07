---
name: homework-agent-lab
description: Use when a Codex agent works in the public homework-agent-lab repo, checks homework inbox by student callsign, handles homework GitHub Issues, or GitHub Issues search/filter UI shows no tasks.
---

# homework-agent-lab

Use this skill for the public repo:

```text
monaxovdulov/homework-agent-lab
```

This repo is a public homework mailbox for student Codex tutors. Students are
identified by public callsigns such as `diogen`.

## Core rules

- Work in Russian unless the user asks otherwise.
- Many students work on Windows. When giving student commands, include the
  PowerShell `.ps1` variant or use the deterministic scripts that have both
  Bash and PowerShell forms.
- Do not use `ai-homebase` or other private repos for student homework.
- Do not store real student names, contacts, secrets, tokens, or hidden teacher
  answers in the public repo.
- Treat a callsign as a public routing label, not as a password.
- Do not solve the whole homework before the student has made a meaningful
  attempt, unless the issue explicitly has `mode:reference`.
- If editing files for a submission, only edit:

```text
submissions/<callsign>/issue-<number>/
```

## Reliable inbox check

GitHub Issues search and label filters can temporarily show an empty list even
when direct issue links and GraphQL still see the issue. Do not conclude that a
student has no homework from the GitHub web filter alone.

Preferred check:

```bash
.agents/skills/homework-agent-lab/scripts/inbox.sh --callsign diogen
```

Equivalent manual check from the repo root:

```bash
git pull --ff-only
scripts/poll-homework.sh --callsign diogen
```

If that is empty, read:

```text
HOMEWORK.md
```

Then open the direct issue link and inspect labels:

```bash
gh issue view ISSUE_NUMBER
```

## Startup workflow

1. Determine the student's callsign.
2. Sync the repo with `git pull --ff-only` when safe.
3. Run the inbox script for the callsign.
4. If no task appears, inspect `HOMEWORK.md` before saying there are no tasks.
5. Show a concise list of matching homework issues.
6. Do not claim a task without explicit approval.
7. Before helping, open the chosen issue and inspect labels.

## Teaching workflow

- If `plan:required` is present, ask for a short plan before code.
- If `attempt:required` is present, ask for the student's first attempt before
  giving a full answer.
- If `checks:required` is present, help create or run checks.
- If `reflection:required` is present, ask what the student understood before
  marking the homework ready for review.

Use hints, questions, small similar examples, debugging, and review. Keep the
student doing the core work.

## Submission

When the student says the homework is ready, use the `submit-homework` skill if
available. The preferred deterministic commands are:

```bash
scripts/submit-homework.sh --callsign CALLSIGN --issue ISSUE_NUMBER --summary "..."
```

Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/submit-homework.ps1 -Callsign CALLSIGN -Issue ISSUE_NUMBER -Summary "..."
```

Do not mark the Issue ready for review until required plan, attempt, checks, and
reflection checkpoints are present.

Use status scripts instead of manually editing labels:

```bash
scripts/request-help.sh ISSUE_NUMBER --message "..."
scripts/return-homework.sh ISSUE_NUMBER --summary "..."
scripts/accept-homework.sh ISSUE_NUMBER --summary "..."
```

Windows PowerShell uses the matching `.ps1` files.
