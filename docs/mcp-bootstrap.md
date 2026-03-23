# MCP Bootstrap

Machine-level MCP setup for Claude Code and Codex should be treated as a first-class forge concern, not as ad-hoc local state.

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

For Codex, the machine-level MCP registry lives in:

```text
~/.codex/config.toml
```

Manage and verify it through the CLI:

```bash
codex mcp add ...
codex mcp list
```

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
claude mcp add -s user chrome-devtools -- npx -y chrome-devtools-mcp@latest
export GITHUB_PERSONAL_ACCESS_TOKEN=<token>
bash "$FORGE_DIR/bin/forge" mcp install github
claude mcp add -s user --transport http figma https://mcp.figma.com/mcp
```

## Figma MCP

Figma provides an official remote MCP server at `https://mcp.figma.com/mcp`.
Authentication is OAuth 2.0 — no API key needed.

### Claude Code

```bash
claude mcp add --scope user --transport http figma https://mcp.figma.com/mcp
```

After adding, **restart Claude Code**. On first connection it will open a browser for Figma OAuth.
Verify: `/mcp` → figma should show `Connected` with tools loaded.

Docs: https://developers.figma.com/docs/figma-mcp-server/remote-server-installation/

### Codex

```bash
codex mcp add figma --url https://mcp.figma.com/mcp
```

Config lands in `~/.codex/config.toml`. OAuth triggers on first use.

Verify with:

```bash
codex mcp list
```

Expected result:
- `figma` is listed
- status is `enabled`
- auth is `OAuth`

### Capabilities

- Read Figma/FigJam/Make files and frames
- Extract design tokens (variables, components, layout)
- Generate code from selected frames
- Turn UI code into editable Figma layers (remote server only)
- Code Connect integration for component consistency

### Limits

- Free Figma plan: 6 MCP tool calls/month
- Paid plan (Dev or Full seat): unlimited

### Troubleshooting

- If `/mcp` doesn't show figma after restart: check `claude mcp list` — if `Failed to connect`, OAuth may not have completed
- If OAuth prompt doesn't appear: try `claude mcp remove figma && claude mcp add --scope user --transport http figma https://mcp.figma.com/mcp` and restart again
- Figma MCP config should live in `~/.claude.json` (user scope), NOT in `~/.claude/settings.json` — the latter may not be visible to `claude mcp list`
- For Codex, check `~/.codex/config.toml` and `codex mcp list`; if `figma` is missing there, no product repo can fix it for you

## Operational Rule

After changing MCP config:
- restart the Claude session
- restart the Codex session if you plan to use Codex on the same machine
- if an active session still cannot see the tool, open a fresh session in the target repo
- if `claude mcp list` shows `Failed to connect`, do not silently downgrade the pipeline step as if the tool were available

That last rule matters for forge QA: missing Playwright is a tooling blocker, not a reason to pretend API smoke equals web QA.
