# Forge Agent Router

This repository runs in `SELF` mode by default.

If the user asks to:
- improve the pipeline
- change skills
- add or evaluate MCP/tools
- update templates, docs, adapters, or process rules
- make the forge more operational

then treat the task as forge work, not product implementation.

Load `core/skills/self-entry/SKILL.md` first for these short prompts.

## Mandatory SELF Preflight

Before substantial forge work:

1. Run:
   - `bash scripts/forge-doctor.sh self .`
   - `bash scripts/forge-status.sh self .`
2. Read:
   - `core/skills/self-entry/SKILL.md`
   - `docs/operating-playbook.md`
   - `docs/design.md`
   - relevant files under `core/`, `docs/`, `scripts/`
3. If the task affects how connected products work, explicitly check the linked project repo after editing forge

## Short Prompts Must Work

Prompts like these should be handled without a long setup prompt:
- `Улучши pipeline`
- `Сделай forge более рабочим`
- `Добавь новый MCP`
- `Упрости запуск PRODUCT/SELF сценариев`

## Source Of Truth

- `docs/design.md` — roadmap and architecture intent
- `docs/operating-playbook.md` — how the system is operated today
- `README.md` and `QUICKSTART.md` — top-level explanation and usage
- `core/` — actual reusable forge assets

## Do Not

- do not treat forge tasks as product implementation by default
- do not invent automation that contradicts current scripts and docs
- do not require long restatement from the user if the repo already contains enough routing context
