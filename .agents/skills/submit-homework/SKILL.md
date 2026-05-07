---
name: submit-homework
description: Use when a student Codex tutor needs to submit homework in monaxovdulov/homework-agent-lab: prepare submissions/<callsign>/issue-<number>/, verify public-safety checks, create a PR, comment on the Issue, and move it to teacher review without closing it.
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

If a required checkpoint is missing, stop and ask the student to add it.

4. Verify the submission directory:

```bash
.agents/skills/submit-homework/scripts/preflight.sh \
  --callsign CALLSIGN \
  --issue ISSUE_NUMBER
```

If the script reports secrets or wrong folder layout, fix that before PR.

5. Create or switch to the student branch:

```bash
git switch -c student/CALLSIGN/issue-ISSUE_NUMBER
```

If the branch already exists, use `git switch student/CALLSIGN/issue-ISSUE_NUMBER`.

6. Stage and commit only relevant public-safe files:

```bash
git add submissions/CALLSIGN/issue-ISSUE_NUMBER/
git status --short
git commit -m "[CALLSIGN][#ISSUE_NUMBER] Submit homework"
```

7. Push and open a PR:

```bash
git push -u origin student/CALLSIGN/issue-ISSUE_NUMBER
gh pr create \
  --repo monaxovdulov/homework-agent-lab \
  --title "[CALLSIGN][#ISSUE_NUMBER] Решение домашки" \
  --body "$(cat <<'PR_BODY'
Refs #ISSUE_NUMBER

## Что сделал

-

## Как проверил

-

## Что понял

-

## Где лежит решение

submissions/CALLSIGN/issue-ISSUE_NUMBER/

## Что проверить учителю

-
PR_BODY
)"
```

Replace placeholders before running the command. Keep the PR body specific.

8. After the PR exists, comment on the Issue and move it to review:

```bash
scripts/complete-homework.sh ISSUE_NUMBER --summary "Кратко: что сделано, что понял, как проверил, ссылка на PR."
```

## Final Response To Student

Return:

- Issue link;
- PR link;
- submission folder;
- checks that were run;
- anything not verified.

Do not say the homework is accepted. Only the teacher can accept it.
