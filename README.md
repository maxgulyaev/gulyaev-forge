# gulyaev-forge

The forge where products are built, processes are refined, and tools are sharpened.

## What is this?

Agent-agnostic AI-driven SDLC pipeline. A "factory" that manages how products are developed — works with **any** AI coding agent.

Two operating modes:
- **PRODUCT** — work on products (features, bugs, pivots, new projects, analytics)
- **SELF** — work on the forge itself (skills, MCP servers, models, patterns, retrospectives)

## Vision

`gulyaev-forge` is a founder operating system for AI-native product work.

Its job is to turn product chaos into a managed flow:
- ideas, bugs, requests, strategy questions, and analytics signals enter a clear pipeline
- each stage produces a concrete artifact and decision
- humans stay in control through gates, instead of delegating blindly

It also gives new AI tools their own disciplined adoption loop:
- new models, skills, MCP servers, and workflows do not get installed impulsively
- they are researched, evaluated, approved, and only then integrated into the forge

The long-term goal is simple: one operating model for building products and upgrading the factory that builds them.

## Who this is for

- **First:** the founder / product owner running one or more products with AI help
- **Then:** specialists joining specific gates with better context and less chaos
- **Later:** a broader reusable concept that can be shared with other teams

## Why it exists

Two core problems:
- product work arrives as chaos: feature ideas, bugs, research, strategy, deploys, follow-ups
- AI tooling evolves too fast: new skills, MCP servers, models, and agent features constantly tempt ad-hoc adoption

`gulyaev-forge` exists to make both flows governable.

The user-facing contract should stay simple:
- describe the business problem in natural language
- let the agent infer the correct path
- answer gates in natural language

## Agent Support

| Agent | Adapter | Status |
|-------|---------|--------|
| Claude Code | `adapters/claude-code/` | entry commands available |
| Cursor | `adapters/cursor/` | planned |
| Codex CLI | `adapters/codex/` | reviewer adapter available |
| Windsurf | `adapters/windsurf/` | planned |
| GitHub Copilot | `adapters/copilot/` | planned |
| Google Jules | `adapters/jules/` | planned |
| Cline | `adapters/cline/` | planned |
| Aider | `adapters/aider/` | planned |

## Universal Contract

Every agent should use the same forge contract underneath:

- **State**: GitHub issue + `.forge/pipeline-state.yaml`
- **Knowledge**: forge base skills + project overlays
- **Artifacts**: `docs/strategy`, `docs/research`, `docs/prd`, `docs/architecture`, and later-stage outputs
- **Canonical intents**:
  - `bugfix`
  - `feature`
  - `investigate`
  - `continue`
  - `gate`
  - `release`
  - `self`

What changes between agents is not the process, but the **entry surface**.

## Stage Agents

Projects may attach external agents to specific stages and roles.

The config shape is generic:

```yaml
stage_agents:
  code_review:
    reviewer:
      adapter: codex-review
      prompt_file: .forge/reviewers/code-review.md
```

Meaning:
- the primary PRODUCT agent still drives the pipeline
- any `stage/role` pair may attach a secondary agent
- today the standard use is Stage 6.5 (`code_review`) with role `reviewer`
- the project decides which reviewer to use
- forge owns the adapter invocation details

Current built-in adapter:
- `codex-review` -> `codex exec -s workspace-write` with a no-edit review prompt, project `prompt_file`, and post-run worktree-drift guard

Practical combinations:
- `code_review/reviewer` -> external code reviewer before QA
- future `architecture/reviewer` -> second opinion on ADR/API/data model changes
- future `qa/reviewer` -> secondary QA/risk pass before deploy

## Release Targets

Projects may declare reusable distribution surfaces in `.forge/config.yaml`.

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

Meaning:
- the user can say `залей на тестфлайт апдейт`
- Claude can enter through `/forge:release`
- forge resolves the target, loads the project runbook, and checks release preconditions before upload
- dirty files inside `scope_paths` block the upload even if the rest of the repo is dirty

This stays generic on purpose:
- `ios_testflight`
- `ios_app_store`
- `web_production`
- `android_internal`
- `android_production`
- future custom channels per product

Notes:
- a target may be fully automated or may end at an explicit store/release gate if the remaining submission steps are manual

## Bugfix Trail

For bugfix quick-path work, local state is not enough.

- QA must be written durably to the issue trail before it is presented as a final gate
- if Stage 6.5 external review is configured, its summary must also be written to the issue trail
- push is allowed only after the issue trail contains:
  - `## QA Gate`
  - `## Stage 6.5 — External Code Review` when configured
  - `/gate approved` or `/gate approved_with_changes`

## QA Tools

Projects may declare preferred QA tooling in `.forge/config.yaml`.

```yaml
qa_tools:
  playwright_mcp:
    enabled: true
    use_for: web_bugfix_qa,web_release_smoke
    scope_paths: apps/web
```

Meaning:
- for web UI bugfix QA, use Playwright MCP before falling back to manual checks
- for web release smoke, prefer Playwright MCP when the target environment is reachable
- if Playwright is not used, the agent must say why

## Entry Surface By Agent

### Claude Code

Recommended entry surface: repo-local slash commands.

Use:
- `/forge:bugfix <problem>`
- `/forge:feature <request>`
- `/forge:investigate <question>`
- `/forge:continue [reply]`
- `/forge:gate <decision>`
- `/forge:review`
- `/forge:release <distribution request>`
- `/forge:self <forge change>` in the forge repo

Why:
- Claude Code is more reliable with explicit command entrypoints than with soft routing through `CLAUDE.md` alone.
- Plugins like `superpowers` can otherwise pull the session into their own workflows.
- Canonical command map lives in `core/pipeline/entry-surface.md`.

Install:

```bash
FORGE_DIR=/path/to/gulyaev-forge

# PRODUCT repo
bash "$FORGE_DIR/scripts/install-claude-commands.sh" product /path/to/project

# SELF repo
bash "$FORGE_DIR/scripts/install-claude-commands.sh" self "$FORGE_DIR"
```

If the forge checkout moves to another path or another machine, rerun install or `forge init --force` in each product repo so local command files point at the new `FORGE_DIR`.

### Codex CLI

Current surfaces:
- `AGENTS.md` + repo-local instructions for direct Codex sessions
- external reviewer adapter via stage-agent launcher

Current reality:
- Codex can read forge rules from `AGENTS.md`, `CLAUDE.md`, `.forge/config.yaml`, and project artifacts.
- Codex can also act as a secondary reviewer when the project config maps `code_review/reviewer` to `codex-review`.
- Direct routing is still softer than Claude slash commands.

Recommendation today:
- use Codex in repos where `AGENTS.md` already routes into forge
- keep prompts short and business-oriented
- validate that Codex follows the current stage instead of defaulting to implementation
- for multi-agent use, prefer Codex as an explicit external reviewer before using it as a second builder

Target adapter:
- dedicated `adapters/codex/`
- stage-agent launcher for review already works
- wider Codex intent router is still planned

### Cursor

Target surface: `.cursor/rules/` adapter generated from forge core.

Status:
- planned, not production-ready yet

Expected shape:
- forge intent router encoded in Cursor rules
- same canonical intents (`bugfix`, `feature`, `investigate`, `continue`, `gate`, `self`)
- same state/artifact contract underneath

### Windsurf

Target surface: Windsurf rules adapter.

Status:
- planned, not production-ready yet

Expected shape:
- same forge contract
- native Windsurf entry layer on top of it

### GitHub Copilot / Cline / Aider

Status:
- planned

Expected shape:
- agent-native adapter layer for entry
- same forge state + skills + artifact contract underneath

### Google Jules and Other Cloud Agents

For cloud or hosted agents, the likely stable surface is not repo-local commands but **task packets**:
- GitHub issue as the contract
- approved stage artifact as context
- optional generated handoff packet from forge

That means these agents should not improvise from a naked prompt.
They should receive:
- issue link / issue body
- current stage
- approved prior artifact
- exact next intent (`bugfix`, `implement`, `review`, `investigate`, etc.)

### OpenClaw / Visual Orchestration Tools

These are better used as a **dashboard or orchestration UI**, not as the source of truth.

Best role:
- visualize pipeline status
- show current issue, current stage, pending gates
- launch the correct adapter entrypoint for the chosen agent

Not the source of truth:
- issue tracker remains the canonical task state
- `.forge/pipeline-state.yaml` remains the local cache
- forge skills remain the reusable process brain

## Architecture

```
gulyaev-forge/
  core/                      # Universal knowledge (pure markdown, any agent reads)
    skills/                  # A-context: expertise per pipeline stage
    pipeline/                # Stage definitions, gate format, processes
    templates/               # Artifact templates (PRD, arch doc, gate report...)
    registry/                # Skill & MCP server catalog
  adapters/                  # Translate core → agent-native format
    claude-code/             # .claude/ + SKILL.md
    cursor/                  # .cursor/rules/ + .cursorrules
    codex/                   # AGENTS.md
    ...
  docs/                      # Design docs, roadmap
```

**In each project** (what forge adds):
```
project/
  .forge/
    config.yaml              # Project config (agents, stage context injection)
```

Core knowledge should live in forge as the source of truth.
Projects may use direct references or thin adapter shims, but should avoid divergent local copies.

## Pipeline (13 stages + code review checkpoint)

```
Strategy → Discovery → PRD → Design → Architecture → Test Plan →
Implementation → Code Review → Test Coverage → Automated QA → Staging Deploy →
Canary Deploy → Product Analytics → Tech Monitoring → back to Strategy
```

Each stage agent receives:
- **A**: Role expertise from `forge/core/skills/[stage]`
- **B**: Project context filtered for that role from `project/.forge/config.yaml`

For every gated stage, explicit human approval is mandatory before the next gated stage may begin.
The durable approval record should live in the issue trail, but the user does not need to write that format manually.

## Quick Start

See **[QUICKSTART.md](QUICKSTART.md)** — step-by-step guide:
1. MCP setup (Context7, Playwright, GitHub)
2. Project initialization (`bin/forge init`, `.forge/config.yaml`, labels, folder structure)
3. Daily workflow (PRODUCT vs SELF mode)
4. How agents find and use forge skills

## Docs

- **[QUICKSTART.md](QUICKSTART.md)** — practical how-to-live-with-this guide
- **[docs/operating-playbook.md](docs/operating-playbook.md)** — exact commands, working model, status tracking
- **[docs/design.md](docs/design.md)** — full architecture, pipeline stages, roadmap
- **[core/pipeline/orchestrator.md](core/pipeline/orchestrator.md)** — stage order, gates, context injection
- **[core/pipeline/entry-surface.md](core/pipeline/entry-surface.md)** — canonical entry commands and routing contract
- **[core/pipeline/issue-tracking.md](core/pipeline/issue-tracking.md)** — Epic→Story→Task hierarchy, labels
