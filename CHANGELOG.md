# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.3] — 2026-05-24

Codex W3.1c review (PASS_WITH_CHANGES) — folded 5 findings.

### Fixed
- SUBMISSION.md version refs bumped (3 places still said v0.1.1 after the v0.1.2 manifest bump).
- `prd` skill description: was "Product Requirements Document" — actually authors a **Behavior Contract** (internal stage id `prd` kept for back-compat, but artifact is one compact contract not a separate PRD + test plan pair).
- `test-plan` skill description: was "test plan / coverage matrix / fixtures" — actually **Proof Hardening** (strengthens the Behavior Contract IN PLACE, no separate file by default).
- `implementation` skill description: was "after architecture + test plan approved" (too narrow). Now covers bugfix / micro_change / small_change / full_feature explicitly, and notes Proof Hardening is optional.
- `investigate` skill description: was overlapping with discovery/scout. Now explicit "INVESTIGATION (not discovery, not scouting)" with sister-skill cross-references.
- SUBMISSION.md "Anthropic Verified" mention softened — there is no public application process visible; verification is at Anthropic's discretion.
- SUBMISSION.md CLAUDE.md rename caveat: v0.2.0 will MOVE content to `skills/contributor-router/SKILL.md` (where Claude Code DOES load it), not blind-rename to CONTRIBUTING.md which would lose the routing.

### Validation status
- `claude plugin validate .` → still 1 warning, 0 errors (unchanged).
- `claude plugin validate --strict .` → still fails on the CLAUDE.md warning; deferred to v0.2.0 per the corrected plan above.

## [0.1.2] — 2026-05-24

Post-W3.1b codex review (PASS_WITH_CHANGES) — caught that `claude plugin validate` IS in Claude Code 2.1.150 (earlier note saying it was unavailable was wrong) and that 15 validation warnings were live.

### Fixed
- All 14 forge stage skills (`core/skills/architecture/SKILL.md`, `code-review`, `design`, `discovery`, `implementation`, `prd`, `product-analytics`, `qa`, `staging-deploy`, `canary-deploy`, `strategy`, `tech-monitoring`, `test-coverage`, `test-plan`) now have YAML frontmatter with `name:` + `description:`. Description text is the consumer-facing trigger (e.g., strategy: "Use when defining or refreshing product strategy …"). Per official docs, `description:` is what Claude uses to auto-invoke the skill.
- SUBMISSION.md updated: removed the false "validate not available in 2.1.150" claim. Added a "Why the remaining CLAUDE.md warning is intentional" section explaining the contributor-router rationale.

### Validation status
- `claude plugin validate .` → 1 warning, 0 errors (was 15 warnings).
- `claude plugin validate --strict .` → still fails on the 1 remaining `CLAUDE.md` warning. v0.2.0 will rename CLAUDE.md → CONTRIBUTING.md to clear strict mode.

### Already in v0.1.1 (carry-over reminder)
- spec-compliant manifest (only `name`, `description`, `version`, `author`, `homepage`, `repository`, `license`)
- `skills` symlink → `core/skills` for spec-required location with back-compat to existing forge scripts

## [0.1.1] — 2026-05-24

Post-W3.1 fact-check after reading official Anthropic plugin docs (https://code.claude.com/docs/en/plugins). v0.1.0 manifest had several non-compliant fields and wrong submission URL in SUBMISSION.md.

### Fixed
- `.claude-plugin/plugin.json` — stripped invented fields (`skills_directory`, `scripts_directory`, `templates_directory`, `adapters_directory`, `commands_directory`, `_compat_notes`, `_install_hint`, `keywords`). Manifest now matches the official schema: `name`, `description`, `version`, `author`, `homepage`, `repository`, `license` only.
- `skills/` added as a symlink to `core/skills/` so Claude Code can find the skill catalogue at the spec-required location while existing forge scripts (`forge-doctor.sh`, `forge-stage-agent.sh`, `INDEX.yaml`) continue to reference `core/skills/`.
- `SUBMISSION.md` — corrected submission URLs from the wrong `clau.de/plugin-directory-submission` to the official `https://claude.ai/settings/plugins/submit` and `https://platform.claude.com/plugins/submit`. Added `claude plugin validate` note (command not in CLI 2.1.150 yet; submission form runs it server-side).
- `SUBMISSION.md` — noted plugin skills will be namespaced as `/gulyaev-forge:<skill>` (per official docs, plugin skills are ALWAYS namespaced).

### Deferred to 0.2.0
- Skills layout normalisation: remove the symlink, move `core/skills/` to top-level `skills/` for real, update internal script refs.
- `agents/` subdir with actual Claude subagent definitions (current `adapters/` is per-CLI translators, not subagents).
- Per-skill SKILL.md frontmatter audit (need `description:` on every SKILL.md for Claude auto-invocation).
- `bin/` for scripts that should be on `$PATH` while plugin is enabled.

## [0.1.0] — 2026-05-24

Initial plugin manifest extraction (W3.1 of Agent-Ready 2026 program — maxgulyaev/spodi#336).

### Added
- `.claude-plugin/plugin.json` declaring this repository as a Claude Code plugin.
  - Non-standard `skills_directory: core/skills` preserved for backward compatibility with existing `forge-stage-agent.sh` + `forge-doctor.sh` paths.
  - Version 0.1.0 (initial public manifest); the underlying skills/scripts/templates have been live in maxgulyaev/spodi since March 2026.
- `LICENSE` (MIT).
- This `CHANGELOG.md`.

### Inherited (pre-manifest, pre-versioning)
- 18 stage skills under `core/skills/<stage>/SKILL.md` (strategy → discovery → prd → design → architecture → test_plan → implementation → code_review → test_coverage → qa → staging_deploy → canary_deploy → product_analytics → tech_monitoring → investigate → scout → product-entry → self-entry).
- 11 scripts under `scripts/` (forge-doctor, forge-status, forge-stage-agent, forge-issue-trail, forge-mcp, forge-init, forge-rules-check, forge-run-state, forge-release-scope, forge-release-target, forge-config-check, install-claude-commands).
- 13 templates under `core/templates/`.
- 8 agent adapters under `adapters/` (aider, claude-code, cline, codex, copilot, cursor, jules, windsurf).
- 3 pipeline docs under `core/pipeline/` (orchestrator, issue-tracking, entry-surface).

### Status of consuming projects
- `maxgulyaev/spodi` consumes this repo via `~/Documents/Dev/gulyaev-forge/` reference and `.forge/config.yaml` overlay (W1.1 fixed 5 broken refs in that overlay; W1.7 added `forge-config-check.sh` to detect future breakage).

### Out of scope for 0.1.0 (planned for 0.2.0+)
- Layout normalisation (top-level `skills/` instead of `core/skills/`).
- Public submission to the `claude-community` marketplace (W3.4 of Agent-Ready 2026).
- Per-skill SKILL.md frontmatter audit (some inherited skills have inconsistent frontmatter).
- Cross-link from spodi's `docs/agent-ready/governance.md` to this plugin manifest once 0.1.0 lands.
