#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash scripts/forge-mcp.sh status
  bash scripts/forge-mcp.sh install playwright
  bash scripts/forge-mcp.sh install github

Examples:
  bash scripts/forge-mcp.sh status
  bash scripts/forge-mcp.sh install playwright
  bash scripts/forge-mcp.sh install github
EOF
}

claude_user_config_file() {
  printf '%s' "${CLAUDE_USER_CONFIG_FILE:-$HOME/.claude.json}"
}

claude_settings_file() {
  printf '%s' "${CLAUDE_SETTINGS_FILE:-$HOME/.claude/settings.json}"
}

playwright_install_dir() {
  printf '%s' "${FORGE_PLAYWRIGHT_MCP_DIR:-$HOME/.claude/mcp/playwright}"
}

playwright_cli_path() {
  printf '%s/node_modules/@playwright/mcp/cli.js' "$(playwright_install_dir)"
}

github_install_dir() {
  printf '%s' "${FORGE_GITHUB_MCP_DIR:-$HOME/.claude/mcp/github}"
}

github_cli_path() {
  printf '%s/node_modules/@modelcontextprotocol/server-github/dist/index.js' "$(github_install_dir)"
}

playwright_json() {
  local cli
  cli=$(playwright_cli_path)

  if [[ -d /Applications/Google\ Chrome.app ]]; then
    printf '{"type":"stdio","command":"node","args":["%s","--browser","chrome"],"env":{}}' "$cli"
  else
    printf '{"type":"stdio","command":"node","args":["%s"],"env":{}}' "$cli"
  fi
}

github_token() {
  local settings
  local token

  if [[ -n "${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ]]; then
    printf '%s' "$GITHUB_PERSONAL_ACCESS_TOKEN"
    return
  fi

  settings=$(claude_settings_file)
  if [[ ! -f "$settings" ]]; then
    return
  fi

  token=$(
    awk '
      /"github"[[:space:]]*:/ { in_github=1 }
      in_github && /"GITHUB_PERSONAL_ACCESS_TOKEN"[[:space:]]*:/ {
        line=$0
        sub(/.*"GITHUB_PERSONAL_ACCESS_TOKEN"[[:space:]]*:[[:space:]]*"/, "", line)
        sub(/".*/, "", line)
        print line
        exit
      }
      in_github && /^[[:space:]]*}[,]?[[:space:]]*$/ { in_github=0 }
    ' "$settings"
  )

  printf '%s' "$token"
}

github_json() {
  local cli
  local token

  cli=$(github_cli_path)
  token=$(github_token)
  printf '{"type":"stdio","command":"node","args":["%s"],"env":{"GITHUB_PERSONAL_ACCESS_TOKEN":"%s"}}' "$cli" "$token"
}

playwright_status_line() {
  if ! command -v claude >/dev/null 2>&1; then
    return 0
  fi

  claude mcp list 2>/dev/null | awk '/^playwright:/ { print; exit }'
}

github_status_line() {
  if ! command -v claude >/dev/null 2>&1; then
    return 0
  fi

  claude mcp list 2>/dev/null | awk '/^github:/ { print; exit }'
}

settings_has_legacy_playwright() {
  local settings
  settings=$(claude_settings_file)
  [[ -f "$settings" ]] && grep -Fq '@anthropic-ai/mcp-server-playwright' "$settings"
}

cmd_status() {
  local user_config
  local settings
  local install_dir
  local cli
  local line
  local github_dir
  local github_cli
  local github_line

  user_config=$(claude_user_config_file)
  settings=$(claude_settings_file)
  install_dir=$(playwright_install_dir)
  cli=$(playwright_cli_path)
  line=$(playwright_status_line || true)
  github_dir=$(github_install_dir)
  github_cli=$(github_cli_path)
  github_line=$(github_status_line || true)

  printf '== Forge MCP status ==\n'
  printf 'Claude user config: %s (%s)\n' "$user_config" "$( [[ -f "$user_config" ]] && printf 'present' || printf 'missing' )"
  printf 'Claude settings: %s (%s)\n' "$settings" "$( [[ -f "$settings" ]] && printf 'present' || printf 'missing' )"
  printf 'Playwright install dir: %s (%s)\n' "$install_dir" "$( [[ -d "$install_dir" ]] && printf 'present' || printf 'missing' )"
  printf 'Playwright CLI: %s (%s)\n' "$cli" "$( [[ -f "$cli" ]] && printf 'present' || printf 'missing' )"
  printf 'GitHub install dir: %s (%s)\n' "$github_dir" "$( [[ -d "$github_dir" ]] && printf 'present' || printf 'missing' )"
  printf 'GitHub CLI: %s (%s)\n' "$github_cli" "$( [[ -f "$github_cli" ]] && printf 'present' || printf 'missing' )"

  if [[ -n "$line" ]]; then
    printf 'Playwright MCP health: %s\n' "$line"
  else
    printf 'Playwright MCP health: playwright not listed\n'
  fi

  if [[ -n "$github_line" ]]; then
    printf 'GitHub MCP health: %s\n' "$github_line"
  else
    printf 'GitHub MCP health: github not listed\n'
  fi

  if settings_has_legacy_playwright; then
    printf 'Warning: %s still contains legacy playwright package @anthropic-ai/mcp-server-playwright\n' "$settings"
  fi
}

cmd_install_playwright() {
  local install_dir
  local cli
  local json

  if ! command -v claude >/dev/null 2>&1; then
    printf 'claude command not found\n' >&2
    exit 1
  fi

  if ! command -v npm >/dev/null 2>&1; then
    printf 'npm command not found\n' >&2
    exit 1
  fi

  install_dir=$(playwright_install_dir)
  mkdir -p "$install_dir"

  if [[ ! -f "$install_dir/package.json" ]]; then
    (
      cd "$install_dir"
      npm init -y >/dev/null
    )
  fi

  (
    cd "$install_dir"
    npm install @playwright/mcp@latest
  )

  cli=$(playwright_cli_path)
  if [[ ! -f "$cli" ]]; then
    printf 'Playwright MCP CLI not found after install: %s\n' "$cli" >&2
    exit 1
  fi

  json=$(playwright_json)

  claude mcp remove -s user playwright >/dev/null 2>&1 || true
  claude mcp add-json -s user playwright "$json" >/dev/null

  printf 'Installed Playwright MCP in %s\n' "$install_dir"
  printf 'Registered user-level Claude MCP entry via ~/.claude.json\n'
  if settings_has_legacy_playwright; then
    printf 'Note: ~/.claude/settings.json still has a legacy playwright entry; keep ~/.claude.json as source of truth or update/remove the old block.\n'
  fi

  cmd_status
}

cmd_install_github() {
  local install_dir
  local cli
  local json
  local token

  if ! command -v claude >/dev/null 2>&1; then
    printf 'claude command not found\n' >&2
    exit 1
  fi

  if ! command -v npm >/dev/null 2>&1; then
    printf 'npm command not found\n' >&2
    exit 1
  fi

  token=$(github_token)
  if [[ -z "$token" ]]; then
    printf 'GitHub token missing. Set GITHUB_PERSONAL_ACCESS_TOKEN or add it to ~/.claude/settings.json first.\n' >&2
    exit 1
  fi

  install_dir=$(github_install_dir)
  mkdir -p "$install_dir"

  if [[ ! -f "$install_dir/package.json" ]]; then
    (
      cd "$install_dir"
      npm init -y >/dev/null
    )
  fi

  (
    cd "$install_dir"
    npm install @modelcontextprotocol/server-github
  )

  cli=$(github_cli_path)
  if [[ ! -f "$cli" ]]; then
    printf 'GitHub MCP CLI not found after install: %s\n' "$cli" >&2
    exit 1
  fi

  json=$(github_json)

  claude mcp remove -s user github >/dev/null 2>&1 || true
  claude mcp add-json -s user github "$json" >/dev/null

  printf 'Installed GitHub MCP in %s\n' "$install_dir"
  printf 'Registered user-level Claude MCP entry via ~/.claude.json\n'

  cmd_status
}

CMD=${1:-}
ARG=${2:-}

case "$CMD" in
  status)
    cmd_status
    ;;
  install)
    case "$ARG" in
      playwright)
        cmd_install_playwright
        ;;
      github)
        cmd_install_github
        ;;
      *)
        usage
        exit 1
        ;;
    esac
    ;;
  ""|-h|--help|help)
    usage
    ;;
  *)
    usage
    exit 1
    ;;
esac
