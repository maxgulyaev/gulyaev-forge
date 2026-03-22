# Behavior Contract

Use this as the default Stage 2 artifact for `small_change` and `full_feature`.

Purpose:
- one compact source of truth for product intent, expected behavior, corner cases, and required proof
- fewer files
- less drift between "what we are building" and "how we will verify it"

Default location:
- `docs/prd/YYYY-MM-DD-<slug>.md`

`docs/prd/` stays as the compatibility path for now even though the artifact is now a Behavior Contract, not a long-form PRD.

## Header

- Feature:
- Issue:
- Lane: `small_change` or `full_feature`
- Status: `draft` / `approved`
- Owner:
- Upstream inputs:

## Why

- User/problem:
- Why now:
- Evidence:

## Scope

- In scope:
- Out of scope:

## Behavior Rules

- `BC-001`:
- `BC-002`:
- `BC-003`:

Write these as observable system behavior, not implementation ideas.

## Scenario Matrix

| ID | Scenario | Expected behavior | Priority |
|----|----------|-------------------|----------|
| `S-01` |  |  | `P0/P1/P2` |
| `S-02` |  |  |  |

Use one row per user-visible scenario.

## Edge Cases

| ID | Case | Expected behavior |
|----|------|-------------------|
| `E-01` |  |  |
| `E-02` |  |  |

Include:
- empty states
- invalid input
- backward compatibility
- migration / sync / parity / offline behavior when relevant

## Design / UX Notes

Only include decisions that matter for behavior or parity.
Do not create a separate design doc unless the UI/UX work is substantial enough to deserve its own gate.

## Technical Constraints

- API / schema / migration:
- platform constraints:
- rollout constraints:

## Proof Required

| ID | Contract item | Proof type | Notes |
|----|---------------|------------|-------|
| `P-01` | `S-01` | unit / integration / e2e / manual |  |
| `P-02` | `E-01` | integration / manual |  |

This is the test/proof section.
Do not create a separate file-backed test plan by default.

## Open Questions

- 
