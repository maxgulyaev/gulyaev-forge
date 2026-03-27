# Project Reviewer Prompt

Use this file when a project wants to add reviewer-specific guidance for an external stage agent.

Example uses:
- Codex as `code_review/reviewer`
- Another future reviewer on `qa/reviewer`

Suggested contents:
- risky product invariants to protect
- issue acceptance items or rollout invariants that must be proven before close / ship
- specific regressions to watch for
- files or areas to inspect more carefully
- what counts as a blocker vs a follow-up
- manual smoke paths that automation does not replace
- secret-handling rules (for example, never echo credentials from env or URLs)
- places where docs or runbooks must stay strictly aligned with actual implementation
- proof-boundary rules for `BUSINESS_RULES.md` work (for example, when helper proof is insufficient for an integration/e2e claim)
- structural/source-read tests that are acceptable only for wiring/existence contracts
- hidden exact-case / raw SQL / transaction paths that can weaken "cross-flow" claims

Keep it thin.
Do not duplicate the whole of `REVIEW.md`.
