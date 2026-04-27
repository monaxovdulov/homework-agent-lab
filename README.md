# Homework Agent Lab

Публичная лаборатория домашних заданий для русскоязычных учеников, где GitHub
Issues работают как конверты с заданиями, а Codex ученика работает как
наставник, а не как бесплатный решатель.

Это не LMS, не приватный дневник и не ферма автосдачи. Это маленький протокол:
учитель выдает задачу, ученик думает и пробует, агент держит рамку обучения,
результат уходит через pull request.

Репозиторий публичный. Не пишите сюда настоящие имена учеников, контакты,
пароли, токены, приватные ключи, скрытые ответы учителя или контекст из личных
репозиториев.

## Быстрый Вход

Текущий индекс домашних:

```text
HOMEWORK.md
```

Первая домашка:

```text
diogen -> Issue #1: Базовый мини-тест по HTTP
https://github.com/monaxovdulov/homework-agent-lab/issues/1
```

Если GitHub Issues или label-фильтры показывают пусто, это еще не значит, что
домашек нет. GitHub search иногда запаздывает. Проверяйте `HOMEWORK.md` и
скрипт:

```bash
scripts/poll-homework.sh --callsign diogen
```

## Для Людей

Если вы ученик:

1. Клонируйте репозиторий.
2. Узнайте свой позывной у учителя.
3. Откройте `HOMEWORK.md`.
4. Запустите проверку входящих:

```bash
git clone https://github.com/monaxovdulov/homework-agent-lab.git
cd homework-agent-lab
git pull --ff-only
scripts/poll-homework.sh --callsign diogen
```

5. Выберите Issue и попросите своего Codex помочь как наставника.
6. Пишите решение только в свою папку:

```text
submissions/<callsign>/issue-<number>/
```

Если вы учитель:

1. Не храните здесь реальные имена учеников.
2. Выдавайте ученикам публичные позывные.
3. Создавайте домашки через `scripts/create-homework.sh`.
4. Проверяйте pull requests учеников.
5. Закрывайте Issue только после проверки.

Если вы просто смотрите репозиторий:

```text
AGENTS.md                         # правила для Codex-агентов
HOMEWORK.md                       # публичный индекс домашних
prompts/student-codex-tutor.md    # русский промпт наставника
.agents/skills/homework-agent-lab # skill для Codex
assignments/                      # материалы заданий от учителя
submissions/                      # сдачи учеников
```

## Для Агентов

Агент ученика должен помнить три вещи:

```text
1. Позывной - это адрес, не пароль.
2. Полное решение до попытки ученика не выдавать.
3. Пустой GitHub filter не доказывает, что домашних нет.
```

Стартовый prompt для Codex ученика:

```text
Ты Codex-наставник в homework-agent-lab.
Мой позывной: diogen.
Используй skill homework-agent-lab.
Проверь входящие домашки и не бери задачу без моего подтверждения.
Работай по-русски и не делай домашку за меня.
```

Порядок старта:

```bash
git pull --ff-only
.agents/skills/homework-agent-lab/scripts/inbox.sh --callsign diogen
```

Если skill не установлен, можно напрямую:

```bash
scripts/poll-homework.sh --callsign diogen
cat HOMEWORK.md
```

Перед помощью агент должен открыть выбранный Issue, прочитать labels и работать
по режиму помощи: `mode:hints-only`, `mode:debug`, `mode:review`,
`mode:example` или `mode:reference`.

## Skill

В репозитории лежит переносимый Codex skill:

```text
.agents/skills/homework-agent-lab/
```

Он учит агента проверять домашки по позывному, обходить пустые GitHub
search-фильтры и держать учебную рамку.

Установка на Linux/macOS из корня клона:

```bash
mkdir -p ~/.codex/skills
ln -s "$PWD/.agents/skills/homework-agent-lab" ~/.codex/skills/homework-agent-lab
export HOMEWORK_AGENT_LAB="$PWD"
```

Если symlink уже существует:

```bash
rm ~/.codex/skills/homework-agent-lab
ln -s "$PWD/.agents/skills/homework-agent-lab" ~/.codex/skills/homework-agent-lab
```

Установка на Windows PowerShell из корня клона:

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.codex\skills"
$SkillPath = "$env:USERPROFILE\.codex\skills\homework-agent-lab"
Remove-Item -Recurse -Force $SkillPath -ErrorAction SilentlyContinue
Copy-Item -Recurse ".agents\skills\homework-agent-lab" $SkillPath
[Environment]::SetEnvironmentVariable("HOMEWORK_AGENT_LAB", (Get-Location).Path, "User")
```

Проверка:

```bash
~/.codex/skills/homework-agent-lab/scripts/inbox.sh --callsign diogen
```

## Как Это Работает

```text
Учитель создает GitHub Issue
  -> Issue получает labels позывного и режима помощи
  -> HOMEWORK.md получает прямую ссылку
  -> ученик запускает Codex-наставника
  -> агент находит домашку по позывному
  -> ученик пишет план, пробует, проверяет и объясняет
  -> сдача идет через pull request
  -> учитель проверяет и закрывает Issue
```

GitHub Issues здесь играют роль почты. `HOMEWORK.md` играет роль доски на
стене: если почтовый фильтр GitHub притворился пустым, доска все равно видна.

## Позывные

У каждого ученика есть публичный позывной:

```text
diogen
sokrat
platon
```

Позывной нужен только для маршрутизации:

```text
student:diogen
diogen
```

В публичном репозитории позывной не является секретом. Таблица соответствий
`позывной -> человек` должна жить только в приватном месте, не здесь.

Если нужна настоящая приватность между учениками, используйте private repo,
закрытую LMS или отдельный сервис с авторизацией.

## Создать Домашку

Основной путь:

```bash
scripts/create-homework.sh \
  --callsign diogen \
  --title "Функции в Python" \
  --goal "Понять цикл, условие и возврат значения из функции." \
  --body "Напиши функцию sum_even(numbers), которая возвращает сумму четных чисел." \
  --pre-code "До кода: объясни задачу своими словами, напиши план из 3 шагов и придумай 3 примера входа/выхода." \
  --checks "Проверь: [], [1, 2, 3, 4], [2, 4, 6]." \
  --reflection "В конце напиши, где была ошибка и почему итоговый вариант работает."
```

Скрипт создает GitHub Issue, ставит labels ученика и режима помощи, добавляет
простые UI-labels и обновляет `HOMEWORK.md`.

Через GitHub UI тоже можно: Issues -> New issue -> Homework assignment.

Если создаете через UI, вручную добавьте labels ученика:

```text
student:diogen
diogen
```

GitHub issue form не умеет сам создавать label из поля "Позывной".

## Учебный Контракт

Хорошая домашка ведет ученика по маршруту:

```text
понять -> спланировать -> попробовать -> проверить -> исправить -> объяснить
```

По умолчанию домашка получает:

```text
статус:ждет-ученика 🕯️
mode:hints-only
plan:required
attempt:required
checks:required
reflection:required
```

Это значит:

- сначала ученик пишет план своими словами;
- потом делает первую попытку;
- Codex дает подсказки, вопросы и разбор ошибок;
- ученик проверяет результат тестами или примерами;
- в конце ученик пишет короткую рефлексию.

Полное эталонное решение разрешено только с явным label:

```text
mode:reference
```

И только если учитель действительно хочет показать разбор после попытки ученика.

## Сдача

Решение кладется сюда:

```text
submissions/<callsign>/issue-<number>/
```

Пример:

```text
submissions/diogen/issue-1/
```

Если есть материалы от учителя, они лежат отдельно:

```text
assignments/issue-1/
```

Сдача кода идет через pull request:

```text
branch: student/<callsign>/issue-<number>
PR title: [<callsign>][#<number>] Решение домашки
PR body: Refs #<number>
```

Не используйте `Closes #<number>` в PR. Issue закрывает учитель после проверки.

Когда домашка готова к проверке:

```bash
scripts/complete-homework.sh ISSUE_NUMBER --summary "Что сделал и что понял."
```

## Labels

Основные labels:

```text
role:student
role:teacher
kind:homework
kind:question
kind:review
help:tutor
privacy:public-safe
```

Статусы:

```text
статус:ждет-ученика 🕯️
статус:ученик-работает ✏️
статус:ждет-проверки 🔍
статус:нужны-правки 📝
статус:нужна-помощь ❓
статус:зачтено ✅
```

Режимы помощи:

```text
mode:hints-only
mode:debug
mode:review
mode:example
mode:reference
```

Контрольные точки:

```text
plan:required
attempt:required
checks:required
reflection:required
```

Маршрутизация ученика:

```text
student:<callsign>
<callsign>
```

Старые технические labels вида `status:*` для новых домашних не используются.

## Режимы Помощи

`mode:hints-only` - режим по умолчанию. Только подсказки, вопросы, мини-примеры
и проверка рассуждений. Полное решение не выдавать.

`mode:debug` - разбор ошибки в уже написанном коде ученика. Можно предложить
маленькое исправление после попытки.

`mode:review` - ревью готовой попытки: что работает, что сломается, что можно
упростить.

`mode:example` - похожий пример, но не прямое решение этой же домашки.

`mode:reference` - эталонное решение только если учитель явно поставил этот
режим.

## Граница Помощи

Codex ученика может:

- объяснять тему;
- задавать наводящие вопросы;
- проверять код ученика;
- помогать искать ошибку;
- писать маленькие похожие примеры;
- предлагать тесты;
- помогать оформить итог после попытки ученика.

Codex ученика не должен:

- молча сдавать готовое решение вместо ученика;
- писать полный финальный ответ до попытки ученика;
- писать решение в папку другого позывного;
- использовать приватную память или личные репозитории;
- просить или сохранять секреты;
- раскрывать связь между позывным и реальным человеком.

## Если Что-То Не Видно

Если прямой Issue открывается, но GitHub Issues tab или search-filter пустой,
используйте такой порядок:

```bash
git pull --ff-only
scripts/poll-homework.sh --callsign diogen
cat HOMEWORK.md
gh issue view 1
```

Пустой web-фильтр GitHub не является источником истины для этой лаборатории.
