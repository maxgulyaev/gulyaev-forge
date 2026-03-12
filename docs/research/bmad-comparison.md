# BMAD Method vs Gulyaev Forge — Сравнительный анализ

**Дата**: 2026-03-12
**Источник**: https://docs.bmad-method.org/

## TL;DR

Оба проекта решают одну задачу — AI-driven SDLC. BMAD зрелее (v6, npm, docs), Forge шире по покрытию (полный product lifecycle с deploy, analytics, monitoring и замкнутым циклом). BMAD заканчивается на code review, Forge замыкает петлю analytics → strategy.

---

## Что общего

| Общая черта | BMAD | Gulyaev Forge |
|---|---|---|
| Фазовый пайплайн | 4 фазы (Analysis → Planning → Solutioning → Implementation) | 13 стадий (Strategy → ... → Tech Monitoring → цикл) |
| Специализированные роли | 9 именованных агентов (Mary, John, Winston...) | 13 ролей по стадиям (Strategist, Researcher, PM...) |
| Гейты между стадиями | Checkpoint-система, validation gates | 3-блочные гейты (Summary, Detailed, Rollback) |
| Story-driven разработка | Epic → Story → Implementation | Epic → Story → Task (3 уровня) |
| Markdown как основа | Да | Да |
| Multi-agent support | Claude Code, Cursor, Copilot | 8 агентов (Claude, Cursor, Codex, Windsurf, Jules, Copilot, Cline, Aider) |
| Шаблоны артефактов | PRD, Architecture, Epics, Stories | PRD, Architecture, Gate reports, Config, Review |
| Code review | `bmad-code-review` (adversarial) | Stage 6.5 Code Review |

---

## Ключевые различия

### 1. Архитектура: Monolith vs Three Layers

**BMAD** — monolithic, ставится в каждый проект:
```
project/_bmad/          # весь фреймворк внутри проекта
project/_bmad-output/   # артефакты
project/.claude/skills/ # IDE-specific skills
```

**Forge** — three-layer, минимальный footprint:
```
forge/core/        # универсальное ядро (одно на все проекты)
forge/adapters/    # переводчики под агентов
project/.forge/    # ТОЛЬКО config.yaml
```

Проект содержит только конфиг. Знания читаются из forge напрямую — нет дублирования.

### 2. Агенты: Персонажи vs Роли

**BMAD** — агенты с именами и характерами (Mary-аналитик, Winston-архитектор). Есть `customize.yaml` для стиля общения.

**Forge** — безличные роли, привязанные к стадии. "You are a Product Strategist" — функция, не персона.

### 3. Покрытие пайплайна

**BMAD** заканчивается на code review. Нет deploy, analytics, monitoring, feedback loop.

**Forge** покрывает полный цикл:
- Stage 9: Staging Deploy
- Stage 10: Canary Deploy
- Stage 11: Product Analytics
- Stage 12: Tech Monitoring
- → Замкнутый цикл обратно в Strategy

BMAD — **build pipeline**, Forge — **product lifecycle**.

### 4. Контекстная фильтрация

**BMAD** — все агенты видят всё. `project-context.md` загружается всеми workflows.

**Forge** — role-based filtering через config.yaml:
```yaml
stages:
  prd:
    inject:
      required:
        - docs/strategy/current.md
        - docs/BACKLOG.md
      # НЕ видит: deploy config, code style, monitoring
```

Stages 0–5 используют inline injection — агент даже не имеет file access.

### 5. Rollback

**BMAD** — нет rollback-плана в гейтах.

**Forge** — каждый гейт содержит Rollback Plan:
- Affected files/migrations
- Exact rollback commands
- Pre-state git commit SHA
- Dependency analysis

### 6. Установка

**BMAD** — npm-пакет (`npx bmad-method install`), CLI с флагами. Зависимость на Node.js.

**Forge** — zero dependencies. Чистый markdown + YAML. Клонируешь репо — готово.

### 7. Issue Tracking

**BMAD** — внутренний sprint-status.yaml.

**Forge** — полная интеграция с GitHub Issues:
- Epic → Story → Task иерархия с labels
- Spec-to-issue bridge (PRD → авто-создание issues)
- PR closes Task → closes Story → closes Epic

### 8. Расширяемость

**BMAD** — модульная система (BMad Builder, TEA, Creative Intelligence Suite). NPM publishing.

**Forge** — MCP Server Registry + Technology Scout workflow (ADOPT/TRIAL/ASSESS/HOLD). Marketplace планируется.

---

## Уникальные фичи BMAD

- **Advanced Elicitation** — структурированный re-thinking (Pre-mortem, First Principles, Red Team, Socratic)
- **Party Mode** — несколько агентов в одном чате для совместных решений
- **Именованные персоны** — emotional engagement
- **BMad Builder** — создание кастомных модулей
- **3 трека сложности** (Quick Flow / Method / Enterprise)
- **BMad-Help** — интеллектуальный гайд, отвечает на 80% вопросов
- **Fresh Chat** — каждый workflow в новом чате для чистого контекста

## Уникальные фичи Forge

- **Story Sharding** — PRD → атомарные story-файлы (~1-2 KB), экономия ~90% токенов
- **Inline Context Injection** — stages 0–5 без file access
- **Deploy Strategy Abstraction** — декларативная стратегия (single_vm → k8s)
- **Two Modes** — PRODUCT (продукт) vs SELF (улучшение forge)
- **Замкнутый product loop** — analytics → strategy → development → deploy → analytics
- **Gate Escalation** — 3 reject → эскалация
- **Role-based context filtering** — агент видит только свой контекст
- **Zero dependencies** — чистый markdown, никаких npm/installers

---

## Зрелость

| Аспект | BMAD | Forge |
|---|---|---|
| Версия | v6 | Phase 0 (Foundation) |
| NPM пакет | Да | Нет |
| Installer/CLI | Да | Нет |
| Документация | Полная (Diátaxis) | Design doc + Quickstart |
| Модули/расширения | 5+ | Планируется |
| Battle-tested | Несколько версий | Первый прогон |

---

## Вердикт

Не "что лучше абсолютно", а **для чего лучше**:

### BMAD лучше если:
- Нужен работающий инструмент прямо сейчас
- Проект заканчивается на "код написан и замержен"
- Нужна экосистема расширений
- Нравится personality-driven подход

### Forge лучше если:
- Нужен полный product lifecycle (strategy → deploy → analytics → strategy)
- Важна контекстная изоляция по ролям
- Работаешь с разными агентами, нужен один стандарт
- Управляешь несколькими проектами из одного forge
- Хочешь zero-dependency решение

---

## Что стоит позаимствовать из BMAD

1. **Advanced Elicitation** — Pre-mortem, First Principles, Red Team для gate reviews
2. **Party Mode** — мульти-агентные обсуждения для architecture decisions
3. **Enterprise track** — compliance-oriented workflow
4. **BMad Builder** — концепция пользовательских модулей
5. **Installer/CLI** — `npx gulyaev-forge init` вместо ручного scaffolding
6. **BMad-Help** — интеллектуальный помощник-навигатор
7. **Fresh Chat** — принудительный новый контекст на каждый workflow
