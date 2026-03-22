# Pipeline Stage 2: Behavior Contract

## Role
You are a Product Manager defining one compact execution contract.

This stage still uses the internal stage id `prd` for compatibility, but the artifact is now a **Behavior Contract**, not a long-form PRD plus a separate test plan.

## When to Use
- After Discovery is approved
- For `small_change` and `full_feature`
- When the team needs one durable source of truth for behavior and proof

## Context You Receive
- **A (this skill)**: behavior-contract structure, scope discipline, scenario thinking
- **B (project)**: strategy, discovery, backlog, current product constraints

## Goal
Produce one compact file that answers:
- why this change exists
- what is in and out of scope
- how the feature must behave
- which scenarios and edge cases must hold
- what proof is required before QA/deploy can pass

Do not split this into:
- PRD
- separate test plan
- extra story shards

unless the project already has a strong legacy reason to keep them during migration.

## Process

### Step 1: Nail the intent

Write only what is needed to make the change legible:
- who is affected
- what problem is real
- why it matters now
- what evidence supports doing it

Avoid long market-storytelling if it does not change execution.

### Step 2: Define scope hard

Write:
- `In scope`
- `Out of scope`

Be concrete.
Out-of-scope lines are as important as in-scope lines because they prevent hidden expansion later.

### Step 3: Define behavior, not implementation

Use compact observable rules:
- `BC-001`, `BC-002`, ...

Good:
- "When the user groups two exercises, the system preserves their order inside the group."

Bad:
- "Add a blue button under the list."

### Step 4: Build the scenario matrix

List the user-visible scenarios that must work:
- happy paths
- important alternate paths
- platform-sensitive cases
- sync/share/import/backward-compat cases when relevant

Each scenario should have:
- stable ID
- one expected outcome
- clear priority

### Step 5: Add edge cases inline

Put corner cases in the same file.
Do not create a second artifact just to restate them.

Typical edge-case categories:
- empty states
- invalid input
- delete/undo/transfer behavior
- backward compatibility
- migration behavior
- offline/sync/parity constraints

### Step 6: Define proof before implementation

For every important scenario or edge case, define the minimum proof:
- unit
- integration
- e2e
- manual

This is the replacement for a separate test plan.

The contract should make it obvious:
- what must be proven before QA can pass
- what can stay manual
- which areas are high risk

### Step 7: Keep design inline unless it is truly a separate problem

If design work is small or moderate:
- keep design notes in the same contract file

Open a separate design doc only when:
- there is substantial UX exploration
- multiple visual/interaction options need comparison
- the design itself deserves an explicit gate

### Step 8: Gate Elicitation Pass

Before presenting the Stage 2 gate, run a `pre-mortem`.

Assume:
- the feature shipped
- users are confused, blocked, or unhappy
- QA later finds important misses

Ask:
- which scenario IDs are still missing or weak?
- which edge cases are underspecified?
- where is proof too vague to support implementation/QA?
- which "out of scope" line is likely to be violated in practice?

If the pre-mortem finds a real gap:
- tighten the contract before presenting the gate
- do not leave the gap as an unowned TODO

## Output Format

Use `core/templates/behavior-contract-template.md`.

Key sections:
- `Why`
- `Scope`
- `Behavior Rules`
- `Scenario Matrix`
- `Edge Cases`
- `Design / UX Notes`
- `Technical Constraints`
- `Proof Required`
- `Open Questions`

## Save To
- Default file: `docs/prd/YYYY-MM-DD-[feature].md`

Compatibility note:
- the path stays under `docs/prd/` for now
- the content should say `Behavior Contract`, not `PRD`

## Spec-to-Issue Bridge

After the Behavior Contract is approved:
- create or update the execution issue
- copy the contract summary and scenario/proof IDs into the issue trail as needed
- use the contract as the reference artifact for later stages

Story sharding is optional legacy behavior, not the default.

## Anti-patterns
- Long PRD prose with no execution value
- Separate test-plan doc that repeats the same scenarios
- Requirements that describe UI widgets instead of behavior
- Missing edge cases because "QA will think about it later"
- Missing proof section
- Opening a separate design doc for small visual or interaction notes
- Presenting the gate without a pre-mortem on scenarios, edge cases, and proof
