# Forge Bugfix

Route this request through `gulyaev-forge` bug handling in the current PRODUCT repo.

User request:
$ARGUMENTS

Required behavior:
1. Load `__FORGE_DIR__/core/skills/product-entry/SKILL.md`.
2. Load local rules from `AGENTS.md`, `CLAUDE.md`, `.forge/config.yaml`, `.forge/pipeline-state.yaml`.
3. Run product preflight:
   - `bash __FORGE_DIR__/scripts/forge-doctor.sh product .`
   - `bash __FORGE_DIR__/scripts/forge-status.sh product .`
4. Treat this as bug/regression intent by default.
5. Find an existing bug issue or create one before editing code if the fix is non-trivial.
   - shared component, cross-screen behavior, or anything beyond a one-line literal fix counts as non-trivial
   - do not postpone issue creation until after implementation
6. Use the bug issue as the execution contract. Do not let an unrelated pending gate on another feature block this bugfix.
7. As soon as the bug issue is chosen, initialize the quick-run state:
   - `bash __FORGE_DIR__/scripts/forge-run-state.sh begin-bugfix . <issue-number> "<issue-title>"`
8. Default path:
   - `implementation`
   - `test_coverage`
   - `qa`
9. Do not deploy unless the user explicitly asks.
10. If the work reaches `implementation` and touches framework/library/API behavior, use Context7 MCP to pull current docs before coding.
11. Record the Context7 decision in quick-run state:
   - `bash __FORGE_DIR__/scripts/forge-run-state.sh set-context7 . yes "<reason>"`
   - or `bash __FORGE_DIR__/scripts/forge-run-state.sh set-context7 . no "<reason>"`
12. Start by showing a short preload summary:
   - chosen issue
   - why this is the quick path
   - what context is being loaded
   - whether Context7 will be used
13. Before leaving implementation, update the quick-run stage:
   - `bash __FORGE_DIR__/scripts/forge-run-state.sh set-stage . test_coverage`
14. If `.forge/config.yaml` configures an external reviewer for `code_review/reviewer`, run it after implementation and before QA:
   - `bash __FORGE_DIR__/scripts/forge-stage-agent.sh run . code_review reviewer`
   - if it finds critical/high issues, fix them and rerun once
   - write a durable issue comment with heading `## Stage 6.5 — External Code Review`
   - carry reviewer findings or residual risks into the QA gate summary
15. For web UI bugfixes:
   - if `.forge/config.yaml` enables `qa_tools.playwright_mcp`, attempt reproduction and verification via Playwright MCP before presenting QA
   - if Playwright MCP is unavailable or unsuitable, say so explicitly and record why in the QA comment
   - QA comment must include `Playwright MCP used: yes/no` and what scenario was actually checked
16. Before presenting QA, update the quick-run state:
   - `bash __FORGE_DIR__/scripts/forge-run-state.sh set-stage . qa`
   - `bash __FORGE_DIR__/scripts/forge-run-state.sh set-gate . pending_approval`
   - write a durable issue comment with heading `## QA Gate`
   - run `bash __FORGE_DIR__/scripts/forge-issue-trail.sh check-bugfix-qa . <issue-number>`
   - if the trail check fails, fix the missing issue comments before showing the gate to the user
17. Stop at the QA gate with:
   - what changed
   - what was verified
   - remaining risk
   - exact next question
18. Do not `git push`, merge, or otherwise ship while `.forge/active-run.env` shows a bugfix run that has not reached `qa + approved`.
19. If the pre-push hook blocks shipping, fix the missing issue/test/QA trail instead of bypassing it.
