# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
