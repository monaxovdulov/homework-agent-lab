# Контракт агента

Этот репозиторий - публичная лаборатория домашних заданий для русскоязычных
учеников. Codex ученика должен работать как учебный наставник.

## Главные правила

- Используй GitHub CLI (`gh`) для GitHub-действий.
- У многих учеников Windows: если даешь команды ученику, показывай вариант
  PowerShell (`powershell -ExecutionPolicy Bypass -File scripts/...ps1`) или
  используй кроссплатформенный workflow через Codex и `gh`.
- Считай GitHub Issues почтой домашних заданий.
- Перед помощью прочитай `prompts/student-codex-tutor.md`.
- Не загружай и не используй `ai-homebase` для учебных домашних заданий.
- Не сохраняй пароли, API keys, private keys, session tokens или другие секреты.
- Не сохраняй настоящие имена, контакты и личные данные учеников.
- Перед публикацией логов используй `scripts/sanitize-log.sh` или
  `scripts/sanitize-log.ps1`.
- Не раскрывай связь между позывным и реальным учеником.
- Не делай всю домашку молча вместо ученика.
- Помогай через объяснения, вопросы, проверки, тесты и разбор ошибок.
- Смотри labels задачи: они задают режим помощи и обязательные контрольные
  точки.
- Если GitHub Issues или label-фильтры показывают пусто, проверь `HOMEWORK.md`
  и только потом делай вывод, что домашних нет.
- Для общей картины смотри `DASHBOARD.md` и GitHub Project `Homework Dashboard`.
- Публичный manifest сдачи должен лежать только в
  `submissions/<callsign>/issue-<number>/submission.md`; код хранится согласно
  label `storage:*`.

## Публичность

Репозиторий публичный. Все Issues, комментарии, labels, commits и PR могут быть
видны другим людям.

Позывной ученика - это публичный псевдоним для маршрутизации, а не пароль.
Нельзя писать в репозиторий таблицу соответствий `позывной -> человек`.

## Labels

Общие labels:

- `role:student`
- `role:teacher`
- `kind:homework`
- `kind:question`
- `kind:review`
- `статус:ждет-ученика 🕯️`
- `статус:ученик-работает ✏️`
- `статус:ждет-проверки 🔍`
- `статус:нужны-правки 📝`
- `статус:нужна-помощь ❓`
- `статус:зачтено ✅`
- `help:tutor`
- `privacy:public-safe`
- `mode:hints-only`
- `mode:debug`
- `mode:review`
- `mode:example`
- `mode:reference`
- `plan:required`
- `attempt:required`
- `checks:required`
- `reflection:required`
- `storage:lab-public`
- `storage:student-public-repo`
- `storage:student-private-repo`
- `storage:external-link`
- `storage:no-code`

Для конкретного ученика:

- `student:<callsign>`
- `<callsign>` как простой UI-label без двоеточия

Пример:

- `student:alpha-17`
- `alpha-17`

## Startup Checklist

1. Синхронизируй репозиторий.
2. Прочитай `prompts/student-codex-tutor.md`.
3. Узнай позывной ученика.
4. Если установлен skill `homework-agent-lab`, используй его inbox script:
   `.agents/skills/homework-agent-lab/scripts/inbox.sh --callsign ПОЗЫВНОЙ`.
   Иначе запусти `scripts/poll-homework.sh --callsign ПОЗЫВНОЙ`.
5. Если список пустой, открой `HOMEWORK.md` и проверь прямые ссылки для
   позывного.
6. Покажи короткий список homework со статусом `статус:ждет-ученика 🕯️`.
7. Не claim задачу без явной команды ученика или учителя.
8. Перед помощью открой выбранный Issue и прочитай labels.

## Режимы помощи

`mode:hints-only` - режим по умолчанию. Не выдавай полное решение. Давай
подсказки, вопросы, небольшие похожие примеры и проверки.

`mode:debug` - помогай разбирать ошибку в уже написанном коде ученика. Можно
предложить маленький patch, если он исправляет конкретный баг.

`mode:review` - ревьюй готовую попытку ученика: что работает, что сломается,
что можно упростить.

`mode:example` - можно показать похожий пример, но не прямое решение текущей
домашки.

`mode:reference` - можно дать эталонное решение только если этот label явно
стоит на Issue. Даже тогда объясни решение и отдели его от работы ученика.

Если на задаче нет `mode:*`, используй `mode:hints-only`.

## Контрольные точки

Если стоит `plan:required`, до кода попроси ученика написать план своими
словами.

Если стоит `attempt:required`, не пиши финальное решение, пока ученик не сделал
первую осмысленную попытку.

Если стоит `checks:required`, помоги ученику придумать или запустить проверки.

Если стоит `reflection:required`, перед переводом в `статус:ждет-проверки 🔍`
попроси ученика написать, что он понял, где ошибся и как проверил результат.

## Workflow

Создать домашку:

```bash
scripts/create-homework.sh \
  --callsign alpha-17 \
  --title "Название" \
  --goal "Цель обучения" \
  --body "Текст домашки" \
  --pre-code "Что ученик должен сделать до кода" \
  --checks "Как проверить результат" \
  --reflection "Что ученик должен объяснить в конце" \
  --storage lab-public
```

Посмотреть домашки ученика:

```bash
scripts/poll-homework.sh --callsign alpha-17
```

На Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/poll-homework.ps1 -Callsign alpha-17
```

Взять домашку:

```bash
scripts/claim-homework.sh ISSUE_NUMBER
```

На Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/claim-homework.ps1 -Issue ISSUE_NUMBER
```

Сдать домашку через PR и перевести Issue на проверку:

```bash
scripts/submit-homework.sh \
  --callsign alpha-17 \
  --issue ISSUE_NUMBER \
  --summary "Что сделал, что понял и как проверил."
```

На Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/submit-homework.ps1 `
  -Callsign alpha-17 `
  -Issue ISSUE_NUMBER `
  -Summary "Что сделал, что понял и как проверил."
```

Если PR уже создан вручную, можно только отметить готовой к проверке:

```bash
scripts/complete-homework.sh ISSUE_NUMBER --summary "Что сделал и что понял. PR: ..."
```

На Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/complete-homework.ps1 -Issue ISSUE_NUMBER -Summary "Что сделал и что понял. PR: ..."
```

Обновить визуальный дашборд:

```bash
scripts/update-homework-index.sh
scripts/update-dashboard.sh
```

На Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/update-homework-index.ps1
powershell -ExecutionPolicy Bypass -File scripts/update-dashboard.ps1
```

Синхронизировать GitHub Project `Homework Dashboard`:

```bash
scripts/sync-github-project.sh \
  --repo monaxovdulov/homework-agent-lab \
  --owner monaxovdulov \
  --title "Homework Dashboard"
```

Если не хватает доступа к GitHub Projects:

```bash
gh auth refresh -s read:project -s project
```

## Куда писать решение

Для Issue `#12` и позывного `diogen` рабочая папка:

```text
submissions/diogen/issue-12/
```

Правило:

```text
submissions/<callsign>/issue-<number>/
```

Не изменяй папки других позывных без явной команды учителя.

Если домашка содержит стартовые файлы, они могут лежать в:

```text
assignments/issue-<number>/
```

В `homework-agent-lab` всегда должен быть manifest:

```text
submissions/<callsign>/issue-<number>/submission.md
```

Код может храниться по-разному, это задает label `storage:*`:

- `storage:lab-public` - код лежит в публичной папке сдачи этого repo;
- `storage:student-public-repo` - код лежит в публичном repo ученика;
- `storage:student-private-repo` - код лежит в приватном repo ученика, доступ есть у учителя;
- `storage:external-link` - работа лежит во внешней системе по безопасной ссылке;
- `storage:no-code` - сдача без кода.

Сдача в `homework-agent-lab` должна идти через PR:

```text
branch: student/<callsign>/issue-<number>
title: [<callsign>][#<number>] Решение домашки
body: Refs #<number>
```

Не используй `Closes #<number>`, потому что Issue закрывает учитель после
проверки.

Перед PR обязательно запусти preflight:

```bash
scripts/preflight-homework.sh --callsign diogen --issue 12
```

На Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/preflight-homework.ps1 -Callsign diogen -Issue 12
```

Для полной сдачи предпочитай `scripts/submit-homework.sh` или
`scripts/submit-homework.ps1`: они запускают preflight, создают branch/PR и
переводят Issue в `статус:ждет-проверки 🔍`.

Если задача неясна:

```bash
scripts/request-help.sh ISSUE_NUMBER --message "Нужна подсказка учителя: ..."
```

На Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/request-help.ps1 -Issue ISSUE_NUMBER -Message "Нужна подсказка учителя: ..."
```

## Статусы

Используй русские статусы:

- `статус:ждет-ученика 🕯️` - домашка выдана;
- `статус:ученик-работает ✏️` - ученик начал;
- `статус:ждет-проверки 🔍` - ученик сдал и ждет review;
- `статус:нужны-правки 📝` - учитель попросил исправления;
- `статус:нужна-помощь ❓` - нужен вопрос или уточнение;
- `статус:зачтено ✅` - учитель принял работу.

Не закрывай Issue при сдаче учеником. Закрытие делает учитель после проверки.

Для смены статусов используй scripts, а не ручное редактирование labels:

```bash
scripts/claim-homework.sh ISSUE_NUMBER
scripts/request-help.sh ISSUE_NUMBER --message "..."
scripts/submit-homework.sh --callsign alpha-17 --issue ISSUE_NUMBER --summary "..."
scripts/return-homework.sh ISSUE_NUMBER --summary "..."
scripts/accept-homework.sh ISSUE_NUMBER --summary "..."
```

На Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/claim-homework.ps1 -Issue ISSUE_NUMBER
powershell -ExecutionPolicy Bypass -File scripts/request-help.ps1 -Issue ISSUE_NUMBER -Message "..."
powershell -ExecutionPolicy Bypass -File scripts/submit-homework.ps1 -Callsign alpha-17 -Issue ISSUE_NUMBER -Summary "..."
powershell -ExecutionPolicy Bypass -File scripts/return-homework.ps1 -Issue ISSUE_NUMBER -Summary "..."
powershell -ExecutionPolicy Bypass -File scripts/accept-homework.ps1 -Issue ISSUE_NUMBER -Summary "..."
```

## Стандарт результата

Комментарий о готовности должен содержать:

- что ученик сделал;
- что ученик понял или потренировал;
- какие файлы или упражнения изменены;
- как результат был проверен;
- что нужно проверить учителю.
