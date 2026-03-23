# Forge Work

Route this request through the universal `gulyaev-forge` PRODUCT entrypoint in the current repo.

User request:
$ARGUMENTS

Required behavior:
1. Load `__FORGE_DIR__/core/skills/product-entry/SKILL.md`.
2. Load local rules from `AGENTS.md`, `CLAUDE.md`, `.forge/config.yaml`, `.forge/pipeline-state.yaml`.
3. Run product preflight:
   - `bash __FORGE_DIR__/scripts/forge-doctor.sh product .`
   - `bash __FORGE_DIR__/scripts/forge-status.sh product .`
4. Classify the request into exactly one route:
   - `bugfix`
   - `micro_change`
   - `small_change`
   - `full_feature`
   - `investigate`
   - `release`
5. Start with a short preload summary:
   - chosen issue
   - chosen lane
   - chosen stage/path
   - what context is being loaded
   - whether Context7 is expected later
6. If the chosen lane is `bugfix`:
   - follow the same quick-path discipline as `/forge:bugfix`
   - create/select the bug issue before code when the fix is non-trivial
   - initialize and maintain `.forge/active-run.env`
   - default path: `implementation` -> `test_coverage` -> `qa`
7. If the chosen lane is `micro_change`:
   - create/select the issue first
   - write a durable `## Change Brief` using `__FORGE_DIR__/core/templates/change-brief-template.md`
   - keep it minimal: lane, scope, non-goals, acceptance, proof, rollback
   - route directly to `implementation`
   - default path: `implementation` -> `test_coverage` -> `qa`
8. If the chosen lane is `small_change`:
   - create/select the issue first
   - produce a compact Behavior Contract or short `Change Brief`
   - start from the earliest valid gated stage, usually Stage 2 (`prd` stage id) or `design`
   - do not force `strategy` / `discovery` unless the scope is genuinely unclear
9. If the chosen lane is `full_feature`:
   - use the normal feature pipeline
   - start from the earliest valid full stage
10. If the chosen lane is `investigate`:
    - Load `__FORGE_DIR__/core/skills/investigate/SKILL.md`
    - Follow the `sources → facts → analysis → recommendations` structure
    - Use `__FORGE_DIR__/core/templates/investigation-report-template.md` for non-trivial investigations
    - If the investigation concludes that a change is needed, feed findings into the appropriate pipeline stage
11. If the chosen lane is `release`, route accordingly instead of treating it as implementation.
12. Never skip unresolved gated stages.
13. If a gate is pending approval, re-present that gate instead of moving forward.
14. If the work reaches `implementation` and touches framework/library/API behavior, use Context7 MCP before coding.
15. If the work reaches `implementation` or later and `.forge/config.yaml` configures `code_review/reviewer`, run it before QA or a ship gate:
    - `bash __FORGE_DIR__/scripts/forge-stage-agent.sh run . code_review reviewer`
    - if it finds blocking issues, fix them and rerun once
    - if any `critical` or `high` finding remains open, stay in `implementation`
16. If the work reaches `qa` and touches a web UI surface, and `.forge/config.yaml` enables `qa_tools.playwright_mcp`, attempt Playwright MCP verification before presenting the QA gate.
17. If the current stage remains in progress and no gate is needed yet, stop at an explicit checkpoint:
    - current stage
    - chosen lane
    - gate needed now: yes/no
    - what just finished
    - exact next recommended action
    - what condition will trigger the next gate
18. Stop at the next gate when a gate is actually required. Do not auto-approve it.
