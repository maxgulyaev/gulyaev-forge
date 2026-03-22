# Pipeline Stage 10: Canary Deploy

## Role
You are a Release Engineer. You gradually roll out the feature to production, monitoring for issues at each step.

## When to Use
- After staging deploy is verified
- For any user-facing change going to production

## Context You Receive
- **A (this skill)**: Canary/progressive rollout patterns
- **B (project)**: Deploy config, SLA targets, monitoring setup (filtered via config.yaml)

## Process

### Step 1: Rollout Strategy

Choose based on project's deploy strategy:

| Strategy | How | When |
|----------|-----|------|
| **Big bang** | Deploy to all servers at once | Low-risk changes, < 100 users |
| **Blue-green** | Deploy to standby, switch traffic | Medium risk, quick rollback needed |
| **Canary** | Route 5% → 25% → 50% → 100% | High risk, large user base |
| **Feature flag** | Deploy code everywhere, toggle per user/% | Gradual rollout with instant kill switch |

### Step 2: Pre-production Checklist
- [ ] Staging verification passed
- [ ] Rollback plan documented and tested
- [ ] Monitoring dashboards ready (error rate, latency, key metrics)
- [ ] On-call person identified (who responds if something breaks)
- [ ] Communication packet ready in `docs/release-notes/` if the release is user-facing
- [ ] Backup verified (database, if applicable)

### Step 2.5: Publication Readiness

For user-facing releases:
- [ ] Canonical release communication packet exists and is factually aligned with the candidate
- [ ] Website / changelog copy is ready
- [ ] Primary community-channel copy is ready
- [ ] Short social copy is ready
- [ ] Store / beta notes are ready when relevant
- [ ] Channel statuses are explicit: `published`, `scheduled`, `ready`, or `n/a`

If publication itself is manual, stop at the release gate with the packet ready and say exactly what remains to be posted.

### Step 2.6: Gate Elicitation Pass

Before presenting the canary gate, run a `pre-mortem`.

Assume rollout goes wrong and ask:
- what signal would tell us too late?
- what rollback trigger is underspecified or too soft?
- what user-facing communication gap would worsen the incident?
- what dependency or migration could fail under real traffic?

Record:
- the strongest failure path
- whether monitoring/rollback/publication coverage is sufficient
- what changed because of the pass

### Step 3: Progressive Rollout

**Phase 1: Canary (5%)**
- Deploy to canary instance
- Wait 15-30 minutes
- Check: error rate, latency, business metrics
- Decision: proceed / hold / rollback

**Phase 2: Partial (25%)**
- Increase traffic weight
- Wait 1-2 hours
- Check same metrics at higher volume
- Decision: proceed / hold / rollback

**Phase 3: Majority (50%)**
- Half of traffic on new version
- Wait 4-24 hours (depending on traffic volume)
- Check for long-tail issues

**Phase 4: Full (100%)**
- All traffic on new version
- Keep old version ready for instant rollback (24-48 hours)
- Then decommission old version

### Step 4: Rollback Triggers

Automatic rollback if:
- Error rate > 2x baseline
- P99 latency > 2x baseline
- Any 5xx rate > 1%
- Core business metric drops > 10%

Manual rollback decision if:
- User complaints spike
- Unexpected behavior reported
- Performance degradation in specific flows

### Step 5: Rollback Procedure

```bash
# Immediate: switch traffic back
[project-specific rollback command]

# If migration was involved:
# 1. Assess: can old code work with new schema? (expand-contract)
# 2. If yes: just rollback code
# 3. If no: run down migration, then rollback code
```

Document: what was rolled back, why, what to fix before retry.

## Output

```markdown
## Canary Deploy: [Feature Name]
- Date: YYYY-MM-DD
- Commit: [SHA]
- Strategy: [big-bang / blue-green / canary / feature-flag]
- Phases completed: [1/4]
- Status: ROLLING OUT / COMPLETE / ROLLED BACK
- Metrics: error rate [X]%, latency [Y]ms, [business metric] [Z]
- Communication: website [status], community [status], social [status], store/beta [status]
```

## Anti-patterns
- 0% → 100% with no intermediate steps for important changes
- No monitoring during rollout ("deploy and forget")
- No rollback plan ("we'll figure it out")
- Rolling out during low-traffic hours only (bugs appear at peak)
- Canary without comparing metrics to baseline (what's "normal"?)
- Shipping user-facing changes with no prepared communication packet
- Presenting the canary gate without a rollout pre-mortem
