# Gate: [Stage Name]

> Project: [project name]
> Stage: [N/12]
> Date: [YYYY-MM-DD]
> Previous gate: [link or N/A]

---

## Summary

**Status:** go / go with concerns / stop

**What was done:**
-
-
-

**Key decisions:**
-

**Risks:**
-

**Question for you:**
[Specific question requiring approval to proceed]

**Decision command (record in issue comment):**
- `/gate approved`
- `/gate approved_with_changes`
- `/gate rejected`

Do not advance labels or `pipeline-state.yaml` until that decision is recorded.

---

## Detailed Review

**Artifact:** [link to the full output file]

**Review checklist:**
- [ ] [What to verify]
- [ ] [What to verify]
- [ ] [What to verify]

**Execution contract for this gate:**
- Issue / acceptance criteria: [link or summary]
- Approved upstream artifacts: [link or summary]
- Stage-specific checklist: [what defines done here]

**Acceptance / completion coverage:**
| Required item | Status | Evidence / blocker |
|---------------|--------|--------------------|
| [criterion / rollout note] | PASS / FAIL / NOT PROVEN | [test, log, screenshot, blocker] |

**Stage advancement basis:**
- Required scope proven: [what is actually evidenced]
- Required scope still unverified or deferred: [if none, say none]
- Evidence contradictions: none / [list]
- Why this status is justified: [why `go` / `go with concerns` / `stop` matches the evidence]

Do not mark this gate `go` while any required item above is still `FAIL` or `NOT PROVEN` unless there is explicit approval for that deferral.

**Elicitation pass:**
- Method: [pre-mortem / inversion / red-team / first-principles / n/a]
- Why this method fits this gate:
- What it tried to break or falsify:
- Findings:
- Did it change the verdict: yes / no

**Process evidence:**
- Context7 used: yes / no
- Why: [framework/library/API docs needed or not needed]
- Playwright MCP used: yes / no / N/A
- Why: [web UI scenario automated or why it was skipped]
- External review required / run: yes / no
- Docs / issue / pipeline-state sync: aligned / mismatch fixed / blocked
- Rule audit / proof boundary: aligned / mismatch fixed / blocked / N/A
- Secret handling issues: none / [list]

**Trade-offs considered:**
| Option | Pros | Cons | Chosen? |
|--------|------|------|---------|
| | | | |
| | | | |

**Diff from previous state:**
[What changed compared to before this stage ran]

---

## Rollback Plan

**Affected files / migrations / deploys:**
-

**Rollback commands:**
```bash
#
```

**Pre-state reference:** [commit SHA or tag]

**Dependencies — what else might break on rollback:**
-
