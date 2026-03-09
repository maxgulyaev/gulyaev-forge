# gulyaev-forge

The forge where products are built, processes are refined, and tools are sharpened.

## What is this?

Agent-agnostic AI-driven SDLC pipeline. A "factory" that manages how products are developed — works with **any** AI coding agent.

Two operating modes:
- **PRODUCT** — work on products (features, bugs, pivots, new projects, analytics)
- **SELF** — work on the forge itself (skills, MCP servers, models, patterns, retrospectives)

## Agent Support

| Agent | Adapter | Status |
|-------|---------|--------|
| Claude Code | `adapters/claude-code/` | planned |
| Cursor | `adapters/cursor/` | planned |
| Codex CLI | `adapters/codex/` | planned |
| Windsurf | `adapters/windsurf/` | planned |
| GitHub Copilot | `adapters/copilot/` | planned |
| Google Jules | `adapters/jules/` | planned |
| Cline | `adapters/cline/` | planned |
| Aider | `adapters/aider/` | planned |

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

No skills or knowledge copied into projects — agents read from forge directly.

## Pipeline (13 stages, full product loop)

```
Strategy → Discovery → PRD → Design → Architecture → Test Plan →
Implementation → Test Coverage → Automated QA → Staging Deploy →
Canary Deploy → Product Analytics → Tech Monitoring → back to Strategy
```

Each stage agent receives:
- **A**: Role expertise from `forge/core/skills/[stage]`
- **B**: Project context filtered for that role from `project/.forge/config.yaml`

## Quick Start

```bash
# Connect forge to a project (generates .forge/config.yaml)
forge init --project ./my-app --agents claude-code,cursor

# Work on a product feature
"PRODUCT: build feature X for my-app"

# Improve the forge itself
"SELF: add new MCP server for monitoring"

# Evaluate a new tool
"SELF/SCOUT: check out Context7 MCP"

# See status across all projects
"PRODUCT/DASHBOARD"
```

## Design

Full architecture and roadmap: [docs/design.md](docs/design.md)
