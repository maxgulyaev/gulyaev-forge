# Quickstart: How to Live with the Forge

> Ты сидишь в VSCode, два терминала (Claude Code + Codex), шпаришь фичи.
> Вот как теперь с этим жить.

## Твоя повседневная структура

```
~/Documents/Dev/
  gulyaev-forge/          ← ЗАВОД (скиллы, pipeline, инструменты)
  spodi/                  ← ПРОДУКТ #1
  boyofthedaybot/         ← ПРОДУКТ #2
  ...                     ← будущие продукты
```

**Правило**: forge не трогаешь когда работаешь над продуктом. Продукт не трогаешь когда работаешь над forge. Два контура.

---

## Два контура: когда что запускать

### PRODUCT — работаешь над продуктом
```bash
cd ~/Documents/Dev/spodi
claude    # или codex, cursor — любой агент
```

Говоришь:
- "Сделаем фичу суперсеты" → pipeline с нужного этапа
- "Баг: кнопка не работает" → quick path (сразу implementation)
- "Как метрики?" → аналитика
- "Статус" → dashboard

### SELF — работаешь над заводом
```bash
cd ~/Documents/Dev/gulyaev-forge
claude    # или любой агент
```

Говоришь:
- "Вот новая штука X, посмотри" → scout
- "Добавим MCP для мониторинга" → meta
- "Обнови скилл архитектуры" → meta
- "Что работает плохо?" → ретро

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

## Шаг 2: Ежедневная работа

### Фича по pipeline (полный цикл)

```
"Хочу сделать суперсеты"
    │
    ▼ Агент читает forge/core/skills/prd/SKILL.md
    ▼ Агент читает spodi/.forge/config.yaml → stages.prd.inject
    ▼ Агент загружает: стратегию, бэклог
    │
    ▼ Пишет PRD → гейт → ты аппрувишь
    ▼ Создаёт Epic + Stories в GitHub Issues
    ▼ Architecture → гейт → ты аппрувишь
    ▼ Создаёт Tasks по дисциплинам
    ▼ Implementation (TDD) → Code Review → QA
    ▼ Deploy → Analytics → Monitoring → обратно в Strategy
```

### Баг / мелкий фикс (quick path)

```
"Баг: кнопка не работает на iOS"
    │
    ▼ Skip прямо к Implementation
    ▼ Пишет тест воспроизводящий баг
    ▼ Фиксит → Code Review → Deploy
```

### Оценка новой технологии

```
"Вот штука X, посмотри"      ← в терминале forge
    │
    ▼ Scout: research → evaluate → recommend
    ▼ Вердикт: ADOPT / TRIAL / ASSESS / HOLD
    ▼ После OK → внедряем
```

---

## Шаг 3: Как агенты находят forge скиллы

### Claude Code (сейчас)
Пока нет адаптера — агент читает скиллы напрямую по пути:
```
~/Documents/Dev/gulyaev-forge/core/skills/[stage]/SKILL.md
```

В CLAUDE.md проекта добавь ссылку:
```markdown
## Forge Pipeline
Skills: ~/Documents/Dev/gulyaev-forge/core/skills/
Pipeline: ~/Documents/Dev/gulyaev-forge/core/pipeline/orchestrator.md
```

### Codex
Codex читает AGENTS.md. Когда напишем адаптер `adapters/codex/` — он сгенерит AGENTS.md из core скиллов. Пока — тот же подход через ссылку.

### Cursor
Cursor читает `.cursorrules` и `.cursor/rules/`. Адаптер `adapters/cursor/` сгенерит их из core.

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
