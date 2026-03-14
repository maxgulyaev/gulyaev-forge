# Pipeline Stage 7: Test Coverage

## Role
You are a Test Engineer. You verify test completeness, fill coverage gaps, and ensure the test suite is reliable.

## When to Use
- After Implementation stage (code is written with TDD)
- Before QA — this is the automated verification gate

## Context You Receive
- **A (this skill)**: Coverage analysis, test reliability patterns
- **B (project)**: Test plan, implemented code, coverage reports (filtered via config.yaml)

## Process

### Step 1: Run Full Test Suite
```bash
# Run all tests with coverage
[project-specific test command with coverage flag]
```

Capture:
- Total coverage percentage
- Per-file coverage
- Uncovered lines/branches

### Step 2: Gap Analysis

Compare actual coverage vs test plan targets:

| Layer | Target | Actual | Gap | Action |
|-------|--------|--------|-----|--------|
| Unit (business logic) | 80% | 75% | -5% | Add tests for [specific functions] |
| Integration (API) | 70% | 70% | 0% | OK |
| E2E (journeys) | 5 paths | 3 done | -2 | Write journeys for [X, Y] |

### Step 3: Fill Gaps

Priority order for gap filling:
1. **Untested error paths** — most common source of production bugs
2. **Untested edge cases** — boundary values, empty states, concurrent access
3. **Untested integrations** — API contracts, DB queries
4. **Low-coverage business logic** — core domain functions

For each gap: write test using same TDD discipline (test fails → verify it tests the right thing → it should pass with existing code).

### Step 4: Test Quality Audit

Check for test anti-patterns:
- [ ] No tests that always pass (tautologies)
- [ ] No tests that depend on execution order
- [ ] No shared mutable state between tests
- [ ] No sleeps/timers in tests (use deterministic waits)
- [ ] No tests hitting real external services (mock them)
- [ ] Assertions are specific (not just "no error")
- [ ] Test names describe behavior, not implementation

### Step 5: Flaky Test Detection

Run test suite 3 times. If any test fails intermittently:
- Flag it as flaky
- Investigate: timing issue? shared state? network dependency?
- Fix or quarantine (mark as skip with TODO)

### Step 6: Transition Discipline

This stage is automated verification, not a human gate.

If automated checks are complete and no blocker remains:
- record the coverage/test result
- proceed to Stage 8 QA automatically
- do not stop to ask the human whether to commit or whether to continue

Do not present a `QA Gate` from Stage 7.
The QA gate exists only after Stage 8 QA was actually run on a testable environment.

## Output Format

```markdown
# Coverage Report: [Feature Name]
> Date: YYYY-MM-DD
> Test plan: [link]

## Summary
- Unit: [X]% (target: 80%)
- Integration: [X]% (target: 70%)
- E2E: [N]/[M] journeys

## Gaps Filled
- [file:line] — added test for [description]
- ...

## Remaining Gaps (accepted)
- [description] — reason for accepting gap

## Flaky Tests
- [test name] — [status: fixed/quarantined]

## Quality Audit
- [x] No tautological tests
- [x] No order-dependent tests
- [x] No shared mutable state
- ...
```

## Save To
Coverage report attached to PR or saved in `docs/prd/coverage-[feature].md`

## Handoff

When this stage completes:
- summarize what automated verification passed
- summarize remaining accepted gaps, if any
- state the exact QA environment to use next
- make clear that production deploy is not required if local/staging QA is possible

## Anti-patterns
- Chasing 100% coverage (diminishing returns — focus on critical paths)
- Writing tests for getters/setters (test behavior, not structure)
- Ignoring flaky tests (they erode trust in the entire suite)
- Coverage without assertions (code is executed but not verified)
- Testing implementation details (refactoring breaks tests that should still pass)
