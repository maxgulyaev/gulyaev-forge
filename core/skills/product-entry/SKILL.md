---
name: product-entry
description: Start PRODUCT work in a connected product repo. Use for short prompts like "run issue #95 to PRD gate", "next stage for current feature", "work on issue #N via forge pipeline", or any feature/bug/product request that should route into the correct pipeline stage instead of defaulting to implementation.
---

# Product Entry

## Purpose

This is the entry skill for PRODUCT work.

Use it before stage-specific work when the user gives a short product prompt and expects the system to infer the correct pipeline behavior.

The user should be able to speak in business language.
Stage names, quick-path selection, issue discipline, and gate mirroring are internal responsibilities of the agent.
Public command surface is defined in `core/pipeline/entry-surface.md`.

## Trigger Examples

- `Сломалось сохранение тренировки. Почини.`
- `Хочу, чтобы в продукте были суперсеты.`
- `Почему падает активация? Разберись.`
- `Кажется, люди отваливаются на онбординге. Посмотри.`
- `Залей на TestFlight апдейт.`
- `Выложи обновление в App Store.`
- `Ок, едем дальше.`

## Intent Router

Treat the user's words as intent, not as stage instructions.

### 1. Bug / regression / outage intent

Signals:
- `сломалось`
- `не работает`
- `упало`
- `ошибка`
- `почини`
- `regression`

Default behavior:
- find an existing issue or create one if the bug is non-trivial
- if the bug touches a shared component, cross-screen behavior, or needs real analysis, create/select the issue before editing code
- use the quick path unless the bug clearly requires strategy or discovery
- default path:
  - `implementation`
  - `test_coverage`
  - `qa`
- stop at the first required gate and present a concise summary

### 2. Feature / change request intent

Signals:
- `хочу`
- `нужно сделать`
- `добавь`
- `сделай`
- `хотим`

Default behavior:
- if there is already an issue with current stage state, resume from there
- if scope is already well-defined and aligned, start from the earliest valid stage
- if scope is still fuzzy, start from `strategy` or `discovery`

### 3. Product question / uncertainty / investigation intent

Signals:
- `почему`
- `разберись`
- `исследуй`
- `стоит ли`
- `что происходит`

Default behavior:
- route to `discovery`, `product_analytics`, or `strategy`
- prefer evidence collection before committing to implementation

### 4. Metrics / funnel / retention intent

Signals:
- `метрики`
- `retention`
- `конверсия`
- `воронка`
- `аналитика`

Default behavior:
- route to `product_analytics`
- if results imply a product decision, stop with an analytics gate and recommendation

### 5. Release / distribution intent

Signals:
- `залей на тестфлайт`
- `testflight`
- `выложи в app store`
- `app store`
- `выложи веб`
- `задеплой веб`
- `deploy web`
- `production deploy`
- `play store`
- `internal testing`
- `release`
- `ship`

Default behavior:
- route to release/distribution flow using configured `release_targets`
- infer the target from the requested channel when possible
- if multiple targets match or the request is ambiguous, ask which release target to use
- treat this as deploy/distribution work, not implementation
- require an already approved candidate before upload

### 6. Gate response intent

If the agent has just presented a gate, treat simple human responses as decisions:
- approval:
  - `ок`
  - `окей`
  - `поехали дальше`
  - `идем дальше`
  - `аппрув`
  - `approved`
- approval with changes:
  - `ок, но поправь X`
  - `да, с изменениями`
  - `approved with changes`
- rejection:
  - `нет`
  - `стоп`
  - `не согласен`
  - `rejected`

The user should not need to type `/gate ...`.
The agent must translate natural approval into the durable issue comment format and only then advance labels/state.

## Workflow

1. Run product preflight:
   - `bash ~/Documents/Dev/gulyaev-forge/scripts/forge-doctor.sh product .`
   - `bash ~/Documents/Dev/gulyaev-forge/scripts/forge-status.sh product .`
2. Read:
   - `.forge/active-run.env` first, if present
   - `.forge/config.yaml`
   - `.forge/pipeline-state.yaml`
   - the linked GitHub issue
   - the latest approved artifact for the current stage, if any
   - governance/strategy/backlog docs required by the stage
3. If `.forge/active-run.env` describes an active bugfix quick run:
   - treat it as the current workflow instead of the unrelated feature pipeline
   - use its issue as the execution contract
   - respect its current quick-path stage and gate status
   - do not lose or overwrite it just because `.forge/pipeline-state.yaml` points to a different feature
4. Check gate lock before advancing:
   - if the current stage is gated and `current_gate_status` is `pending_approval`, stop at that gate
   - if the current stage is gated and there is no explicit approval recorded yet, treat it as `pending_approval`
   - for cross-session continuity, record decisions in the issue trail as:
     - `/gate approved`
     - `/gate approved_with_changes`
     - `/gate rejected`
   - if the user approves in the current chat, mirror that decision into the GitHub issue before updating stage labels or `.forge/pipeline-state.yaml`
   - for an active bugfix quick run, mirror the same decision into `.forge/active-run.env`
5. Resolve the target stage from intent:
   - if the user names a target stage or gate, treat it as the desired destination, not permission to skip unresolved gates
   - otherwise infer the path from bug / feature / question / metrics intent
   - stop at the first unresolved gated stage on the path
6. Load the correct stage context:
   - forge base skill: `~/Documents/Dev/gulyaev-forge/core/skills/[stage]/SKILL.md`
   - project overlay: `.forge/skills/[stage].md` if present
7. Work as that stage role.
   - Do not default to implementation unless the target stage really is implementation or later.
   - If the current stage remains in progress and no gate is required yet, present a checkpoint, not a vague progress note.
   - The checkpoint must explicitly say:
     - current stage
     - gate needed now: yes/no
     - what just finished
     - exact next recommended action
     - what condition will trigger the next gate

## Expected Outputs

For pre-implementation stages, produce the stage artifact plus a forge gate summary.

Examples:
- `strategy` -> strategy doc + strategy gate
- `prd` -> PRD doc + PRD gate
- `architecture` -> architecture doc + architecture gate
- `bug fix` -> code change + tests + QA gate

If the current gate is still unresolved:
- re-present the current gate or explain the blocker
- ask for an explicit decision
- do not advance `stage/*` labels or `.forge/pipeline-state.yaml`

If the current stage is still in progress and no gate is needed yet:
- present a checkpoint
- make it explicit that no approval is being requested now
- say exactly what the next step is

If the task is implementation or later, follow the stage skill and project rules for code/test/deploy work.

## Anti-Patterns

- Treating every issue as an implementation task
- Treating `до PRD gate` as permission to auto-approve Strategy or Discovery
- Forcing the user to speak in stage names when their intent is already clear
- Asking the user to type `/gate approved` manually when they already said `ok, go ahead`
- Asking the user to restate all context that already exists in repo files
- Loading the whole repository when stage-specific context is enough
- Skipping `.forge/pipeline-state.yaml` and then guessing the current stage
- Updating issue labels or `.forge/pipeline-state.yaml` to the next gated stage before approval is recorded
