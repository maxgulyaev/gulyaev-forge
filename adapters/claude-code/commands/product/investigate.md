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
4. Load `__FORGE_DIR__/core/skills/investigate/SKILL.md`.
5. Treat this as question / uncertainty / evidence-gathering intent.
6. Follow the `sources → facts → analysis → recommendations` structure from the investigate skill.
7. Use `__FORGE_DIR__/core/templates/investigation-report-template.md` for non-trivial investigations.
8. Find or create an issue if the investigation is non-trivial.
9. Start with a short preload summary:
   - chosen issue
   - investigation question and scope
   - why this is an investigation flow
10. End with structured evidence, analysis with confidence levels, actionable recommendations, and the correct next gate or pipeline stage if a change is warranted.
