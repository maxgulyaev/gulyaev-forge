# Forge Skill Catalog (`INDEX.yaml`)

## Purpose

`INDEX.yaml` is a slim, machine-readable catalog of every skill under
`core/skills/`. It exists so that an agent entering Forge can decide which
skill body to read without scanning the directory or loading every
`SKILL.md` up front.

The pattern follows the lazy-loading discipline described in Anthropic's
"Code execution with MCP" (Nov 2025): keep the dispatch surface small,
load tool bodies only when the runtime actually needs them.

## Contract

- Every directory under `core/skills/` that contains a `SKILL.md` MUST have
  exactly one corresponding entry in `INDEX.yaml`.
- `forge-doctor self` enforces presence, YAML validity, and coverage.
- The catalog is **additive**. Agents and adapters that read
  `core/skills/<name>/SKILL.md` directly continue to work. The catalog is a
  preferred entry point, not a replacement.

## How an agent should use it

1. At session entry, load `core/skills/INDEX.yaml`.
2. Pick the candidate skill(s) using `kind`, `stage_id`, `triggers`,
   and current pipeline state from `.forge/pipeline-state.yaml` /
   `.forge/active-run.env`.
3. Read the body of the chosen skill from `path`.
4. Read other skill bodies only if the chosen workflow explicitly hands
   off to them.

The catalog itself is intentionally small. It is meant to fit comfortably
in context alongside the chosen stage skill, not to replace it.

## When to update

- Adding a new skill directory under `core/skills/`: append an entry.
- Renaming a skill directory or its `stage_id`: update the matching
  entry and any project overlays that reference the old name.
- Substantially changing the role/triggers/inputs of a skill: refresh
  `description`, `triggers`, and `inputs`. Keep `description` to one line.
- `size_lines` is informational. It may drift between edits and is
  re-synced as a side effect of routine maintenance, not on every commit.

## Non-goals (for this pass)

- This catalog does NOT enforce per-stage MCP loading. The `stages:`
  field already present in `core/registry/mcp-servers.yaml` continues to
  describe MCP scoping at a documentary level; runtime enforcement is a
  separate follow-up.
- This catalog does NOT split `core/pipeline/orchestrator.md` or
  `core/pipeline/issue-tracking.md`. Those remain whole references.
