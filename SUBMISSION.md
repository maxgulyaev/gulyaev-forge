# Claude Code marketplace submission checklist

W3.4 of Agent-Ready 2026 program (maxgulyaev/spodi#336), corrected per official Anthropic plugin docs (W3.1b).

**Status as of 2026-05-24:** v0.1.3 manifest live (`.claude-plugin/plugin.json`), `skills/` symlinked to `core/skills/` for spec compliance, LICENSE + CHANGELOG present.

## How the submission process works (2026-05, per official docs)

- The official channels are the in-app submission forms:
  - **Claude.ai**: https://claude.ai/settings/plugins/submit
  - **Console**: https://platform.claude.com/plugins/submit
- Anthropic runs `claude plugin validate` on submission AND automated safety screening.
- Approved plugins are pinned to a specific commit SHA in `anthropics/claude-plugins-community`.
- CI bumps the pin automatically as you push new commits.
- Catalog syncs nightly; expect a delay between approval and `marketplace.json` appearance.

The official `claude-plugins-official` directory is **curated by Anthropic**. The submission form does NOT add plugins there. We're aiming for `claude-community` only.

## Pre-flight checklist

- [x] `.claude-plugin/plugin.json` exists at repo root and parses as valid JSON
- [x] Manifest fields are spec-compliant only (`name`, `description`, `version`, `author`, `homepage`, `repository`, `license`) — no invented `_compat_notes` / `skills_directory` etc.
- [x] Version follows semver (currently `0.1.3`)
- [x] `LICENSE` file at repo root (MIT)
- [x] `CHANGELOG.md` with at least one entry
- [x] `README.md` explains what the plugin does, how to install, and example usage
- [x] `skills/` exists at repo root (symlink to `core/skills/` for back-compat with existing forge scripts)
- [x] `claude plugin validate .` passes (Claude Code 2.1.150 DOES expose the command — earlier note was wrong). Currently 1 advisory warning about plugin-root `CLAUDE.md` not being loaded as plugin context (intentional — that CLAUDE.md is for forge contributors, not plugin consumers; documented below). `claude plugin validate --strict .` fails on warnings; for now we ship with warnings.
- [ ] `git grep -E "ghp_|ghs_|gho_|github_pat_|sk-ant-"` returns no matches (no secrets)
- [ ] No machine-specific absolute paths in tracked files
- [ ] All shell scripts run with `bash` (zsh-only constructs flagged in PR review)
- [ ] Each `SKILL.md` has frontmatter `description:` — important: it's what Claude uses to auto-invoke the skill

## Submission form fields (prepare these strings)

When opening https://claude.ai/settings/plugins/submit or https://platform.claude.com/plugins/submit:

**Plugin name:** `gulyaev-forge`

**Plugin namespace (auto, FYI):** After install, skills will be `/gulyaev-forge:<skill-name>` (e.g., `/gulyaev-forge:strategy`, `/gulyaev-forge:code-review`). Per official docs, plugin skills are ALWAYS namespaced to prevent conflicts.

**Tagline / short description:** `Universal pipeline orchestrator for AI-agent-driven product engineering — 18 stage skills + 8 agent adapters.`

**Long description:**
```
Gulyaev Forge is a Claude Code plugin that turns a product team into a pipeline-driven shop. It ships 18 stage skills (strategy → discovery → PRD → design → architecture → test plan → implementation → code review → test coverage → QA → staging/canary deploy → product analytics → tech monitoring → investigate / scout / product-entry / self-entry), 8 agent adapters (claude-code, codex, cursor, aider, cline, copilot, jules, windsurf), 11 operator scripts (forge-doctor, forge-status, forge-stage-agent, forge-config-check, forge-issue-trail, forge-mcp, forge-init, forge-rules-check, forge-run-state, forge-release-scope, forge-release-target), and 13 stage templates.

Forge is the Enterprise tier of a 3-tier hierarchy (Enterprise / Project / Personal). Designed to be lazy-loaded — agents pick up only the stage skill they need via INDEX.yaml dispatch, not all 18 at once.

Used in production by maxgulyaev/spodi (a Russian-language fitness app) where it drove the 2026 Q2 Agent-Ready program: safety scaffolding + cost economy + multi-agent CI review wiring.
```

**Repository URL:** `https://github.com/maxgulyaev/gulyaev-forge`

**License:** `MIT`

**Tags / categories:** `pipeline`, `orchestration`, `code-review`, `stage-gates`, `agent-ready`, `multi-agent`, `forge`

**Maintainer:** Max Gulyaev (@maxgulyaev)

**After install, users run:**
```
/plugin marketplace add anthropics/claude-plugins-community
/plugin install gulyaev-forge@claude-community
```

### Why the remaining CLAUDE.md warning is intentional

`claude plugin validate` emits 1 warning:

> CLAUDE.md at the plugin root is not loaded as project context. To ship context with your plugin, use a skill (skills/<name>/SKILL.md) instead.

Forge's root `CLAUDE.md` is the **contributor router** — it guides agents that are working ON forge itself (writing new skills, debugging the pipeline). Plugin **consumers** never see this file; they install the plugin and invoke `/gulyaev-forge:<skill-name>` directly. The warning is informational, not an error. We accept it for v0.1.x. v0.2.0 will move CLAUDE.md content somewhere Claude Code DOES load (likely a `skills/contributor-router/SKILL.md` with the same content), keeping the contributor routing live; a blind file rename would lose the routing logic embedded in the current CLAUDE.md.

## After submission

1. Save the submission ID returned by the form.
2. The review pipeline runs automated validation. Watch for results (per official docs there's "a delay between approval and your plugin appearing in marketplace.json" while the nightly catalog sync happens).
3. If validation fails, fix in a follow-up commit + re-submit form with the new commit SHA.
4. Once accepted, the plugin appears in `claude-community`. Users install via the commands above.

## Known v0.2.0 work (post-submission polish)

These are NOT blockers for v0.1.3 submission but should land before any potential push toward an "Anthropic Verified" review (no public application process visible today; verification appears to be at Anthropic's discretion):

- **Skills layout normalisation** — currently `skills/` is a symlink to `core/skills/`. Move to a real directory and update `forge-doctor.sh` / `forge-stage-agent.sh` to use the new path; remove the symlink. Spodi consumer side (`.forge/config.yaml`) doesn't reference forge skills directly so no consumer migration needed.
- **`agents/` subdir** — official spec wants agent definitions there. Forge has `adapters/` instead (per-CLI-tool translators, not Claude subagents). Either rename or add a separate `agents/` with actual subagent definitions.
- **Per-skill SKILL.md frontmatter audit** — some inherited skills may have missing `description:` fields. Without `description:`, Claude can't auto-invoke the skill (per official docs: "Include a `description` so Claude knows when to use the skill").
- **`bin/` directory** — if any forge script should be on the user's `$PATH` while the plugin is enabled, move to `bin/` per spec.
- **`hooks/hooks.json`** — if forge ships hooks, they go here, NOT in `settings.json`.
- **`monitors/monitors.json`** — if forge wants to ship background monitors (e.g., a status-poll), add here.
- **`claude plugin validate`** locally once the CLI exposes the command.

## After this PR

- User (Max) opens https://claude.ai/settings/plugins/submit or https://platform.claude.com/plugins/submit and fills the form using the strings above.
- W3 of Agent-Ready 2026 is effectively closed — remaining work is platform-side review + any v0.2.0 polish.

## Refs

- Official Anthropic plugin docs: https://code.claude.com/docs/en/plugins
- Plugin reference: https://code.claude.com/docs/en/plugins-reference
- Discover plugins: https://code.claude.com/docs/en/discover-plugins
- Plugin marketplaces: https://code.claude.com/docs/en/plugin-marketplaces
- Community catalog: https://github.com/anthropics/claude-plugins-community
