# Submissions

Здесь ученики сдают решения домашних заданий.

Формат папки:

```text
submissions/<callsign>/issue-<number>/
```

Пример для позывного `diogen` и Issue `#12`:

```text
submissions/diogen/issue-12/
```

Обязательный файл для любой сдачи:

```text
submission.md
```

Шаблон:

```text
submissions/TEMPLATE.md
```

Рекомендуемые файлы для `storage:lab-public`:

```text
solution.py
submission.md
```

Если домашка не про код:

```text
answer.md
submission.md
```

## Где может лежать код

Домашка выбирает один storage mode через label:

- `storage:lab-public` - код лежит прямо в `submissions/<callsign>/issue-<number>/`;
- `storage:student-public-repo` - код лежит в публичном репозитории ученика, а здесь лежит только `submission.md`;
- `storage:student-private-repo` - код лежит в приватном репозитории ученика, учитель должен иметь доступ, а здесь лежит только публично безопасный `submission.md`;
- `storage:external-link` - работа лежит во внешней системе, а здесь лежит безопасная ссылка/описание;
- `storage:no-code` - сдача без кода, обычно `answer.md` и `submission.md`.

Даже если код хранится не здесь, в `homework-agent-lab` всегда должен быть:

```text
submissions/<callsign>/issue-<number>/submission.md
```

Минимальные поля manifest:

```text
Issue: #12
Callsign: diogen
Storage: lab-public
Checks: ...
Reflection: ...
```

Для `storage:student-public-repo` и `storage:external-link` добавьте:

```text
Submission URL: https://...
```

Для `storage:student-private-repo` добавьте:

```text
Access: учитель добавлен как collaborator
```

Правила:

- не пишите в папку другого позывного;
- не храните настоящие имена, контакты или личные данные;
- не храните секреты, токены, пароли, private keys;
- не кладите скрытые ответы учителя;
- в PR указывайте `Refs #<номер issue>`, а не `Closes #<номер issue>`.

Issue закрывает учитель после проверки.

## Как сдавать

У ученика должен быть установлен Codex и GitHub CLI (`gh`). На Windows используйте
PowerShell-команды.

Перед сдачей:

```bash
scripts/preflight-homework.sh --callsign diogen --issue 12
```

Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/preflight-homework.ps1 -Callsign diogen -Issue 12
```

Полная сдача через PR:

```bash
scripts/submit-homework.sh \
  --callsign diogen \
  --issue 12 \
  --summary "Кратко: что сделал, что понял и как проверил."
```

Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/submit-homework.ps1 `
  -Callsign diogen `
  -Issue 12 `
  -Summary "Кратко: что сделал, что понял и как проверил."
```

Если прикладываете лог, сначала зацензурьте его:

```bash
scripts/sanitize-log.sh raw.log public.log
```

Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/sanitize-log.ps1 -InputLog raw.log -OutputLog public.log
```
