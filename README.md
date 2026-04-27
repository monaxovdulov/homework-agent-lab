# Homework Agent Lab

Experimental private repository for homework coaching with a student Codex agent.

The repository is intentionally separate from private memory repositories such as
`ai-homebase`. It should contain only assignment text, student attempts, teacher
feedback, and safe teaching context.

## Model

```text
Teacher creates GitHub Issue
  -> student Codex checks queued homework
  -> student Codex claims one issue
  -> student works with Codex as a tutor
  -> result is posted as comments, commits, or pull requests
```

GitHub Issues are the mailbox. Labels route and track work:

```text
role:student
role:teacher
kind:homework
kind:question
kind:review
status:queued
status:claimed
status:blocked
status:done
help:tutor
```

## Student Codex Startup

```bash
cd /path/to/homework-agent-lab
git pull --ff-only
scripts/poll-homework.sh
```

If the learner decides to work on an issue:

```bash
scripts/claim-homework.sh ISSUE_NUMBER
```

When the learner says the assignment is ready for teacher review:

```bash
scripts/complete-homework.sh ISSUE_NUMBER --summary "Short summary of what was learned and completed."
```

## Teaching Boundary

The student Codex agent is a tutor, not a silent homework solver.

It may:

- explain concepts;
- ask guiding questions;
- review student code;
- write small examples that are not the final answer;
- generate tests and debugging hints;
- help the learner break a problem into steps.

It must not:

- submit a complete final answer without learner participation;
- hide uncertainty or fabricate results;
- store secrets, tokens, passwords, private keys, or personal data;
- pull context from `ai-homebase` or other private memory repositories.

## Creating Homework

Use the GitHub issue template "Homework assignment" or create an issue with:

```bash
gh issue create \
  --title "[homework] Topic or task title" \
  --body "Assignment text..." \
  --label role:student \
  --label kind:homework \
  --label status:queued \
  --label help:tutor
```

Keep each issue focused on one assignment.

