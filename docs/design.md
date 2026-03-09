# AI-Driven SDLC Pipeline — Meta-Agent Architecture

> Дата: 2026-03-09
> Статус: Idea / Brainstorm → Phase 0 in progress
> Автор: Max + Claude brainstorm session
> Репа: gulyaev-forge

## Концепция

Полный product loop где каждый этап выполняет специализированный AI-агент.
Каждый агент получает два типа контекста:
- **A (экспертиза этапа)** — skill с best practices, фреймворками, паттернами
- **B (контекст проекта)** — стратегия, бэклог, метрики, текущее состояние конкретного продукта

Pipeline работает через **гейты** — между этапами человек ревьюит и аппрувит.

Аналогия: **gulyaev-forge — это завод**. Завод производит продукты (PRODUCT) и модернизирует собственные станки (SELF).

---

## Полный Pipeline (Product Loop)

```
┌─────────────────────────────────────────────────────────┐
│                    PRODUCT LOOP                         │
│                                                         │
│  ┌──────────┐    ┌───────────┐    ┌──────┐             │
│  │ Strategy │───→│ Discovery │───→│ PRD  │             │
│  └────▲─────┘    └───────────┘    └──┬───┘             │
│       │                              │                  │
│       │                        ┌─────▼──────┐          │
│       │                        │   Design    │          │
│       │                        └─────┬──────┘          │
│       │                              │                  │
│       │                     ┌────────▼────────┐        │
│       │                     │  Architecture   │        │
│       │                     └────────┬────────┘        │
│       │                              │                  │
│       │                      ┌───────▼───────┐         │
│       │                      │  Test Plan    │         │
│       │                      └───────┬───────┘         │
│       │                              │                  │
│       │                    ┌─────────▼─────────┐       │
│       │                    │  Implementation   │       │
│       │                    └─────────┬─────────┘       │
│       │                              │                  │
│       │                     ┌────────▼────────┐        │
│       │                     │ Test Coverage   │        │
│       │                     └────────┬────────┘        │
│       │                              │                  │
│       │                      ┌───────▼───────┐         │
│       │                      │ Automated QA  │         │
│       │                      └───────┬───────┘         │
│       │                              │                  │
│       │                     ┌────────▼────────┐        │
│       │                     │ Staging Deploy  │        │
│       │                     └────────┬────────┘        │
│       │                              │                  │
│       │                     ┌────────▼────────┐        │
│       │                     │ Canary Deploy   │        │
│       │                     └────────┬────────┘        │
│       │                              │                  │
│  ┌────┴──────────┐    ┌──────────────▼──────────────┐  │
│  │ Tech          │◄───│ Product Analytics           │  │
│  │ Monitoring    │    │ (retention, conversion,     │  │
│  │ (errors,      │    │  feature adoption)          │  │
│  │  latency,     │    └─────────────────────────────┘  │
│  │  crashes)     │                                     │
│  └───────────────┘                                     │
└─────────────────────────────────────────────────────────┘

Decision points после аналитики:
  → Continue  — метрики растут, продолжаем roadmap
  → Amplify   — что-то стрельнуло, усиливаем
  → Pivot     — метрики плохие, меняем направление
  → Kill      — фича не работает, откатываем
```

---

## Два контура работы

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│   PRODUCT                          SELF                          │
│   "Работаем над продуктом"         "Работаем над собой"          │
│                                                                  │
│   Завод производит товар            Завод модернизирует станки   │
│                                                                  │
│   ┌─────────────────────┐          ┌─────────────────────┐      │
│   │ • New Project       │          │ • Scout             │      │
│   │ • Feature / Bug     │          │ • Meta (pipeline)   │      │
│   │ • Pivot             │          │ • Upgrade           │      │
│   │ • Analytics         │          │ • Retrospective     │      │
│   │ • Dashboard         │          │                     │      │
│   └─────────────────────┘          └─────────────────────┘      │
│                                                                  │
│   Контекст: проект                 Контекст: gulyaev-forge      │
│   Артефакты: в проекте             Артефакты: в forge            │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### Определение контура

При старте сессии Claude:
1. Читает контекст сообщения
2. Если контур очевиден → запускает playbook
3. Если неясно → спрашивает:
   ```
   Два контура:
   PRODUCT — работа над продуктом (фича, баг, новый проект, аналитика, пивот)
   SELF    — работа над собой (скиллы, MCP, модели, паттерны, pipeline)
   Что делаем?
   ```

---

### Контур PRODUCT

#### New Project
**Триггеры:** "хочу собрать новый проект", "новая идея для продукта"

1. Запускает `/init` — scaffolding структуры проекта
2. Запускает полный pipeline с этапа Strategy
3. Проект сразу под управлением 2.0

#### Feature / Bug / Improvement
**Триггеры:** "сделаем фичу X", "issue #N", "баг в Y"

1. Загружает product-context проекта
2. Определяет текущий этап pipeline
3. Запускает с нужного этапа (PRD / Architecture / Implementation...)
4. Гейты между этапами

#### Pivot
**Триггеры:** "нужно менять направление", "метрики плохие", "переосмыслить продукт"

1. Загружает текущую стратегию + аналитику
2. Запускает Strategy с фокусом на изменение направления
3. Пересматривает бэклог, приоритеты, roadmap
4. Каскадное обновление зависимых артефактов (PRD, arch...)

#### Analytics
**Триггеры:** "как метрики?", "что с retention?", "проанализируй результаты"

1. Собирает данные (PostHog, Sentry, App Store Connect...)
2. Сравнивает с baseline из project-context
3. Даёт вердикт: continue / amplify / pivot / kill
4. Обновляет metrics-baseline

#### Dashboard
**Триггеры:** "что у меня по проектам?", "статус"

```
PRODUCT
  📱 Spodi — Implementation: суперсеты (этап 6/12)
  🤖 TG-бот — idle, 2 открытых issue

SELF
  Pipeline 2.0: Phase 0 ██░░░░ 2/7 tasks
  Scout queue: Context7 MCP (ADOPT, ждёт подключения)
```

---

### Контур SELF

#### Scout
**Триггеры:** "вот штука X, посмотри", ссылка на инструмент

1. Research — что, как, зрелость
2. Evaluate — fit в pipeline, cost/benefit
3. Recommend — adopt / trial / assess / hold
4. После OK — implement везде

**Формат:**
```
[Название]
Что: одно предложение
Этапы: где в pipeline
Вердикт: ADOPT / TRIAL / ASSESS / HOLD
Почему: 1-2 предложения
Действие: что сделать
```

#### Meta
**Триггеры:** "обновим pipeline", "новый скилл", "доработаем паттерн"

1. Загружает forge roadmap
2. Показывает текущий статус
3. Вносит изменения (скилл, шаблон, документация)
4. Если generic — применяет ко всем проектам

#### Upgrade
**Триггеры:** "вышла новая модель", "обнови CLI", "новая версия MCP"

1. Оценивает breaking changes
2. Тестирует совместимость
3. Обновляет конфиги
4. Прогоняет smoke test на одном проекте → раскатывает на все

#### Retrospective
**Триггеры:** "что работает плохо?", "как улучшить процесс?", "ретро"

1. Анализирует последние N сессий
2. Выявляет паттерны: где застревали, что повторяли, где ошибались
3. Предлагает конкретные улучшения в pipeline/скиллах
4. После OK — реализует

---

## Этапы с MCP и контекстами

| # | Этап | Контекст A (skill) | Контекст B (проект) | MCP / Инструменты | Артефакт | Гейт |
|---|------|--------------------|--------------------|-------------------|----------|------|
| 0 | **Strategy** | product-strategy best practices | текущая стратегия, метрики, аналитика прошлых циклов | — | strategy doc (.md) | YES |
| 1 | **Discovery** | market-research, user-research методологии | стратегия, целевая аудитория, текущие боли | WebSearch, WebFetch, PostHog API | research report (.md) | YES |
| 2 | **PRD** | PRD best practices, user stories шаблоны | стратегия, research report, бэклог | — | PRD (.md) с acceptance criteria | YES |
| 3 | **Design** | UI/UX паттерны, design system | PRD, текущий дизайн, бренд гайдлайны | **Figma MCP** | макеты / design specs | YES |
| 4 | **Architecture** | arch patterns, масштабирование, security | PRD, design, текущий стек, схема БД | **Context7 MCP** (свежие доки) | arch doc + diagrams | YES |
| 5 | **Test Plan** | testing strategies, coverage patterns | PRD (acceptance criteria), arch doc | — | test plan (.md) | NO |
| 6 | **Implementation** | coding standards, паттерны стека | arch doc, test plan, текущий код | **Context7 MCP** | PR с кодом | YES |
| 7 | **Test Coverage** | TDD, coverage best practices | test plan, написанный код | — | тесты + coverage report | NO |
| 8 | **Automated QA** | e2e testing patterns | PRD (acceptance criteria), staging URL | **Playwright MCP** | QA report + скриншоты | YES |
| 9 | **Staging Deploy** | deploy patterns | текущая инфра, deploy config | Docker MCP / Bash | работающий staging | NO |
| 10 | **Canary Deploy** | canary/blue-green patterns | deploy strategy, prod config | Bash + SSH (или K8s когда дорастём) | canary live | YES |
| 11 | **Product Analytics** | analytics methodology, A/B testing | метрики до фичи, target KPI из PRD | PostHog/Amplitude API | analytics report | YES |
| 12 | **Tech Monitoring** | SRE best practices, alerting | baseline метрики, SLA | **Sentry MCP**, Grafana API | monitoring report | YES |

---

## Формат гейтов

Каждый гейт содержит 3 блока:

### Блок 1: Summary (для быстрого ревью)
```markdown
## Gate: [Название этапа]
**Статус:** go / go with concerns / stop
**Что сделано:** 3-5 bullet points
**Ключевые решения:** что было выбрано и почему (1-2 строки)
**Риски:** если есть
**Вопрос к тебе:** конкретный вопрос для аппрува
```

### Блок 2: Detailed (для глубокого ревью)
```markdown
## Детали
- Полный артефакт этапа (ссылка на файл)
- Чеклист проверки: на что обратить внимание
- Trade-offs: варианты которые рассматривались
- Diff: что изменилось по сравнению с предыдущим состоянием
```

### Блок 3: Rollback Plan
```markdown
## Откат
- Затронутые файлы / миграции / деплои
- Команды для отката (git revert SHA, migration down, deploy rollback)
- Состояние "до" (ссылка на коммит/тег)
- Зависимости: что ещё может сломаться при откате
```

---

## Мета-агент: Skill над скиллами

### Проблема
Ни один агент не может знать всё. Для задачи "спроектировать систему на 500K юзеров" нужны скиллы по Kubernetes, очередям, шардингу — которых может не быть в текущем наборе.

### Решение: Meta-Agent
Агент который **управляет собственным набором инструментов**:

```
Задача поступает
    │
    ▼
Meta-Agent оценивает задачу
    │
    ▼
Проверяет текущие скиллы и MCP
    │
    ├── Хватает → запускает этап
    │
    └── Не хватает → ищет в Registry
            │
            ▼
        Предлагает человеку:
        "Для этой задачи нужен X. Подключаем? [Y/N]"
            │
            ▼
        После аппрува — устанавливает и использует
```

### Что meta-agent умеет:
1. **Inventory** — знает какие скиллы/MCP уже установлены
2. **Gap Analysis** — определяет чего не хватает для конкретной задачи
3. **Search** — ищет нужные скиллы в registry / интернете
4. **Recommend** — предлагает конкретные инструменты с обоснованием
5. **Install** — после аппрува подключает (добавляет MCP в конфиг, скилл в проект)
6. **Delegate** — передаёт задачу специализированному агенту с правильным контекстом

---

## Centralized Skill & MCP Registry (будущий отдельный проект)

### Идея
Единый реестр скиллов и MCP серверов — как npm/PyPI но для AI-агентов.

### Что должен содержать:
- **Каталог скиллов** — по категориям (architecture, testing, deploy, analytics...)
- **Каталог MCP серверов** — с описанием capabilities
- **Метаданные** — версия, автор, совместимость, рейтинг
- **Dependency graph** — какие скиллы хорошо работают вместе
- **Search API** — чтобы meta-agent мог программно искать

### Источники для начального наполнения:
- `everything-claude-code` коллекция (уже установлена, 70+ скиллов)
- `superpowers` коллекция
- GitHub: `awesome-mcp-servers`, `awesome-claude-code`
- Официальные MCP от Anthropic, Playwright, Figma и т.д.
- Community skills из open source

### Формат записи в registry:
```yaml
name: kubernetes-architect
type: skill
category: [architecture, infrastructure, deploy]
description: Kubernetes cluster design, scaling strategies, Helm charts
works_with:
  - docker-patterns
  - terraform-mcp
  - monitoring-patterns
project_context_needs:
  - current infrastructure description
  - expected scale (users, RPS)
  - budget constraints
install: claude skill add kubernetes-architect
```

---

## Deploy Strategy Abstraction

Pipeline не привязан к конкретной инфре. Каждый проект декларирует стратегию деплоя:

```yaml
deploy:
  current: single_vm
  strategies:
    single_vm:
      description: "1 VM, Docker Compose, rsync deploy"
      suitable_for: "< 5K users"
    blue_green:
      description: "2 VM, nginx weighted routing"
      suitable_for: "5K - 50K users"
    canary_alb:
      description: "Application Load Balancer, weighted routing"
      suitable_for: "50K - 500K users"
    kubernetes:
      description: "Managed K8s, Helm, HPA autoscaling"
      suitable_for: "> 500K users or microservices"
```

---

## Project Scaffolding (`/init`)

При подключении проекта к pipeline — команда `/init` создаёт правильную структуру файлов.

### Два сценария:
- **Новый проект** → создаёт с нуля
- **Существующий проект** (подбивка) → сканирует, дополняет недостающее

### Обязательный минимум (любой проект):
```
.claude/
  pipeline/
    project-context.yaml     # Кто мы, что делаем, стек, метрики, контексты по этапам
CLAUDE.md                    # Правила для агентов, стек, code style
docs/
  strategy/                  # Стратегия продукта → этап Strategy
  research/                  # Discovery отчёты → этап Discovery
  prd/                       # Требования, user stories → этап PRD
  architecture/              # Техдизайн, ADR, диаграммы → этап Architecture
  analytics/                 # Продуктовая и техническая аналитика → замыкание цикла
```

### Опциональные расширения (по стеку):
```
# Frontend (web/mobile UI)
docs/design/                 # UI/UX спеки, скриншоты макетов, design tokens

# Backend (API, services)
migrations/                  # SQL миграции (numbered)
docs/runbooks/               # Deploy, rollback, incident response

# Mobile (iOS/Android)
docs/release-notes/          # Чейнджлоги для App Store / Google Play

# ML/AI
docs/experiments/            # A/B тесты, модели, эксперименты

# Инфра (multi-node, k8s)
infra/                       # Terraform, Helm charts, k8s manifests
docs/sla/                    # SLA, SLO, SLI определения
```

### Как работает `/init`:
```
forge init --project ./spodi

Сканирую текущую структуру...
  ✅ CLAUDE.md — есть
  ✅ docs/ — есть
  ✅ migrations/ — есть
  ❌ .claude/pipeline/project-context.yaml — нет → СОЗДАТЬ
  ❌ docs/strategy/ — нет (найден docs/plans/product-strategy.md) → ПЕРЕНЕСТИ
  ❌ docs/research/ — нет (найден docs/market-research-*.md) → ПЕРЕНЕСТИ
  ❌ docs/prd/ — нет → СОЗДАТЬ
  ❌ docs/architecture/ — нет → СОЗДАТЬ
  ❌ docs/analytics/ — нет → СОЗДАТЬ

Стек: Go + Next.js + SwiftUI → предлагаю расширения:
  ✅ migrations/ — уже есть
  ❌ docs/design/ → СОЗДАТЬ (есть фронтенд)
  ❌ docs/runbooks/ → СОЗДАТЬ (есть бэкенд)
  ❌ docs/release-notes/ → СОЗДАТЬ (есть мобайл)

Создаём? [Y/N]
```

### Правила scaffolding:
1. **Никогда не удаляет** существующие файлы
2. **Предлагает перенос** если находит файлы в нестандартных местах
3. **Создаёт README.md** в каждой новой папке с описанием что тут хранится
4. **Генерирует project-context.yaml** на основе анализа проекта (стек, структура)
5. **Коммитит** изменения отдельным коммитом "chore: init forge pipeline structure"

---

## Контекст B: Project Context Injection

Каждый проект содержит набор файлов которые инжектятся в агента:

```yaml
# project-context.yaml
project: spodi
stages:
  strategy:
    inject: [docs/strategy/current.md, docs/analytics/metrics-baseline.md, docs/BACKLOG.md]
  discovery:
    inject: [docs/strategy/current.md, docs/strategy/target-audience.md]
  prd:
    inject: [docs/strategy/current.md, docs/BACKLOG.md, docs/research/latest.md]
  design:
    inject: [docs/prd/current.md, docs/design/brand-guidelines.md, docs/design/design-system.md]
  architecture:
    inject: [docs/prd/current.md, docs/design/current.md, CLAUDE.md]
  implementation:
    inject: [docs/architecture/current.md, CLAUDE.md, docs/prd/test-plan.md]
  product_analytics:
    inject: [docs/strategy/current.md, docs/analytics/metrics-baseline.md, docs/prd/current.md]
  tech_monitoring:
    inject: [docs/analytics/metrics-baseline.md, docs/runbooks/deploy-config.md]
```

---

## Technology Scout Workflow

Когда пользователь скидывает новый инструмент (модель, MCP, скилл, библиотеку):

```
Пользователь: "Вот штука X, посмотри"
        │
        ▼
   1. RESEARCH
   - Что это, как работает, зрелость, community
   - Аналоги и альтернативы
        │
        ▼
   2. EVALUATE
   - На каких этапах pipeline полезно?
   - Cost/benefit (сложность внедрения vs выигрыш)
   - Риски (зависимость, стабильность, безопасность)
   - Совместимость с текущим стеком
        │
        ▼
   3. RECOMMEND
   - Вердикт: adopt / trial / assess / hold
   - Конкретно куда встаёт в pipeline
   - Какие текущие инструменты заменяет/дополняет
        │
        ▼
   4. IMPLEMENT (после OK пользователя)
   - Подключить ко всем проектам где применимо
   - Обновить registry (когда появится)
   - Обновить pipeline design doc
   - Обновить CLAUDE.md если влияет на workflow
```

Вердикты:
- **Adopt** — внедряем сразу, явный выигрыш
- **Trial** — пробуем на одном проекте/этапе
- **Assess** — интересно, но нужно больше инфы / подождать зрелости
- **Hold** — не сейчас (с объяснением почему)

---

## Roadmap реализации

### Принцип: generic с первого дня, обкатка на Spodi

Проекты под управление: Spodi (основной), TG-бот, будущие проекты.
Всё что создаём для pipeline — переиспользуемо между проектами.

---

### Phase 0: Фундамент
> Цель: репа gulyaev-forge + базовая инфраструктура

- [x] **0.1** Создать репу `gulyaev-forge` со структурой
- [ ] **0.2** Перенести design doc из Spodi в forge
- [ ] **0.3** Установить и настроить ключевые MCP серверы:
  - Context7 (свежие доки библиотек → этапы Architecture, Implementation)
  - Playwright MCP (браузерное тестирование → этап Automated QA)
  - Figma MCP (если используется Figma → этап Design)
- [ ] **0.4** Реализовать `/init` — scaffolding скилл
- [ ] **0.5** Создать шаблон `project-context.yaml`
- [ ] **0.6** Обкатать `/init` на Spodi — подбить под стандартную структуру
- [ ] **0.7** Создать мастер-skill `/pipeline` — точка входа, знает этапы и порядок

### Phase 1: Первые 3 этапа (Strategy → Discovery → PRD)
> Цель: product-часть pipeline работает end-to-end

- [ ] **1.1** Skill `pipeline-strategy` (A: strategy frameworks + B: project context)
- [ ] **1.2** Skill `pipeline-discovery` (A: research methods + B: strategy, аудитория)
- [ ] **1.3** Skill `pipeline-prd` (A: PRD best practices + B: strategy, research, бэклог)
- [ ] **1.4** Gate format — реализовать шаблон гейта (summary + detailed + rollback)
- [ ] **1.5** Обкатать на реальной фиче Spodi: прогнать Strategy → Discovery → PRD

### Phase 2: Design + Architecture
> Цель: от PRD до готового техдизайна

- [ ] **2.1** Skill `pipeline-design` (A: UI/UX patterns + B: PRD, design system, бренд)
- [ ] **2.2** Skill `pipeline-architecture` (A: arch patterns, scaling + B: PRD, design, стек)
- [ ] **2.3** Интеграция Context7 MCP в architecture skill
- [ ] **2.4** Обкатать: Design + Architecture для той же фичи

### Phase 3: Implementation + Testing
> Цель: от архитектуры до рабочего кода с тестами

- [ ] **3.1** Skill `pipeline-implementation` (A: coding standards + B: arch doc, test plan)
- [ ] **3.2** Skill `pipeline-test-plan` (A: testing strategies + B: PRD, arch doc)
- [ ] **3.3** Skill `pipeline-test-coverage` (A: TDD + B: test plan, код)
- [ ] **3.4** Skill `pipeline-qa` (A: e2e patterns + B: PRD acceptance criteria)
- [ ] **3.5** Интеграция Playwright MCP в QA skill
- [ ] **3.6** Обкатать: полный цикл Implementation → QA

### Phase 4: Deploy pipeline
> Цель: от кода до прода

- [ ] **4.1** Skill `pipeline-staging-deploy` (A: deploy patterns + B: deploy config)
- [ ] **4.2** Skill `pipeline-canary-deploy` (A: canary patterns + B: prod config, SLA)
- [ ] **4.3** Deploy strategy abstraction (single_vm → blue_green → k8s)
- [ ] **4.4** Обкатать: staging + canary на Spodi

### Phase 5: Analytics loop (замыкаем цикл)
> Цель: данные из прода кормят следующую итерацию

- [ ] **5.1** Skill `pipeline-product-analytics` (A: analytics methodology + B: KPI, baseline)
- [ ] **5.2** Skill `pipeline-tech-monitoring` (A: SRE practices + B: SLA, baseline)
- [ ] **5.3** Decision engine: continue / amplify / pivot / kill
- [ ] **5.4** Auto-trigger: аналитика → новая итерация Strategy

### Phase 6: Meta-agent
> Цель: pipeline умеет расширять сам себя

- [ ] **6.1** Tool inventory — агент знает свои текущие скиллы и MCP
- [ ] **6.2** Gap analysis — определяет чего не хватает для задачи
- [ ] **6.3** Search — ищет в интернете / known sources
- [ ] **6.4** Recommend + Install (после аппрува)

### Phase 7: Registry (отдельный проект)
> Цель: централизованный каталог скиллов и MCP для любого пользователя

- [ ] **7.1** Определить schema для registry entries
- [ ] **7.2** Seed data: импорт everything-claude-code, superpowers, awesome-mcp-servers
- [ ] **7.3** Search API
- [ ] **7.4** Интеграция с meta-agent

---

### Порядок подбивки проектов под Pipeline 2.0

1. **Spodi** — обкатка всех фаз, основной guinea pig
2. **TG-бот** — подключение после Phase 1 (лёгкий проект, валидация generic-формата)
3. **Новые проекты** — стартуют сразу с pipeline (после Phase 3)

---

## Open Questions

- [ ] Параллельные этапы: бэк + фронт + мобайл одновременно на этапе Implementation?
- [ ] Как мерить эффективность самого pipeline? Meta-метрики (time to ship, defect rate)?
- [ ] Как обрабатывать ситуацию когда гейт отклонён 3 раза подряд? Эскалация?
- [ ] Shared state между агентами — файлы в git или что-то более structured?
- [ ] Нужен ли отдельный "Project Manager" агент который трекает весь pipeline?
