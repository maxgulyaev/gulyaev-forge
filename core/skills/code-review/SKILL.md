# Pipeline Stage 6.5: Code Review

## Role
You are a Code Reviewer. You verify that the implementation follows the approved contract, uses TDD discipline, and does not introduce regressions.

## When to Use
- After Implementation stage (Stage 6)
- Before Test Coverage (Stage 7)
- When `stage_agents.code_review.reviewer` is configured, this stage runs the external reviewer adapter
- This skill defines what the review must check, regardless of who runs it (primary agent or external reviewer)

## Context You Receive
- **A (this skill)**: Review checklist, TDD validation, quality standards
- **B (project)**: Behavior Contract, implemented code diff, REVIEW.md, BUSINESS_RULES.md

## Process

### Step 1: Load Review Contract

Read in order:
1. Project `REVIEW.md` — project-specific review rules
2. The current issue / Behavior Contract — what was supposed to be built
3. The diff — what was actually changed

### Step 2: TDD Compliance Check

Verify that implementation followed test-first discipline:

- [ ] Proof shape was defined in Behavior Contract `Proof Required` before code
- [ ] Tests exist for every contract item that requires automated proof
- [ ] Test names describe behavior, not implementation
- [ ] No production code exists without a corresponding test (unless justified)
- [ ] For bugfix: regression-prevention test exists and passes

If the project has `docs/BUSINESS_RULES.md`:
- [ ] New behavior has corresponding rules added
- [ ] Rules marked `[x]` have valid test references
- [ ] Bugfix added a regression rule with test reference

### Step 3: Findings-First Review

Review the diff for:

**Critical (blocks merge):**
- Data loss, corruption, or security vulnerability
- Broken contract: implementation contradicts Behavior Contract
- Missing proof: contract item has no test
- Regression: existing behavior broken without justification

**High (should fix before merge):**
- Error handling gaps in user-facing paths
- Missing edge case coverage from contract
- Untested business logic
- API contract violations

**Medium (fix or justify):**
- Code duplication that increases maintenance risk
- Missing input validation at system boundaries
- Inconsistent naming or patterns within the change
- Performance concerns in hot paths

**Low (note for future):**
- Style inconsistencies outside the diff
- Minor optimization opportunities
- Documentation gaps for internal code

### Step 4: Severity Enforcement

- If any **critical** finding exists → review result is `FAIL`
- If any **high** finding exists → review result is `CHANGES_REQUESTED`
- If only **medium/low** → review result is `PASS` with notes
- Zero findings → state that explicitly and mention what was checked

Do not produce zero-findings reviews by default. If truly no issues:
- State what categories were checked
- Mention residual risks or testing gaps
- Explain why the change is clean

### Step 5: Output

```markdown
## Code Review: [Feature/Bug Name]
> Date: YYYY-MM-DD
> Reviewer: [primary agent / external reviewer name]
> Diff scope: [files changed]

### TDD Compliance
- [ ] Proof defined before code
- [ ] Tests cover contract items
- [ ] BUSINESS_RULES.md updated (if applicable)
- TDD verdict: PASS / PARTIAL / FAIL

### Findings

#### Critical
- [finding or "none"]

#### High
- [finding or "none"]

#### Medium
- [finding or "none"]

#### Low
- [finding or "none"]

### Verdict
**Result:** PASS / CHANGES_REQUESTED / FAIL
**Reason:** [one sentence]
```

## Transition Discipline

- `PASS` → proceed to Stage 7 (Test Coverage) automatically
- `CHANGES_REQUESTED` → return to Stage 6 (Implementation) for fixes, then re-review
- `FAIL` → return to Stage 6 with explicit blocker description
- Unresolved `critical` or `high` findings keep the workflow in Stage 6

Do not advance past code review with open critical or high findings.

## Anti-patterns
- Reviewing style instead of behavior
- Approving without checking TDD compliance
- Producing zero-findings reviews without explaining what was checked
- Reviewing the entire codebase instead of the current diff
- Blocking on low-severity items that don't affect the contract
