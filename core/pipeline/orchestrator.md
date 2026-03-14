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
Runs after implementation, before test coverage. Auto-proceed only if no blocking findings remain.
Uses `REVIEW.md` in project root for project-specific review rules.

[GATE] = requires human approval before proceeding
[────] = auto-proceed if criteria met (human can still intervene)

Non-gated transition rule:
- Stage 6.5 (`code_review`) -> Stage 7 (`test_coverage`) should proceed automatically if blocking review findings are fixed
- Stage 7 (`test_coverage`) -> Stage 8 (`qa`) should proceed automatically if automated verification is complete and no blocker remains
- do not stop between these stages just to ask whether to commit or whether to continue
- unresolved `critical` / `high` review findings, or findings marked only `partially addressed`, keep the workflow in `implementation`

## Related Documents
- **Issue Tracking**: `core/pipeline/issue-tracking.md` — spec-to-issue bridge, label system, provider adapters
- **Entry Surface**: `core/pipeline/entry-surface.md` — public commands and routing contract

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

### For natural-language prompts:
The user does not need to name stages explicitly.

The entry router should infer the path:
- bug/regression/outage → quick path toward Implementation
- feature/change request → earliest valid product stage
- evidence/analysis question → Discovery or Product Analytics
- short approval reply like `ok, go ahead` → gate decision for the current presented gate

### For analytics loop:
1. Start at Stage 11 (Product Analytics)
2. Analytics produces recommendation: continue/amplify/pivot/kill
3. This feeds into Stage 0 (Strategy) for the next cycle

## Gate Protocol

**Hard rule:** a gated stage remains unresolved until a human records one of these decisions:
- `/gate approved`
- `/gate approved_with_changes`
- `/gate rejected`

The decision should live in the issue trail. If approval happens in the agent chat using natural language such as `ok`, `go ahead`, or `approved with changes`, the agent must mirror that decision into the issue before moving labels or `pipeline-state.yaml`.

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

Do not update `stage/*` labels, `current_stage`, or `stages_completed` for the next stage before one of the explicit gate decisions above is recorded.

## Checkpoint Protocol

Not every pause in the pipeline is a gate.

When the current stage is still **in progress** and no human decision is required yet, the agent must present a **checkpoint**, not a vague progress update.

This is especially important for long-running stages such as:
- Stage 6: Implementation
- multi-story discovery or architecture work
- release preparation before the actual release gate

At each checkpoint, explicitly state:

### Block 1: Status
```
## Checkpoint: [Stage Name]
Status: in progress
Gate needed now: yes / no
Current unit: [story / shard / task]
What just finished: 2-5 bullets
What is still in progress: 1-3 bullets
Next recommended action: one exact next step
What happens next: next checkpoint or next gate condition
Need anything from you now?: no / exact question
```

Checkpoint rules:
- `Next recommended action` must be one exact next step, not a menu of internal options
- do not ask the human to choose between unfinished implementation items, `commit now`, or `go to QA`
  unless there is a real product decision to make
- if known implementation scope is still incomplete, do not present QA as a parallel option
- if the next unfinished item is unambiguous, recommend it directly
- do not label something a `QA gate` before Stage 8 QA was actually executed
- do not require production deploy just to begin QA if a local, staging, or other testable environment exists

### Block 2: State Sync
```
Issue label: [current stage label]
pipeline-state: [current local stage]
Sync status: aligned / mismatch fixed / blocked
```

If issue label and `.forge/pipeline-state.yaml` disagree, the agent must resolve or surface that mismatch before giving "what next" guidance.

### Durable Trail

For long-running implementation work, when the agent pauses after a completed story or shard, it should write a durable issue comment with heading:

```text
## Implementation Checkpoint
```

This comment must make clear that:
- the stage is still `implementation`
- no gate decision is being requested yet
- exactly which story or shard was completed
- exactly which story or shard is next
- whether any unfinished implementation scope still blocks QA

### When To Ask For A Gate

The agent should present an `Implementation Gate` only when the current implementation slice is actually ready to leave Stage 6 and move to Stage 7.

Completing one story inside a multi-story implementation does **not** automatically mean a gate is needed.

The agent should present a `QA Gate` only after:
- Stage 7 test coverage is complete
- Stage 8 QA was actually executed on a testable environment
- evidence from QA is available

Automated checks, review completion, migration planning, or deploy preparation are not themselves a QA gate.

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
  → Ship only after QA approval
```

Must still have:
- Clear problem statement (even if one sentence)
- Bug issue as execution contract for any non-trivial fix
- Tests for the fix
- QA verification
- Stop at QA gate before `git push` / merge / deploy

Quick-path local state:

```
project/.forge/
  active-run.env          # локальный quick-run state для bugfix/hotfix
```

Use `active-run.env` for bugfix continuity across sessions when the main
`pipeline-state.yaml` still points to a different feature.

## State Tracking

### Source of truth — таск-трекер

Основное состояние pipeline хранится в таск-трекере (GitHub Issues).
`pipeline-state.yaml` — локальный кеш для удобства оркестратора, НЕ source of truth.
Для quick-path bugfix дополнительно используется `active-run.env` как локальный state
текущего short-lived run; issue trail всё равно остаётся durable source of truth.

При каждом переходе между этапами оркестратор **обязан**:
1. После завершения gated stage записать артефакт и добавить gate comment в issue
2. Выставить `current_gate_status: pending_approval` в `pipeline-state.yaml`
3. Остановиться и ждать явного решения человека
4. Только после `/gate approved` или `/gate approved_with_changes`:
   - обновить лейбл `stage/*` на issue фичи (убрать старый, добавить новый)
   - добавить комментарий о зафиксированном решении
   - обновить `pipeline-state.yaml` и перевести `current_stage` дальше

### Обновление issue при переходе

```bash
# Пример: фича #95 завершила Strategy stage и ждёт решения

# 1. Комментарий с результатом gate
gh issue comment 95 --body "## Pipeline: Strategy → Discovery
**Gate:** pending approval
**Артефакт:** docs/strategy/2026-03-10-supersets.md
**Решение:** GO WITH CONCERNS — scope v1, приоритет повышен до P1

Decision command:
/gate approved
/gate approved_with_changes
/gate rejected"

# 2. После явного approval обновить stage label
gh issue edit 95 --remove-label "stage/strategy" --add-label "stage/discovery"

# 3. Комментарий с зафиксированным решением
gh issue comment 95 --body "/gate approved"
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
current_stage: 0          # strategy
current_gate_status: pending_approval
current_stage_artifact: docs/strategy/2026-03-10-supersets.md
issue: 95
stages_completed: []
stages_skipped:
  - stage: 3
    reason: "Backend-only feature, no UI changes in this iteration"
```
