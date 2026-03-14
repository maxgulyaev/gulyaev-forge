# Forge Continue

Continue the active PRODUCT workflow in the current repo.

User reply or extra context:
$ARGUMENTS

Required behavior:
1. Load `~/Documents/Dev/gulyaev-forge/core/skills/product-entry/SKILL.md`.
2. Load local rules from `AGENTS.md`, `CLAUDE.md`, `.forge/config.yaml`, `.forge/pipeline-state.yaml`.
3. Run product preflight:
   - `bash ~/Documents/Dev/gulyaev-forge/scripts/forge-doctor.sh product .`
   - `bash ~/Documents/Dev/gulyaev-forge/scripts/forge-status.sh product .`
4. Check `.forge/active-run.env` first.
   - if there is an active bugfix run, continue that quick path instead of the unrelated feature pipeline
   - use the active bugfix issue as the execution contract
5. Read the current issue and current gate state.
6. If the current gate is pending approval:
   - interpret `$ARGUMENTS` as the user's natural-language decision when possible
   - if this is an active bugfix QA gate, first run `bash ~/Documents/Dev/gulyaev-forge/scripts/forge-issue-trail.sh check-bugfix-qa . <issue-number>` and refuse to advance until the issue trail is complete
   - mirror that decision into the issue as `/gate approved`, `/gate approved_with_changes`, or `/gate rejected`
   - if this is an active bugfix run, mirror the decision into `.forge/active-run.env` via `forge-run-state.sh set-gate`
   - only then advance one stage if allowed
7. If no gate is pending, resume the current issue from the correct next stage.
8. Never skip unresolved gated stages.
9. For an approved bugfix QA gate:
   - do not auto-push unless the user explicitly asks to ship
   - instead mark the quick run ready and explain what is unlocked next
10. Start with a short preload summary and explain whether you are:
   - re-presenting a gate
   - recording a gate decision
   - or continuing to the next allowed stage
