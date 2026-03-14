# Forge Feature

Route this request through `gulyaev-forge` feature handling in the current PRODUCT repo.

User request:
$ARGUMENTS

Required behavior:
1. Load `__FORGE_DIR__/core/skills/product-entry/SKILL.md`.
2. Load local rules from `AGENTS.md`, `CLAUDE.md`, `.forge/config.yaml`, `.forge/pipeline-state.yaml`.
3. Run product preflight:
   - `bash __FORGE_DIR__/scripts/forge-doctor.sh product .`
   - `bash __FORGE_DIR__/scripts/forge-status.sh product .`
4. Treat this as feature/change-request intent.
5. Find the existing issue for this feature or create one if missing and the request is non-trivial.
6. Determine the earliest valid stage for this feature:
   - resume from the issue stage if it already exists
   - otherwise start from `strategy` or `discovery` when scope is unclear
   - otherwise use the earliest valid downstream stage
7. Never skip unresolved gated stages.
8. If a gate is pending approval, re-present that gate instead of moving forward.
9. If the work reaches `implementation` and touches framework/library/API behavior, use Context7 MCP to pull current docs before coding.
10. If the work reaches `implementation` or later and `.forge/config.yaml` configures an external reviewer for `code_review/reviewer`, run it before presenting QA or a ship gate:
    - `bash __FORGE_DIR__/scripts/forge-stage-agent.sh run . code_review reviewer`
    - if it finds blocking issues, fix them and rerun once
11. If the work reaches `qa` and the feature touches a web UI surface, and `.forge/config.yaml` enables `qa_tools.playwright_mcp`, attempt QA verification via Playwright MCP before presenting the QA gate.
    - if Playwright MCP is unavailable or unsuitable, say so explicitly in the QA output
    - include `Playwright MCP used: yes/no` and which web scenario was checked
12. Start by showing a short preload summary:
   - chosen issue
   - chosen stage/path
   - what context is being loaded
   - whether Context7 is expected at code stage
13. If the current stage remains in progress and no gate is needed yet, stop at an explicit checkpoint instead of a vague summary:
   - current stage
   - gate needed now: yes/no
   - what just finished
   - exact next recommended action
   - what condition will trigger the next gate
14. Stop at the next gate when a gate is actually required. Do not auto-approve it.
