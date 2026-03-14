# Project Reviewer Prompt

Use this file when a project wants to add reviewer-specific guidance for an external stage agent.

Example uses:
- Codex as `code_review/reviewer`
- Another future reviewer on `qa/reviewer`

Suggested contents:
- risky product invariants to protect
- specific regressions to watch for
- files or areas to inspect more carefully
- what counts as a blocker vs a follow-up

Keep it thin.
Do not duplicate the whole of `REVIEW.md`.
