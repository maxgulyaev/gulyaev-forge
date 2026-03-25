# Pipeline Orchestrator

## Purpose
This is the master document that defines how the pipeline runs — stage order, gate rules, context injection, and decision flow.

## Stage Order

```
0. Strategy       [GATE] ──→
1. Discovery      [GATE] ──→
2. Behavior Contract (`prd`) [GATE] ──→
3. Design         [GATE] ──→
4. Architecture   [GATE] ──→
5. Proof Hardening (`test_plan`) [────] ──→
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
Skill: `core/skills/code-review/SKILL.md` — includes TDD compliance validation.

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
   - Bug fix or `micro_change` → start at Stage 6 (Implementation)
   - `small_change` → start at the earliest valid gated stage, usually Stage 2 or 3
2. Load project config: `project/.forge/config.yaml`
3. For the starting stage, inject context A (skill from forge) + context B (project files filtered by stage)
4. Execute stage skill
5. Present gate (if applicable)
6. On approval → advance to next stage

### For natural-language prompts:
The user does not need to name stages explicitly.

The entry router should infer the path:
- bug/regression/outage → quick path toward Implementation
- feature/change request → choose `micro_change`, `small_change`, or `full_feature`, then the earliest valid stage for that lane
- evidence/analysis question → Discovery or Product Analytics
- short approval reply like `ok, go ahead` → gate decision for the current presented gate

## Execution Lanes

The stage model stays the same, but PRODUCT entry should first choose a lane:

- `bugfix`
  Quick path with bug issue discipline and `active-run.env`.

- `micro_change`
  One narrow surface, no backend/schema/sync/shared-contract change, low rollback cost.
  Path: durable `Change Brief` -> Stage 6 -> 7 -> 8.

- `small_change`
  Bounded but meaningful product behavior change that still needs a short contract.
  Path: compact Behavior Contract / short `Change Brief` -> earliest valid gated stage, usually Stage 2 or 3.

- `full_feature`
  New flow, shared contract, backend/schema/sync work, or multi-story effort.
  Path: earliest valid full pipeline stage.

Lane rules:
- do not force a full Strategy/Discovery loop for every local tweak
- do not keep work in a short lane once the blast radius expands beyond its criteria
- when in doubt, start short and promote the lane as soon as evidence shows it is insufficient

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

### What A Gate Decision Means

A gate decision is a judgment about whether the pipeline may unlock the **next** stage.
It is not a reward for effort and not a restatement of the previous agent's recommendation.

Judge the gate against:
- the execution contract: GitHub issue acceptance criteria, approved upstream artifacts, and any stage-specific checklist
- the current evidence: tests, screenshots, logs, review findings, deploy notes, and other proof collected in this stage
- movement along the pipeline: whether the current stage is complete enough that exposing the next stage is actually safe and coherent

Use these rules:
- `approved` only when required current-stage scope is covered and the evidence is internally consistent
- `approved_with_changes` only when the next stage can safely start and the remaining changes are bounded, explicit, and do not reopen the current-stage contract
- `rejected` when required scope is still unverified, incomplete, contradicted by evidence, or when useful work happened but it is still not enough to unlock the next stage

A prior gate summary, QA verdict, or subagent recommendation is input evidence, not the decision itself.

Before presenting a "ready" verdict or closing an issue, map each required acceptance item to concrete evidence.
Do not downgrade the contract by editing docs, comments, or summaries to sound more complete than the implementation really is.
If the diff changes deploy, rollback, smoke, or operator behavior, code, docs, issue trail, and `.forge/pipeline-state.yaml` must remain aligned.
Never print secrets or credentials into the durable trail; if exposure already happened, record rotation / cleanup before calling the work complete.

## Stage-Agent Transport Boundary

Forge may use secondary agents for explicit stage/role handoffs, but their transport/runtime is not part of the source-of-truth layer.

Keep this boundary explicit:
- **Source of truth**
  - issue trail
  - approved stage artifacts
  - `.forge/pipeline-state.yaml`
- **Transport/runtime**
  - how a secondary agent is reached for a specific handoff
  - examples over time: local CLI adapter, MCP-exposed agent runtime, ACP/A2A remote agent

Rules:
- a secondary agent may produce evidence, findings, drafts, or recommendations
- a secondary agent must not unilaterally advance the pipeline or replace the approved artifact chain
- the primary orchestrator remains responsible for:
  - loading the correct stage context
  - deciding when a gate is actually needed
  - judging the gate from contract + evidence
  - recording stage state changes

This allows forge to evolve its `stage_agents` transport model later without rewriting the process contract.

### Gate Elicitation Patterns

For high-risk gated stages, run one explicit second-pass reasoning method before presenting the gate.

Purpose:
- stress the draft decision before the human sees it
- surface blind spots that a straight-line summary may miss
- make "go" mean "we tried to break this and still believe it should advance"

Default methods:
- `strategy` -> `inversion`
  Ask what would make this strategy fail, not matter, or optimize the wrong thing.
- Stage 2 `prd` / Behavior Contract -> `pre-mortem`
  Assume the feature shipped badly; identify missing scenarios, edge cases, or false assumptions.
- `architecture` -> `red-team`
  Attack failure modes, data risk, security gaps, rollout hazards, and operational blind spots.
- `canary_deploy` -> `pre-mortem`
  Assume rollout goes wrong; identify rollback triggers, monitoring blind spots, and publication gaps.

Rules:
- record the elicitation method in the gate summary
- say what it tried to falsify
- say whether it changed the verdict
- if no material concern was found, state that explicitly instead of silently omitting the pass
- low-risk gates may mark this as `n/a`, but high-risk gates should not skip it by default

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

### Compact Moderator Checkpoint

When one agent is building and another agent or human is moderating asynchronously, use this compact packet instead of free-form recap:

```markdown
## Moderator Checkpoint
- Current issue: [#N]
- Current stage: [stage]
- Gate needed now: yes / no
- Recommended action: [continue_implementation / run_review / run_test_coverage / run_qa / present_gate / stop_for_input]
- Exact next step: [one sentence]
- Remaining blockers: [none / short list]
- Needs from moderator: [none / one exact input or approval]
```

Rules:
- ask at most one concrete question
- do not end with `what next?` when `Recommended action` is already clear
- if `Needs from moderator: none`, continue the workflow instead of waiting for a stylistic approval
- if a secret or credential is needed, ask the moderator to set it locally via env or the target system; do not ask for the raw value in chat

Compact moderator replies may be one line:
- `continue`
- `run_review`
- `run_test_coverage`
- `run_qa`
- `present_gate`
- `hold`
- `input: [exact item]`

### Block 2: State Sync
```
Issue label: [current stage label]
pipeline-state: [current local stage]
Sync status: aligned / mismatch fixed / blocked
```

### Block 2A: Execution Proposal (for long runs)
When the current stage will continue through multiple milestones before the next gate or handoff, the checkpoint should also include:

```
Current slice: [contract slice / story / question]
Milestones:
1. [next milestone]
2. [next milestone]
3. [optional milestone]
Validation:
- [milestone 1] -> [proof / verification]
- [milestone 2] -> [proof / verification]
- [milestone 3] -> [proof / verification]
Stop-and-fix rule:
- if a milestone fails validation, reveals source-of-truth drift, or expands scope beyond the approved slice, stop, repair or re-scope, and re-check before continuing
Active milestone now: [exact next milestone]
```

Execution Proposal rules:
- use it for long implementation, investigation, architecture, or release-preparation runs
- keep it compact: this is not a new `plans.md`
- milestone order should follow dependency order, not convenience order
- each milestone must name the proof that will decide whether the agent continues
- do not ask the human to approve the internal milestone list unless it changes product scope or reveals a real blocker

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
- if more than one milestone remains before the gate, the current execution proposal and stop-and-fix rule

### When To Ask For A Gate

The agent should present an `Implementation Gate` only when the current implementation slice is actually ready to leave Stage 6 and move to Stage 7.

Completing one story inside a multi-story implementation does **not** automatically mean a gate is needed.

The agent should present a `QA Gate` only after:
- Stage 7 test coverage is complete
- Stage 8 QA was actually executed on a testable environment
- evidence from QA is available
- the QA evidence was checked back against the issue contract and required surfaces/flows, not only against the QA agent's own summary

If required flows remain `NOT TESTED`, if evidence contradicts the reported outcome, or if only build/route registration checks passed, stay in Stage 8.

Automated checks, review completion, migration planning, or deploy preparation are not themselves a QA gate.

For release/deploy work:
- if the change is user-facing, Stage 9/10 must also produce a durable release communication packet in `docs/release-notes/`
- the packet is the canonical source for website / store / community / social wording
- a release gate should state which channels are already published, which are only prepared, and which are `n/a`
- do not treat a user-facing ship as fully ready when deploy mechanics are complete but release communication does not exist

## Behavior Contract Migration

Forge now treats Stage 2 as a **Behavior Contract** stage:
- one compact artifact for intent, scope, behavior, edge cases, and proof
- fewer files
- less drift between product spec and test plan

Compatibility rules for now:
- internal stage id remains `prd`
- Stage 5 stage id remains `test_plan`
- default doc path remains `docs/prd/`
- Stage 5 should tighten the same contract in place instead of creating a second file-backed test plan

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
- Артефакты предыдущих этапов (Behavior Contract, Architecture) — inline в промпте
- Полный доступ к файловым тулам для реализации

### Разделение этапов по режиму

| Этапы | Режим | Файловые тулы |
|-------|-------|---------------|
| 0–5 (Strategy → Proof Hardening) | Inline injection | Нет — контекст в промпте |
| 6–8 (Implementation → QA) | Полный доступ | Да — Read, Write, Edit, Bash |
| 9–12 (Deploy → Monitoring) | Полный доступ | Да |

## Stage Skip Rules

Some stages can be skipped:
- **Design** (Stage 3): Skip if feature is backend-only (no UI)
- **Proof Hardening** (Stage 5): Skip when the contract already has enough proof detail; for hotfixes, add tests/proof retroactively
- **Staging Deploy** (Stage 9): Skip if no staging environment (deploy directly with feature flag)
- **Canary Deploy** (Stage 10): Skip for < 100 users (big bang is fine)

Skip decisions must be documented in the gate.

## Parallel Execution

Some stages can run in parallel:
- **Design + Architecture** (Stages 3-4): Can overlap if designer and architect coordinate
- **Implementation across platforms** (Stage 6): Backend first, then web + mobile in parallel
- **Product Analytics + Tech Monitoring** (Stages 11-12): Independent data collection

## Quick Path Local State

Bugfix quick path local state:

```
project/.forge/
  active-run.env          # локальный quick-run state для bugfix/hotfix
```

Use `active-run.env` for bugfix continuity across sessions when the main
`pipeline-state.yaml` still points to a different feature.

`micro_change` uses the normal issue + `pipeline-state.yaml` trail unless the project explicitly adds a separate short-run state later.

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
