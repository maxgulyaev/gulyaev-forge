# gulyaev-forge

## What is this
AI-driven SDLC pipeline — a "factory" for building products.
Two operating modes: PRODUCT (work on products) and SELF (work on the forge itself).

## Two Operating Modes

### PRODUCT — work on a product
Triggered by: feature requests, bug reports, new project ideas, pivots, analytics questions.
Context: loads from the target project's `project-context.yaml`.
Artifacts: saved in the target project's repo.

Sub-modes:
- **New Project** — full pipeline from Strategy, includes `/init` scaffolding
- **Feature / Bug** — enters pipeline at the appropriate stage
- **Pivot** — Strategy with focus on direction change, cascading updates
- **Analytics** — product/tech metrics analysis, continue/amplify/pivot/kill
- **Dashboard** — status across all projects

### SELF — work on the forge
Triggered by: new tools/skills/MCP, pipeline improvements, retrospectives.
Context: this repo.
Artifacts: saved here.

Sub-modes:
- **Scout** — evaluate new technology (adopt/trial/assess/hold)
- **Meta** — improve pipeline, create/update skills
- **Upgrade** — update models, CLI, MCP versions
- **Retrospective** — analyze what works/doesn't, improve processes

## Pipeline Stages (PRODUCT mode)

0. Strategy → 1. Discovery → 2. PRD → 3. Design → 4. Architecture →
5. Test Plan → 6. Implementation → 7. Test Coverage → 8. Automated QA →
9. Staging Deploy → 10. Canary Deploy → 11. Product Analytics → 12. Tech Monitoring
→ loops back to Strategy

## Architecture: A + B Context Injection

Each pipeline agent receives:
- **A (expertise)** — skill from `skills/pipeline-*/` with best practices for that stage
- **B (project)** — project-specific context from `project-context.yaml`

## Gate Format

Every gate between stages contains:
1. **Summary** — 3-5 bullets, recommendation (go/concerns/stop), question for approval
2. **Detailed** — full artifact, review checklist, trade-offs, diff
3. **Rollback Plan** — affected files/migrations/deploys, rollback commands, pre-state reference

## Key Rules
- NEVER skip gates — always wait for human approval
- NEVER deploy without explicit user OK
- Every artifact is saved to the project's standard directory structure
- When evaluating new tech (Scout), always give a clear verdict with reasoning
- Pipeline is generic — works for any project, specifics come from project-context.yaml

## File Structure
```
skills/          — Pipeline stage skills (A-context)
templates/       — Scaffolding templates, gate templates
docs/            — Design docs, roadmap
registry/        — Skill & MCP catalog
```

## Design Doc
Full design and roadmap: `docs/design.md`
