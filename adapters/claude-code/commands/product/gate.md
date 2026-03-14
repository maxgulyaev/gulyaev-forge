# Forge Gate

Apply a gate decision for the current PRODUCT workflow.

User decision:
$ARGUMENTS

Required behavior:
1. Load `__FORGE_DIR__/core/skills/product-entry/SKILL.md`.
2. Check `.forge/active-run.env` first; if an active bugfix run exists, treat it as the current workflow.
3. Read `.forge/pipeline-state.yaml` and the linked GitHub issue.
4. Identify the currently pending gate.
5. Interpret the user's decision in natural language:
   - approval
   - approval with changes
   - rejection
6. Mirror the durable decision into the issue trail using exactly one of:
   - `/gate approved`
   - `/gate approved_with_changes`
   - `/gate rejected`
7. If this is an active bugfix QA gate, first run `bash __FORGE_DIR__/scripts/forge-issue-trail.sh check-bugfix-qa . <issue-number>` and stop if the durable issue trail is incomplete.
8. If this is an active bugfix run, also update `.forge/active-run.env` via `forge-run-state.sh set-gate`.
9. Update labels and `.forge/pipeline-state.yaml` only if the decision allows advancement.
10. Advance at most one gated transition.
11. Show a short confirmation of:
   - which gate was decided
   - what issue comment was written
   - what stage is now active
