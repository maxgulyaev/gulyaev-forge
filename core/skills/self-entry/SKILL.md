---
name: self-entry
description: Start SELF work in the gulyaev-forge repo. Use for short prompts like "improve the pipeline", "make forge more operational", "add a new MCP", or "change the process" so the agent routes into the right forge submode instead of treating it as generic coding work.
---

# Self Entry

## Purpose

This is the entry skill for SELF work inside `gulyaev-forge`.

Use it before making forge changes when the user gives a short prompt and expects the system to infer the correct operational route.

## Trigger Examples

- `Улучши pipeline`
- `Сделай forge более рабочим`
- `Добавь новый MCP`
- `Измени процесс гейтов`
- `Упрости запуск PRODUCT/SELF`

## Workflow

1. Run self preflight:
   - `bash scripts/forge-doctor.sh self .`
   - `bash scripts/forge-status.sh self .`
2. Load the slim skill catalog before reading other skill bodies:
   - `core/skills/INDEX.yaml`
   - use it to find utility skills (`scout`, `investigate`) or stage skills relevant to the requested forge change
   - read each chosen skill body from its `path` field
   - direct reads of `core/skills/<name>/SKILL.md` remain a supported fallback when the catalog is unavailable or out of date
3. Read:
   - `docs/operating-playbook.md`
   - `docs/design.md`
   - the most relevant files under `core/`, `docs/`, `scripts/`
4. Resolve the submode:
   - tool evaluation -> `Scout`
   - process / skill / template / adapter change -> `Meta`
   - version / runtime / MCP upgrade -> `Upgrade`
   - analyze pain points -> `Retrospective`
5. Execute the task in that submode.
6. If the forge change affects a connected product, validate it in that product repo after editing forge.

For `Scout` work specifically:
- use `core/skills/scout/SKILL.md`
- record the result in `docs/research/scout-queue.md`
- update `core/registry/mcp-servers.yaml` when the candidate belongs in the technical catalog

## Expected Outputs

- concrete forge edits
- updated docs or templates when behavior changes
- explicit validation notes

## Anti-Patterns

- Asking the user for a long restatement when repo docs already define the system
- Treating forge work as product implementation
- Changing process behavior without updating the relevant docs/templates
