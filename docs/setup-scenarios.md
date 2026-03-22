# Setup Scenarios

This is the shortest way to think about forge setup:

- machine-level setup: agent CLIs, MCP servers, OAuth, forge checkout
- product-level setup: repo init, `.forge/`, local Claude commands, product overlays

Do not redo machine-level steps for every product on the same computer.
Do redo them when you move to a new computer, VPS, or clean environment.

## Scenario 1: I just cloned forge and want the same setup

Use this when:
- you are new to forge
- this machine does not have the agent CLIs or MCP setup yet
- you want the first product running in the system

### 1. Clone forge and the first product

```bash
WORKSPACE_DIR=$HOME/workspace
FORGE_DIR="$WORKSPACE_DIR/gulyaev-forge"
PRODUCT_DIR="$WORKSPACE_DIR/my-product"

mkdir -p "$WORKSPACE_DIR"
git clone git@github.com:maxgulyaev/gulyaev-forge.git "$FORGE_DIR"
git clone git@github.com:your-org/your-product.git "$PRODUCT_DIR"
```

### 2. Install and verify agent CLIs

Minimum:
- `git`
- `gh`
- `claude`

Optional, but recommended if you use Codex in the same system:
- `codex`

### 3. Run machine-level MCP bootstrap once

Use:
- [docs/mcp-bootstrap.md](mcp-bootstrap.md)

What belongs here:
- Claude MCPs in `~/.claude.json`
- Codex MCPs in `~/.codex/config.toml`
- OAuth flows like Figma

Important:
- Figma MCP is machine-level, not product-level
- if Figma OAuth is already done on this machine, do not repeat it for every repo

### 4. Verify the machine state

```bash
cd "$FORGE_DIR"
bash scripts/forge-doctor.sh self .
bash scripts/forge-status.sh self .
claude mcp list
codex mcp list
```

Expected:
- Claude sees `context7`, `playwright`, `github`, `figma`
- Codex sees `figma`
- doctor/status report the same thing

### 5. Initialize the first product

```bash
cd "$PRODUCT_DIR"
bash "$FORGE_DIR/bin/forge" init --project .
bash "$FORGE_DIR/scripts/forge-doctor.sh" product .
bash "$FORGE_DIR/scripts/forge-status.sh" product .
```

If the product already existed before forge:
- run `forge init --project . --force` to refresh local adapters and overlays

## Scenario 2: I already use forge with one or more products and want one more product

Use this when:
- forge already works on this machine
- Claude/Codex are already installed
- MCPs and OAuth are already set up

You do not need to redo machine bootstrap.

### 1. Clone the new product

```bash
PRODUCT_DIR=$HOME/workspace/new-product
git clone git@github.com:your-org/new-product.git "$PRODUCT_DIR"
```

### 2. Attach the product to forge

```bash
FORGE_DIR=$HOME/workspace/gulyaev-forge

cd "$PRODUCT_DIR"
bash "$FORGE_DIR/bin/forge" init --project .
bash "$FORGE_DIR/scripts/forge-doctor.sh" product .
bash "$FORGE_DIR/scripts/forge-status.sh" product .
```

What this does:
- creates or refreshes `.forge/config.yaml`
- installs repo-local Claude command files
- installs the forge pre-push hook
- creates the base docs/overlay structure if missing

What it does not do:
- it does not reinstall Figma MCP
- it does not repeat OAuth on the same machine
- it does not change other products

## Scenario 3: I already use forge and want another device, computer, or VPS

Use this when:
- you bought a new laptop
- you want the same stack on a desktop and a laptop
- you are setting up a remote machine or VPS

Treat this as a new machine.

### 1. Clone forge on the new machine

```bash
WORKSPACE_DIR=$HOME/workspace
FORGE_DIR="$WORKSPACE_DIR/gulyaev-forge"

mkdir -p "$WORKSPACE_DIR"
git clone git@github.com:maxgulyaev/gulyaev-forge.git "$FORGE_DIR"
```

### 2. Reinstall machine-level agent tooling

Install:
- `git`
- `gh`
- `claude`
- `codex` if you use it on that machine

Then repeat machine-level MCP bootstrap from:
- [docs/mcp-bootstrap.md](mcp-bootstrap.md)

Reason:
- `~/.claude.json` and `~/.codex/config.toml` do not move with the repo
- OAuth sessions and local installs are machine-local state

### 3. Verify the new machine before touching products

```bash
cd "$FORGE_DIR"
bash scripts/forge-doctor.sh self .
bash scripts/forge-status.sh self .
claude mcp list
codex mcp list
```

### 4. Reconnect each product on that machine

For every product repo:

```bash
FORGE_DIR=$HOME/workspace/gulyaev-forge
PRODUCT_DIR=$HOME/workspace/my-product

cd "$PRODUCT_DIR"
bash "$FORGE_DIR/bin/forge" init --project . --force
bash "$FORGE_DIR/scripts/forge-doctor.sh" product .
bash "$FORGE_DIR/scripts/forge-status.sh" product .
```

Use `--force` because local command files and adapter shims may still point to the old forge path.

## Verification Matrix

| Check | Scenario 1 | Scenario 2 | Scenario 3 |
|-------|------------|------------|------------|
| `bash scripts/forge-doctor.sh self .` | yes | no | yes |
| `bash scripts/forge-status.sh self .` | yes | no | yes |
| `claude mcp list` | yes | usually no | yes |
| `codex mcp list` | yes if using Codex | usually no | yes if using Codex |
| `forge init --project .` | yes | yes | yes |
| `forge init --project . --force` | maybe | maybe | usually yes |
| Product `forge-doctor.sh product .` | yes | yes | yes |
| Product `forge-status.sh product .` | yes | yes | yes |

## Rules To Remember

- machine-level MCP setup lives outside product repos
- Figma is shared by all products on the same machine
- adding another product is cheap; moving to another machine is not
- if forge changes path, rerun product init or installer refresh
- if doctor/status disagree with CLI reality, doctor/status are wrong and should be fixed
