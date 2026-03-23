# Operating Playbook

This is the minimum working model for running `gulyaev-forge` today.

Use portable shell variables in the examples below:

```bash
FORGE_DIR=/path/to/gulyaev-forge
PROJECT_DIR=/path/to/project
```

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
cd "$PROJECT_DIR"
bash "$FORGE_DIR/scripts/forge-doctor.sh" product .
bash "$FORGE_DIR/scripts/forge-status.sh" product .
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
- `/forge:work <request>`
- `/forge:bugfix <problem>`
- `/forge:feature <request>`
- `/forge:investigate <question>`
- `/forge:continue [reply]`
- `/forge:gate <decision>`
- `/forge:review`
- `/forge:release <distribution request>`

Practical rule:
- use `/forge:work` as the default single PRODUCT command
- use specialist commands only when you want to bias the router explicitly

Canonical source of truth for this public command surface:
- `core/pipeline/entry-surface.md`

Good prompts:
- `Поменяй порядок шаблонов в iOS по дате добавления.`
- `Сломалось сохранение тренировки. Почини.`
- `Хочу, чтобы можно было собирать суперсеты.`
- `Разберись, почему люди отваливаются на онбординге.`
- `Ок, едем дальше.`

Gate rule:
- the user can speak in business language; stage selection is internal
- `до Behavior Contract gate` or legacy phrasing like `до PRD gate` means "move toward Stage 2, but stop at the first unresolved gated stage"
- a gated stage does not advance until approval is recorded
- a gate decision asks whether the current stage is ready to unlock the next stage, not whether some useful work happened
- the agent must judge a gate from the issue contract, approved upstream artifacts, and current evidence; a prior agent's `PASS` / `go` is input evidence, not source of truth
- `approved_with_changes` is only for bounded follow-ups that do not reopen the current stage contract
- if required current-stage scope is still unverified or contradicted by evidence, reject the gate instead of advancing with TODOs
- for high-risk gated stages, run one explicit elicitation pass before presenting the gate:
  - `strategy` -> inversion
  - `Behavior Contract` -> pre-mortem
  - `architecture` -> red-team
  - `canary_deploy` -> pre-mortem
- the user does not need to type slash commands
- the router should also choose an execution lane for feature/change work:
  - `micro_change` for low-blast-radius local tweaks
  - `small_change` for bounded behavior changes needing a short contract
  - `full_feature` for the normal full pipeline
- `micro_change` should produce a durable `## Change Brief` and go straight to implementation instead of forcing a full contract/design loop
- `small_change` should default to a compact Behavior Contract and the earliest valid gated stage, not automatically to Strategy/Discovery
- the agent mirrors natural replies like `ок`, `поехали дальше`, or `да, но поправь X` into `/gate ...` comments in the issue trail
- if the stage is still in progress and no approval is needed yet, the agent must present a checkpoint with `Gate needed now: yes/no` and one exact next step
- for long implementation / investigation / release-prep runs, the checkpoint should also include a compact `Execution Proposal`:
  - current slice
  - milestone order
  - proof for each milestone
  - stop-and-fix rule if validation fails or scope drifts
- this `Execution Proposal` replaces ad-hoc prompt dumps for long runs; it does not create a new `plans.md` or `status.md`
- when the work reaches `implementation`, use Context7 for framework/library/API docs instead of guessing from memory
- for bugfix quick path, create/select the bug issue before code if the fix is non-trivial
- for bugfix quick path, keep `.forge/active-run.env` in sync and do not push before the QA gate is approved
- if `stage_agents.code_review.reviewer` is configured, run it before QA and include its findings in the gate summary
- for QA gates, route registration, build success, or unauthenticated `401` checks do not replace required user-facing journey evidence

TDD enforcement rule:
- implementation must follow proof-first discipline: define proof shape before writing code
- for projects with `docs/BUSINESS_RULES.md`:
  - bugfix → add regression-prevention rule with test reference
  - feature → add behavior rules before code
  - test_coverage → verify all `[x]` rules have passing tests
  - qa gate → include business rules coverage summary
- enforcement levels by lane:

| Lane | Proof Required | BUSINESS_RULES update | Test-First |
|------|---------------|----------------------|------------|
| `bugfix` | yes | yes (regression rule) | yes |
| `micro_change` | yes | if behavior changes | yes |
| `small_change` | yes | if behavior changes | yes |
| `full_feature` | yes | yes (new rules) | yes |

- code review (Stage 6.5) must validate TDD compliance before approving
- run `bash <forge-root>/scripts/forge-rules-check.sh <project> --verify` as part of test_coverage
- if `forge-rules-check.sh --verify` fails (missing test files for `[x]` rules), block QA progression

Track progress in:
- GitHub issue labels and comments
- `project/.forge/pipeline-state.yaml`
- `project/.forge/active-run.env` for active bugfix/hotfix runs
- stage artifacts in `docs/strategy`, `docs/prd`, `docs/architecture`, and so on

Behavior Contract rule:
- Stage 2 public artifact is now a compact **Behavior Contract**
- it lives under `docs/prd/` for compatibility
- it should contain product intent, scenarios, edge cases, and required proof in one file
- Stage 5 should harden that same file in place instead of creating a separate test-plan doc by default

## Stage Agents

Forge can attach secondary agents to explicit stage/role pairs.

Current supported shape in `project/.forge/config.yaml`:

```yaml
stage_agents:
  code_review:
    reviewer:
      transport: local_cli
      adapter: codex-review
      prompt_file: .forge/reviewers/code-review.md
```

Transport model:
- **source of truth is not the transport**
  - issue trail
  - approved artifacts
  - `.forge/pipeline-state.yaml`
- `stage_agents` only define how a secondary agent is reached for one exact handoff
- the transport/runtime must never decide stage transitions, gate verdicts, or overwrite the approved artifact chain

Current built-in adapter registry:
- `codex-review` -> runs `codex exec -s workspace-write` with a no-edit review prompt, optional project prompt overlay, and a worktree-drift guard

The shape is generic even if current usage is narrow:
- `stage_agents.<stage>.<role>` selects a secondary agent for that exact handoff
- the project owns the mapping
- forge owns the adapter invocation details
- today the pilot project uses only `code_review/reviewer`

Current and future transport classes:
- `local_cli`
  - current supported runtime
  - forge launches a local command or adapter in the same machine/workspace
- `mcp`
  - future candidate
  - forge would call an already-available MCP-exposed agent/tool runtime
- `acp_a2a`
  - future candidate
  - forge would hand off to a remote agent over an agent-to-agent transport such as ACP/A2A

Adoption rule:
- do not introduce `mcp` or `acp_a2a` just because the protocol is interesting
- revisit them only when `stage_agents` need more than review-only local helpers:
  - multiple long-running secondary agents
  - remote agents outside the current workspace
  - clear pain from the explicit local adapter model

Practical boundary:
- use forge to decide **what stage/role handoff should happen**
- use the transport only to decide **how the secondary agent is reached**
- keep gates, approved artifacts, and pipeline progression in forge itself

Useful commands:

```bash
bash "$FORGE_DIR/scripts/forge-stage-agent.sh" show . code_review reviewer
bash "$FORGE_DIR/scripts/forge-stage-agent.sh" run . code_review reviewer
```

Practical model:
- Claude stays the builder/orchestrator
- Codex acts as the external reviewer
- future projects can swap the reviewer by config without rewriting the pipeline
- future transport upgrades should preserve this mental model instead of replacing forge with an agent mesh

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
bash "$FORGE_DIR/scripts/forge-release-target.sh" list .
bash "$FORGE_DIR/scripts/forge-release-target.sh" show . ios_testflight
bash "$FORGE_DIR/scripts/forge-release-scope.sh" dirty . ios_testflight
```

## Release Communication

User-facing releases should produce a durable communication artifact, not just an upload.

Default rule:
- if a release changes what users see, do, or feel, prepare a canonical packet in `docs/release-notes/`
- treat that packet as the source of truth for user-facing wording across website, store/beta notes, and owned channels
- do not reduce `release notes` to App Store text only

Minimum packet contents:
- canonical summary of what changed for users
- concrete user-visible additions, fixes, or behavior changes
- availability / rollout note
- channel adaptations:
  - product website or changelog
  - primary community channel such as Telegram / Discord / email
  - short social variant for X / LinkedIn / other socials
  - store or beta notes when the target is mobile/distribution
- publication plan with status per channel: `draft`, `ready`, `published`, or `n/a`

Operational rule:
- Stage 9/10 release work is not fully ready for a user-facing ship until the communication packet exists
- publication itself may still be manual, but the release gate must say what is already published versus only prepared
- internal-only or invisible releases may mark the packet `n/a`, but that decision should be explicit

Recommended path:
- `docs/release-notes/YYYY-MM-DD-<slug>.md`
- template: `core/templates/release-notes-template.md`

Optional project metadata in `.forge/config.yaml`:

```yaml
release_communication:
  channels:
    website:
      type: changelog
    community:
      type: telegram_post
    social_short:
      type: short_social
    beta_notes:
      type: store_notes
```

Use this as lightweight routing metadata for the agent.
If absent, fall back to the generic channel set above.

## Bugfix Trail

Quick-path bugfixes must leave a durable trail in the issue, not only in local state.

Required before ship:
- `## QA Gate` comment
- `## Stage 6.5 — External Code Review` comment when external reviewer is configured
- `/gate approved` or `/gate approved_with_changes`

Useful commands:

```bash
bash "$FORGE_DIR/scripts/forge-issue-trail.sh" show-bugfix . 101
bash "$FORGE_DIR/scripts/forge-issue-trail.sh" check-bugfix-ship . 101
```

## QA Tools

For web-heavy products, declare preferred QA tools explicitly:

```yaml
qa_tools:
  playwright_mcp:
    enabled: true
    use_for: web_feature_qa,web_bugfix_qa,web_release_smoke
    scope_paths: apps/web
```

Operational rule:
- for web feature QA, the agent should use Playwright MCP before defaulting to manual QA
- if `playwright_mcp` is enabled and the surface is web UI, the agent should use it before defaulting to manual QA
- if it is not used, the gate must explain why

Look for these fields in `pipeline-state.yaml`:
- `current_stage`
- `current_gate_status`
- `current_stage_artifact`

## Scenario 2: Improve The Forge

Run this from `gulyaev-forge`.

```bash
cd "$FORGE_DIR"
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
- `docs/mcp-bootstrap.md` for machine-level Claude MCP setup

Good prompts:
- `Хочу изменить процесс stage gates`
- `Добавь новый MCP в forge`
- `Улучши architecture skill`
- `Нужно сделать forge более рабочим для нового пилота`

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
- per-machine MCP installation from `docs/mcp-bootstrap.md` and `bin/forge mcp`
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
