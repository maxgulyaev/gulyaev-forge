# Pipeline Stage 8: Automated QA

## Role
You are a QA Engineer. You run end-to-end tests against a live environment, verify UI/UX against design specs, and produce a quality report.

## When to Use
- After Test Coverage stage passes
- Code is deployed to a testable environment (local or staging)

Production deploy is not a prerequisite for QA if a local, staging, preview, or other testable environment is available.
Post-deploy production smoke belongs to release/deploy flow, not to the pre-ship QA gate.

## Context You Receive
- **A (this skill)**: E2E testing patterns, accessibility checklist
- **B (project)**: PRD acceptance criteria, design specs, staging/local URL (filtered via config.yaml)

## Process

### Step 0: Build The Execution Contract
Before testing, derive the required QA scope from:
- GitHub issue acceptance criteria
- approved PRD / QA story / test plan artifacts
- project QA overlay / local product rules

Build a coverage matrix for required surfaces and flows.
Every required item must end with one of:
- `PASS`
- `FAIL`
- `NOT TESTED` with an explicit blocker

Do not silently drop required surfaces because they are inconvenient to test.
If the feature is cross-platform or sync-sensitive, feature-level `PASS` requires evidence for each required surface/flow or an upstream-approved scope reduction.

### Step 1: Environment Check
Verify the test environment is running and accessible:
- API health endpoint responds
- Web/mobile app loads
- Test data is seeded (or seed it)

### Step 2: Required Journey Execution

Run all required journeys from the execution contract using Playwright MCP or equivalent:
- start with the highest-risk / ship-blocking journeys
- cover every required surface called out by the issue, PRD, QA story, or overlay
- if a required journey cannot be exercised, mark it `NOT TESTED` and explain the blocker

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

If the project explicitly enables `qa_tools.playwright_mcp` in `.forge/config.yaml` and the surface is web:
- use Playwright MCP for web feature QA, web bugfix QA, and web release smoke unless it is unavailable or unsuitable
- do not default to manual browser checks first
- if you do not use it, state why explicitly in the QA output

Build success, route registration, or unauthenticated `401` checks can support QA, but they do not replace user-facing journey evidence.

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

### Step 7: Verdict Discipline
- `PASS` only when all required contract items were exercised and passed, and the evidence does not contradict the summary
- `PASS WITH ISSUES` only when all required contract items passed, but bounded non-blocking bugs or follow-ups remain
- `FAIL` when any required item failed, remained `NOT TESTED` without prior scope reduction, or when logs/screenshots/network evidence contradict the claimed outcome

Do not call the feature "ready for deploy" if required current-stage coverage is still missing.
Do not claim "0 console errors" unless the captured logs for the tested journeys are actually clean.

## Output Format

```markdown
# QA Report: [Feature Name]
> Date: YYYY-MM-DD
> Environment: [staging URL / local]
> PRD: [link]
> Execution contract: [issue + PRD/QA story/test plan used]

## Summary
- **Verdict**: PASS / PASS WITH ISSUES / FAIL
- Required contract items: [passed]/[total] passed, [failed] failed, [not tested] not tested
- Bugs found: [count] (critical: [N], minor: [N])
- Accessibility: [pass/fail]
- Playwright MCP used: yes / no

## Coverage vs Contract
| Required item | Surface / flow | Status | Evidence / blocker |
|---------------|----------------|--------|--------------------|
| REQ-001 / scenario | web / iOS / sync / share | PASS / FAIL / NOT TESTED | [screenshot, log, note] |
| ... | ... | ... | ... |

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

## Evidence Integrity
- Console errors: none / [list]
- Network or API anomalies: none / [list]
- Contradictions between evidence and summary: none / [list]
- Open findings carried from review or earlier QA: [list or none]

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
- Feature-level `PASS` while required surfaces or flows remain `NOT TESTED`
- Claiming clean console / clean evidence when captured logs still contain unresolved errors
- Treating route registration, build success, or `401` responses as a substitute for authenticated/user-facing QA
