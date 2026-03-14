# Claude Code Adapter

Claude Code is more reliable with explicit slash-command entrypoints than with soft discovery through `CLAUDE.md` alone.

Natural-language prompts remain the desired product contract, but today the practical adapter for Claude Code is:
- repo-local `CLAUDE.md`
- repo-local `.claude/commands/forge/*.md`
- forge core skills and project overlays behind those commands

## Recommended Commands

Canonical source of truth for this command surface:
- `core/pipeline/entry-surface.md`

In a PRODUCT repo:
- `/forge:bugfix <business description>`
- `/forge:feature <business description>`
- `/forge:investigate <question or uncertainty>`
- `/forge:continue [optional short reply]`
- `/forge:gate <approval or feedback>`
- `/forge:release <distribution request>`

In the forge repo:
- `/forge:self <what to improve>`

## Install

```bash
# Product repo
bash ~/Documents/Dev/gulyaev-forge/scripts/install-claude-commands.sh product /path/to/project

# Forge repo
bash ~/Documents/Dev/gulyaev-forge/scripts/install-claude-commands.sh self ~/Documents/Dev/gulyaev-forge
```

The installer copies command files into `.claude/commands/forge/` in the target repo.

## Why This Exists

Without explicit entry commands, Claude Code can:
- default to generic implementation behavior
- prioritize plugin workflows over project-specific process
- miss forge routing rules even when they are present in `CLAUDE.md`

Slash commands make the entry intent explicit while still letting the user speak in business language inside the command arguments.
