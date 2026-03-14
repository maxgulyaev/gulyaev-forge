# Forge Release

Route this request through `gulyaev-forge` release/distribution handling in the current PRODUCT repo.

User request:
$ARGUMENTS

Required behavior:
1. Load `~/Documents/Dev/gulyaev-forge/core/skills/product-entry/SKILL.md`.
2. Load local rules from `AGENTS.md`, `CLAUDE.md`, `.forge/config.yaml`, `.forge/pipeline-state.yaml`.
3. Run product preflight:
   - `bash ~/Documents/Dev/gulyaev-forge/scripts/forge-doctor.sh product .`
   - `bash ~/Documents/Dev/gulyaev-forge/scripts/forge-status.sh product .`
4. Treat this as release/distribution intent, not generic implementation.
5. Read configured release targets:
   - `bash ~/Documents/Dev/gulyaev-forge/scripts/forge-release-target.sh list .`
6. Infer the target from the user's words when possible:
   - `testflight`, `тестфлайт` -> channel `testflight`
   - `app store`, `appstore`, `эпп стор` -> channel `app_store`
   - `веб`, `web`, `frontend`, `site` together with `prod`, `production`, `прод`, `deploy` -> prefer platform `web` with channel `production`
   - `play internal`, `internal testing` -> channel `play_internal`
   - `play production`, `google play`, `play store`, `прод в google play` -> channel `play_production`
7. If the target is ambiguous, list the configured release targets and ask which one to use.
8. Once a target is chosen, inspect it:
   - `bash ~/Documents/Dev/gulyaev-forge/scripts/forge-release-target.sh show . <target-name>`
   - `bash ~/Documents/Dev/gulyaev-forge/scripts/forge-release-scope.sh show . <target-name>`
   - read the referenced runbook in `CLAUDE.md` or the configured doc path
9. Verify release preconditions before any upload:
   - the target exists
   - the candidate work is already approved/shippable
   - if `.forge/active-run.env` exists, its gate must already allow shipping
   - the worktree/commit scope must be isolated to the approved change
   - `bash ~/Documents/Dev/gulyaev-forge/scripts/forge-release-scope.sh dirty . <target-name>` must report no dirty files in the target scope
10. Start by showing a short preload summary:
   - chosen target
   - chosen candidate issue/run
   - runbook source
   - whether upload will execute now or what blocks it
11. If the user explicitly asked to upload/release and the preconditions pass:
   - execute the project-specific archive/upload flow from the runbook
   - do not invent hidden steps beyond the runbook; if the runbook says upload is only part of the process, stop at the next explicit release gate
   - if the chosen target is web and `.forge/config.yaml` enables `qa_tools.playwright_mcp`, use Playwright MCP for post-deploy smoke when the target environment is reachable
   - if Playwright MCP is unavailable, say so explicitly and leave a manual smoke checklist instead
   - report build/version and exact upload destination
   - post the durable shipped/upload comment in the relevant issue trail
   - if this was a bugfix quick run and shipping completed, clear `.forge/active-run.env`
12. If the target is not ready, stop with an explicit release gate:
   - what is ready
   - what is blocked
   - exact next action
