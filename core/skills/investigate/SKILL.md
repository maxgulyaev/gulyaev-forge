---
name: investigate
description: Evidence-first investigation and audit mode. Use when the request is about uncertainty, diagnosis, incident analysis, architecture review, product research, or deep discovery — any situation where the agent should collect evidence before proposing changes.
---

# Investigate

## Purpose

This skill turns ad-hoc "figure it out" requests into structured evidence-first investigations.

The agent acts as an **investigator**, not a builder. The goal is to produce a clear picture of reality before anyone commits to a course of action.

Works in both PRODUCT and SELF modes.

## When To Use

- Uncertainty: "why is this happening?", "what's going on with X?"
- Incident / diagnosis: "users report Y", "something broke but we're not sure what"
- Architecture review: "is our auth layer solid?", "audit the data model"
- Product research: "should we add feature Z?", "what do competitors do here?"
- Deep discovery: scope is too fuzzy for a Behavior Contract yet
- Audit: "check compliance with X", "review security posture"

## Core Structure

Every investigation follows four phases in strict order:

```
sources → facts → analysis → recommendations
```

### 1. Sources

Identify and list everything consulted:
- code, configs, logs, metrics, dashboards
- documentation, issues, PRs, commit history
- external references, standards, benchmarks
- user reports, analytics data
- interviews / stakeholder input (if referenced)

Each source gets a short tag (e.g., `[S1]`, `[S2]`) for citation in later sections.

### 2. Facts

Record only what is directly observable or verifiable:
- what the code actually does (not what it's supposed to do)
- what metrics actually show
- what users actually reported
- what the config actually contains

Rules:
- no inference in this section
- no "probably" or "likely"
- every fact cites at least one source tag
- contradictions between sources are facts too — record both sides

### 3. Analysis

Inference, reasoning, and pattern recognition based on the facts:
- root cause hypotheses with supporting fact references
- risk assessment
- trade-off analysis
- comparison with known good patterns or standards
- confidence level for each conclusion: `high` / `medium` / `low`

Rules:
- every analytical claim must cite fact numbers
- clearly mark assumptions
- distinguish correlation from causation
- if evidence is insufficient, say so explicitly

### 4. Recommendations

Actionable next steps:
- each recommendation gets a confidence: `high` / `medium` / `low`
- each recommendation gets an effort estimate: `trivial` / `small` / `medium` / `large`
- prioritize by impact × confidence, not by effort
- distinguish "fix now" from "fix later" from "investigate further"

Optional: if the investigation leads to a clear decision, include a **Decision Record** section with the decision, rationale, alternatives considered, and consequences accepted.

## Scope Control

Before starting:
1. State the **question** — what exactly are we trying to learn?
2. State the **scope** — what is in and out of bounds?
3. State the **stop condition** — when is the investigation done?

If the investigation grows beyond the original scope, stop and present a checkpoint asking whether to expand.

## Output

Use the template at `core/templates/investigation-report-template.md`.

The report can be:
- written to `docs/investigations/` in a PRODUCT repo
- presented in chat for lightweight investigations
- attached to a GitHub issue as a comment for issue-linked investigations

## Integration With Pipeline

- If the investigation concludes that a code change is needed, it becomes input to a subsequent pipeline stage (usually `implementation` or `architecture`), not a mandate to start coding immediately.
- If the investigation is linked to an issue, update the issue with findings before transitioning.
- The investigation itself is not a gated stage — it produces evidence that feeds into gated stages.
- For SELF investigations, findings may feed into Scout evaluations or Meta changes.

## Anti-Patterns

- Jumping to recommendations before completing facts
- Mixing evidence and inference in the same section
- Treating investigation as implementation — the output is a report, not code
- Scope creep without explicit checkpoint
- Anchoring on a hypothesis and only collecting confirming evidence
- Presenting low-confidence conclusions as certainties
