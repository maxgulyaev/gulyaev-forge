# Forge Continue

Continue the active PRODUCT workflow in the current repo.

User reply or extra context:
$ARGUMENTS

Required behavior:
1. Load `__FORGE_DIR__/core/skills/product-entry/SKILL.md`.
2. Load local rules from `AGENTS.md`, `CLAUDE.md`, `.forge/config.yaml`, `.forge/pipeline-state.yaml`.
3. Run product preflight:
   - `bash __FORGE_DIR__/scripts/forge-doctor.sh product .`
   - `bash __FORGE_DIR__/scripts/forge-status.sh product .`
4. Check `.forge/active-run.env` first.
   - if there is an active bugfix run, continue that quick path instead of the unrelated feature pipeline
   - use the active bugfix issue as the execution contract
5. Read the current issue and current gate state.
6. If the issue stage label and `.forge/pipeline-state.yaml` disagree:
   - reconcile them if the correct state is unambiguous from the durable issue trail
   - otherwise stop and present the mismatch before giving "what next" guidance
7. If the current gate is pending approval:
   - interpret `$ARGUMENTS` as the user's natural-language decision when possible
   - if this is an active bugfix QA gate, first run `bash __FORGE_DIR__/scripts/forge-issue-trail.sh check-bugfix-qa . <issue-number>` and refuse to advance until the issue trail is complete
   - mirror that decision into the issue as `/gate approved`, `/gate approved_with_changes`, or `/gate rejected`
   - if this is an active bugfix run, mirror the decision into `.forge/active-run.env` via `forge-run-state.sh set-gate`
   - only then advance one stage if allowed
8. If no gate is pending, resume the current issue from the correct next stage or continue the current in-progress stage.
9. Never skip unresolved gated stages.
10. For non-gated transitions after implementation:
   - if Stage 6.5 external review is complete and no blocking findings remain, continue into `test_coverage`
   - if Stage 7 `test_coverage` is complete and no blocker remains, continue into `qa`
   - do not stop just to ask whether to commit or whether to continue
   - if any `critical` or `high` review finding is still open, or only partially addressed, remain in `implementation`
11. For an approved bugfix QA gate:
   - do not auto-push unless the user explicitly asks to ship
   - instead mark the quick run ready and explain what is unlocked next
12. If the current stage is still in progress and no gate is required yet, respond with an explicit checkpoint that includes:
    - current stage
    - gate needed now: yes/no
    - what just finished
    - exact next recommended action
    - what condition will trigger the next gate
    - do not present a menu of internal implementation choices when the next unfinished item is already clear
    - do not ask the user to choose between commit timing, continued implementation, or QA unless a real human decision exists
    - do not call something a QA gate before Stage 8 QA was actually executed
13. If continuing into `qa` for a feature that touches a web UI surface, and `.forge/config.yaml` enables `qa_tools.playwright_mcp`, use Playwright MCP before presenting the QA gate unless it is unavailable or unsuitable.
   - if not used, say why explicitly
   - include `Playwright MCP used: yes/no` and which scenario was actually checked
14. Start with a short preload summary and explain whether you are:
   - re-presenting a gate
   - recording a gate decision
   - continuing the next allowed stage
   - or presenting a non-gate checkpoint
