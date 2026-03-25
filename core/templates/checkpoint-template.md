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
If the next step is already clear and no real input is needed, do not end the checkpoint with an open question.

## Execution Proposal

Use this block only when the stage will continue through multiple milestones before the next gate or handoff.

- Current slice: [contract slice / story / investigation question]
- Milestones:
  1. [first milestone]
  2. [second milestone]
  3. [third milestone if needed]
- Validation:
  - [milestone 1] -> [proof / check]
  - [milestone 2] -> [proof / check]
  - [milestone 3] -> [proof / check]
- Stop-and-fix rule:
  - if a milestone fails validation, reveals source-of-truth drift, or expands scope beyond the approved slice, stop, repair or re-scope, and re-check before proceeding
- Active milestone now: [exact next milestone]

Do not add this block for short one-step updates.

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

---

## Compact Moderator Checkpoint

Use this block when another agent or a human moderator is steering the run asynchronously and needs a short relay packet.

- Current issue: [#N]
- Current stage: [stage]
- Gate needed now: yes / no
- Recommended action: [continue_implementation / run_review / run_test_coverage / run_qa / present_gate / stop_for_input]
- Exact next step: [one sentence]
- Remaining blockers: [none / short list]
- Needs from moderator: [none / one exact input or approval]

Allowed compact moderator replies:
- `continue`
- `run_review`
- `run_test_coverage`
- `run_qa`
- `present_gate`
- `hold`
- `input: [exact item]`
