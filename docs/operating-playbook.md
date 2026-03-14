# Operating Playbook

This is the minimum working model for running `gulyaev-forge` today.

## Layer Model

Short prompts should first route through an entry skill:
- `core/skills/product-entry/SKILL.md` for PRODUCT work
- `core/skills/self-entry/SKILL.md` for SELF work

After that, every stage should be assembled from four layers:

1. **Forge base skill**
   - `gulyaev-forge/core/skills/[stage]/SKILL.md`
   - universal role expertise
2. **Project overlay skill**
   - `project/.forge/skills/[stage].md`
   - thin product-specific guidance for that stage
3. **Project context config**
   - `project/.forge/config.yaml`
   - machine-readable file injection and stage settings
4. **Adapter shim**
   - `.claude/skills/`, `AGENTS.md`, `.cursor/rules/`, and similar
   - delivery format for the chosen agent

## Source Of Truth Order

When these layers disagree, use this order:

1. GitHub issue acceptance criteria and approved stage artifacts
2. Project overlay skill
3. Forge base skill
4. Adapter shim text

Some forge rules should remain non-overridable:
- gate discipline
- rollout safety
- source-of-truth hierarchy
- mandatory post-deploy smoke for risky surfaces

## Agent Matrix

Use the same forge contract everywhere:
- GitHub issue + `.forge/pipeline-state.yaml`
- forge base skills + project overlays
- stage artifacts in `docs/...`

What changes is the entry surface and the current trust level.

| Agent | Recommended entry | Trust level now | Adapter status |
|-------|-------------------|-----------------|----------------|
| Claude Code | `/forge:*` commands in `.claude/commands/forge/` | High | Working |
| Codex CLI | business-language prompt + `AGENTS.md` router, or external reviewer via stage-agent launcher | Medium | Review adapter working |
| Cursor | native rules adapter | Low | Planned |
| Windsurf | native rules adapter | Low | Planned |
| GitHub Copilot / Cline / Aider | agent-native adapter layer | Low | Planned |
| Google Jules / cloud agents | issue handoff packet + approved artifact | Low | Manual concept |
| OpenClaw / visual orchestration | dashboard that launches the right entrypoint | Medium as UI, not as source of truth | Concept |

Practical rule:
- if Claude Code is available, use `/forge:*`
- if Codex is available, use short business prompts and validate the first routing step
- for hosted/cloud agents, send a structured handoff packet instead of a naked prompt

## Scenario 1: Work On A Product

Run this from the product repo.

```bash
cd ~/Documents/Dev/spodi
bash ~/Documents/Dev/gulyaev-forge/scripts/forge-doctor.sh product .
bash ~/Documents/Dev/gulyaev-forge/scripts/forge-status.sh product .
```

`forge-status.sh product` should be the first place to look for the immediate next action:
- reconcile state mismatch
- record a gate decision
- or continue the current stage without a gate

Then start the agent in the product repo:

```bash
claude
# or codex
```

If you are using Claude Code, prefer explicit entry commands:
- `/forge:bugfix <problem>`
- `/forge:feature <request>`
- `/forge:investigate <question>`
- `/forge:continue [reply]`
- `/forge:gate <decision>`
- `/forge:review`
- `/forge:release <distribution request>`

Canonical source of truth for this public command surface:
- `core/pipeline/entry-surface.md`

Good prompts:
- `Сломалось сохранение тренировки. Почини.`
- `Хочу, чтобы можно было собирать суперсеты.`
- `Разберись, почему люди отваливаются на онбординге.`
- `Ок, едем дальше.`

Gate rule:
- the user can speak in business language; stage selection is internal
- `до PRD gate` means "move toward PRD, but stop at the first unresolved gated stage"
- a gated stage does not advance until approval is recorded
- the user does not need to type slash commands
- the agent mirrors natural replies like `ок`, `поехали дальше`, or `да, но поправь X` into `/gate ...` comments in the issue trail
- if the stage is still in progress and no approval is needed yet, the agent must present a checkpoint with `Gate needed now: yes/no` and one exact next step
- when the work reaches `implementation`, use Context7 for framework/library/API docs instead of guessing from memory
- for bugfix quick path, create/select the bug issue before code if the fix is non-trivial
- for bugfix quick path, keep `.forge/active-run.env` in sync and do not push before the QA gate is approved
- if `stage_agents.code_review.reviewer` is configured, run it before QA and include its findings in the gate summary

Track progress in:
- GitHub issue labels and comments
- `project/.forge/pipeline-state.yaml`
- `project/.forge/active-run.env` for active bugfix/hotfix runs
- stage artifacts in `docs/strategy`, `docs/prd`, `docs/architecture`, and so on

## Stage Agents

Forge can attach secondary agents to explicit stage/role pairs.

Current supported shape in `project/.forge/config.yaml`:

```yaml
stage_agents:
  code_review:
    reviewer:
      adapter: codex-review
      prompt_file: .forge/reviewers/code-review.md
```

Current built-in adapter registry:
- `codex-review` -> runs `codex exec -s workspace-write` with a no-edit review prompt, optional project prompt overlay, and a worktree-drift guard

The shape is generic even if current usage is narrow:
- `stage_agents.<stage>.<role>` selects a secondary agent for that exact handoff
- the project owns the mapping
- forge owns the adapter invocation details
- today `Spodi` uses only `code_review/reviewer`

Useful commands:

```bash
bash ~/Documents/Dev/gulyaev-forge/scripts/forge-stage-agent.sh show . code_review reviewer
bash ~/Documents/Dev/gulyaev-forge/scripts/forge-stage-agent.sh run . code_review reviewer
```

Practical model:
- Claude stays the builder/orchestrator
- Codex acts as the external reviewer
- future projects can swap the reviewer by config without rewriting the pipeline

## Release Targets

Forge can also attach named distribution surfaces to a project.

Current supported shape in `project/.forge/config.yaml`:

```yaml
release_targets:
  ios_testflight:
    platform: ios
    channel: testflight
    deploy_stage: canary_deploy
    runbook: CLAUDE.md#testflight--ios-distribution
    scope_paths: apps/ios
  web_production:
    platform: web
    channel: production
    deploy_stage: canary_deploy
    runbook: CLAUDE.md#web--production-deploy
    scope_paths: apps/web,apps/api,deploy,migrations
```

Practical model:
- the user says `залей на тестфлайт апдейт`
- Claude enters via `/forge:release`
- forge resolves the configured target and its runbook
- upload only happens if the release candidate already passed the needed gates
- a release target can represent either a full automated upload or an upload-plus-manual-store-gate flow
- dirty files inside the target `scope_paths` must block upload

Useful commands:

```bash
bash ~/Documents/Dev/gulyaev-forge/scripts/forge-release-target.sh list .
bash ~/Documents/Dev/gulyaev-forge/scripts/forge-release-target.sh show . ios_testflight
bash ~/Documents/Dev/gulyaev-forge/scripts/forge-release-scope.sh dirty . ios_testflight
```

## Bugfix Trail

Quick-path bugfixes must leave a durable trail in the issue, not only in local state.

Required before ship:
- `## QA Gate` comment
- `## Stage 6.5 — External Code Review` comment when external reviewer is configured
- `/gate approved` or `/gate approved_with_changes`

Useful commands:

```bash
bash ~/Documents/Dev/gulyaev-forge/scripts/forge-issue-trail.sh show-bugfix . 101
bash ~/Documents/Dev/gulyaev-forge/scripts/forge-issue-trail.sh check-bugfix-ship . 101
```

## QA Tools

For web-heavy products, declare preferred QA tools explicitly:

```yaml
qa_tools:
  playwright_mcp:
    enabled: true
    use_for: web_bugfix_qa,web_release_smoke
    scope_paths: apps/web
```

Operational rule:
- if `playwright_mcp` is enabled and the surface is web UI, the agent should use it before defaulting to manual QA
- if it is not used, the gate must explain why

Look for these fields in `pipeline-state.yaml`:
- `current_stage`
- `current_gate_status`
- `current_stage_artifact`

## Scenario 2: Improve The Forge

Run this from `gulyaev-forge`.

```bash
cd ~/Documents/Dev/gulyaev-forge
bash scripts/forge-doctor.sh self .
bash scripts/forge-status.sh self .
```

Then start the agent in the forge repo:

```bash
claude
# or codex
```

If you are using Claude Code here, prefer:
- `/forge:self <what to improve>`

Canonical source of truth:
- `core/pipeline/entry-surface.md`

Good prompts:
- `Хочу изменить процесс stage gates`
- `Добавь новый MCP в forge`
- `Улучши architecture skill`
- `Нужно сделать forge более рабочим для пилота на Spodi`

Track progress in:
- `docs/design.md` roadmap
- git history and working tree
- pilot project state in connected products

For technology/tool scouting, keep the result in:
- `core/skills/scout/SKILL.md`
- `core/templates/scout-note-template.md`
- `docs/research/scout-queue.md`
- `core/registry/mcp-servers.yaml` when the tool belongs in the registry

## Current Reality

Today the system is only partially automated.

What already works:
- forge base skills
- pipeline docs and gate format
- project config and pipeline-state files
- `forge init` MVP scaffolding for new projects
- manual use through Claude Code / Codex / GitHub Issues
- doctor and status scripts

What is still manual:
- full orchestration between stages
- adapter generation
- per-machine MCP installation from `QUICKSTART.md`
- automatic issue label sync and artifact writing

Until those are automated, you drive the transitions manually and use the docs plus scripts as the control surface.
That manual control still requires explicit gate approval before any later gated stage can start.

## Recommended Project Footprint

Minimum project setup:

```text
project/
  .forge/
    config.yaml
    pipeline-state.yaml
    skills/
      [stage].md
  CLAUDE.md
  REVIEW.md
```

`config.yaml` says what to inject.

`skills/[stage].md` says how this product should bend the generic role behavior.

`CLAUDE.md` and `REVIEW.md` stay as project-wide execution rules, not stage overlays.
