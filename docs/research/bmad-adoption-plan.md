# Plan: Усиление Forge по результатам анализа BMAD

> Дата: 2026-03-12
> Источник: [bmad-comparison.md](bmad-comparison.md)
> Статус: Draft → ждёт реализации

## Цель

Закрыть все преимущества BMAD Method перед Forge. После реализации — Forge сильнее по каждому аспекту.

---

## Задачи

### P0 — Быстрые wins (встраиваются в существующие файлы)

#### 1. Advanced Elicitation в гейтах
**Файлы**: `core/templates/gate-template.md`, `core/pipeline/orchestrator.md`

Добавить секцию `## Elicitation` в gate-template. Агент обязан прогнать один из методов перед показом гейта человеку:

| Стадия | Метод по умолчанию |
|---|---|
| Strategy | Pre-mortem ("представь что стратегия провалилась, почему?") |
| PRD | Inversion ("что нужно сделать, чтобы PRD гарантированно провалился?") |
| Architecture | Red Team ("атакуй свою архитектуру, найди 3 уязвимости") |
| Design | Stakeholder Mapping ("кого затрагивает, что скажут?") |
| Implementation | First Principles ("каждое допущение в коде верно?") |
| Canary Deploy | Pre-mortem ("деплой откатили через час, что случилось?") |

Доступные методы (агент может выбрать другой если релевантнее):
- Pre-mortem Analysis
- First Principles Thinking
- Inversion
- Red Team vs Blue Team
- Socratic Questioning
- Constraint Removal
- Stakeholder Mapping
- Analogical Reasoning

Результат elicitation включается в Block 2 (Detailed) гейта.

**Чем сильнее BMAD**: у них — ручной opt-in второй проход. У нас — автоматическая часть gate protocol.

#### 2. Fresh Context Rule
**Файл**: `core/pipeline/orchestrator.md`

Добавить явное правило:
```
## Fresh Context Rule
Каждая стадия = чистый контекст.
Агент получает ТОЛЬКО: A (skill) + B (injected project files).
Информация между стадиями передаётся ТОЛЬКО через артефакты.
Если что-то важно — оно должно быть записано в артефакте предыдущей стадии.
```

Уже подразумевается inline injection, но нужно сделать explicit.

**Чем сильнее BMAD**: у них — рекомендация "открой новый чат". У нас — архитектурный инвариант.

#### 3. Adversarial Code Review Protocol
**Файл**: `core/skills/implementation/SKILL.md` (секция Code Review)

Добавить:
```
## Adversarial Review Protocol
1. Reviewer ОБЯЗАН найти минимум 3 findings.
2. Если findings = 0, переанализировать с фокусом на:
   - Edge cases, race conditions, concurrency
   - Security (injection, auth bypass, IDOR, secrets in code)
   - Performance (N+1, unbounded queries, memory leaks)
   - Error handling (silent failures, missing retries, no timeouts)
3. Severity: critical | major | minor | nit
4. Critical/Major блокируют merge.
5. Finding "всё идеально" не принимается — всегда есть что улучшить.
```

**Чем сильнее BMAD**: у них — zero-findings re-analysis. У нас — то же + severity blocking + конкретные области фокуса.

---

### P1 — Новые скиллы и концепции

#### 4. Three Complexity Tracks
**Файл**: `core/pipeline/orchestrator.md`

Добавить секцию определения трека:

| Трек | Scope | Маршрут | Когда |
|---|---|---|---|
| **Quick** | 1–5 stories | Implementation → Code Review → QA | Багфикс, мелкое улучшение |
| **Standard** | 5–30 stories | Полный пайплайн (13 стадий) | Фича, новый модуль |
| **Enterprise** | 30+ stories | Полный + Security Review + Compliance Check + Audit Trail | Регулируемые отрасли |

Enterprise добавляет:
- **Security Review** (после Architecture, перед Test Plan) — threat modeling, OWASP, data flow analysis
- **Compliance Check** (после QA, перед Canary) — regulatory requirements, audit readiness
- **Audit Trail** — лог всех решений и аппрувов по всему pipeline

Трек определяется автоматически на Strategy/PRD, переопределяется вручную.

#### 5. Multi-Perspective Review
**Файл**: новый `core/skills/multi-review/SKILL.md`

Структурированный мульти-перспективный анализ артефактов на гейтах:

```markdown
## Multi-Review: [Артефакт]

### Perspective: Security
Findings: ...
Risk: high/medium/low

### Perspective: Performance
Findings: ...
Risk: high/medium/low

### Perspective: Maintainability
Findings: ...
Risk: high/medium/low

## Consolidated: go / go with concerns / stop
Key risks: ...
```

Когда применять:
- Architecture гейт → Security + Performance + Maintainability
- PRD гейт → PM + UX + Tech Lead
- Strategy гейт → Product + Business + Engineering
- Canary Deploy гейт → SRE + Security + Product

**Чем сильнее BMAD**: Party Mode у них — ad-hoc в одном чате. У нас — структурированный протокол с consolidated verdict.

#### 6. Forge Navigator
**Файл**: новый `core/skills/navigator/SKILL.md`

Скилл-навигатор, который:
- Знает карту forge (все стадии, скиллы, шаблоны, MCP)
- Сканирует состояние проекта (артефакты, этап pipeline)
- Отвечает на вопросы ("с чего начать?", "что дальше?", "почему reject?")
- Предлагает следующий шаг
- Показывает Dashboard

Пример:
```
> forge help "у меня SaaS идея"
→ Начни с PRODUCT → New Project → Strategy.
  Нужен: docs/strategy/current.md
  Скилл: core/skills/strategy/SKILL.md
  Первый шаг: опиши проблему, целевую аудиторию, гипотезу.
```

**Чем сильнее BMAD**: BMad-Help — статический промпт. Navigator видит реальное состояние проекта.

---

### P2 — Инфраструктура

#### 7. Skill Packs (модульная система)
**Файл**: новый `core/registry/skill-packs.yaml` + документация

Концепция расширяемых наборов скиллов:

```yaml
packs:
  security-review:
    description: "Security-focused stages for regulated industries"
    adds_stages:
      - after: architecture
        name: security-review
        skill: core/skills/security-review/SKILL.md
        gate: true

  ml-experiment:
    description: "ML experiment tracking and evaluation"
    adds_stages:
      - after: implementation
        name: experiment-tracking
        skill: core/skills/experiment-tracking/SKILL.md

  game-dev:
    description: "Game development: GDD, level design, playtesting"
    adds_stages:
      - replace: prd
        name: gdd
        skill: core/skills/gdd/SKILL.md
```

Активация:
```yaml
# project/.forge/config.yaml
packs:
  - security-review
```

**Чем сильнее BMAD**: BMad Builder → npm publish → npm install. Наши Skill Packs — одна строка в YAML, zero dependencies.

#### 8. Agent Preferences
**Файл**: `core/templates/project-context.yaml`

```yaml
preferences:
  style: concise            # concise | detailed | conversational
  language: ru              # язык артефактов и коммуникации
  gate_detail: summary      # summary | full (с чего начинать гейт)
  auto_elicitation: true    # автоматический elicitation
  track: standard           # quick | standard | enterprise
```

#### 9. Forge CLI
**Файл**: новый `bin/forge` (bash)

```bash
forge init [--project PATH]        # scaffolding
forge status                       # dashboard
forge adapter add AGENT            # добавить адаптер
forge scout URL                    # technology scout
forge validate                     # проверка config.yaml
forge help QUERY                   # navigator
```

Zero dependencies — чистый bash. Работает везде.

---

### P3 — Документация

#### 10. Diátaxis Documentation
**Структура**:
```
docs/
  tutorials/
    first-feature.md          # "Первая фича через Forge от А до Я"
    new-project.md            # "Новый проект с нуля"
  how-to/
    add-agent-adapter.md      # "Как добавить адаптер для нового агента"
    skip-stages.md            # "Как пропускать стадии"
    custom-skill-pack.md      # "Как создать свой Skill Pack"
  explanation/
    why-role-filtering.md     # "Зачем контекстная фильтрация по ролям"
    gates-prevent-drift.md    # "Как гейты предотвращают drift"
    three-layers.md           # "Почему три слоя, а не monolith"
  reference/
    skills.md                 # Все 13 скиллов — формат, входы, выходы
    config-schema.md          # Полная схема config.yaml
    gate-format.md            # Формат гейтов
    cli.md                    # Справочник CLI команд
```

---

## Порядок реализации

```
P0 (быстрые wins, 1 сессия):
  1. Elicitation в гейтах        ← gate-template.md + orchestrator.md
  2. Fresh Context Rule          ← orchestrator.md
  3. Adversarial Review          ← implementation SKILL.md

P1 (новые скиллы, 1-2 сессии):
  4. Three Complexity Tracks     ← orchestrator.md
  5. Multi-Perspective Review    ← новый skill
  6. Forge Navigator             ← новый skill

P2 (инфраструктура, 2-3 сессии):
  7. Skill Packs                 ← registry + template
  8. Agent Preferences           ← project-context.yaml
  9. Forge CLI                   ← bin/forge

P3 (документация, 1-2 сессии):
  10. Diátaxis docs              ← docs/tutorials, how-to, explanation, reference
```

---

## Результат после реализации

| Аспект | До | После |
|---|---|---|
| Elicitation | Нет | Auto в каждом гейте |
| Complexity tracks | Quick Path only | Quick / Standard / Enterprise |
| Multi-agent review | Нет | Structured multi-perspective |
| Navigator | Нет | Forge Navigator + project state |
| Fresh context | Implicit | Explicit rule + architectural guarantee |
| CLI | Нет | `forge` bash CLI |
| Module system | Нет | Skill Packs |
| Adversarial review | Basic | Protocol + severity + mandatory findings |
| Agent customization | Нет | Per-project preferences |
| Documentation | Design + Quickstart | Full Diátaxis |

Forge будет сильнее BMAD по каждому аспекту, сохраняя свои уникальные преимущества: full lifecycle, role-based filtering, three-layer architecture, zero dependencies, multi-project.
