# Codex Adapter

Current Codex integration in forge is stage-agent based.

What works now:
- `codex-review` as an external reviewer adapter
- the adapter runs `codex exec -s workspace-write`
- forge prepends its own review contract and may add a project-local reviewer prompt overlay
- forge rejects the run if Codex leaves any worktree drift behind

Configured via project `.forge/config.yaml`:

```yaml
stage_agents:
  code_review:
    reviewer:
      adapter: codex-review
      prompt_file: .forge/reviewers/code-review.md
```

Launch through forge:

```bash
bash ~/Documents/Dev/gulyaev-forge/scripts/forge-stage-agent.sh run /path/to/project code_review reviewer
```

This is intentionally narrower than a full Codex router.
Codex is used here as a focused secondary reviewer, while the primary PRODUCT agent can remain Claude Code.

The mapping is generic:
- `stage_agents.<stage>.<role>` decides where the external agent is attached
- current standard is `code_review/reviewer`
- future projects may attach Codex to other review roles without changing the pipeline contract
