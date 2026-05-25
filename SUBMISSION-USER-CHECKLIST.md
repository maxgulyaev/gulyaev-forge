# W3.4 — Community marketplace submission (USER ACTIONS)

> Step-by-step checklist for **Max** to submit `gulyaev-forge` to Anthropic's community plugin marketplace. Claude cannot do these — they require your Anthropic account.
>
> Verified against official Anthropic docs on 2026-05-25:
> - https://code.claude.com/docs/en/discover-plugins
> - https://code.claude.com/docs/en/plugins
> - https://code.claude.com/docs/en/plugin-marketplaces

## TL;DR — what & why

`gulyaev-forge` v0.1.3 is on main, `claude plugin validate .` returns 0 errors. To make it installable as `/plugin install gulyaev-forge@claude-community` for anyone (including spodi sessions), it needs to be added to the **community marketplace** (`anthropics/claude-plugins-community`).

There is no public application for the **official** marketplace — that one is curated by Anthropic at their discretion.

---

## Pre-flight (verify before submission)

Run inside `~/Documents/Dev/gulyaev-forge`:

```bash
# 1. On main, clean tree
git checkout main && git pull && git status

# 2. Validator clean
claude plugin validate .
# Expect: 0 errors, 1 warning (CLAUDE.md root) — deferred to v0.2.0, OK to submit with it

# 3. Tag the release
git tag -a v0.1.3 -m "v0.1.3 — codex W3.1c findings folded; ready for community marketplace"
git push origin v0.1.3

# 4. Confirm version is consistent
grep -n "0.1.3" CHANGELOG.md SUBMISSION.md .claude-plugin/plugin.json
```

If any of those fail, fix before continuing.

---

## How to submit — only ONE supported path

Anthropic exposes a single submission flow: a **web form** behind your Anthropic account login. Both URLs below resolve to the same form (one for personal accounts, one for Console / workspace accounts):

- **Personal account**: https://claude.ai/settings/plugins/submit
- **Workspace / Console**: https://platform.claude.com/plugins/submit

> The community repo `anthropics/claude-plugins-community` is a **read-only mirror** — direct PRs there are auto-closed. Do not fork-and-PR. Do not paste the repo URL anywhere except the form above.

### Steps

1. Open one of the two URLs above (logged in as Max).
2. The form asks for:
   - Plugin repository URL: `https://github.com/maxgulyaev/gulyaev-forge`
   - Specific commit SHA or tag: `v0.1.3` (or paste the SHA of the tag)
   - Short description (≤140 chars): grab from `.claude-plugin/plugin.json` `description` field
   - Categories / tags (optional)
3. Submit.

You'll get a confirmation email or in-app notification. The submission triggers Anthropic's automated validation pipeline + a human review.

---

## What to expect

- **Automated validation**: schema check on plugin.json, skill frontmatter, SKILL.md format. We've already run `claude plugin validate .` — should pass.
- **Safety screen**: Anthropic scans for obvious red flags (eval / network exfil / suspicious shell-out). Forge is read-only on the local repo + scripted shell helpers; should pass.
- **Manual review**: a human looks at the README + SUBMISSION.md and decides whether the plugin is generally useful or too niche.
- **Outcome**:
  - **Accepted** → merged into the community marketplace, pinned to your v0.1.3 commit SHA. Then `/plugin install gulyaev-forge@claude-community` works for everyone.
  - **Changes requested** → you'll get a comment with the required fixes. Make changes, bump version, re-submit (or ask Anthropic to re-pin if it's pre-merge).
  - **Rejected** → rare. Usually for security / scope reasons. Plugin still works as a local install (see below).

Expected turnaround: **5–14 days** based on the community-marketplace queue volume visible in May 2026.

---

## After acceptance

1. **Update `spodi/docs/agent-ready/governance.md`** — bump "W3.4 pending" → "W3.4 shipped <date>", remove the local-install snippet
2. **Update spodi `.claude/settings.json`** — paste the `extraKnownMarketplaces` + `enabledPlugins` JSON from governance.md
3. **Smoke test from a fresh project** — `/plugin install gulyaev-forge@claude-community` then `/gulyaev-forge:strategy` should work
4. **Close `spodi#336`** — W3 complete, Agent-Ready 2026 program shipped

---

## Local install (until acceptance, or as fallback)

Per Anthropic plugin docs, **local install via `/plugin marketplace add <path>` requires a `.claude-plugin/marketplace.json`** file in the target directory — NOT just `plugin.json`. Forge currently has only `plugin.json`.

Two options to use the plugin locally before/without submission:

### Option 1 — set up forge as its own one-plugin marketplace

Add a minimal `.claude-plugin/marketplace.json` to the repo that lists itself:

```json
{
  "name": "gulyaev-forge-local",
  "plugins": [
    { "name": "gulyaev-forge", "source": "." }
  ]
}
```

Then:

```bash
/plugin marketplace add ~/Documents/Dev/gulyaev-forge
/plugin install gulyaev-forge@gulyaev-forge-local
/reload-plugins
```

(This is a 5-minute change — open as a follow-up PR if needed.)

### Option 2 — symlink-based dev install (current spodi setup)

Add `~/.claude/settings.json` (or per-project `.claude/settings.json`):

```jsonc
{
  "developmentPlugins": [
    "~/Documents/Dev/gulyaev-forge"
  ]
}
```

This is the path-based reference spodi uses today, captured in `docs/agent-ready/governance.md`. No marketplace JSON needed, but no auto-update either.

---

## Refs

- Anthropic plugin install docs: https://code.claude.com/docs/en/discover-plugins
- Plugin authoring docs: https://code.claude.com/docs/en/plugins
- Marketplace authoring docs: https://code.claude.com/docs/en/plugin-marketplaces
- Community marketplace mirror (read-only): https://github.com/anthropics/claude-plugins-community
- Official marketplace (curated by Anthropic, no public submission): https://github.com/anthropics/claude-plugins-official
- Plugin landing page: https://claude.com/plugins
- Forge SUBMISSION.md (internal acceptance checklist): SUBMISSION.md
- Spodi governance cross-link: spodi/docs/agent-ready/governance.md (PR #340)
