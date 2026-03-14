# MCP Bootstrap

Machine-level MCP setup for Claude Code should be treated as a first-class forge concern, not as ad-hoc local state.

## Canonical Source Of Truth

For Claude Code, the canonical MCP registry is the user-level config managed by:

```bash
claude mcp add -s user ...
claude mcp add-json -s user ...
claude mcp list
claude mcp get <name>
```

In practice this lives in:

```text
~/.claude.json
```

`~/.claude/settings.json` may still exist for plugins, statusline, legacy manual config, or older experiments. Do not assume that MCP entries placed there are visible to `claude mcp list`.

## Playwright

`@playwright/mcp` proved unreliable through ephemeral `npx` on this machine. Forge now provides a stable bootstrap path:

```bash
FORGE_DIR=/path/to/gulyaev-forge
bash "$FORGE_DIR/bin/forge" mcp install playwright
```

What it does:
- installs `@playwright/mcp` into `~/.claude/mcp/playwright`
- registers user-level Claude MCP in `~/.claude.json`
- prefers local Chrome on macOS when available
- keeps the install reusable across all product repos

Verify with:

```bash
bash "$FORGE_DIR/bin/forge" mcp status
claude mcp get playwright
claude mcp list
```

Expected result:
- `playwright` appears in `claude mcp list`
- status is `Connected`

## Other MCPs

For CLI-managed MCPs, prefer explicit user-scoped registration:

```bash
claude mcp add -s user context7 -- npx -y @upstash/context7-mcp@latest
export GITHUB_PERSONAL_ACCESS_TOKEN=<token>
bash "$FORGE_DIR/bin/forge" mcp install github
claude mcp add -s user --transport http figma https://mcp.figma.com/mcp
```

## Operational Rule

After changing MCP config:
- restart the Claude session
- if an active session still cannot see the tool, open a fresh session in the target repo
- if `claude mcp list` shows `Failed to connect`, do not silently downgrade the pipeline step as if the tool were available

That last rule matters for forge QA: missing Playwright is a tooling blocker, not a reason to pretend API smoke equals web QA.
