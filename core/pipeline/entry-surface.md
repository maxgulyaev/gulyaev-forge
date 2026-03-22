# Entry Surface

This file is the canonical source of truth for how a human should enter `gulyaev-forge`.

## Principle

Forge exposes **intent entrypoints**, not public stage commands.

Public contract:
- the human says what they want
- the router decides which pipeline stage should handle it
- unresolved gates still block progress

Internal contract:
- stage skills live under `core/skills/[stage]/SKILL.md`
- stage choice comes from intent + issue state + `.forge/pipeline-state.yaml`
- stage names are internal operating details unless the agent needs to explain them

This means forge intentionally does **not** expose commands like:
- `/forge:strategy`
- `/forge:architecture`
- `/forge:implementation`

If the user says `доведи до Behavior Contract gate` or legacy phrasing like `до PRD gate`, that is a destination hint, not permission to skip unresolved earlier gates.

## Public Entry Surface

### PRODUCT

- `/forge:work <request>`
  Use as the default universal entrypoint for PRODUCT work.
  Default behavior: classify the request into `bugfix`, `micro_change`, `small_change`, `full_feature`, `investigate`, or `release`, choose the issue, and route to the earliest valid stage without making the user pick a pipeline manually.

- `/forge:bugfix <problem>`
  Use for bug, regression, outage, or broken behavior.
  Default path: bug issue -> `implementation` -> `test_coverage` -> `code_review` when configured -> `qa`.

- `/forge:feature <request>`
  Use for explicit feature or product change intent.
  Default behavior: same router as `/forge:work`, but with feature/change bias instead of bug/investigate/release bias.

- `/forge:investigate <question>`
  Use for uncertainty, diagnosis, product research, analytics questions, or "why is this happening?" requests.
  Default path: `discovery`, `product_analytics`, or `strategy`.

- `/forge:continue [reply]`
  Use to continue the current workflow or answer the current gate in natural language.
  Default behavior: resume active workflow; if a gate is pending, mirror the decision into the issue and advance at most one transition; if no gate is pending, return an explicit checkpoint with `Gate needed now: yes/no` and one exact next action.

- `/forge:gate <decision>`
  Use when the human wants to record an explicit gate decision directly.
  Default behavior: write exactly one durable `/gate ...` decision to the issue trail, then update labels/state if advancement is allowed.

- `/forge:review [focus]`
  Use to run the configured external reviewer for the current PRODUCT repo.
  Default behavior: execute Stage 6.5 external code review and write the durable review summary to the issue trail.

- `/forge:release <distribution request>`
  Use for upload, deploy, store submission, or distribution work.
  Default behavior: resolve the configured `release_target`, validate preconditions, prepare or verify the user-facing release communication packet when relevant, run the target-specific runbook, and stop at the next release gate if needed.

Specialist commands remain valid, but `/forge:work` is the recommended default when the human does not want to choose the lane manually.

### SELF

- `/forge:self <forge change>`
  Use inside the forge repo for pipeline, docs, skills, templates, adapters, or process changes.

## Natural-Language Contract

The user may speak in business language instead of slash commands.

Examples:
- `/forge:work поменяй порядок шаблонов в iOS по дате добавления`
- `Кнопка не работает. Почини.`
- `Хочу добавить суперсеты.`
- `Почему люди не доходят до оплаты?`
- `Ок, едем дальше.`
- `Выложи апдейт в TestFlight.`
- `Сделай forge более рабочим.`

The adapter or entry skill should map these to the same intents above, even when the user does not name the command.

## Execution Lanes

After resolving intent, the router should classify the work into one execution lane:

- `bugfix`
  Broken behavior, regression, outage, or incident. Use the quick path and bug issue discipline.

- `micro_change`
  One surface or platform, low-blast-radius tweak with no API/schema/sync/shared-contract change.
  Typical examples: sort order, copy, label, spacing, default selection, local filter, local presentation rule.
  Default path: durable `Change Brief` -> `implementation` -> `test_coverage` -> `qa`.

- `small_change`
  Bounded product change that is still small enough to avoid full Strategy/Discovery, but large enough to need a short contract before coding.
  Typical examples: one or two UX behaviors, parity adjustment, interaction model tweak, or bounded multi-screen change without migrations.
  Default path: compact Behavior Contract / `Change Brief` -> earliest valid gated stage, usually Stage 2 (`prd` stage id) or `design`.

- `full_feature`
  New multi-step flow, shared contract change, backend/schema/sync/share/import behavior, or anything cross-platform enough that a short brief is no longer sufficient.
  Default path: earliest valid full pipeline stage.

- `investigate`
  Evidence-first research, diagnosis, analytics, or product uncertainty.

- `release`
  Deploy, upload, distribution, or store-facing work.

## Resolution Rules

1. Check whether there is an active bugfix quick run in `.forge/active-run.env`.
2. Read `.forge/pipeline-state.yaml` and the linked issue.
3. Resolve intent first, then choose the execution lane, then the earliest valid stage.
4. Never skip an unresolved gated stage.
5. A gate decision is an independent judgment about whether the current stage can unlock the next one.
6. Judge gates from the issue contract, approved upstream artifacts, and current evidence; do not simply echo the last agent's `PASS` / `FAIL` recommendation.
7. If the user approves in chat, mirror that approval into the issue before moving labels or state.
8. Advance at most one gated transition per gate decision.

## Where The Surface Lives

### Claude Code

Installed into the target repo as:
- `.claude/commands/forge/*.md`

Templates live in forge at:
- `adapters/claude-code/commands/product/*.md`
- `adapters/claude-code/commands/self/self.md`

### Codex and other agents

Current routing is softer:
- `AGENTS.md`
- entry skills such as `core/skills/product-entry/SKILL.md` and `core/skills/self-entry/SKILL.md`
- project-local `CLAUDE.md` / `.forge/config.yaml`

## Related Files

- `core/skills/product-entry/SKILL.md`
- `core/skills/self-entry/SKILL.md`
- `core/pipeline/orchestrator.md`
- `adapters/claude-code/README.md`
