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

**Process evidence:**
- Context7 used: yes / no
- Why: [framework/library/API docs needed or not needed]
- Playwright MCP used: yes / no / N/A
- Why: [web UI scenario automated or why it was skipped]

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
