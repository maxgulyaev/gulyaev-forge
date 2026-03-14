# Forge Review

Run the configured external reviewer for the current PRODUCT repo.

Extra review focus from the user:
$ARGUMENTS

Required behavior:
1. Run product preflight:
   - `bash ~/Documents/Dev/gulyaev-forge/scripts/forge-doctor.sh product .`
   - `bash ~/Documents/Dev/gulyaev-forge/scripts/forge-status.sh product .`
2. Read `.forge/config.yaml`, `REVIEW.md`, and the current issue context.
3. Run the configured code-review stage agent:
   - `bash ~/Documents/Dev/gulyaev-forge/scripts/forge-stage-agent.sh run . code_review reviewer`
4. Treat that output as the external reviewer result for Stage 6.5.
5. Record the external reviewer result durably in the current issue trail:
   - use heading `## Stage 6.5 — External Code Review`
   - include findings by severity and disposition: fixed / accepted / follow-up
6. If the reviewer finds blocking issues:
   - summarize findings by severity
   - fix them before moving to QA
   - rerun the reviewer once
7. If there are no blocking findings:
   - say so explicitly
   - carry residual risks/testing gaps into the next QA gate
