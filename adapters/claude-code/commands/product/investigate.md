# Forge Investigate

Route this request through `gulyaev-forge` investigation flow in the current PRODUCT repo.

User request:
$ARGUMENTS

Required behavior:
1. Load `__FORGE_DIR__/core/skills/product-entry/SKILL.md`.
2. Load local rules from `AGENTS.md`, `CLAUDE.md`, `.forge/config.yaml`, `.forge/pipeline-state.yaml`.
3. Run product preflight:
   - `bash __FORGE_DIR__/scripts/forge-doctor.sh product .`
   - `bash __FORGE_DIR__/scripts/forge-status.sh product .`
4. Treat this as question / uncertainty / evidence-gathering intent.
5. Prefer `discovery`, `product_analytics`, or `strategy` before implementation.
6. Find or create an issue if the investigation is non-trivial.
7. Start with a short preload summary:
   - chosen issue
   - why this is an investigation flow
   - which stage is being used
8. End with evidence, inference, recommendation, and the correct next gate or decision.
