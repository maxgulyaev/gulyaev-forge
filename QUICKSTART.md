# Quickstart: How to Live with the Forge

> Ты сидишь в VSCode, два терминала, шпаришь фичи.
> Вот как теперь с этим жить.

Во всех примерах ниже используй свои пути:

```bash
FORGE_DIR=/path/to/gulyaev-forge
PROJECT_DIR=/path/to/project
```

`Spodi` ниже упоминается только как pilot example. Forge не привязан ни к нему, ни к конкретной папке на диске.

---

## Сначала выбери setup-сценарий

Не все шаги из этого файла нужны каждый раз.

Есть три нормальных входа:
1. Я только зашёл в git и увидел репозиторий, хочу себе такое же.
2. Я уже работаю с продуктами в forge и хочу ещё один продукт.
3. Я уже работаю с forge и хочу второй девайс, компьютер или VPS.

Канонический маршрут по этим кейсам:
- [docs/setup-scenarios.md](docs/setup-scenarios.md)

Короткое правило:
- machine-level setup: `claude`, `codex`, MCP, OAuth, forge checkout
- product-level setup: `forge init`, `.forge/`, repo-local commands, hooks

То есть:
- новый продукт на той же машине не требует заново ставить Figma MCP
- новый компьютер или VPS требует повторить machine bootstrap

---

## Твоё рабочее место

### Что открыто на экране

```
┌─────────────────────────────────────────────────────────┐
│  VSCode                                                 │
│  ┌───────────────────────┬─────────────────────────────┐│
│  │                       │                             ││
│  │   Код проекта         │   Терминал 1: Claude Code   ││
│  │                       │   $ claude                  ││
│  │                       │                             ││
│  │                       ├─────────────────────────────┤│
│  │                       │                             ││
│  │                       │   Терминал 2: Codex / другой││
│  │                       │   $ codex                   ││
│  │                       │                             ││
│  └───────────────────────┴─────────────────────────────┘│
└─────────────────────────────────────────────────────────┘
```

### Структура на диске

```
/workspace/
  gulyaev-forge/          ← ЗАВОД (скиллы, pipeline, инструменты)
  product-a/              ← ПРОДУКТ #1
  product-b/              ← ПРОДУКТ #2
  ...                     ← будущие продукты
```

### Главное правило

**Два контура. Не смешивай.**

| Контур | Где сидишь | Что делаешь |
|--------|-----------|-------------|
| **PRODUCT** | `cd "$PROJECT_DIR"` | Фичи, баги, деплой, аналитика |
| **SELF** | `cd "$FORGE_DIR"` | Скиллы, MCP, паттерны, ретро |

Forge не трогаешь когда работаешь над продуктом. Продукт не трогаешь когда работаешь над forge.

---

## Как начать работу (каждый день)

### Сценарий 1: Делаю фичу / фикшу баг

```bash
# 1. Открой VSCode в папке продукта
cd "$PROJECT_DIR"
code .

# 2. Проверь что проект готов к pipeline
bash "$FORGE_DIR/scripts/forge-doctor.sh" product .
bash "$FORGE_DIR/scripts/forge-status.sh" product .

# 3. Открой терминал, запусти агента
claude    # или codex, cursor — любой

# 4. Скажи что делать
```

Смотри на строку `Immediate next action` в `forge-status.sh product .`:
- если там `reconcile...` — сначала чини sync состояния
- если там `record the current gate decision...` — сейчас нужен gate
- если там `continue the current ... stage...` — gate сейчас не нужен, проси checkpoint и следующий шаг

Если это Claude Code, лучший практический вход сейчас через slash-команды:

```text
/forge:bugfix Кнопка сохранения тренировки сломалась
/forge:feature Хочу добавить суперсеты
/forge:investigate Разберись, почему люди отваливаются на онбординге
/forge:continue Ок, едем дальше
/forge:review
```

Source of truth для этих entrypoints:
- `$FORGE_DIR/core/pipeline/entry-surface.md`

**Как говорить с агентом:**

Говори как бизнес, а не как оркестратор.
Не нужно думать категориями `strategy/prd/qa`.
Но для Claude Code сейчас лучше заворачивать это в `/forge:*`, чтобы он точно вошёл через правильный router.
Публичный контракт команд вынесен в `core/pipeline/entry-surface.md`.

**Примеры нормальных команд агенту:**

| Что говоришь | Что произойдёт |
|-------------|----------------|
| "Хочу сделать суперсеты" | Агент сам определит, с какого stage начать, и поведёт фичу дальше |
| "Кнопка не работает на iOS. Почини." | Агент распознает bug intent и пойдёт по quick path |
| "Почему люди не доходят до оплаты? Разберись." | Агент пойдёт в аналитику/исследование, а не сразу в код |
| "Ок, едем дальше" | Агент воспримет это как gate decision и сам отзеркалит approval в issue |

Если gate сейчас не нужен, агент обязан сказать это явно в формате checkpoint:
- `Current stage`
- `Gate needed now: no`
- `What just finished`
- `Next recommended action`

Если работа идёт через модерацию вторым агентом или человеком, проси compact moderator checkpoint:
- пиши его на языке модератора
- если модерация идёт на русском, начни с `Что от тебя сейчас нужно: ...`
- `Current issue`
- `Current stage`
- `Gate needed now`
- `Recommended action`
- `Exact next step`
- `Remaining blockers`
- `Needs from moderator`

И отвечай одним из коротких решений:
- `continue`
- `run_review`
- `run_test_coverage`
- `run_qa`
- `present_gate`
- `hold`
- `input: ...`

Для русской модерации можно отвечать так:
- `продолжай`
- `запусти review`
- `запусти test_coverage`
- `прогони qa`
- `покажи gate`
- `пауза`
- `ввод: ...`

На code stage правило простое:
- если задача трогает библиотеку, фреймворк, SDK или внешний API, агент должен сначала тянуть актуальные доки через Context7
- если это багfix quick path, агент обязан завести bug issue до кода для нетривиального фикса и держать локальный quick-run state в `.forge/active-run.env`
- push в таком quick path должен блокироваться pre-push hook'ом, пока не показан QA gate и не записан approval
- если для `code_review/reviewer` настроен внешний reviewer, агент должен вызвать его до QA gate
- это не отменяется для `deploy/*.sh`, shell automation, rollback flow или runbooks, если они меняют поведение
- перед закрытием issue агент обязан показать, чем доказан каждый acceptance item; docs-апдейт не заменяет недостающий guard или smoke
- секреты из `.env`, `DATABASE_URL`, cloud console и похожих мест нельзя печатать в чат/issue; при утечке нужен rotation follow-up

### Почему так

У Claude Code плагины и общие эвристики могут перехватывать поведение раньше, чем мягкие repo-правила из `CLAUDE.md`.
Поэтому для него slash-команды сейчас не украшение, а надёжный adapter layer.

Важно: запрос вроде `Прогони #95 до Behavior Contract gate` или legacy-фраза `до PRD gate` не разрешает перепрыгивать незакрытые гейты.
Если текущий gated stage ещё не approved, агент должен остановиться на нём и запросить решение.

### Сценарий 2: Улучшаю завод

```bash
# 1. Открой VSCode в папке forge
cd "$FORGE_DIR"
code .

# 2. Проверь текущее состояние forge
bash scripts/forge-doctor.sh self .
bash scripts/forge-status.sh self .

# 3. Запусти агента
claude

# 4. Скажи что делать
```

**Примеры:**

| Что говоришь | Что произойдёт |
|-------------|----------------|
| "Вот новая штука X, посмотри" | Scout: research → evaluate → ADOPT/TRIAL/ASSESS/HOLD |
| "Добавим MCP для мониторинга" | Добавление в registry, настройка, тест |
| "Обнови скилл архитектуры" | Правка core/skills/architecture/SKILL.md |
| "Что работает плохо?" | Ретроспектива: разбор проблем, план улучшений |

### Сценарий 3: Новый проект с нуля

```bash
# 1. Создай папку
mkdir -p "$PROJECT_DIR" && cd "$PROJECT_DIR"

# 2. Инициализируй git, код, whatever

# 3. Подключи к forge
bash "$FORGE_DIR/bin/forge" init --project .

# 4. Заполни .forge/config.yaml под проект

# 5. Работай как обычно — агент видит .forge/config.yaml
claude
```

Что делает `forge init` в MVP:
- создаёт `.forge/config.yaml` и `.forge/pipeline-state.yaml`
- создаёт `CLAUDE.md`, `REVIEW.md`, `.forge/reviewers/code-review.md`
- создаёт `.forge/skills/*.md` для основных stage overlays
- создаёт базовые папки `docs/strategy`, `docs/research`, `docs/prd`, `docs/architecture`, `docs/analytics`
- ставит `.claude/commands/forge/*` и pre-push hook для Claude path

Если forge переехал в другую папку или ты поднял новый компьютер:

```bash
bash "$FORGE_DIR/bin/forge" init --project "$PROJECT_DIR" --force
```

Это обновит `CLAUDE.md`, overlay-шаблоны и локальные `/forge:*` команды под новый путь forge.

Если нужен GitHub label set:

```bash
bash "$FORGE_DIR/bin/forge" init --project . --labels
```

---

## Как агент понимает что делать?

Агент получает четыре слоя контекста:

```
Слой A — Forge base skill
  $FORGE_DIR/core/skills/[stage]/SKILL.md
  Как писать PRD, как делать архитектуру, как деплоить и т.п.

Слой B — Project overlay skill
  project/.forge/skills/[stage].md
  Локальные правила продукта для этой роли

Слой C — Контекст проекта (из .forge/config.yaml)
  Стратегия, бэклог, стек, метрики — отфильтрованные под роль агента
  PRD-агент видит стратегию + бэклог, но не видит деплой-конфиг
  DevOps-агент видит деплой-конфиг, но не видит бэклог

Слой D — Adapter shim
  .claude/skills/, AGENTS.md, .cursor/rules/...
  Доставка этих правил в формат конкретного агента
```

## Как смотреть прогресс

### В продукте

```bash
cd "$PROJECT_DIR"
bash "$FORGE_DIR/scripts/forge-status.sh" product .
```

Где смотреть:
- GitHub issue labels и комментарии
- `.forge/pipeline-state.yaml`
- stage-артефакты в `docs/strategy`, `docs/prd`, `docs/architecture`, `docs/plans`

Смотри в `pipeline-state.yaml` прежде всего:
- `current_stage`
- `current_gate_status`
- `current_stage_artifact`

Для quick path багфиксов отдельно смотри:
- `.forge/active-run.env`
- текущий bug issue
- QA gate summary перед push

Для external reviewers:
- `bash "$FORGE_DIR/scripts/forge-stage-agent.sh" show . code_review reviewer`
- `bash "$FORGE_DIR/scripts/forge-stage-agent.sh" run . code_review reviewer`

## Как аппрувить гейт

Есть два рабочих способа:

1. В текущей сессии ответить по-человечески:
   - `Ок, едем дальше`
   - `Да, но поправь вот это`
   - `Нет, стоп`
2. Для следующей сессии записать решение в issue comment:
   - `/gate approved`
   - `/gate approved_with_changes`
   - `/gate rejected`

Если approval дан в чате, агент обязан сначала отзеркалить его в issue, и только потом двигать `stage/*` labels и `.forge/pipeline-state.yaml`.

### В forge

```bash
cd "$FORGE_DIR"
bash scripts/forge-status.sh self .
```

Где смотреть:
- `docs/design.md` roadmap
- `git status`
- `git log --oneline`

Для Claude Code adapter уже есть: `.claude/commands/forge/*.md`.
Для остальных агентов пока работает repo-local routing через `AGENTS.md` / rules / прямые пути к forge.
В `CLAUDE.md` проекта уже должна быть ссылка:
```markdown
## Forge Pipeline
Skills: $FORGE_DIR/core/skills/
Pipeline: $FORGE_DIR/core/pipeline/orchestrator.md
```

---

## Шаг 0: Подключение MCP серверов

### Context7 (свежие доки библиотек)

```bash
claude mcp add -s user context7 -- npx -y @upstash/context7-mcp@latest
```

Проверка: в claude напиши "найди доки Fiber v2" — должен подтянуть актуальные.

### Playwright (браузерное тестирование)

```bash
FORGE_DIR=/path/to/gulyaev-forge
bash "$FORGE_DIR/bin/forge" mcp install playwright
```

Для Claude Code канонический источник истины здесь — `claude mcp` и `~/.claude.json`, не ручной блок в `~/.claude/settings.json`.

### GitHub (issues, PRs, boards)

```bash
FORGE_DIR=/path/to/gulyaev-forge
export GITHUB_PERSONAL_ACCESS_TOKEN=<токен>
bash "$FORGE_DIR/bin/forge" mcp install github
```

GitHub токен: Settings → Developer settings → Personal access tokens → Generate new token (repo, project scopes).

### Figma (дизайн, макеты)

Remote MCP (OAuth авторизация):
```bash
claude mcp add -s user --transport http figma https://mcp.figma.com/mcp
codex mcp add figma --url https://mcp.figma.com/mcp
```

После добавления:
- перезапусти Claude Code
- если используешь Codex, открой новую Codex session
- пройди OAuth в браузере

Проверка:

```bash
claude mcp list
codex mcp list
```

Подробнее: [Figma MCP Server Guide](https://help.figma.com/hc/en-us/articles/32132100833559-Guide-to-the-Figma-MCP-server)

---

## Шаг 1: Инициализация проекта (пример пилотного продукта)

Пока `/init` скилл не написан, делаем руками:

### 1.1 Создай .forge/config.yaml и .forge/skills в проекте

```bash
mkdir -p "$PROJECT_DIR/.forge"
mkdir -p "$PROJECT_DIR/.forge/skills"
```

```yaml
# $PROJECT_DIR/.forge/config.yaml
project:
  name: your-product
  description: "One-line product description"
  stage: mvp
  repo: https://github.com/your-org/your-product

agents:
  - claude-code
  - codex

stack:
  backend: [go, fiber, postgresql, redis]
  frontend: [nextjs, react, tailwind]
  mobile: [swiftui, swiftdata]
  infra: [docker, yandex-cloud]
  ai: [python, fastapi, gemini]

tracking:
  provider: github
  project_board: true
  labels:
    stage_prefix: "stage/"
    priority_prefix: "p"

deploy:
  current: single_vm
  environments:
    staging: "localhost (docker-compose)"
    production: "https://api.example.com"

metrics:
  baseline: docs/analytics/baseline.md
  analytics_provider: custom
  monitoring_provider: custom

stages:
  strategy:
    inject:
      required:
        - docs/plans/2026-02-28-product-strategy.md
        - docs/BACKLOG.md
      if_exists:
        - docs/analytics/baseline.md
  discovery:
    inject:
      required:
        - docs/plans/2026-02-28-product-strategy.md
      if_exists:
        - docs/market-research-2026-02.md
  prd:
    inject:
      required:
        - docs/plans/2026-02-28-product-strategy.md
        - docs/BACKLOG.md
      if_exists:
        - docs/market-research-2026-02.md
  design:
    inject:
      required: []
      if_exists:
        - docs/design/tahoe-design-system.md
  architecture:
    inject:
      required:
        - CLAUDE.md
      if_exists:
        - docs/domain-model.md
  test_plan:
    inject:
      required: []
      if_exists:
        - docs/domain-model.md
  implementation:
    inject:
      required:
        - CLAUDE.md
  code_review:
    inject:
      required:
        - REVIEW.md
  test_coverage:
    inject:
      required: []
      if_exists: []
  qa:
    inject:
      required: []
      if_exists: []
  staging_deploy:
    inject:
      required:
        - CLAUDE.md
      if_exists:
        - deploy/docker-compose.prod.yml
  canary_deploy:
    inject:
      required:
        - CLAUDE.md
      if_exists:
        - deploy/docker-compose.prod.yml
        - docs/ops/release-checklist.md
  product_analytics:
    inject:
      required:
        - docs/plans/2026-02-28-product-strategy.md
      if_exists:
        - docs/analytics/baseline.md
  tech_monitoring:
    inject:
      required: []
      if_exists:
        - docs/analytics/baseline.md
```

Пример overlay-файла для конкретного stage:

```bash
bash "$FORGE_DIR/bin/forge" init --project "$PROJECT_DIR" --dry-run
```

### 1.2 Создай недостающие папки

```bash
cd "$PROJECT_DIR"
mkdir -p docs/{strategy,research,prd,prd/stories,architecture,architecture/adr,design,analytics,runbooks,release-notes}
```

### 1.3 Перенеси существующие файлы (опционально)

```bash
# Стратегия
cp docs/plans/2026-02-28-product-strategy.md docs/strategy/current.md

# Research
cp docs/market-research-2026-02.md docs/research/2026-02-market-research.md
```

### 1.4 Создай labels в GitHub

```bash
cd "$PROJECT_DIR"

# Level
gh label create "level/epic" --color "7B68EE" --description "Feature/initiative"
gh label create "level/story" --color "4169E1" --description "User-facing behavior"
gh label create "level/task" --color "2E8B57" --description "Concrete work item"

# Stage
gh label create "stage/strategy" --color "E0E0E0" --description "Strategy in progress"
gh label create "stage/discovery" --color "E0E0E0" --description "Discovery in progress"
gh label create "stage/prd" --color "E0E0E0" --description "Requirements defined"
gh label create "stage/design" --color "E0E0E0" --description "Design in progress"
gh label create "stage/architecture" --color "E0E0E0" --description "Architecture defined"
gh label create "stage/implementation" --color "E0E0E0" --description "In development"
gh label create "stage/review" --color "E0E0E0" --description "In code review"
gh label create "stage/qa" --color "E0E0E0" --description "In QA"
gh label create "stage/shipped" --color "E0E0E0" --description "Deployed to production"

# Priority (keep existing p0, p1, p2 if already there)

# Discipline
gh label create "discipline/design" --color "F0C0FF" --description "UI/UX work"
gh label create "discipline/backend" --color "C0F0C0" --description "API/DB work"
gh label create "discipline/frontend" --color "C0E0FF" --description "Web UI work"
gh label create "discipline/mobile" --color "FFE0C0" --description "iOS/Android work"
gh label create "discipline/test" --color "FFC0C0" --description "Test/QA work"
gh label create "discipline/devops" --color "E0E0E0" --description "Deploy/infra work"

# Source
gh label create "source/prd" --color "FFFFFF" --description "From behavior contract"
gh label create "source/analytics" --color "FFFFFF" --description "From product analytics"
gh label create "source/monitoring" --color "FFFFFF" --description "From tech monitoring"

# Type (keep existing if any)
gh label create "type/feature" --color "FFFFFF" --description "New functionality"
gh label create "type/bug" --color "FFFFFF" --description "Defect"
gh label create "type/improvement" --color "FFFFFF" --description "Enhancement"
gh label create "type/tech-debt" --color "FFFFFF" --description "Internal quality"
```

---

## Как проходит pipeline (подробно)

### Фича — полный цикл

```
"Хочу сделать суперсеты"
    │
    ▼ Strategy — нужна ли фича? совпадает со стратегией?
    ▼ Discovery — ресерч конкурентов, пользователей
    ▼ Behavior Contract — intent, behavior, corner cases, proof
    │   ↓ Гейт → ты аппрувишь
    │   ↓ Создаёт Epic + Stories в GitHub Issues
    │
    ▼ Design — UI/UX, потоки, accessibility
    ▼ Architecture — модель данных, API, ADR
    │   ↓ Гейт → ты аппрувишь
    │   ↓ Создаёт Tasks по дисциплинам (backend, frontend, mobile, test)
    │
    ▼ Proof Hardening — дотягивание proof section в том же контракте
    ▼ Implementation — TDD: тесты → код → рефактор
    ▼ Code Review — авто-ревью PR по REVIEW.md
    ▼ Test Coverage — проверка покрытия, закрытие дыр
    ▼ QA — E2E прогон (Playwright), accessibility, edge cases
    │   ↓ Гейт → ты аппрувишь
    │
    ▼ Staging Deploy — деплой на тест, smoke test
    ▼ Canary Deploy — 5% → 25% → 50% → 100%
    ▼ Product Analytics — метрики vs цели, фаннелы
    ▼ Tech Monitoring — ошибки, latency, SLA
    │
    ↺ Обратно в Strategy (continue / amplify / pivot / kill)
```

### Баг / мелкий фикс — quick path

```
"Баг: кнопка не работает на iOS"
    │
    ▼ Skip прямо к Implementation
    ▼ Пишет тест воспроизводящий баг
    ▼ Фиксит → Code Review → Deploy
```

### Оценка новой технологии — scout (в forge терминале!)

```
"Вот штука X, посмотри"
    │
    ▼ Research → Evaluate → Recommend
    ▼ Вердикт: ADOPT / TRIAL / ASSESS / HOLD
    ▼ После OK → внедряем во все проекты
```

Что использовать:
- `core/skills/scout/SKILL.md` — как оценивать
- `core/templates/scout-note-template.md` — шаблон заметки
- `docs/research/scout-queue.md` — backlog входящих находок
- `core/registry/mcp-servers.yaml` — технический каталог, если находка туда подходит

---

## Вход по агентам

| Агент | Entry surface | Надёжность сейчас |
|-------|---------------|-------------------|
| **Claude Code** | `.claude/commands/forge/*.md` | Высокая |
| **Codex** | `AGENTS.md` + repo-local rules | Средняя |
| **Cursor** | `.cursor/rules/` / `.cursorrules` (target) | Низкая, адаптер ещё не готов |
| **Windsurf** | `.windsurfrules` (target) | Низкая, адаптер ещё не готов |
| **Cloud agents / Jules / OpenClaw UI** | issue packet + approved artifact | Концепт / вручную |

### Claude Code

PRODUCT:

```bash
cd "$FORGE_DIR"
bash scripts/forge-doctor.sh self .
bash scripts/forge-status.sh self .

cd "$PROJECT_DIR"
claude
```

```text
/forge:bugfix Кнопка сохранения тренировки сломалась
/forge:feature Хочу добавить суперсеты
/forge:investigate Разберись, почему люди отваливаются на онбординге
/forge:continue
/forge:gate Ок, едем дальше
/forge:release Залей на TestFlight апдейт
```

SELF:

```bash
cd "$FORGE_DIR"
claude
```

```text
/forge:self Сделай forge более рабочим
```

### Codex

PRODUCT:

```bash
cd "$PROJECT_DIR"
codex
```

```text
Сломалось сохранение тренировки. Почини.
Хочу добавить суперсеты.
Покажи текущий gate по #95.
Ок, едем дальше.
```

SELF:

```bash
cd "$FORGE_DIR"
codex
```

```text
Нужно улучшить pipeline.
Сделай forge более рабочим.
```

Замечание:
- для Codex это пока мягче, чем Claude slash-команды
- `AGENTS.md` уже помогает, но полноценный adapter ещё впереди
- как внешний reviewer Codex уже подключается жёстче через `stage_agents.code_review.reviewer`

## Release Targets

Если проект публикует mobile/desktop builds, заведи release targets в `.forge/config.yaml`:

```yaml
release_targets:
  ios_testflight:
    platform: ios
    channel: testflight
    deploy_stage: canary_deploy
    runbook: CLAUDE.md#testflight--ios-distribution
    scope_paths: apps/ios
  web_production:
    platform: web
    channel: production
    deploy_stage: canary_deploy
    runbook: CLAUDE.md#web--production-deploy
    scope_paths: apps/web,apps/api,deploy,migrations
```

Тогда в Claude можно писать коротко:

```text
/forge:release Залей на TestFlight апдейт
/forge:release Выложи обновление в App Store
/forge:release Выкати веб на прод
/forge:release Загрузи internal build в Play Console
```

Полезные команды:

```bash
bash "$FORGE_DIR/scripts/forge-release-target.sh" list .
bash "$FORGE_DIR/scripts/forge-release-target.sh" show . ios_testflight
bash "$FORGE_DIR/scripts/forge-release-scope.sh" dirty . ios_testflight
```

## Bugfix Trail

Для bugfix quick-path теперь нужен durable issue trail, а не только чат и `.forge/active-run.env`.

Проверка:

```bash
bash "$FORGE_DIR/scripts/forge-issue-trail.sh" show-bugfix . 101
bash "$FORGE_DIR/scripts/forge-issue-trail.sh" check-bugfix-qa . 101
```

Push bugfix-а блокируется, если в issue нет:
- `## QA Gate`
- `## Stage 6.5 — External Code Review` when configured
- `/gate approved` or `/gate approved_with_changes`

## QA Tools

Если проекту нужен repeatable web QA, добавь это в `.forge/config.yaml`:

```yaml
qa_tools:
  playwright_mcp:
    enabled: true
    use_for: web_feature_qa,web_bugfix_qa,web_release_smoke
    scope_paths: apps/web
```

Тогда для web UI багов агент должен сначала пытаться использовать Playwright MCP, а не сразу сваливаться в `manual QA pending`.

### Cursor / Windsurf

Пока native adapter не готов, работать можно только в режиме "best effort":

```text
Сломалось X. Почини.
Хочу сделать Y.
Разберись, почему происходит Z.
```

Но ожидание должно быть честным:
- это пока не production-grade routing
- без adapter layer такие агенты чаще будут сползать в generic implementation mode

### Cloud Agents / Jules / OpenClaw

Для них правильный вход — не свободный prompt, а handoff packet:
- issue
- current stage
- approved previous artifact
- exact next intent

Пример handoff:

```text
Issue: #95
Current stage: discovery
Approved artifact: docs/strategy/2026-03-10-supersets.md
Next intent: investigate and prepare discovery gate
```

OpenClaw лучше использовать как dashboard / orchestration UI:
- смотреть status
- выбирать агент
- запускать правильный entrypoint

---

## Что готово сейчас vs что будет

| Компонент | Статус | Где |
|-----------|--------|-----|
| Core skills (13 этапов) | ГОТОВО | `core/skills/*/SKILL.md` |
| Pipeline orchestrator | ГОТОВО | `core/pipeline/orchestrator.md` |
| Issue tracking + hierarchy | ГОТОВО | `core/pipeline/issue-tracking.md` |
| MCP registry | ГОТОВО | `core/registry/mcp-servers.yaml` |
| Gate template | ГОТОВО | `core/templates/gate-template.md` |
| Config template | ГОТОВО | `core/templates/project-context.yaml` |
| REVIEW.md template | ГОТОВО | `core/templates/REVIEW.md.template` |
| Design doc | ГОТОВО | `docs/design.md` |
| Pilot project config | ГОТОВО | `.forge/config.yaml` |
| Pilot project labels | ГОТОВО | стандартный label set |
| Pilot project REVIEW.md | ГОТОВО | `REVIEW.md` в репе продукта |
| `forge init` | ГОТОВО (MVP) | `scripts/forge-init.sh`, `bin/forge` |
| Claude Code адаптер | ГОТОВО (entry commands) | `adapters/claude-code/` |
| Codex адаптер | PARTIAL | External reviewer via `forge-stage-agent.sh`, full intent router позже |
| MCP setup | ГОТОВО на текущей машине + есть валидация | `~/.claude.json`, `bin/forge mcp status`, `scripts/forge-doctor.sh self .` |

---

## Новый компьютер (полная настройка с нуля)

Всё что нужно сделать на чистой машине, чтобы начать работать.

### 1. Установи инструменты

```bash
# Homebrew (если нет)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Git + GitHub CLI
brew install git gh
gh auth login

# Claude Code
npm install -g @anthropic-ai/claude-code

# (Опционально) Другие агенты
# npm install -g @openai/codex    # Codex
# brew install --cask cursor      # Cursor
```

### 2. Склонируй репозитории

```bash
mkdir -p "${WORKSPACE_DIR:-$HOME/workspace}"
cd "${WORKSPACE_DIR:-$HOME/workspace}"

# Завод (обязательно — тут скиллы и pipeline)
git clone https://github.com/maxgulyaev/gulyaev-forge.git

# Продукты
git clone git@github.com:your-org/your-product.git
# git clone git@github.com:your-org/another-product.git
```

### 3. Настрой MCP серверы (глобально, один раз на машину)

MCP серверы ставятся один раз на уровне пользователя и доступны из любого проекта на этой машине.
Канонический source of truth:
- `claude mcp add -s user ...`
- `claude mcp list`
- `~/.claude.json`
- `codex mcp add ...`
- `codex mcp list`
- `~/.codex/config.toml`

`~/.claude/settings.json` может существовать для плагинов, statusline и legacy-настроек, но не считай его главным реестром MCP для Claude Code.

Если это второй или третий продукт на той же машине, этот шаг обычно пропускается.

```bash
FORGE_DIR="${WORKSPACE_DIR:-$HOME/workspace}/gulyaev-forge"
```

```bash
# Context7 — свежие доки библиотек
claude mcp add -s user context7 -- npx -y @upstash/context7-mcp@latest

# Playwright — браузерное тестирование (этап QA), стабильная установка
bash "$FORGE_DIR/bin/forge" mcp install playwright

# GitHub — issues, PRs, boards (spec-to-issue bridge), стабильная установка
export GITHUB_PERSONAL_ACCESS_TOKEN=<токен>
bash "$FORGE_DIR/bin/forge" mcp install github

# Figma — дизайн, макеты (remote OAuth)
claude mcp add -s user --transport http figma https://mcp.figma.com/mcp
codex mcp add figma --url https://mcp.figma.com/mcp
# После новой Claude/Codex session пройди OAuth в браузере
```

GitHub токен: [Settings → Developer settings → Personal access tokens](https://github.com/settings/tokens) — scopes: `repo`, `project`.

### 4. Установи плагины Claude Code

```bash
# Superpowers — brainstorming, planning, TDD, debugging workflows
claude /install-plugin superpowers

# Everything Claude Code — Go/Swift/Python review, security, patterns
claude /install-plugin everything-claude-code

# Swift LSP (если работаешь с iOS)
claude /install-plugin swift-lsp
```

### 5. Настрой глобальные параметры

В `~/.claude/settings.json` должны остаться глобальные параметры Claude Code, например плагины и statusline:

```json
{
  "enabledPlugins": {
    "superpowers@claude-plugins-official": true,
    "everything-claude-code@everything-claude-code": true,
    "swift-lsp@claude-plugins-official": true
  }
}
```

### 6. Проверь что всё работает

```bash
bash "$FORGE_DIR/bin/forge" mcp status
bash "$FORGE_DIR/scripts/forge-doctor.sh" self "$FORGE_DIR"
claude mcp list
codex mcp list

cd "$PROJECT_DIR"
claude

# В claude напиши:
# "найди доки Fiber v2"     → Context7 должен подтянуть
# "покажи open issues"      → GitHub MCP должен ответить
# "прочитай forge pipeline" → должен найти core/pipeline/orchestrator.md
# "/forge:bugfix Тестовая поломка" → должен зайти через фордж-команду
```

### Чеклист

- [ ] `git`, `gh`, `claude` установлены
- [ ] `codex` установлен, если ты используешь Codex на этой машине
- [ ] `gulyaev-forge` склонирован в удобную для тебя папку
- [ ] Продукты склонированы рядом
- [ ] `bash "$FORGE_DIR/scripts/forge-doctor.sh" self .` проходит без ошибок
- [ ] MCP: Context7, Playwright, GitHub, Figma — видны через `claude mcp list`
- [ ] Figma виден через `codex mcp list`, если на этой машине используешь Codex
- [ ] GitHub токен добавлен
- [ ] Figma OAuth авторизация пройдена
- [ ] Плагины: superpowers, everything-claude-code
- [ ] Тест: `claude` в папке продукта → всё подхватывает

---

## FAQ

**Q: Обязательно проходить все 13 этапов?**
Нет. Quick path для мелких задач: сразу Implementation → Code Review → Deploy.

**Q: Что если я работаю в Codex а не Claude Code?**
Core скиллы — чистый markdown. Любой агент может их прочитать по пути.
Для Claude используй repo-local `/forge:*`.
Для Codex сегодня нормальный entrypoint это plain prompt вроде `forge work: ...` или pipeline task через `AGENTS.md`.

**Q: Где хранить креды для MCP?**
В machine-level MCP config, не в репе:
- Claude Code: `~/.claude.json`
- Codex: `~/.codex/config.toml`

**Q: Как обновить скилл?**
`cd gulyaev-forge` → правишь `core/skills/[stage]/SKILL.md` → commit → push. Все проекты сразу видят обновление.

**Q: Как добавить новый проект?**
1. `mkdir -p project/.forge`
2. Скопируй `core/templates/project-context.yaml` → `project/.forge/config.yaml`
3. Заполни под проект
4. Создай `REVIEW.md`
5. Создай labels в GitHub
