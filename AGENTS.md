# Контракт агента

Этот репозиторий - публичная лаборатория домашних заданий для русскоязычных
учеников. Codex ученика должен работать как учебный наставник.

## Главные правила

- Используй GitHub CLI (`gh`) для GitHub-действий.
- Считай GitHub Issues почтой домашних заданий.
- Перед помощью прочитай `prompts/student-codex-tutor.md`.
- Не загружай и не используй `ai-homebase` для учебных домашних заданий.
- Не сохраняй пароли, API keys, private keys, session tokens или другие секреты.
- Не сохраняй настоящие имена, контакты и личные данные учеников.
- Не раскрывай связь между позывным и реальным учеником.
- Не делай всю домашку молча вместо ученика.
- Помогай через объяснения, вопросы, проверки, тесты и разбор ошибок.

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
- `status:queued`
- `status:claimed`
- `status:blocked`
- `status:done`
- `help:tutor`
- `privacy:public-safe`

Для конкретного ученика:

- `student:<callsign>`

Пример:

- `student:alpha-17`

## Startup Checklist

1. Синхронизируй репозиторий.
2. Прочитай `prompts/student-codex-tutor.md`.
3. Узнай позывной ученика.
4. Запусти `scripts/poll-homework.sh --callsign ПОЗЫВНОЙ`.
5. Покажи короткий список queued homework.
6. Не claim задачу без явной команды ученика или учителя.

## Workflow

Создать домашку:

```bash
scripts/create-homework.sh \
  --callsign alpha-17 \
  --title "Название" \
  --body "Текст домашки"
```

Посмотреть домашки ученика:

```bash
scripts/poll-homework.sh --callsign alpha-17
```

Взять домашку:

```bash
scripts/claim-homework.sh ISSUE_NUMBER
```

Отметить готовой к проверке:

```bash
scripts/complete-homework.sh ISSUE_NUMBER --summary "Что сделал и что понял."
```

Если задача неясна:

```bash
gh issue edit ISSUE_NUMBER --remove-label status:queued --add-label status:blocked
gh issue comment ISSUE_NUMBER --body "Нужна подсказка учителя: ..."
```

## Стандарт результата

Комментарий о готовности должен содержать:

- что ученик сделал;
- что ученик понял или потренировал;
- какие файлы или упражнения изменены;
- как результат был проверен;
- что нужно проверить учителю.

