---
name: product-entry
description: Start PRODUCT work in a connected product repo. Use for short prompts like "run issue #95 to the behavior-contract gate", "next stage for current feature", "work on issue #N via forge pipeline", or any feature/bug/product request that should route into the correct pipeline stage instead of defaulting to implementation.
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
- `Поменяй порядок шаблонов в iOS по дате добавления.`
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

## Execution Lane Router

After intent resolution, choose exactly one execution lane.

### A. `bugfix`

Use when the request is primarily about broken behavior, regression, or incident response.

Default behavior:
- use the quick path
- create/select the bug issue before code when the fix is non-trivial
- keep `.forge/active-run.env` in sync

### B. `micro_change`

Use when all of these are true:
- one platform or one narrow surface
- no API/schema/migration/sync/shared-contract change
- no new multi-step user journey
- rollback is simple
- a full contract/design packet would be disproportionate

Typical examples:
- list sort order
- local copy tweak
- default tab or filter
- local menu item order
- spacing / label / empty-state polish with bounded behavior

Default behavior:
- create/select the issue first
- write a durable `## Change Brief` using `core/templates/change-brief-template.md`
- keep the brief minimal: lane, scope, non-goals, acceptance, proof
- route directly to `implementation`
- then continue through `test_coverage` -> `qa`

### C. `small_change`

Use when the change is still bounded, but at least one of these is true:
- touches more than one surface or platform
- changes an interaction model, parity expectation, or meaningful UX behavior
- needs one short product contract before code
- may reopen a small amount of design/contract thinking, but not full discovery

Default behavior:
- create/select the issue first
- produce a short `Change Brief` or compact Behavior Contract
- start from the earliest valid gated stage, usually Stage 2 (`prd` stage id) or `design`
- do not force `strategy` / `discovery` unless the scope is still genuinely unclear

### D. `full_feature`

Use when any of these are true:
- new flow or substantial workflow addition
- backend/API/schema/migration change
- sync/share/import/export behavior
- cross-platform contract or parity work with material blast radius
- multiple stories are likely

Default behavior:
- start from the earliest valid full stage
- use the normal feature pipeline

Promotion rule:
- if new evidence shows the chosen lane was too small, promote it immediately
- do not keep a `micro_change` or `small_change` in the short lane once backend/shared-contract complexity appears

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
- if the release is user-facing, prepare or verify a canonical communication packet in `docs/release-notes/` before calling the target ready

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

1. Run product preflight from the current product repo using the same forge checkout that provided this skill:
   - `bash <forge-root>/scripts/forge-doctor.sh product .`
   - `bash <forge-root>/scripts/forge-status.sh product .`
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
   - when a gate is pending or the user asks for an approval decision, assess it independently from:
     - the issue acceptance criteria
     - approved upstream artifacts
     - the current stage evidence and open findings
   - treat prior gate summaries, QA reports, and subagent verdicts as input evidence, not as the gate decision itself
   - for cross-session continuity, record decisions in the issue trail as:
     - `/gate approved`
     - `/gate approved_with_changes`
     - `/gate rejected`
   - if the user approves in the current chat, mirror that decision into the GitHub issue before updating stage labels or `.forge/pipeline-state.yaml`
   - for an active bugfix quick run, mirror the same decision into `.forge/active-run.env`
5. Resolve the target stage from intent:
   - if the user names a target stage or gate, treat it as the desired destination, not permission to skip unresolved gates
   - otherwise infer the path from bug / feature / question / metrics intent
   - for feature/change requests, choose `micro_change`, `small_change`, or `full_feature` before choosing the starting stage
   - stop at the first unresolved gated stage on the path
6. Load the correct stage context:
   - forge base skill: `<forge-root>/core/skills/[stage]/SKILL.md`
   - project overlay: `.forge/skills/[stage].md` if present
7. Work as that stage role.
   - Do not default to implementation unless the target stage really is implementation or later.
   - If the current stage remains in progress and no gate is required yet, present a checkpoint, not a vague progress note.
   - For non-gated stages such as `code_review` and `test_coverage`, auto-proceed to the next allowed stage when criteria are satisfied instead of stopping for internal execution choices.
   - The checkpoint must explicitly say:
     - current stage
     - chosen lane
     - gate needed now: yes/no
     - what just finished
     - exact next recommended action
     - what condition will trigger the next gate
   - If the stage will continue through multiple milestones before the next gate, include a compact `Execution Proposal`:
     - current slice
     - milestone order
     - proof for each milestone
     - stop-and-fix rule

## Expected Outputs

For pre-implementation stages, produce the stage artifact plus a forge gate summary.

Examples:
- `strategy` -> strategy doc + strategy gate
- `prd` -> Behavior Contract + Behavior Contract gate
- `architecture` -> architecture doc + architecture gate
- `bug fix` -> code change + tests + QA gate
- `micro_change` -> `Change Brief` + targeted code/test/QA without forcing a full contract packet
- `small_change` -> compact Behavior Contract + the next valid gated stage, not automatic Strategy/Discovery by default

If the current gate is still unresolved:
- re-present the current gate or explain the blocker
- explicitly separate:
  - required scope that is proven
  - required scope that is still unverified
  - evidence that contradicts the reported status, if any
- ask for an explicit decision
- do not advance `stage/*` labels or `.forge/pipeline-state.yaml`

If the current stage is still in progress and no gate is needed yet:
- present a checkpoint
- make it explicit that no approval is being requested now
- say exactly what the next step is

If the task is implementation or later, follow the stage skill and project rules for code/test/deploy work.

## Anti-Patterns

- Treating every issue as an implementation task
- Treating `до Behavior Contract gate` or `до PRD gate` as permission to auto-approve Strategy or Discovery
- Forcing the user to speak in stage names when their intent is already clear
- Asking the user to type `/gate approved` manually when they already said `ok, go ahead`
- Asking the user to restate all context that already exists in repo files
- Loading the whole repository when stage-specific context is enough
- Skipping `.forge/pipeline-state.yaml` and then guessing the current stage
- Updating issue labels or `.forge/pipeline-state.yaml` to the next gated stage before approval is recorded
- Approving a gate just because a stage report says `PASS` without checking the underlying contract coverage and evidence
