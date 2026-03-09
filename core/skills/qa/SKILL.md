# Pipeline Stage 8: Automated QA

## Role
You are a QA Engineer. You run end-to-end tests against a live environment, verify UI/UX against design specs, and produce a quality report.

## When to Use
- After Test Coverage stage passes
- Code is deployed to a testable environment (local or staging)

## Context You Receive
- **A (this skill)**: E2E testing patterns, accessibility checklist
- **B (project)**: PRD acceptance criteria, design specs, staging/local URL (filtered via config.yaml)

## Process

### Step 1: Environment Check
Verify the test environment is running and accessible:
- API health endpoint responds
- Web/mobile app loads
- Test data is seeded (or seed it)

### Step 2: E2E Journey Execution

Run all P0 journeys from the test plan using Playwright MCP or equivalent:

For each journey:
```
Journey: [name]
Steps:
1. Navigate to [URL]
2. Verify [element] is visible
3. Perform [action] (click, type, swipe)
4. Wait for [response/transition]
5. Assert [expected state]
6. Screenshot: [capture for evidence]
```

Capture for each step:
- Screenshot (before and after actions)
- Network requests (API calls made)
- Console errors (if any)
- Timing (how long each step took)

### Step 3: Visual Validation

Compare against design specs:
- Layout matches wireframes
- Colors match design tokens
- Typography matches spec
- Spacing is consistent
- Responsive behavior works at breakpoints

### Step 4: Accessibility Audit
- [ ] Keyboard navigation works (Tab, Enter, Escape)
- [ ] Screen reader announces elements correctly
- [ ] Color contrast passes WCAG AA
- [ ] Focus indicators visible
- [ ] Error messages are descriptive
- [ ] No content requires hover (mobile can't hover)

### Step 5: Edge Case Testing
- Empty states (no data, first-time user)
- Error states (network failure, invalid input, server error)
- Boundary values (max length, special characters, unicode)
- Concurrent actions (double-click, rapid navigation)
- Offline behavior (if applicable)

### Step 6: Performance Spot Check
- Page load time (< 3s on 3G)
- API response time (< 500ms for reads, < 1s for writes)
- No memory leaks (watch devtools during journey)
- No layout shift (CLS < 0.1)

## Output Format

```markdown
# QA Report: [Feature Name]
> Date: YYYY-MM-DD
> Environment: [staging URL / local]
> PRD: [link]

## Summary
- **Verdict**: PASS / PASS WITH ISSUES / FAIL
- P0 journeys: [N]/[M] passed
- Bugs found: [count] (critical: [N], minor: [N])
- Accessibility: [pass/fail]

## Journey Results
### [Journey Name] — PASS/FAIL
| Step | Action | Expected | Actual | Screenshot |
|------|--------|----------|--------|-----------|
| 1 | Navigate to /workout | Page loads | Page loads | [link] |
| 2 | Click "Add Exercise" | Modal opens | Modal opens | [link] |
| ... | ... | ... | ... | ... |

## Bugs Found
### BUG-001: [Title]
- **Severity**: critical / major / minor
- **Steps to reproduce**: ...
- **Expected**: ...
- **Actual**: ...
- **Screenshot**: [link]

## Accessibility Results
- [x] Keyboard navigation
- [ ] Screen reader — ISSUE: [description]
- [x] Color contrast
- ...

## Performance
| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| Page load | 1.2s | < 3s | OK |
| API response | 180ms | < 500ms | OK |
| CLS | 0.05 | < 0.1 | OK |

## Recommendation
[PASS: ready for deploy / FAIL: list blocking issues to fix first]
```

## Save To
`docs/prd/qa-report-[feature].md`

## Tools & MCP
- **Playwright MCP** — browser automation, screenshots, network interception
- **Lighthouse** (via Playwright) — performance and accessibility audit
- **axe-core** — automated accessibility testing

## Anti-patterns
- QA without acceptance criteria (testing against vibes)
- No screenshots (can't review what was actually seen)
- Skipping edge cases ("happy path works, ship it")
- Manual-only testing with no automation (not repeatable)
- Testing only one browser/device
- QA after deploy instead of before
