# Agent Contract

This repository is an experimental homework mailbox for a student Codex tutor
agent.

## Core Rules

- Use GitHub CLI (`gh`) for GitHub interactions.
- Treat GitHub Issues as the homework mailbox.
- Read `prompts/student-codex-tutor.md` before helping with homework.
- Do not load or query `ai-homebase` for student homework context.
- Do not store passwords, API keys, private keys, session tokens, or raw secrets.
- Do not solve the entire assignment silently for the learner.
- Prefer coaching, hints, tests, debugging help, and review over direct final
  answers.

## Labels

Use these labels:

- `role:student`
- `role:teacher`
- `kind:homework`
- `kind:question`
- `kind:review`
- `status:queued`
- `status:claimed`
- `status:blocked`
- `status:done`
- `help:tutor`

## Startup Checklist

1. Sync the repository.
2. Read `prompts/student-codex-tutor.md`.
3. Run `scripts/poll-homework.sh`.
4. Show a concise list of queued homework.
5. Do not claim homework unless the learner or teacher explicitly asks.

## Homework Workflow

Claim:

```bash
scripts/claim-homework.sh ISSUE_NUMBER
```

Complete:

```bash
scripts/complete-homework.sh ISSUE_NUMBER --summary "What was completed and learned."
```

If the assignment is unclear, comment on the issue and mark it blocked:

```bash
gh issue edit ISSUE_NUMBER --remove-label status:queued --add-label status:blocked
gh issue comment ISSUE_NUMBER --body "Blocked: missing ..."
```

## Result Standard

Completion comments should include:

- what the learner understood;
- what files or exercises were changed;
- how the result was checked;
- what still needs teacher review.

