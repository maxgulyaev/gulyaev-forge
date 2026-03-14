# Checkpoint: [Stage Name]

> Project: [project name]
> Stage: [N/12]
> Date: [YYYY-MM-DD]
> Gate needed now: yes / no

---

## Status

**Current unit of work:**
[story / shard / task]

**What just finished:**
-
-

**What is still in progress:**
-

**Next recommended action:**
[exact next action the human or agent should take]

Do not list multiple internal options here when the next step is already clear.

**What happens next:**
[next checkpoint or next gate condition]

**Need anything from you now?:**
- `No` — continue with `/forge:continue`
- or `[specific decision / missing input]`

Only ask for input here if a real human decision or blocker exists.
Do not ask the human to choose between internal implementation steps, commit timing, or premature QA.

---

## State Sync

- Issue label: [current `stage/*` label]
- `.forge/pipeline-state.yaml`: [current local stage]
- Sync status: aligned / mismatch fixed / blocked

If issue state and local pipeline-state disagree, resolve or report that mismatch before continuing.

---

## Evidence

**Artifacts / files touched:**
-

**Verification so far:**
-

**Context7 used:** yes / no
**Why:** [docs-sensitive change or not]

**External review run:** yes / no / not yet
**Why:** [stage not ready or adapter not configured]
