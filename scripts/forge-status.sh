#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash scripts/forge-status.sh self [forge-dir]
  bash scripts/forge-status.sh product [project-dir]

Examples:
  bash scripts/forge-status.sh self .
  bash scripts/forge-status.sh product /Users/maxgulyaev/Documents/Dev/spodi
EOF
}

trim_quotes() {
  sed -E 's/^[[:space:]]*//; s/[[:space:]]*$//; s/^"//; s/"$//'
}

read_top_level_scalar() {
  local file=$1
  local key=$2
  awk -v key="$key" '
    $0 ~ "^" key ":" {
      sub("^[^:]+:[[:space:]]*", "", $0)
      sub(/[[:space:]]+#.*/, "", $0)
      print $0
      exit
    }
  ' "$file" | trim_quotes
}

read_project_name() {
  local file=$1
  awk '
    /^project:$/ { in_project=1; next }
    in_project && /^[^ ]/ { exit }
    in_project && /^  name:/ {
      sub("^[^:]+:[[:space:]]*", "", $0)
      sub(/[[:space:]]+#.*/, "", $0)
      print $0
      exit
    }
  ' "$file" | trim_quotes
}

read_tracking_label_prefix() {
  local file=$1
  local key=$2
  awk -v key="$key" '
    /^tracking:$/ { in_tracking=1; next }
    in_tracking && /^[^ ]/ { exit }
    in_tracking && /^  labels:$/ { in_labels=1; next }
    in_tracking && /^  [a-z_]+:/ && $0 !~ /^  labels:$/ { in_labels=0 }
    in_labels && $0 ~ ("^    " key ":") {
      sub("^[^:]+:[[:space:]]*", "", $0)
      sub(/[[:space:]]+#.*/, "", $0)
      print $0
      exit
    }
  ' "$file" | trim_quotes
}

read_stage_agent_scalar() {
  local file=$1
  local stage=$2
  local role=$3
  local key=$4
  awk -v stage="$stage" -v role="$role" -v key="$key" '
    /^stage_agents:$/ { in_agents=1; next }
    in_agents && /^[^ ]/ { in_agents=0; in_stage=0; in_role=0 }
    in_agents && $0 ~ ("^  " stage ":$") { in_stage=1; in_role=0; next }
    in_agents && /^  [a-z_]+:$/ && $0 !~ ("^  " stage ":$") { in_stage=0; in_role=0 }
    in_stage && $0 ~ ("^    " role ":$") { in_role=1; next }
    in_stage && /^    [a-z_]+:$/ && $0 !~ ("^    " role ":$") { in_role=0 }
    in_role && $0 ~ ("^      " key ":") {
      sub("^[^:]+:[[:space:]]*", "", $0)
      sub(/[[:space:]]+#.*/, "", $0)
      print $0
      exit
    }
  ' "$file" | trim_quotes
}

read_release_target_scalar() {
  local file=$1
  local target=$2
  local key=$3
  awk -v target="$target" -v key="$key" '
    /^release_targets:$/ { in_targets=1; next }
    in_targets && /^[^ ]/ { in_targets=0; in_target=0 }
    in_targets && $0 ~ ("^  " target ":$") { in_target=1; next }
    in_targets && /^  [A-Za-z0-9_]+:$/ && $0 !~ ("^  " target ":$") { in_target=0 }
    in_target && $0 ~ ("^    " key ":") {
      sub("^[^:]+:[[:space:]]*", "", $0)
      sub(/[[:space:]]+#.*/, "", $0)
      print $0
      exit
    }
  ' "$file" | trim_quotes
}

read_qa_tool_scalar() {
  local file=$1
  local tool=$2
  local key=$3
  awk -v tool="$tool" -v key="$key" '
    /^qa_tools:$/ { in_tools=1; next }
    in_tools && /^[^ ]/ { in_tools=0; in_tool=0 }
    in_tools && $0 ~ ("^  " tool ":$") { in_tool=1; next }
    in_tools && /^  [A-Za-z0-9_]+:$/ && $0 !~ ("^  " tool ":$") { in_tool=0 }
    in_tool && $0 ~ ("^    " key ":") {
      sub("^[^:]+:[[:space:]]*", "", $0)
      sub(/[[:space:]]+#.*/, "", $0)
      print $0
      exit
    }
  ' "$file" | trim_quotes
}

collect_qa_tool_names() {
  local file=$1
  awk '
    /^qa_tools:$/ { in_tools=1; next }
    in_tools && /^[^ ]/ { exit }
    in_tools && /^  [A-Za-z0-9_]+:$/ {
      name=$1
      sub(/:$/, "", name)
      print name
    }
  ' "$file"
}

collect_release_target_names() {
  local file=$1
  awk '
    /^release_targets:$/ { in_targets=1; next }
    in_targets && /^[^ ]/ { exit }
    in_targets && /^  [A-Za-z0-9_]+:$/ {
      name=$1
      sub(/:$/, "", name)
      print name
    }
  ' "$file"
}

collect_stage_agent_specs() {
  local file=$1
  awk '
    /^stage_agents:$/ { in_agents=1; next }
    in_agents && /^[^ ]/ { exit }
    in_agents && /^  [a-z_]+:$/ {
      stage=$1
      sub(/:$/, "", stage)
      next
    }
    in_agents && /^    [a-z_]+:$/ {
      role=$1
      sub(/:$/, "", role)
      next
    }
    in_agents && /^      adapter:/ {
      adapter=$0
      sub("^[^:]+:[[:space:]]*", "", adapter)
      sub(/[[:space:]]+#.*/, "", adapter)
      gsub(/^"|"$/, "", adapter)
      print stage "|" role "|" adapter
    }
  ' "$file"
}

claude_settings_file() {
  printf '%s' "${CLAUDE_SETTINGS_FILE:-$HOME/.claude/settings.json}"
}

settings_contains() {
  local file=$1
  local pattern=$2
  [[ -f "$file" ]] && grep -Fq "$pattern" "$file"
}

print_self_mcp_status() {
  local settings
  settings=$(claude_settings_file)

  printf '\nClaude MCP:\n'
  if [[ -f "$settings" ]]; then
    printf '  settings: present (%s)\n' "$settings"
  else
    printf '  settings: missing (%s)\n' "$settings"
    return
  fi

  if settings_contains "$settings" '"context7"' && settings_contains "$settings" '@upstash/context7-mcp'; then
    printf '  context7: configured\n'
  else
    printf '  context7: missing\n'
  fi

  if settings_contains "$settings" '"playwright"' && settings_contains "$settings" '@anthropic-ai/mcp-server-playwright'; then
    printf '  playwright: configured\n'
  else
    printf '  playwright: missing\n'
  fi

  if settings_contains "$settings" '"github"' && settings_contains "$settings" '@modelcontextprotocol/server-github'; then
    printf '  github: configured\n'
  else
    printf '  github: missing\n'
  fi

  if settings_contains "$settings" 'GITHUB_PERSONAL_ACCESS_TOKEN'; then
    printf '  github env: configured\n'
  else
    printf '  github env: missing\n'
  fi

  if settings_contains "$settings" '"figma"' && settings_contains "$settings" 'https://mcp.figma.com/mcp'; then
    printf '  figma: configured\n'
  else
    printf '  figma: missing\n'
  fi
}

stage_name() {
  case "$1" in
    0) printf 'strategy' ;;
    1) printf 'discovery' ;;
    2) printf 'prd' ;;
    3) printf 'design' ;;
    4) printf 'architecture' ;;
    5) printf 'test_plan' ;;
    6) printf 'implementation' ;;
    6.5) printf 'code_review' ;;
    7) printf 'test_coverage' ;;
    8) printf 'qa' ;;
    9) printf 'staging_deploy' ;;
    10) printf 'canary_deploy' ;;
    11) printf 'product_analytics' ;;
    12) printf 'tech_monitoring' ;;
    *) printf '%s' "$1" ;;
  esac
}

load_active_run() {
  local file=$1
  if [[ ! -f "$file" ]]; then
    return 1
  fi

  FORGE_RUN_KIND=$(decode_active_run_value "$(read_active_run_value "$file" "FORGE_RUN_KIND")")
  FORGE_RUN_ISSUE=$(decode_active_run_value "$(read_active_run_value "$file" "FORGE_RUN_ISSUE")")
  FORGE_RUN_TITLE=$(decode_active_run_value "$(read_active_run_value "$file" "FORGE_RUN_TITLE")")
  FORGE_RUN_STAGE=$(decode_active_run_value "$(read_active_run_value "$file" "FORGE_RUN_STAGE")")
  FORGE_RUN_GATE_STATUS=$(decode_active_run_value "$(read_active_run_value "$file" "FORGE_RUN_GATE_STATUS")")
  FORGE_RUN_CONTEXT7_USED=$(decode_active_run_value "$(read_active_run_value "$file" "FORGE_RUN_CONTEXT7_USED")")
  FORGE_RUN_CONTEXT7_REASON=$(decode_active_run_value "$(read_active_run_value "$file" "FORGE_RUN_CONTEXT7_REASON")")
  FORGE_RUN_CREATED_AT=$(decode_active_run_value "$(read_active_run_value "$file" "FORGE_RUN_CREATED_AT")")
  FORGE_RUN_UPDATED_AT=$(decode_active_run_value "$(read_active_run_value "$file" "FORGE_RUN_UPDATED_AT")")
}

read_active_run_value() {
  local file=$1
  local key=$2
  awk -v key="$key" '
    index($0, key "=") == 1 {
      print substr($0, length(key) + 2)
      exit
    }
  ' "$file"
}

decode_active_run_value() {
  local value=${1-}

  if [[ "$value" == \$\'*\' ]] && [[ "$value" == *"'" ]]; then
    value=${value#\$\'}
    value=${value%\'}
  fi

  value=${value//\\ / }
  value=${value//\\,/,}
  value=${value//\\\'/\'}
  value=${value//\\\\/\\}
  printf '%s' "$value"
}

is_gated_stage() {
  case "$(stage_name "$1")" in
    strategy|discovery|prd|design|architecture|implementation|qa|canary_deploy|product_analytics|tech_monitoring)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

print_product_status() {
  local dir=$1
  local config="$dir/.forge/config.yaml"
  local state="$dir/.forge/pipeline-state.yaml"
  local project_name='-'
  local feature='-'
  local stage='-'
  local stage_prefix='stage/'
  local gate_status=''
  local stage_artifact=''
  local issue='-'
  local issue_summary=''
  local active_run="$dir/.forge/active-run.env"
  local stage_agents=''
  local release_targets=''
  local qa_tools=''
  local scope_paths=''
  local stage_sync_ok=1
  local immediate_next_action=''

  printf '== PRODUCT status ==\n'
  printf 'Project dir: %s\n' "$dir"

  if [[ -f "$config" ]]; then
    project_name=$(read_project_name "$config")
    stage_prefix=$(read_tracking_label_prefix "$config" "stage_prefix")
    stage_agents=$(collect_stage_agent_specs "$config")
    qa_tools=$(collect_qa_tool_names "$config")
    release_targets=$(collect_release_target_names "$config")
  fi

  if [[ -f "$state" ]]; then
    feature=$(read_top_level_scalar "$state" "current_feature")
    stage=$(read_top_level_scalar "$state" "current_stage")
    gate_status=$(read_top_level_scalar "$state" "current_gate_status")
    stage_artifact=$(read_top_level_scalar "$state" "current_stage_artifact")
    issue=$(read_top_level_scalar "$state" "issue")
  fi

  [[ -n "$project_name" ]] || project_name='-'
  [[ -n "$feature" ]] || feature='-'
  [[ -n "$issue" ]] || issue='-'

  printf 'Project: %s\n' "$project_name"
  printf 'Current feature: %s\n' "$feature"
  if [[ -n "$stage" ]]; then
    printf 'Current stage: %s (%s)\n' "$stage" "$(stage_name "$stage")"
  else
    printf 'Current stage: -\n'
  fi
  if [[ -n "$stage_artifact" ]]; then
    printf 'Current artifact: %s\n' "$stage_artifact"
  fi
  if is_gated_stage "$stage"; then
    if [[ -z "$gate_status" ]]; then
      gate_status='unknown (treat as pending_approval)'
    fi
    printf 'Gate status: %s\n' "$gate_status"
  fi
  if [[ "$issue" == "-" ]]; then
    printf 'Issue: -\n'
  else
    printf 'Issue: #%s\n' "$issue"
  fi

  if load_active_run "$active_run"; then
    printf '\nActive quick run:\n'
    printf '  kind: %s\n' "${FORGE_RUN_KIND:-unknown}"
    printf '  issue: #%s\n' "${FORGE_RUN_ISSUE:-unknown}"
    printf '  title: %s\n' "${FORGE_RUN_TITLE:-}"
    printf '  stage: %s\n' "${FORGE_RUN_STAGE:-unknown}"
    printf '  gate: %s\n' "${FORGE_RUN_GATE_STATUS:-none}"
    printf '  Context7 used: %s\n' "${FORGE_RUN_CONTEXT7_USED:-unknown}"
    if [[ -n "${FORGE_RUN_CONTEXT7_REASON:-}" ]]; then
      printf '  Context7 reason: %s\n' "${FORGE_RUN_CONTEXT7_REASON}"
    fi
    if [[ "${FORGE_RUN_KIND:-}" == "bugfix" ]] && { [[ ! "${FORGE_RUN_STAGE:-}" =~ ^(qa|done)$ ]] || [[ ! "${FORGE_RUN_GATE_STATUS:-}" =~ ^(approved|approved_with_changes)$ ]]; }; then
      printf '  push guard: active until QA gate approval is recorded\n'
      immediate_next_action='continue the active bugfix quick run before resuming the unrelated feature pipeline'
    fi
  fi

  if [[ -n "$stage_agents" ]]; then
    printf '\nStage agents:\n'
    while IFS='|' read -r agent_stage agent_role agent_adapter; do
      [[ -n "$agent_stage" ]] || continue
      printf '  %s/%s -> %s\n' "$agent_stage" "$agent_role" "$agent_adapter"
    done <<< "$stage_agents"
  fi

  if [[ -n "$qa_tools" ]]; then
    printf '\nQA tools:\n'
    while IFS= read -r tool; do
      [[ -n "$tool" ]] || continue
      enabled=$(read_qa_tool_scalar "$config" "$tool" "enabled")
      use_for=$(read_qa_tool_scalar "$config" "$tool" "use_for")
      scope_paths=$(read_qa_tool_scalar "$config" "$tool" "scope_paths")
      printf '  %s -> enabled=%s\n' "$tool" "${enabled:-unknown}"
      if [[ -n "$use_for" ]]; then
        printf '    use_for: %s\n' "$use_for"
      fi
      if [[ -n "$scope_paths" ]]; then
        printf '    scope_paths: %s\n' "$scope_paths"
      fi
    done <<< "$qa_tools"
  fi

  if [[ -n "$release_targets" ]]; then
    printf '\nRelease targets:\n'
    while IFS= read -r target; do
      [[ -n "$target" ]] || continue
      platform=$(read_release_target_scalar "$config" "$target" "platform")
      channel=$(read_release_target_scalar "$config" "$target" "channel")
      deploy_stage=$(read_release_target_scalar "$config" "$target" "deploy_stage")
      scope_paths=$(read_release_target_scalar "$config" "$target" "scope_paths")
      printf '  %s -> %s / %s / %s\n' "$target" "${platform:-unknown-platform}" "${channel:-unknown-channel}" "${deploy_stage:-unknown-stage}"
      if [[ -n "$scope_paths" ]]; then
        printf '    scope_paths: %s\n' "$scope_paths"
      fi
    done <<< "$release_targets"
  fi

  if [[ "$issue" != "-" ]] && command -v gh >/dev/null 2>&1; then
    issue_summary=$(gh issue view "$issue" \
      --repo "$(git -C "$dir" remote get-url origin 2>/dev/null || true)" \
      --json number,title,state,labels \
      --jq '"#\(.number) [\(.state)] \(.title) | labels: \(.labels | map(.name) | join(", "))"' \
      2>/dev/null || true)
    if [[ -n "$issue_summary" ]]; then
      printf 'Issue status: %s\n' "$issue_summary"
      if [[ -n "$stage_prefix" ]] && [[ "$issue_summary" != *"${stage_prefix}$(stage_name "$stage")"* ]]; then
        printf 'Stage sync warning: issue labels do not match local current_stage (%s%s expected)\n' "$stage_prefix" "$(stage_name "$stage")"
        stage_sync_ok=0
      fi
    fi
  fi

  if is_gated_stage "$stage"; then
    printf '\nGate discipline:\n'
    printf '  - do not advance past %s until approval is recorded\n' "$(stage_name "$stage")"
    printf '  - issue comment commands: /gate approved | /gate approved_with_changes | /gate rejected\n'
    printf '  - if approval was given in chat, mirror it to the issue before changing labels/state\n'
  fi

  if [[ -z "$immediate_next_action" ]]; then
    if [[ "$stage_sync_ok" -eq 0 ]]; then
      immediate_next_action='reconcile issue stage label and .forge/pipeline-state.yaml before continuing'
    elif is_gated_stage "$stage" && [[ "$gate_status" =~ ^(pending_approval|unknown) ]]; then
      immediate_next_action='record the current gate decision via /forge:continue or /forge:gate before advancing'
    elif [[ -n "$stage" ]] && [[ "$stage" != "-" ]]; then
      immediate_next_action="continue the current ${stage} stage; no gate is needed right now, so expect an explicit checkpoint with the exact next step"
    fi
  fi

  if [[ -n "$immediate_next_action" ]]; then
    printf '\nImmediate next action:\n'
    printf '  - %s\n' "$immediate_next_action"
  fi

  if [[ -f "$state" ]]; then
    printf '\nProgress cache: %s\n' "${state#$dir/}"
    awk '
    /^stages_completed:$/ { in_completed=1; print "Completed stages:"; next }
    /^stages_skipped:$/ { in_completed=0; in_skipped=1; print "Skipped stages:"; next }
    in_completed || in_skipped { print "  " $0 }
    ' "$state"
  else
    printf '\nProgress cache: missing (.forge/pipeline-state.yaml)\n'
  fi

  if [[ -d "$dir/.forge/skills" ]]; then
    printf '\nProject overlays:\n'
    find "$dir/.forge/skills" -maxdepth 1 -type f ! -name '.DS_Store' -print | sort | sed "s#^$dir/##; s#^#  #"
  fi

  printf '\nTrack progress in:\n'
  printf '  - GitHub issue labels/comments\n'
  printf '  - .forge/pipeline-state.yaml\n'
  printf '  - docs artifacts for the current stage\n'
}

print_self_status() {
  local dir=$1
  local branch='-'
  local dirty='-'
  local pending='0'

  printf '== SELF status ==\n'
  printf 'Forge dir: %s\n' "$dir"

  if git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD)
    dirty=$(git -C "$dir" status --short | wc -l | tr -d ' ')
  fi

  printf 'Branch: %s\n' "$branch"
  printf 'Dirty paths: %s\n' "$dirty"

  printf '\nRecent commits:\n'
  git -C "$dir" log --oneline -n 5 | sed 's/^/  /'

  printf '\nForge tooling:\n'
  if [[ -f "$dir/bin/forge" ]]; then
    printf '  bin/forge: present\n'
  else
    printf '  bin/forge: missing\n'
  fi
  if [[ -f "$dir/scripts/forge-init.sh" ]]; then
    printf '  forge init: present\n'
  else
    printf '  forge init: missing\n'
  fi

  print_self_mcp_status

  printf '\nRoadmap focus:\n'
  pending=$(awk '
    /^### Phase 0:/ { in_roadmap=1 }
    /^## Open Questions/ { in_roadmap=0 }
    in_roadmap && /^- \[ \]/ { count += 1 }
    END { print count + 0 }
  ' "$dir/docs/design.md")
  printf '  Pending roadmap tasks: %s\n' "$pending"
  awk '
    /^### Phase 0:/ { in_roadmap=1 }
    /^## Open Questions/ { in_roadmap=0 }
    in_roadmap && /^- \[ \]/ { print "  " $0 }
  ' "$dir/docs/design.md" | sed -n '1,8p'

  printf '\nTrack progress in:\n'
  printf '  - docs/design.md roadmap checklists\n'
  printf '  - git status / git log\n'
  printf '  - project pilot state in the target repo (for example Spodi)\n'
}

MODE=${1:-}
TARGET=${2:-.}

if [[ -z "$MODE" ]]; then
  usage
  exit 1
fi

if [[ ! -d "$TARGET" ]]; then
  printf 'Target directory not found: %s\n' "$TARGET"
  exit 1
fi

TARGET=$(cd "$TARGET" && pwd -P)

case "$MODE" in
  self)
    print_self_status "$TARGET"
    ;;
  product)
    print_product_status "$TARGET"
    ;;
  *)
    usage
    exit 1
    ;;
esac
