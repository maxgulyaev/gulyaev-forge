# Pipeline Orchestrator

## Purpose
This is the master document that defines how the pipeline runs — stage order, gate rules, context injection, and decision flow.

## Stage Order

```
0. Strategy      [GATE] ──→
1. Discovery     [GATE] ──→
2. PRD           [GATE] ──→
3. Design        [GATE] ──→
4. Architecture  [GATE] ──→
5. Test Plan     [────] ──→
6. Implementation[GATE] ──→
7. Test Coverage [────] ──→
8. Automated QA  [GATE] ──→
9. Staging Deploy[────] ──→
10. Canary Deploy[GATE] ──→
11. Product Analytics [GATE] ──→
12. Tech Monitoring   [GATE] ──→ back to 0. Strategy
```

[GATE] = requires human approval before proceeding
[────] = auto-proceed if criteria met (human can still intervene)

## How to Start the Pipeline

### For a new feature:
1. Determine entry point:
   - Brand new idea → start at Stage 0 (Strategy) or Stage 1 (Discovery)
   - Idea from backlog with strategy alignment → start at Stage 2 (PRD)
   - Bug fix or small improvement → start at Stage 6 (Implementation)
2. Load project config: `project/.forge/config.yaml`
3. For the starting stage, inject context A (skill from forge) + context B (project files filtered by stage)
4. Execute stage skill
5. Present gate (if applicable)
6. On approval → advance to next stage

### For analytics loop:
1. Start at Stage 11 (Product Analytics)
2. Analytics produces recommendation: continue/amplify/pivot/kill
3. This feeds into Stage 0 (Strategy) for the next cycle

## Gate Protocol

At each gate, present:

### Block 1: Summary
```
## Gate: [Stage Name] → [Next Stage Name]
Status: go / go with concerns / stop
What was done: 3-5 bullets
Key decisions: what was chosen and why
Risks: if any
Question: specific question for approval
```

### Block 2: Detailed
```
Artifact: [link to file created by this stage]
Review checklist: what to verify
Trade-offs: options considered
Diff: what changed vs previous state
```

### Block 3: Rollback Plan
```
Affected: files / migrations / deploys
Commands: specific rollback commands
Pre-state: commit SHA or tag
Dependencies: what else might break
```

### Gate Responses
- **Approved** → proceed to next stage
- **Approved with changes** → apply feedback, re-present gate
- **Rejected** → go back to current stage with feedback
- **Rejected 3x** → escalate: "This stage has been rejected 3 times. Consider: going back to a previous stage, reframing the problem, or pausing to discuss the approach."

## Context Injection Rules

For each stage, the orchestrator:
1. Reads `project/.forge/config.yaml`
2. Finds `stages.[current_stage].inject`
3. Loads `required` files (fail if missing)
4. Loads `if_exists` files (skip if missing)
5. Loads `search` patterns (glob for matching files)
6. Passes loaded context + stage skill to the agent

**Critical rule**: Agent ONLY sees files in its inject list. No browsing the full project for decision-making.

## Stage Skip Rules

Some stages can be skipped:
- **Design** (Stage 3): Skip if feature is backend-only (no UI)
- **Test Plan** (Stage 5): Skip for hotfixes (but add tests retroactively)
- **Staging Deploy** (Stage 9): Skip if no staging environment (deploy directly with feature flag)
- **Canary Deploy** (Stage 10): Skip for < 100 users (big bang is fine)

Skip decisions must be documented in the gate.

## Parallel Execution

Some stages can run in parallel:
- **Design + Architecture** (Stages 3-4): Can overlap if designer and architect coordinate
- **Implementation across platforms** (Stage 6): Backend first, then web + mobile in parallel
- **Product Analytics + Tech Monitoring** (Stages 11-12): Independent data collection

## Quick Path (Small Changes)

For small changes (bug fixes, copy changes, minor tweaks):
```
Skip to Stage 6 (Implementation) directly
  → Stage 7 (Test Coverage)
  → Stage 8 (QA) — abbreviated
  → Stage 9/10 (Deploy)
```

Must still have:
- Clear problem statement (even if one sentence)
- Tests for the fix
- QA verification

## State Tracking

Pipeline state is tracked in the project:
```
project/.forge/
  config.yaml              # Static config
  pipeline-state.yaml      # Current state (auto-generated)
```

```yaml
# pipeline-state.yaml (auto-updated by orchestrator)
current_feature: "supersets"
current_stage: 6          # implementation
stages_completed:
  - stage: 0
    date: 2026-03-10
    gate: approved
    artifact: docs/strategy/2026-03-10-supersets.md
  - stage: 2
    date: 2026-03-10
    gate: approved
    artifact: docs/prd/2026-03-10-supersets.md
  - stage: 4
    date: 2026-03-11
    gate: approved_with_changes
    artifact: docs/architecture/2026-03-11-supersets.md
stages_skipped:
  - stage: 3
    reason: "Backend-only feature, no UI changes in this iteration"
```
