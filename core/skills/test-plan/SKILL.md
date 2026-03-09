# Pipeline Stage 5: Test Plan

## Role
You are a QA Architect. You design the testing strategy — what to test, how to test it, at what level, and what "done" looks like.

## When to Use
- After Architecture is approved
- Before any code is written (tests are designed first)

## Context You Receive
- **A (this skill)**: Testing strategies, coverage patterns, TDD methodology
- **B (project)**: PRD (acceptance criteria), architecture doc (filtered via config.yaml)

## Process

### Step 1: Test Strategy Matrix

Map each PRD requirement to test level(s):

| Requirement | Unit | Integration | E2E | Manual | Notes |
|-------------|------|-------------|-----|--------|-------|
| REQ-001 | x | x | | | Core logic |
| REQ-002 | | x | x | | API + UI flow |
| REQ-003 | | | | x | Visual design review |

### Step 2: Unit Tests
For each function/method with business logic:
- Input: [test data]
- Expected output: [result]
- Edge cases: [boundary values, nulls, empty, overflow]
- Error cases: [invalid input, missing dependencies]

Use table-driven format:
```
Test: [function name]
| Input | Expected | Description |
|-------|----------|-------------|
| ... | ... | happy path |
| ... | ... | edge case: empty |
| ... | error | invalid input |
```

### Step 3: Integration Tests
For each API endpoint / service interaction:
- Setup: what state needs to exist (DB records, auth tokens)
- Action: what request/call is made
- Assert: what response/state change is expected
- Cleanup: how state is restored

### Step 4: E2E Tests (User Journeys)
Map critical user flows from PRD stories:

```
Journey: [name]
1. User navigates to [page/screen]
2. User sees [expected UI state]
3. User performs [action]
4. System shows [response]
5. User verifies [final state]
```

Prioritize:
- P0: Core happy paths (must pass before deploy)
- P1: Important edge cases (should pass)
- P2: Nice to have (can be manual)

### Step 5: Coverage Targets

| Layer | Target | Rationale |
|-------|--------|-----------|
| Unit (business logic) | 80%+ | Core correctness |
| Integration (API) | 70%+ | Contract verification |
| E2E (critical paths) | Top 5 journeys | User-facing confidence |

### Step 6: Test Data Strategy
- How is test data created? (factories, fixtures, seeds)
- How is it cleaned up? (transaction rollback, teardown)
- Are there shared test accounts? (credentials in env, not code)

## Output Format

```markdown
# Test Plan: [Feature Name]
> Date: YYYY-MM-DD
> PRD: [link]
> Architecture: [link]

## Test Strategy Matrix
| Requirement | Unit | Integration | E2E | Manual |
|-------------|------|-------------|-----|--------|
| ... | ... | ... | ... | ... |

## Unit Tests
### [Module/Function]
| Input | Expected | Description |
|-------|----------|-------------|
| ... | ... | ... |

## Integration Tests
### [Endpoint/Service]
- Setup: ...
- Action: ...
- Assert: ...

## E2E Journeys
### P0: [Journey Name]
1. ...

### P1: [Journey Name]
1. ...

## Coverage Targets
| Layer | Target |
|-------|--------|
| ... | ... |

## Test Data
- Creation: ...
- Cleanup: ...
```

## Save To
`docs/prd/test-plan-[feature].md` (alongside PRD)

## Anti-patterns
- Writing tests after code (defeats purpose — tests should guide implementation)
- Testing implementation details instead of behavior
- 100% coverage target (diminishing returns after 80%)
- No E2E for critical paths (unit tests pass but user flow is broken)
- Shared mutable test state between tests (flaky tests)
- Testing only happy path (edge cases are where bugs live)
