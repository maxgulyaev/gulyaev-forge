# Anti-drift: why `.forge/*` is a derived cache, not the source of truth

## The problem this solves

On 2026-06-21 the Spodi forge state had drifted badly from reality:

- `.forge/active-run.env` pointed at a stale bugfix (#369).
- `.forge/pipeline-state.yaml` pointed at an issue (#312) that had been **closed a month earlier**.
- Meanwhile the **real** recent work (#400 / #401 / #402 / #369 / #363 / #366) had
  run largely **outside** the forge pipeline — manual commits and Codex sessions.

Root cause:

1. `.forge/active-run.env` is git-ignored → **local only** → invisible across
   machines and sessions. Parallel work on a second computer shares no run-state.
2. `.forge/pipeline-state.yaml` is only updated when someone runs forge; manual
   commits and Codex sessions bypass it, so it goes stale.
3. The **durable** layer stayed accurate the whole time. Only the local cache lied.

## The model

> **The durable layer is the source of truth. `.forge/*` is a derived,
> self-healing cache. When they disagree, the durable layer wins.**

The durable layer is everything that lives on the server and is shared by every
machine, agent, and human:

- **GitHub issues** and their `stage/*` **labels** (the authoritative stage).
- **Open PRs** and their head branches.
- **Git tags** like `prod-*` (durable deploy markers).
- **Issue comments** carrying machine-maintained state behind HTML sentinels.

`.forge/pipeline-state.yaml` and `.forge/active-run.env` are caches *derived* from
that layer. They make local runs fast and ergonomic, but they are never trusted
over GitHub.

### Why no hard blocking git hooks

A hard `pre-push`/`pre-commit` that **blocks** is the obvious-but-wrong fix. It:

- is trivially bypassed (`git push --no-verify`), so it does not actually enforce;
- is hostile to the owner's legitimate flexible workflow — manual commits, Codex
  sessions, multiple machines, and batched bug fixes all need to push freely;
- gets disabled the first time it blocks a legitimate emergency push, after which
  it protects nothing.

So the strategy is **detection + self-heal + a central sentinel**, never
prevention. The only enforcement that genuinely works across machines is
**server-side** (Layer 3), and even that only *reports*.

## The four layers

### L1 — Reconcile / self-heal (`scripts/forge-reconcile.sh`)

Rebuilds the local `pipeline-state.yaml` view from durable GitHub state and
loudly reports drift:

- a `current_feature` / `issue` that is **CLOSED**;
- an `active-run` issue that is closed;
- a `stage/*` label that **disagrees** with the cached stage (alias-aware:
  `code_review` ≡ `stage/review`);
- an open PR that **references a closed issue**.

Read-only by default (exit code `2` on drift). `--apply` rewrites the cache from
durable state; `--json` emits a machine-readable summary.

```bash
bash scripts/forge-reconcile.sh /path/to/project          # report drift (read-only)
bash scripts/forge-reconcile.sh /path/to/project --apply  # rebuild the cache
```

`scripts/forge-status.sh product` runs the read-only check on **every** status
run, so drift surfaces automatically. `/forge:continue` reads it too (step 6 of
its flow — see `adapters/claude-code/commands/product/continue.md`).

### L2 — Run-state lives in GitHub (`scripts/forge-run-state.sh`)

The "active run" becomes readable from **any** machine/session because it is
stored on the issue:

- the **`stage/*` label** is the authoritative stage;
- a single maintained issue comment carries the full run-state JSON inside an
  HTML sentinel: `<!--forge-run-state-->…JSON…<!--/forge-run-state-->`.

`.forge/active-run.env` is now a **derived cache hydrated from that comment**.
Existing callers that read `active-run.env` keep working unchanged.

```bash
bash scripts/forge-run-state.sh publish     <project-dir>          # local run -> issue comment
bash scripts/forge-run-state.sh read-remote <project-dir> <issue>  # print issue-side JSON
bash scripts/forge-run-state.sh hydrate     <project-dir> <issue>  # issue -> local cache (any machine)
```

### L3 — Central drift sentinel (`templates/github/forge-drift-sentinel.yml`)

A portable GitHub Actions workflow (push + daily cron) that checks durable
invariants **server-side** for every open issue with a `stage/*` label:

- issue **closed** but a referencing PR is still **open**;
- stage label inconsistent with PR merge state (pre-merge stage but PR merged, or
  post-merge stage but PR still open);
- an open PR referencing an **open issue with no `stage/*` label** (work outside
  the pipeline);
- head branch **far behind base** with duplicate already-merged commits (the
  classic merge-conflict source from the #366 incident).

On violation it labels the issue **`forge/drift`** and posts/updates a sticky
comment; both clear automatically when the drift is gone. Because it runs
centrally, it catches drift introduced on **any** machine. It is **non-blocking**
— it reports, it never fails a push or merge.

The template is parameterized (no Spodi-specific values): `STAGE_PREFIX`,
`DRIFT_LABEL`, `BEHIND_THRESHOLD`, and `DRY_RUN` are env knobs in the workflow.

### L4 — Advisory git hook (`core/templates/githooks/commit-msg`)

A committed, in-repo `commit-msg` hook that extracts `#NNN` from the message and
**warns** (to stderr, never exits non-zero) if the referenced issue is **CLOSED**
or has **no `stage/*` label** — a nudge to update the trail or run `/forge:gate`.
It is installed identically on every machine via `core.hooksPath .githooks`, so
the hook itself never drifts. Explicitly non-blocking so it survives the
manual/Codex/multi-machine reality.

## Install / enable

From the forge repo, against a product repo:

```bash
bash scripts/install-claude-commands.sh product /path/to/project
```

This installs the `/forge:*` commands, the `commit-msg` advisory hook (L4), and
the drift-sentinel workflow + script (L3) under `.github/`. To enable L3, commit
the `.github/` files and push — GitHub Actions runs them server-side with the
default `GITHUB_TOKEN` (it needs `issues: write`, already declared in the
workflow `permissions:` block).

L1 and L2 are plain scripts in this repo; call them directly or via `bin/forge`
(`status product` runs the L1 read-only check for you).

## Quick mental model

| Layer | Where it runs | Blocks? | Catches drift from other machines? |
|-------|---------------|---------|------------------------------------|
| L1 reconcile | local, on demand / on status | no | only when you run it locally |
| L2 run-state | issue comment + label | no | yes (hydrate from any machine) |
| L3 sentinel | GitHub Actions (server) | no | **yes — always** |
| L4 commit-msg | local git hook | **no (advisory)** | no |

The durable layer is the truth; these four layers keep the derived cache honest
without ever standing between the owner and a push.
