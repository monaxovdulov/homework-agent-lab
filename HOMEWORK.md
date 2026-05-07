# Домашки

Публичный индекс домашних заданий по позывным.

Этот файл нужен как устойчивый вход для учеников, потому что GitHub label-фильтры
могут показывать пустой список до обновления поискового индекса. Источник
задания все равно находится в GitHub Issue; здесь лежат только прямые ссылки.

## Как проверять входящие

Основной способ для Codex-наставника:

```bash
scripts/poll-homework.sh --callsign diogen
```

На Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/poll-homework.ps1 -Callsign diogen
```

Если GitHub Issues или label-фильтр показывают пусто, сначала открой этот файл,
а потом переходи по прямой ссылке на Issue.

## diogen

| Issue | Тема | Статус | Сдача |
| --- | --- | --- | --- |
| [#1](https://github.com/monaxovdulov/homework-agent-lab/issues/1) | [homework][diogen] Базовый мини-тест по HTTP | ждет-ученика 🕯️ | `submissions/diogen/issue-1/` |


## sokrat

| Issue | Тема | Статус | Сдача |
| --- | --- | --- | --- |
| [#2](https://github.com/monaxovdulov/homework-agent-lab/issues/2) | [homework][sokrat] RPG-агент: роль, HP и безопасные логи | ждет-ученика 🕯️ | `submissions/sokrat/issue-2/` |
