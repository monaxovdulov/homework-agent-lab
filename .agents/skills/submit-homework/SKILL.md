---
name: submit-homework
description: "Use when a student Codex tutor needs to submit homework in monaxovdulov/homework-agent-lab: prepare submissions/<callsign>/issue-<number>/, verify public-safety checks, create a PR, comment on the Issue, and move it to teacher review without closing it."
---

# submit-homework

Use this skill only for final submission of homework in the public repository:

```text
monaxovdulov/homework-agent-lab
```

Students are identified only by callsign. Never write real names, contacts,
secrets, or the mapping between callsign and a real person.

## Submission Contract

- Work only in `submissions/<callsign>/issue-<number>/`.
- Do not edit another callsign's folder.
- Require `submissions/<callsign>/issue-<number>/submission.md` for every
  storage mode.
- Do not include API keys, passwords, private keys, session tokens, or real
  personal data.
- Use `Refs #<number>` in PR text. Never use `Closes #<number>`.
- Do not close the Issue. The teacher closes it after review.
- Keep tutor mode: do not silently finish missing learning work for the student.

## Workflow

1. Confirm the callsign and Issue number from the user or current context.
2. Read the Issue and labels:

```bash
gh issue view ISSUE_NUMBER --repo monaxovdulov/homework-agent-lab
```

3. Check required checkpoints from labels before submission:

- `plan:required`: the student has written a short plan.
- `attempt:required`: there is a meaningful first attempt.
- `checks:required`: tests, commands, or manual scenarios are included.
- `reflection:required`: the student wrote what they understood and how they
  checked the result.
- `storage:*`: determines where code lives. Supported values are
  `storage:lab-public`, `storage:student-public-repo`,
  `storage:student-private-repo`, `storage:external-link`, and
  `storage:no-code`.

If a required checkpoint is missing, stop and ask the student to add it.

The manifest must include `Issue`, `Callsign`, `Storage`, `Checks`, and
`Reflection`. For `storage:student-public-repo` or `storage:external-link`, it
must include a public-safe `Submission URL`. For `storage:student-private-repo`,
it must describe teacher `Access` without exposing secrets or personal data.

4. Verify the submission directory.

```bash
scripts/preflight-homework.sh --callsign CALLSIGN --issue ISSUE_NUMBER
```

On Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/preflight-homework.ps1 -Callsign CALLSIGN -Issue ISSUE_NUMBER
```

If the script reports secrets or wrong folder layout, fix that before PR.

5. Submit through the deterministic script.

```bash
scripts/submit-homework.sh \
  --callsign CALLSIGN \
  --issue ISSUE_NUMBER \
  --summary "What the student did, understood, and checked."
```

On Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/submit-homework.ps1 `
  -Callsign CALLSIGN `
  -Issue ISSUE_NUMBER `
  -Summary "What the student did, understood, and checked."
```

The script creates or reuses `student/CALLSIGN/issue-ISSUE_NUMBER`, commits only
`submissions/CALLSIGN/issue-ISSUE_NUMBER/`, pushes it, opens or reuses a PR, and
moves the Issue to `статус:ждет-проверки 🔍`.

6. If a PR was created manually, use completion only after verifying the PR body
   uses `Refs #ISSUE_NUMBER` and not `Closes #ISSUE_NUMBER`.

```bash
scripts/complete-homework.sh ISSUE_NUMBER --summary "Кратко: что сделано, что понял, как проверил, ссылка на PR."
```

On Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/complete-homework.ps1 -Issue ISSUE_NUMBER -Summary "Кратко: что сделано, что понял, как проверил, ссылка на PR."
```

## Log Sanitizing

If the student needs to publish logs, sanitize them first:

```bash
scripts/sanitize-log.sh raw.log public.log
```

On Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/sanitize-log.ps1 -InputLog raw.log -OutputLog public.log
```

## Final Response To Student

Return:

- Issue link;
- PR link;
- submission folder;
- checks that were run;
- anything not verified.

Do not say the homework is accepted. Only the teacher can accept it.
