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
5. Still classify the change into an execution lane before choosing the starting stage:
   - `micro_change` for one-surface, low-blast-radius tweaks with no API/schema/sync/shared-contract change
   - `small_change` for bounded product changes that need a short contract
   - `full_feature` for the normal full pipeline
6. Find the existing issue for this feature or create one if missing and the request is non-trivial.
7. For `micro_change`, write a durable `## Change Brief` using `__FORGE_DIR__/core/templates/change-brief-template.md` before coding, then route directly to `implementation`.
8. Determine the earliest valid stage for this feature:
   - resume from the issue stage if it already exists
   - otherwise start from `strategy` or `discovery` only when scope is genuinely unclear or too large for the short lanes
   - otherwise use the earliest valid downstream stage for the chosen lane
   - for `small_change`, prefer a compact Behavior Contract over a separate PRD + test plan pair
9. Never skip unresolved gated stages.
10. If a gate is pending approval, re-present that gate instead of moving forward.
11. If the work reaches `implementation` and touches framework/library/API behavior, use Context7 MCP to pull current docs before coding.
12. If the work reaches `implementation` or later and `.forge/config.yaml` configures an external reviewer for `code_review/reviewer`, run it before presenting QA or a ship gate:
    - `bash __FORGE_DIR__/scripts/forge-stage-agent.sh run . code_review reviewer`
    - if it finds blocking issues, fix them and rerun once
    - if any `critical` or `high` finding remains open, or is only partially addressed, remain in `implementation`
13. If the work reaches `qa` and the feature touches a web UI surface, and `.forge/config.yaml` enables `qa_tools.playwright_mcp`, attempt QA verification via Playwright MCP before presenting the QA gate.
    - if Playwright MCP is unavailable or unsuitable, say so explicitly in the QA output
    - include `Playwright MCP used: yes/no` and which web scenario was checked
    - compare the QA evidence back to the issue acceptance criteria, approved artifacts, and any QA story/checklist before presenting the gate
    - name any required surfaces or flows that remain untested
    - do not call the feature ready for Stage 9 / deploy if required current-stage coverage is still missing or contradicted by the evidence
    - do not present a QA gate before QA was actually executed on a testable environment
14. Start by showing a short preload summary:
   - chosen issue
   - chosen lane
   - chosen stage/path
   - what context is being loaded
   - whether Context7 is expected at code stage
15. If the current stage remains in progress and no gate is needed yet, stop at an explicit checkpoint instead of a vague summary:
   - current stage
   - chosen lane
   - gate needed now: yes/no
   - what just finished
   - exact next recommended action
   - what condition will trigger the next gate
16. Stop at the next gate when a gate is actually required. Do not auto-approve it.
