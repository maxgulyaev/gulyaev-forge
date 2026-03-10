# Quickstart: How to Live with the Forge

> Ты сидишь в VSCode, два терминала, шпаришь фичи.
> Вот как теперь с этим жить.

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
~/Documents/Dev/
  gulyaev-forge/          ← ЗАВОД (скиллы, pipeline, инструменты)
  spodi/                  ← ПРОДУКТ #1
  boyofthedaybot/         ← ПРОДУКТ #2
  ...                     ← будущие продукты
```

### Главное правило

**Два контура. Не смешивай.**

| Контур | Где сидишь | Что делаешь |
|--------|-----------|-------------|
| **PRODUCT** | `cd ~/Documents/Dev/spodi` | Фичи, баги, деплой, аналитика |
| **SELF** | `cd ~/Documents/Dev/gulyaev-forge` | Скиллы, MCP, паттерны, ретро |

Forge не трогаешь когда работаешь над продуктом. Продукт не трогаешь когда работаешь над forge.

---

## Как начать работу (каждый день)

### Сценарий 1: Делаю фичу / фикшу баг

```bash
# 1. Открой VSCode в папке продукта
cd ~/Documents/Dev/spodi
code .

# 2. Открой терминал, запусти агента
claude    # или codex, cursor — любой

# 3. Скажи что делать
```

**Примеры команд агенту:**

| Что говоришь | Что произойдёт |
|-------------|----------------|
| "Хочу сделать суперсеты" | Полный pipeline: PRD → Design → Architecture → Code → QA → Deploy |
| "Баг: кнопка не работает на iOS" | Quick path: сразу тест → фикс → деплой |
| "Пофикси issue #42" | Агент читает issue, кодит, создаёт PR |
| "Какие метрики сейчас?" | Аналитика: дашборд, фаннелы, когорты |

### Сценарий 2: Улучшаю завод

```bash
# 1. Открой VSCode в папке forge
cd ~/Documents/Dev/gulyaev-forge
code .

# 2. Запусти агента
claude

# 3. Скажи что делать
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
mkdir ~/Documents/Dev/my-new-project && cd $_

# 2. Инициализируй git, код, whatever

# 3. Подключи к forge (пока руками, потом /init):
mkdir -p .forge
cp ~/Documents/Dev/gulyaev-forge/core/templates/project-context.yaml .forge/config.yaml
# Заполни config.yaml под проект

# 4. Работай как обычно — агент видит .forge/config.yaml
claude
```

---

## Как агент понимает что делать?

Агент получает два слоя контекста:

```
Слой A — Экспертиза этапа (из forge)
  ~/Documents/Dev/gulyaev-forge/core/skills/[stage]/SKILL.md
  Как писать PRD, как делать архитектуру, как деплоить и т.п.

Слой B — Контекст проекта (из .forge/config.yaml)
  Стратегия, бэклог, стек, метрики — отфильтрованные под роль агента
  PRD-агент видит стратегию + бэклог, но не видит деплой-конфиг
  DevOps-агент видит деплой-конфиг, но не видит бэклог
```

Пока адаптер не написан, агент читает скиллы по прямому пути. В `CLAUDE.md` проекта уже должна быть ссылка:
```markdown
## Forge Pipeline
Skills: ~/Documents/Dev/gulyaev-forge/core/skills/
Pipeline: ~/Documents/Dev/gulyaev-forge/core/pipeline/orchestrator.md
```

---

## Шаг 0: Подключение MCP серверов

### Context7 (свежие доки библиотек)

Через marketplace (рекомендуется):
```bash
claude /install-plugin context7
```

Или вручную — добавь в `~/.claude/settings.json`:
```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"]
    }
  }
}
```

Проверка: в claude напиши "найди доки Fiber v2" — должен подтянуть актуальные.

### Playwright (браузерное тестирование)

```bash
claude /install-plugin playwright
```

Или вручную:
```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/mcp-server-playwright"]
    }
  }
}
```

### GitHub (issues, PRs, boards)

```bash
claude /install-plugin github
```

Или вручную:
```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "<твой токен>"
      }
    }
  }
}
```

GitHub токен: Settings → Developer settings → Personal access tokens → Generate new token (repo, project scopes).

---

## Шаг 1: Инициализация проекта (Spodi)

Пока `/init` скилл не написан, делаем руками:

### 1.1 Создай .forge/config.yaml в Spodi

```bash
mkdir -p ~/Documents/Dev/spodi/.forge
```

```yaml
# ~/Documents/Dev/spodi/.forge/config.yaml
project:
  name: spodi
  description: "Fitness tracking ecosystem — gym workout diary"
  stage: mvp
  repo: https://github.com/maxgulyaev/spodi

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
    priority_prefix: "priority/"

deploy:
  current: single_vm
  environments:
    staging: "localhost (docker-compose)"
    production: "https://api.spodi.ru"

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
        - docs/spodi-domain-model.md
  implementation:
    inject:
      required:
        - CLAUDE.md
  qa:
    inject:
      required: []
      if_exists: []
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

### 1.2 Создай недостающие папки

```bash
cd ~/Documents/Dev/spodi
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
cd ~/Documents/Dev/spodi

# Level
gh label create "level/epic" --color "7B68EE" --description "Feature/initiative"
gh label create "level/story" --color "4169E1" --description "User-facing behavior"
gh label create "level/task" --color "2E8B57" --description "Concrete work item"

# Stage
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
gh label create "source/prd" --color "FFFFFF" --description "From PRD"
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
    ▼ PRD — требования (EARS), user stories, метрики
    │   ↓ Гейт → ты аппрувишь
    │   ↓ Создаёт Epic + Stories в GitHub Issues
    │
    ▼ Design — UI/UX, потоки, accessibility
    ▼ Architecture — модель данных, API, ADR
    │   ↓ Гейт → ты аппрувишь
    │   ↓ Создаёт Tasks по дисциплинам (backend, frontend, mobile, test)
    │
    ▼ Test Plan — стратегия тестирования, E2E сценарии
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

---

## Другие агенты (когда будут адаптеры)

| Агент | Как читает скиллы | Адаптер |
|-------|-------------------|---------|
| **Claude Code** | CLAUDE.md + прямые пути к skills/ | `adapters/claude-code/` (TODO) |
| **Codex** | AGENTS.md | `adapters/codex/` (TODO) |
| **Cursor** | `.cursorrules` + `.cursor/rules/` | `adapters/cursor/` (TODO) |
| **Windsurf** | `.windsurfrules` | `adapters/windsurf/` (TODO) |

Пока адаптеров нет — все агенты читают скиллы по прямым путям. Это работает.

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
| `/init` скилл | TODO | Автоматизация шага 1 |
| Claude Code адаптер | TODO | Генерация .claude/ из core |
| Codex адаптер | TODO | Генерация AGENTS.md из core |
| MCP setup | TODO | Подключить Context7, Playwright, GitHub |
| Spodi config | TODO | `.forge/config.yaml` |
| Spodi labels | TODO | GitHub labels |
| Spodi REVIEW.md | ГОТОВО | `REVIEW.md` в репе Spodi |

---

## FAQ

**Q: Обязательно проходить все 13 этапов?**
Нет. Quick path для мелких задач: сразу Implementation → Code Review → Deploy.

**Q: Что если я работаю в Codex а не Claude Code?**
Core скиллы — чистый markdown. Любой агент может их прочитать по пути. Адаптеры добавим позже.

**Q: Где хранить креды для MCP?**
В `~/.claude/settings.json` (не в репе). GitHub токен — через env переменные.

**Q: Как обновить скилл?**
`cd gulyaev-forge` → правишь `core/skills/[stage]/SKILL.md` → commit → push. Все проекты сразу видят обновление.

**Q: Как добавить новый проект?**
1. `mkdir -p project/.forge`
2. Скопируй `core/templates/project-context.yaml` → `project/.forge/config.yaml`
3. Заполни под проект
4. Создай `REVIEW.md`
5. Создай labels в GitHub
