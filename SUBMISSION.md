# Claude Code marketplace submission checklist

W3.4 of Agent-Ready 2026 program (maxgulyaev/spodi#336). Step-by-step preparation for submitting gulyaev-forge to the claude-community marketplace.

**Status as of 2026-05-24:** v0.1.0 manifest live (`.claude-plugin/plugin.json`), CHANGELOG present, MIT LICENSE present. Ready for submission once the user completes the steps below.

## How the submission process works (2026-05)

- The official channel is the submission form at **https://clau.de/plugin-directory-submission**.
- Direct pull requests against `anthropics/claude-plugins-community` are auto-closed; the form is the only accepted route.
- Anthropic runs automated validation + safety screening before adding plugins to the directory.
- An "Anthropic Verified" badge requires additional review by Anthropic staff (quality + safety perspective).

## Pre-flight checklist (verify before submitting)

- [x] `.claude-plugin/plugin.json` exists at repo root and parses as valid JSON
- [x] `plugin.json` declares `name`, `description`, `version`, `author`, `license`
- [x] Version follows semver (currently `0.1.0`)
- [x] `LICENSE` file at repo root (MIT)
- [x] `CHANGELOG.md` with at least one entry
- [x] `README.md` explains what the plugin does, how to install, and example usage
- [ ] No secrets in tracked files (`git grep -E "ghp_|ghs_|gho_|github_pat_|sk-ant-" -- '*'` returns nothing)
- [ ] No machine-specific absolute paths in tracked files (`/Users/maxgulyaev/` etc.)
- [ ] All shell scripts are POSIX-friendly OR clearly require bash (no zsh-only constructs)
- [ ] All skill `SKILL.md` files have a frontmatter `name:` and `description:` (the `description:` is what Claude uses to match the skill to a task — clear triggers boost activation rate per Habr AI Kit case)

## Submission form fields (prepare these strings)

When the user opens https://clau.de/plugin-directory-submission, they will need:

**Plugin name:** `gulyaev-forge`

**Tagline (1 line):** `Universal pipeline orchestrator for AI-agent-driven product engineering — 18 stage skills + 8 agent adapters.`

**Description (longer):**
```
Gulyaev Forge is a Claude Code plugin that turns a fitness-tracking product team into a pipeline-driven shop. It ships 18 stage skills (strategy → discovery → PRD → design → architecture → test plan → implementation → code review → test coverage → QA → staging/canary deploy → product analytics → tech monitoring), 8 agent adapters (claude-code, codex, cursor, aider, cline, copilot, jules, windsurf), 11 operator scripts (forge-doctor, forge-status, forge-stage-agent, forge-config-check, ...), and 13 stage templates.

The Enterprise tier of a 3-tier hierarchy (Enterprise / Project / Personal). Designed to be lazy-loaded — agents pick up only the stage skill they need via INDEX.yaml dispatch, not all 18 at once.

Used in production by maxgulyaev/spodi (a Russian-language fitness app) where it drove the 2026 Q2 Agent-Ready program (safety scaffolding + cost economy + multi-agent CI review wiring).
```

**Repository URL:** `https://github.com/maxgulyaev/gulyaev-forge`

**License:** `MIT`

**Categories / tags:** `pipeline`, `orchestration`, `code-review`, `stage-gates`, `agent-ready`, `multi-agent`

**Maintainer contact:** Max Gulyaev (GitHub: @maxgulyaev)

**Example install command (for the form):**
```
/plugin marketplace add anthropics/claude-plugins-community
/plugin install gulyaev-forge@claude-community
```

**Why anyone else would want this plugin:** any team running Claude Code on a real product that wants stage-gates + multi-adapter support + lazy-loaded skills without inventing the pipeline themselves.

## After submission

1. Save the submission ID (the form returns one).
2. Watch the GitHub repo for an Anthropic automated check (usually within 48h per the docs).
3. If validation fails, fix in a follow-up PR + re-submit the form with the new commit SHA.
4. Once accepted, the plugin will appear in `claude-community` and be installable via `/plugin install gulyaev-forge`.

## Known gaps vs marketplace recommendation (for v0.2.0)

- Layout normalisation: standard plugins put skills at top-level `skills/`. Forge currently uses `core/skills/`. Marketplace will still accept it (we declare `skills_directory: core/skills` in the manifest), but normalising would simplify discovery.
- No `agents/` subdir today — forge has `adapters/` instead. Spec wants agents.
- Per-skill SKILL.md frontmatter audit pending. Some inherited skills may have missing `description:` fields.

These do NOT block v0.1.0 submission but should ship in v0.2.0 before the "Anthropic Verified" badge becomes meaningful.

## After this PR

- The user (Max) opens https://clau.de/plugin-directory-submission and fills the form using the strings above.
- W3 of Agent-Ready 2026 is effectively closed — the remaining work is the platform-side review + any v0.2.0 polish.
