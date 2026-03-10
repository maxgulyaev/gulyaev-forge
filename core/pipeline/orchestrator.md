# Pipeline Orchestrator

## Purpose
This is the master document that defines how the pipeline runs — stage order, gate rules, context injection, and decision flow.

## Stage Order

```
0. Strategy       [GATE] ──→
1. Discovery      [GATE] ──→
2. PRD            [GATE] ──→
3. Design         [GATE] ──→
4. Architecture   [GATE] ──→
5. Test Plan      [────] ──→
6. Implementation [GATE] ──→
6.5 Code Review   [────] ──→  ← NEW: /code-review (multi-agent PR review)
7. Test Coverage  [────] ──→
8. Automated QA   [GATE] ──→
9. Staging Deploy [────] ──→
10. Canary Deploy [GATE] ──→
11. Product Analytics [GATE] ──→
12. Tech Monitoring   [GATE] ──→ back to 0. Strategy
```

**Stage 6.5: Code Review** — automated multi-agent PR review via Claude Code `/code-review`.
Runs after implementation, before test coverage. Auto-proceed if no critical findings.
Uses `REVIEW.md` in project root for project-specific review rules.

[GATE] = requires human approval before proceeding
[────] = auto-proceed if criteria met (human can still intervene)

## Related Documents
- **Issue Tracking**: `core/pipeline/issue-tracking.md` — spec-to-issue bridge, label system, provider adapters

## How to Start the Pipeline

### For a new feature:
1. Determine entry point:
   - Brand new idea → start at Stage 0 (Strategy) or Stage 1 (Discovery)
   - Idea from backlog with strategy alignment → start at Stage 2 (PRD)
   - Bug fix or small improvement → start at Stage 6 (Implementation)
2. Load project config: `project/.forge/config.yaml`
3. For the starting stage, inject context A (skill from forge) + context B (project files filtered by stage)
4. Execute stage skill
5. Present gate (if applicable)
6. On approval → advance to next stage

### For analytics loop:
1. Start at Stage 11 (Product Analytics)
2. Analytics produces recommendation: continue/amplify/pivot/kill
3. This feeds into Stage 0 (Strategy) for the next cycle

## Gate Protocol

At each gate, present:

### Block 1: Summary
```
## Gate: [Stage Name] → [Next Stage Name]
Status: go / go with concerns / stop
What was done: 3-5 bullets
Key decisions: what was chosen and why
Risks: if any
Question: specific question for approval
```

### Block 2: Detailed
```
Artifact: [link to file created by this stage]
Review checklist: what to verify
Trade-offs: options considered
Diff: what changed vs previous state
```

### Block 3: Rollback Plan
```
Affected: files / migrations / deploys
Commands: specific rollback commands
Pre-state: commit SHA or tag
Dependencies: what else might break
```

### Gate Responses
- **Approved** → proceed to next stage
- **Approved with changes** → apply feedback, re-present gate
- **Rejected** → go back to current stage with feedback
- **Rejected 3x** → escalate: "This stage has been rejected 3 times. Consider: going back to a previous stage, reframing the problem, or pausing to discuss the approach."

## Context Injection Rules

### Принцип: inline injection

Claude Code (и аналогичные инструменты) не имеют механизма ограничения доступа к файлам.
Subagent с тулами Read/Grep/Glob может прочитать что угодно в проекте.
Промпт-уровневая изоляция («не читай лишнего») — ненадёжна.

**Решение**: оркестратор сам читает файлы из inject-списка и передаёт их содержимое
inline в промпт агента. Агент получает замкнутый контекст и не нуждается в файловых тулах
для принятия решений на этапах Strategy–Architecture.

### Порядок действий

Для каждого этапа оркестратор:
1. Читает `project/.forge/config.yaml`
2. Находит `stages.[current_stage].inject`
3. Читает `required` файлы (fail если отсутствуют)
4. Читает `if_exists` файлы (skip если отсутствуют)
5. Читает файлы по `search` паттернам (glob)
6. Читает skill этапа из `core/skills/[stage]/SKILL.md`
7. Запускает subagent (Agent tool), передавая **в промпте**:
   - Содержимое всех inject-файлов (inline, не путь)
   - Содержимое skill-файла
   - Описание задачи (issue body, feature name)
   - Формат ожидаемого артефакта
8. Subagent работает **без файловых тулов** (только генерирует текст артефакта)
9. Оркестратор записывает артефакт в проект и презентует gate

### Когда агенту нужны файловые тулы

На этапах Implementation (6) и позже агент должен читать и писать код —
здесь inline injection не применяется. Вместо этого агент получает:
- CLAUDE.md проекта (как обычно, через контекст)
- Артефакты предыдущих этапов (PRD, Architecture) — inline в промпте
- Полный доступ к файловым тулам для реализации

### Разделение этапов по режиму

| Этапы | Режим | Файловые тулы |
|-------|-------|---------------|
| 0–5 (Strategy → Test Plan) | Inline injection | Нет — контекст в промпте |
| 6–8 (Implementation → QA) | Полный доступ | Да — Read, Write, Edit, Bash |
| 9–12 (Deploy → Monitoring) | Полный доступ | Да |

## Stage Skip Rules

Some stages can be skipped:
- **Design** (Stage 3): Skip if feature is backend-only (no UI)
- **Test Plan** (Stage 5): Skip for hotfixes (but add tests retroactively)
- **Staging Deploy** (Stage 9): Skip if no staging environment (deploy directly with feature flag)
- **Canary Deploy** (Stage 10): Skip for < 100 users (big bang is fine)

Skip decisions must be documented in the gate.

## Parallel Execution

Some stages can run in parallel:
- **Design + Architecture** (Stages 3-4): Can overlap if designer and architect coordinate
- **Implementation across platforms** (Stage 6): Backend first, then web + mobile in parallel
- **Product Analytics + Tech Monitoring** (Stages 11-12): Independent data collection

## Quick Path (Small Changes)

For small changes (bug fixes, copy changes, minor tweaks):
```
Skip to Stage 6 (Implementation) directly
  → Stage 7 (Test Coverage)
  → Stage 8 (QA) — abbreviated
  → Stage 9/10 (Deploy)
```

Must still have:
- Clear problem statement (even if one sentence)
- Tests for the fix
- QA verification

## State Tracking

### Source of truth — таск-трекер

Основное состояние pipeline хранится в таск-трекере (GitHub Issues).
`pipeline-state.yaml` — локальный кеш для удобства оркестратора, НЕ source of truth.

При каждом переходе между этапами оркестратор **обязан**:
1. Обновить лейбл `stage/*` на issue фичи (убрать старый, добавить новый)
2. Добавить комментарий к issue с результатом gate (артефакт, статус, решение)
3. Обновить `pipeline-state.yaml` (локальный кеш)

### Обновление issue при переходе

```bash
# Пример: фича #95 прошла Strategy gate → переход в Discovery

# 1. Убрать старый stage-лейбл, добавить новый
gh issue edit 95 --remove-label "stage/strategy" --add-label "stage/discovery"

# 2. Комментарий с результатом gate
gh issue comment 95 --body "## Pipeline: Strategy → Discovery
**Gate:** approved
**Артефакт:** docs/strategy/2026-03-10-supersets.md
**Решение:** GO WITH CONCERNS — scope v1, приоритет повышен до P1"
```

### Локальный кеш (pipeline-state.yaml)

```
project/.forge/
  config.yaml              # Статичный конфиг
  pipeline-state.yaml      # Локальный кеш (авто-генерируется)
```

```yaml
# pipeline-state.yaml (авто-обновляется оркестратором)
current_feature: "supersets"
current_stage: 6          # implementation
issue: 95
stages_completed:
  - stage: 0
    date: 2026-03-10
    gate: approved
    artifact: docs/strategy/2026-03-10-supersets.md
  - stage: 2
    date: 2026-03-10
    gate: approved
    artifact: docs/prd/2026-03-10-supersets.md
  - stage: 4
    date: 2026-03-11
    gate: approved_with_changes
    artifact: docs/architecture/2026-03-11-supersets.md
stages_skipped:
  - stage: 3
    reason: "Backend-only feature, no UI changes in this iteration"
```
