# gulyaev-forge

The forge where products are built, processes are refined, and tools are sharpened.

## What is this?

AI-driven SDLC pipeline — a "factory" that manages how products are developed. Each stage of development is handled by a specialized AI agent with strict rules and relevant context.

Two operating modes:
- **PRODUCT** — work on products (features, bugs, pivots, new projects, analytics)
- **SELF** — work on the forge itself (skills, MCP servers, models, patterns, retrospectives)

## Structure

```
skills/                  # Pipeline stage skills (A-context: expertise)
  init/                  # Project scaffolding
  pipeline/              # Master skill — orchestrates stages
  pipeline-strategy/     # Stage 0: Product strategy
  pipeline-discovery/    # Stage 1: User research, competitor analysis
  pipeline-prd/          # Stage 2: Product requirements
  pipeline-design/       # Stage 3: UI/UX design
  pipeline-architecture/ # Stage 4: Technical architecture
  pipeline-implementation/ # Stage 6: Code
  pipeline-test-plan/    # Stage 5: Test specifications
  pipeline-test-coverage/# Stage 7: Test implementation
  pipeline-qa/           # Stage 8: Automated QA (Playwright)
  pipeline-staging-deploy/ # Stage 9: Staging
  pipeline-canary-deploy/  # Stage 10: Canary release
  pipeline-product-analytics/ # Stage 11: Product metrics
  pipeline-tech-monitoring/   # Stage 12: Technical monitoring
  scout/                 # Technology evaluation
  dashboard/             # Project status overview
templates/               # Templates for connecting projects
  scaffolding/           # File structure templates
    base/                # Required minimum (any project)
    extensions/          # Stack-specific (frontend, backend, mobile, ml, infra)
docs/                    # Design docs, roadmap, playbooks
registry/                # Skill & MCP server catalog
```

## Quick Start

```bash
# 1. Connect forge to a project
claude "SELF: подключи forge к проекту ~/myproject"

# 2. Work on a product
claude "PRODUCT: сделаем фичу X в Spodi"

# 3. Evaluate a new tool
claude "SELF: вот штука Context7 MCP, посмотри"

# 4. Check status
claude "PRODUCT: dashboard"
```

## Design

See [docs/design.md](docs/design.md) for full architecture and roadmap.
