# Stream B — forge drift hardening (2026-06-21)

Overnight autonomous run. Branch: **`feat/forge-drift-hardening-2026-06-21`**
(base `main`). Nothing was committed or pushed to `main`; no force pushes.

## Why

On 2026-06-21 the Spodi forge state drifted from reality: `.forge/active-run.env`
pointed at a stale bugfix (#369), `.forge/pipeline-state.yaml` pointed at an
issue (#312) closed a month earlier, while the real recent work (#400/#401/#402/
#369/#363/#366) ran largely outside forge. Root cause: `.forge/*` is a local-only,
manually-updated cache that goes stale and is invisible across machines, while
the durable layer (GitHub issues + `stage/*` labels + PRs + `prod-*` tags) stayed
accurate. Conclusion driving the design: **the durable layer is the source of
truth; `.forge/*` must be a derived, self-healing cache.** Detection + self-heal
+ a central server-side sentinel — never hard blocking hooks (bypassable and
hostile to the manual / Codex / multi-machine / bug-batch workflow).

## What shipped (the four layers)

### L1 — Reconcile / self-heal — `scripts/forge-reconcile.sh`
Rebuilds the local `pipeline-state.yaml` view from durable GitHub state (open
issues with `stage/*` labels, open PRs, `prod-*` tags) and loudly reports drift:
- `current_feature`/`issue` that is **CLOSED**;
- `active-run` issue that is **CLOSED**;
- a `stage/*` label disagreeing with the cached stage (**alias-aware**:
  `code_review` ≡ `stage/review`, `prd` ≡ `behavior_contract`, etc.);
- an open **PR referencing a closed issue** (precise ref matching — `#NNN` +
  numeric branch segments, never bare digits in titles).

Read-only by default (**exit 2** on drift); `--apply` rewrites the cache;
`--json` for machines. **Fails hard (exit 1)** on any non-404 `gh` error or a
crashed helper, so an auth/network/rate-limit blip can never masquerade as
"no drift". Wired into `scripts/forge-status.sh product` (runs the read-only
check on every status) and referenced from the `/forge:continue` flow doc.

### L2 — Run-state lives in GitHub — `scripts/forge-run-state.sh`
The active run is now durable on the issue and readable from any machine:
the **`stage/*` label is authoritative**, and a single maintained issue comment
carries the full run-state JSON behind an HTML sentinel
(`<!--forge-run-state-->…JSON…<!--/forge-run-state-->`). New subcommands:
`publish` (local run → issue), `read-remote` (print issue JSON), `hydrate`
(issue → local cache, on any machine). `.forge/active-run.env` is now a derived
cache; **existing callers are unchanged** (backward compatible). Values are
passed to `python3` via the environment, so a title with quotes/`&`/`<>` is
injection-safe. Also fixed the `%q` decode codec (in both `forge-run-state.sh`
and `forge-status.sh`) to fully invert backslash-escaping and the empty-`''`
form — a pre-existing bug that mangled tricky titles in `show`.

### L3 — Central drift sentinel — `templates/github/forge-drift-sentinel.yml` + `forge_drift_sentinel.py`
Portable, parameterized GitHub Actions workflow (push + daily cron +
`workflow_dispatch`) that checks durable invariants **server-side** for every
open issue with a `stage/*` label: issue closed but PR open; stage label vs PR
merge state; open PR referencing an unlabelled open issue; branch far behind
base (with a duplicate-subject hint). On violation it labels the issue
`forge/drift` and posts/updates a sticky comment; both **auto-clear** when fixed
(clear pass scans `state=all` so closed issues clear too). Non-blocking; the only
layer that catches drift from any machine. Tunables (`STAGE_PREFIX`,
`DRIFT_LABEL`, `BEHIND_THRESHOLD`, `DRY_RUN`) are env knobs — nothing
Spodi-specific. Bounded pagination so a mature repo can't burn rate limit; a
non-404 API failure raises `GHFatal` → job exits 1 rather than a misleading pass.

### L4 — Advisory (non-blocking) git hook — `core/templates/githooks/commit-msg`
Extracts `#NNN` and **warns** (stderr, **never exits non-zero**) if the issue is
CLOSED or has no `stage/*` label. Installed identically on every machine via the
in-repo `.githooks` dir (`core.hooksPath`). Survives the manual/Codex/
multi-machine reality. Degrades to silent if `gh` is missing/unauthenticated.

### Docs + wiring
- `docs/anti-drift.md` — the model, the four layers, why no hard blocking hooks,
  install/enable steps, and a quick comparison table.
- `adapters/claude-code/commands/product/continue.md` — now points at
  `forge-reconcile.sh` and `forge-run-state.sh hydrate`, and references the doc.
- `scripts/install-claude-commands.sh product` — installs the L4 hook and the L3
  sentinel (`.github/`) alongside the existing commands/pre-push.

## Commits (8, on the branch only)

```
1cf2e60 fix(forge): address Codex review round 3 (1 P2)
a824311 fix(forge): address Codex review round 2 (1 P1 + 3 P2) + drop stray .pyc
b58b02a fix(forge): address Codex review round 1 (1 P1 + 3 P2)
4385201 docs(forge): anti-drift model + wire reconcile/hydrate into /forge:continue
c8d6385 feat(forge): L3 central drift sentinel (GH Action) + L4 advisory commit-msg hook
ba84c59 feat(forge): L2 — durable run-state on the issue (cross-machine), self-healing cache
680cf9e feat(forge): L1 — forge-reconcile drift self-heal + wire read-only check into status
93a9107 chore(doctor): add SCRIPT_DIR resolution (preserved partial change)
```

The owner's pre-existing uncommitted `scripts/forge-doctor.sh` change is
preserved as commit `93a9107`.

## Files added / changed

Added: `scripts/forge-reconcile.sh`, `scripts/forge-reconcile.test.sh`,
`scripts/forge-run-state.test.sh`, `templates/github/forge-drift-sentinel.yml`,
`templates/github/forge_drift_sentinel.py`,
`templates/github/forge_drift_sentinel.test.py`,
`core/templates/githooks/commit-msg`, `core/templates/githooks/commit-msg.test.sh`,
`docs/anti-drift.md`, this report.

Changed: `scripts/forge-run-state.sh` (L2 + codec), `scripts/forge-status.sh`
(L1 wiring + codec), `scripts/install-claude-commands.sh` (L3/L4 install),
`scripts/forge-doctor.sh` (preserved), `adapters/.../continue.md`, `.gitignore`
(`__pycache__`/`*.pyc`).

## Test evidence

All run offline (GitHub stubbed via fake `gh` on PATH / monkeypatched
`gh_request`).

| Suite | Result |
|-------|--------|
| `scripts/forge-reconcile.test.sh` (L1) | **9 passed, 0 failed** — clean, closed issue, alias, genuine mismatch, `--apply`, `--json`, gh-failure fail-hard, Drift-4 ref-lookup fail-hard, Drift-4 helper-crash fail-hard |
| `scripts/forge-run-state.test.sh` (L2) | **3 passed, 0 failed** — publish sentinel, read-remote (quote-bearing title intact), cross-machine hydrate |
| `templates/github/forge_drift_sentinel.test.py` (L3) | **ALL PASS (14)** — label/ref parsing, stage sets, `gh_paginate` limit, `gh_get_or_none` 404-vs-fatal |
| `core/templates/githooks/commit-msg.test.sh` (L4) | **5 passed, 0 failed** — closed/unlabelled warn, labelled silent, no-ref silent, **missing gh still succeeds** (proves non-blocking) |
| `scripts/forge-config-check.test.sh` (existing regression) | **5 pass, 0 fail** |

Static analysis:
- **shellcheck 0.11.0**: every new shell file is **CLEAN**. `forge-status.sh`
  and `install-claude-commands.sh` carry only the **3 pre-existing** infos that
  exist identically on `main` (confirmed by diffing finding counts) — no new
  findings introduced.
- **actionlint** (incl. embedded shellcheck): workflow template **exit 0, clean**.
- **python**: `py_compile` OK; ruby YAML + actionlint both validate the workflow
  triggers (push/schedule/workflow_dispatch).
- Read-only run against the real Spodi `.forge` (hand-reconciled today): **"No
  drift: local cache agrees with GitHub."**
- macOS bash 3.2 substring-loop sanity check passes (the codec decoder).

## Review rounds (foreign-family: Codex CLI `--full-auto`)

| Round | Verdict |
|-------|---------|
| 1 | 1×P1 (gh failures swallowed → false clean), 3×P2 (bare-digit refs; unproven duplicate claim; clear pass only open issues) — **all fixed** |
| 2 | 1×P1 (Drift-4 still failed open), 3×P2 (unbounded pagination; still claimed proven duplicate; mid-scan API errors swallowed) + stray `.pyc` — **all fixed** |
| 3 | 1×P2 (`|| true` masked a python crash) — **fixed** (python3 preflight + fail-hard) |
| 4 | **CLEAN** |

**Final verdict: 0 P0 / 0 P1 / 0 P2.** Plus self-review (same-family) for
portability and non-blocking-ness throughout.

## How the owner installs / enables each layer

From the forge repo, against a product repo (e.g. Spodi):

```bash
bash scripts/install-claude-commands.sh product /path/to/project
```

This installs the `/forge:*` commands, the **L4** advisory `commit-msg` hook, and
the **L3** sentinel workflow + script under `.github/`.

- **L1** — run on demand: `bash scripts/forge-reconcile.sh <project-dir>`
  (read-only) or `--apply` to rebuild the cache. It also runs automatically as
  part of `bash scripts/forge-status.sh product <project-dir>` (and via
  `/forge:continue`).
- **L2** — `forge-run-state.sh publish <dir>` after starting/advancing a run;
  on a fresh machine, `forge-run-state.sh hydrate <dir> <issue>` to rebuild the
  local cache from the issue.
- **L3** — commit the installed `.github/forge-drift-sentinel.yml` +
  `.github/forge/forge_drift_sentinel.py` and push; Actions runs it server-side
  with the default `GITHUB_TOKEN` (needs `issues: write`, already declared).
  First run also creates the `forge/drift` label.
- **L4** — active immediately after install (the installer sets
  `core.hooksPath .githooks`); it only warns, never blocks.

## Honest caveats

- The **L3 GitHub Action is only fully validatable server-side**. Locally it is
  static-checked (actionlint clean, `py_compile` OK) and its pure parsing/
  classification logic is unit-tested, but the live API behaviour (real
  pagination, label/comment mutation, `compare` semantics) has not run against
  GitHub from this session. Recommend a first `workflow_dispatch` run with
  `dry_run: true` to confirm before letting it label issues.
- The duplicate-commit detector (invariant 4) uses **commit-subject matching as
  a hint, not patch-equivalence proof** (deliberately — subject equality ≠ patch
  equality). The message says "inspect" and recommends merging base in; it never
  asserts a proven duplicate.
- No changes were made to the Spodi repo; the only Spodi interaction was
  read-only reconcile checks against its `.forge` and GitHub.
