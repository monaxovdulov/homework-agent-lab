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

Рекомендуемые файлы:

```text
solution.py
reflection.md
```

Если домашка не про код:

```text
answer.md
reflection.md
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
