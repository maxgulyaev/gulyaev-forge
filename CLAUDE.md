# gulyaev-forge

## What is this
Agent-agnostic AI-driven SDLC pipeline — a "factory" for building products.
Works with any AI coding agent (Claude Code, Cursor, Codex, Windsurf, Jules, Copilot, etc.).

Two operating modes: PRODUCT (work on products) and SELF (work on the forge itself).

## Architecture: Three Layers

### Core (universal, agent-agnostic)
`core/` — pure markdown knowledge that any agent can read:
- `core/skills/` — A-context: expertise per pipeline stage (how to write PRD, how to architect, etc.)
- `core/pipeline/` — stage definitions, gate format, orchestration rules
- `core/templates/` — artifact templates (PRD, arch doc, gate report, config.yaml...)
- `core/registry/` — catalog of known skills and MCP servers

### Adapters (agent-specific)
`adapters/` — translate core into agent-native format:
- `adapters/claude-code/` — .claude/ structure, SKILL.md format
- `adapters/cursor/` — .cursorrules, .cursor/rules/
- `adapters/codex/` — AGENTS.md
- etc.

### Project footprint
What forge adds to each project — ONLY `.forge/`:
```
project/.forge/
  config.yaml    # Agents used, stage context injection (role-filtered)
```
No skills, no knowledge copies. Agents read A-context from forge directly.

## Role-Oriented Context Filtering

Each pipeline agent receives ONLY the project context relevant to its role:
- PRD agent → strategy + backlog + research (NOT deploy config, NOT code style)
- Architecture agent → PRD + design + tech stack (NOT market research)
- QA agent → PRD acceptance criteria + staging URL (NOT strategy)

Filtering is defined in `project/.forge/config.yaml` under `stages.[name].inject`.

## Two Operating Modes

### PRODUCT — work on a product
Triggered by: feature requests, bug reports, new project ideas, pivots, analytics.
Context: target project's `.forge/config.yaml` + forge core skills.

Sub-modes: New Project, Feature/Bug, Pivot, Analytics, Dashboard

### SELF — work on the forge
Triggered by: new tools/skills/MCP, pipeline improvements, retrospectives.
Context: this repo.

Sub-modes: Scout, Meta, Upgrade, Retrospective

## Session Router

This repo is `SELF` by default.

Short prompts like these must work without a long setup prompt:
- `Улучши pipeline`
- `Добавь новый MCP`
- `Сделай forge более рабочим`
- `Упрости запуск PRODUCT/SELF сценариев`

Before substantial forge work:
1. Run `bash scripts/forge-doctor.sh self .`
2. Run `bash scripts/forge-status.sh self .`
3. Read `core/skills/self-entry/SKILL.md`
4. Use `docs/operating-playbook.md` + `docs/design.md` as operational context
5. If the change affects connected projects, validate the target project repo after editing forge

## Pipeline Stages

0. Strategy → 1. Discovery → 2. PRD → 3. Design → 4. Architecture →
5. Test Plan → 6. Implementation → 7. Test Coverage → 8. Automated QA →
9. Staging Deploy → 10. Canary Deploy → 11. Product Analytics → 12. Tech Monitoring
→ loops back to Strategy

## Gate Format

Every gate between stages contains:
1. **Summary** — 3-5 bullets, recommendation (go/concerns/stop), approval question
2. **Detailed** — full artifact, review checklist, trade-offs, diff
3. **Rollback Plan** — affected files, rollback commands, pre-state reference

## Key Rules
- NEVER skip gates — always wait for human approval
- Agents read A-knowledge from forge, B-context from project (filtered by role)
- Core knowledge is pure markdown — agent-agnostic
- Adapters translate to native format but never change the substance
- When evaluating new tech (Scout), give clear verdict: adopt/trial/assess/hold
- Technology Scout: research → evaluate → recommend → implement (after OK)

## Design Doc
Full design and roadmap: `docs/design.md`
