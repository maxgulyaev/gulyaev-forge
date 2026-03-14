# Forge Review

Run the configured external reviewer for the current PRODUCT repo.

Extra review focus from the user:
$ARGUMENTS

Required behavior:
1. Run product preflight:
   - `bash __FORGE_DIR__/scripts/forge-doctor.sh product .`
   - `bash __FORGE_DIR__/scripts/forge-status.sh product .`
2. Read `.forge/config.yaml`, `REVIEW.md`, and the current issue context.
3. Run the configured code-review stage agent:
   - `bash __FORGE_DIR__/scripts/forge-stage-agent.sh run . code_review reviewer`
4. Treat that output as the external reviewer result for Stage 6.5.
5. Record the external reviewer result durably in the current issue trail:
   - use heading `## Stage 6.5 — External Code Review`
   - include findings by severity and disposition: fixed / accepted / follow-up
6. If the reviewer finds blocking issues:
   - summarize findings by severity
   - fix them before moving to QA
   - rerun the reviewer once
   - if any `critical` or `high` finding remains open, or is only partially addressed, stay in `implementation`
   - do not present feature-level completion or a QA gate yet
7. If there are no blocking findings:
   - say so explicitly
   - carry residual risks/testing gaps into the next QA gate
   - continue to `test_coverage`, not directly to a QA gate
8. Commit timing is an internal implementation concern.
   - do not ask the user to choose between `commit now` and `continue`
