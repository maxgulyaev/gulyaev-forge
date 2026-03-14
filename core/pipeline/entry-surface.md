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

If the user says `доведи до PRD gate`, that is a destination hint, not permission to skip unresolved earlier gates.

## Public Entry Surface

### PRODUCT

- `/forge:bugfix <problem>`
  Use for bug, regression, outage, or broken behavior.
  Default path: bug issue -> `implementation` -> `test_coverage` -> `code_review` when configured -> `qa`.

- `/forge:feature <request>`
  Use for new feature or product change.
  Default path: resume existing issue stage if present, otherwise start from the earliest valid stage.

- `/forge:investigate <question>`
  Use for uncertainty, diagnosis, product research, analytics questions, or "why is this happening?" requests.
  Default path: `discovery`, `product_analytics`, or `strategy`.

- `/forge:continue [reply]`
  Use to continue the current workflow or answer the current gate in natural language.
  Default behavior: resume active workflow; if a gate is pending, mirror the decision into the issue and advance at most one transition.

- `/forge:gate <decision>`
  Use when the human wants to record an explicit gate decision directly.
  Default behavior: write exactly one durable `/gate ...` decision to the issue trail, then update labels/state if advancement is allowed.

- `/forge:review [focus]`
  Use to run the configured external reviewer for the current PRODUCT repo.
  Default behavior: execute Stage 6.5 external code review and write the durable review summary to the issue trail.

- `/forge:release <distribution request>`
  Use for upload, deploy, store submission, or distribution work.
  Default behavior: resolve the configured `release_target`, validate preconditions, run the target-specific runbook, and stop at the next release gate if needed.

### SELF

- `/forge:self <forge change>`
  Use inside the forge repo for pipeline, docs, skills, templates, adapters, or process changes.

## Natural-Language Contract

The user may speak in business language instead of slash commands.

Examples:
- `Кнопка не работает. Почини.`
- `Хочу добавить суперсеты.`
- `Почему люди не доходят до оплаты?`
- `Ок, едем дальше.`
- `Выложи апдейт в TestFlight.`
- `Сделай forge более рабочим.`

The adapter or entry skill should map these to the same intents above.

## Resolution Rules

1. Check whether there is an active bugfix quick run in `.forge/active-run.env`.
2. Read `.forge/pipeline-state.yaml` and the linked issue.
3. Resolve intent first, then the earliest valid stage.
4. Never skip an unresolved gated stage.
5. If the user approves in chat, mirror that approval into the issue before moving labels or state.
6. Advance at most one gated transition per gate decision.

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
