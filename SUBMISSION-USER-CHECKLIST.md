# W3.4 — Community marketplace submission (USER ACTIONS)

> This is a step-by-step checklist for **Max** to submit `gulyaev-forge` to the community plugin marketplace. Claude cannot do these steps — they require your Anthropic account.
>
> All claims here verified against the official docs on 2026-05-25:
> https://code.claude.com/docs/en/discover-plugins

## TL;DR — what & why

`gulyaev-forge` v0.1.3 is on main, `claude plugin validate .` returns 0 errors. To make it installable via `/plugin install gulyaev-forge@claude-community` for anyone (including spodi sessions), it needs to be added to the **community marketplace** at https://github.com/anthropics/claude-plugins-community.

There is no public application form for the **official** marketplace — that one is curated by Anthropic at their discretion.

---

## Pre-flight (verify before submission)

Run inside `~/Documents/Dev/gulyaev-forge`:

```bash
# 1. On main, clean tree
git checkout main && git pull && git status

# 2. Validator clean
claude plugin validate .
# Expect: 0 errors, 1 warning (CLAUDE.md root) — accept warning, deferred to v0.2.0

# 3. Tag the release
git tag -a v0.1.3 -m "v0.1.3 — codex W3.1c findings folded; ready for community marketplace"
git push origin v0.1.3

# 4. Confirm CHANGELOG and SUBMISSION.md reflect v0.1.3
grep -n "0.1.3" CHANGELOG.md SUBMISSION.md plugin.json
```

If any of those fail, fix before continuing.

---

## Submission (4 paths — pick one)

### Path A — in-app `/plugin` form (RECOMMENDED, easiest)

1. Open Claude Code in any project
2. Type `/plugin` to open the plugin manager
3. Find the "Submit a plugin" or "Submit to community" option (tab varies by CLI version 2.1.150+)
4. Paste the repo URL: `https://github.com/maxgulyaev/gulyaev-forge`
5. Confirm version: `v0.1.3`
6. Submit

You should get a confirmation message. The submission triggers Anthropic's automated validation + safety screen.

### Path B — `https://claude.com/plugins`

1. Open https://claude.com/plugins in browser (logged in as Max)
2. Look for "Submit a plugin" CTA
3. Paste repo URL + version
4. Submit

### Path C — PR to `anthropics/claude-plugins-community`

If Paths A and B aren't visible in your CLI version yet:

1. Fork https://github.com/anthropics/claude-plugins-community
2. Add an entry pointing to your repo + commit SHA for v0.1.3 (look at existing entries for format)
3. Open a PR — Anthropic's bot runs automated validation
4. If validation passes, an Anthropic team member reviews + merges

Reference: official docs say "third-party plugins that have passed Anthropic's automated validation and safety screening. Each plugin is pinned to a specific commit SHA in the catalog."

### Path D — manual ping

If none of the above work, file an issue at `anthropics/claude-plugins-community` describing what you want to submit.

---

## What to expect

Once submitted (any path):

- **Automated validation**: schema check on plugin.json, skill frontmatter, SKILL.md format. We've already run `claude plugin validate .` so this should pass.
- **Safety screen**: Anthropic scans for obvious red flags (eval / network exfil / suspicious permissions). Forge is read-only on the local repo + scripted; should pass.
- **Manual review**: a human looks at the README/SUBMISSION.md and decides whether the plugin is generally useful or too niche.
- **Outcome**:
  - **Accepted** → merged into `anthropics/claude-plugins-community`, pinned to your v0.1.3 commit SHA. Then `/plugin install gulyaev-forge@claude-community` works for everyone.
  - **Changes requested** → Anthropic comments with what to fix. Make changes, bump to v0.1.4, push, ask Anthropic to re-pin.
  - **Rejected** → rare. Usually for security or scope reasons. Keep using as a local plugin.

Expected turnaround: **5–14 days** based on the volume of submissions visible in the community-marketplace PR queue (May 2026).

---

## After acceptance

1. **Update `governance.md`** — bump "W3.4 pending" → "W3.4 shipped <date>", remove the local-install snippet
2. **Update spodi `.claude/settings.json`** — add `extraKnownMarketplaces` + `enabledPlugins` per `docs/agent-ready/governance.md`
3. **Test from a fresh project** — `/plugin install gulyaev-forge@claude-community` then `/gulyaev-forge:strategy` should work
4. **Close `#336`** (Agent-Ready 2026 umbrella) — W3 complete

---

## If you want to keep iterating WITHOUT public submission

You can use the plugin locally indefinitely:

```bash
# Inside Claude Code in any project:
/plugin marketplace add ~/Documents/Dev/gulyaev-forge
/plugin install gulyaev-forge@gulyaev-forge
/reload-plugins
```

The local marketplace name is the repo basename. No submission required. Auto-updates won't happen — you `git pull` in the repo + `/plugin marketplace update gulyaev-forge` manually.

---

## Refs

- Anthropic plugin docs (May 2026): https://code.claude.com/docs/en/discover-plugins
- Community marketplace: https://github.com/anthropics/claude-plugins-community
- Official marketplace: https://github.com/anthropics/claude-plugins-official (no public application)
- Plugin landing: https://claude.com/plugins
- Forge SUBMISSION.md (internal acceptance checklist): SUBMISSION.md
- Spodi governance cross-link: spodi/docs/agent-ready/governance.md (PR #340)
