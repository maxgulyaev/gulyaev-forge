#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash scripts/forge-doctor.sh self [forge-dir]
  bash scripts/forge-doctor.sh product [project-dir]

Examples:
  bash scripts/forge-doctor.sh self .
  bash scripts/forge-doctor.sh product /path/to/project
EOF
}

ok() {
  printf 'OK   %s\n' "$1"
}

warn() {
  printf 'WARN %s\n' "$1"
  WARNINGS=$((WARNINGS + 1))
}

err() {
  printf 'ERR  %s\n' "$1"
  ERRORS=$((ERRORS + 1))
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

collect_stage_names() {
  local file=$1
  awk '
    /^stages:$/ { in_stages=1; next }
    in_stages && /^[^ ]/ { exit }
    in_stages && /^  [a-z_]+:$/ {
      name=$0
      sub(/^  /, "", name)
      sub(/:$/, "", name)
      print name
    }
  ' "$file"
}

collect_required_paths() {
  local file=$1
  awk '
    /^stages:$/ { in_stages=1; next }
    in_stages && /^[^ ]/ { exit }
    in_stages && /^  [a-z_]+:$/ { section=""; next }
    in_stages && /^ {6}required:$/ { section="required"; next }
    in_stages && /^ {6}(if_exists|search):$/ { section=""; next }
    in_stages && section == "required" && /^ {8}- / {
      path=$0
      sub(/^ {8}- /, "", path)
      sub(/[[:space:]]+#.*/, "", path)
      gsub(/^"|"$/, "", path)
      print path
    }
  ' "$file"
}

collect_overlay_files() {
  local dir=$1
  if [[ -d "$dir/.forge/skills" ]]; then
    find "$dir/.forge/skills" -maxdepth 1 -type f ! -name '.DS_Store' | sort
  fi
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

check_self_mcp_server() {
  local settings=$1
  local name=$2
  local key_pattern=$3
  local command_pattern=$4

  if settings_contains "$settings" "$key_pattern" && settings_contains "$settings" "$command_pattern"; then
    ok "Claude MCP configured: $name"
  elif settings_contains "$settings" "$key_pattern"; then
    warn "Claude MCP entry present but command looks unexpected: $name"
  else
    warn "Claude MCP missing: $name"
  fi
}

check_self_mcp_setup() {
  local settings
  settings=$(claude_settings_file)

  if [[ -f "$settings" ]]; then
    ok "Claude settings present: $settings"
  else
    warn "Claude settings missing: $settings"
    return
  fi

  if settings_contains "$settings" '"mcpServers"'; then
    ok "Claude settings define mcpServers"
  else
    warn "Claude settings missing mcpServers block"
  fi

  check_self_mcp_server "$settings" "context7" '"context7"' '@upstash/context7-mcp'
  check_self_mcp_server "$settings" "playwright" '"playwright"' '@anthropic-ai/mcp-server-playwright'
  check_self_mcp_server "$settings" "github" '"github"' '@modelcontextprotocol/server-github'

  if settings_contains "$settings" 'GITHUB_PERSONAL_ACCESS_TOKEN'; then
    ok "Claude GitHub MCP env configured"
  else
    warn "Claude GitHub MCP env missing GITHUB_PERSONAL_ACCESS_TOKEN"
  fi
}

check_stage_agents() {
  local dir=$1
  local config=$2
  local specs
  local stage
  local role
  local adapter
  local prompt_file

  specs=$(collect_stage_agent_specs "$config")

  if [[ -z "$specs" ]]; then
    ok "No stage agents configured"
    return
  fi

  while IFS='|' read -r stage role adapter; do
    [[ -n "$stage" ]] || continue

    case "$adapter" in
      codex-review)
        ok "Stage agent configured: $stage/$role -> $adapter"
        if command -v codex >/dev/null 2>&1; then
          ok "Codex CLI present for $stage/$role"
        else
          warn "$stage/$role uses codex-review but `codex` is not installed"
        fi
        ;;
      none)
        ok "Stage agent explicitly disabled: $stage/$role"
        ;;
      *)
        warn "Unknown stage agent adapter configured for $stage/$role: $adapter"
        ;;
    esac

    prompt_file=$(read_stage_agent_scalar "$config" "$stage" "$role" "prompt_file")
    if [[ -n "$prompt_file" ]]; then
      if [[ -f "$dir/$prompt_file" ]]; then
        ok "Stage agent prompt file present for $stage/$role: $prompt_file"
      else
        warn "Stage agent prompt file missing for $stage/$role: $prompt_file"
      fi
    fi
  done <<< "$specs"
}

check_release_targets() {
  local dir=$1
  local config=$2
  local targets
  local target
  local platform
  local channel
  local deploy_stage
  local runbook
  local runbook_file
  local scope_paths

  targets=$(collect_release_target_names "$config")
  if [[ -z "$targets" ]]; then
    ok "No release targets configured"
    return
  fi

  while IFS= read -r target; do
    [[ -n "$target" ]] || continue
    platform=$(read_release_target_scalar "$config" "$target" "platform")
    channel=$(read_release_target_scalar "$config" "$target" "channel")
    deploy_stage=$(read_release_target_scalar "$config" "$target" "deploy_stage")
    runbook=$(read_release_target_scalar "$config" "$target" "runbook")
    scope_paths=$(read_release_target_scalar "$config" "$target" "scope_paths")

    if [[ -n "$platform" && -n "$channel" && -n "$deploy_stage" ]]; then
      ok "Release target configured: $target -> $platform / $channel / $deploy_stage"
    else
      warn "Release target incomplete: $target (need platform, channel, deploy_stage)"
    fi

    if [[ -n "$runbook" ]]; then
      runbook_file=${runbook%%#*}
      if [[ -f "$dir/$runbook_file" ]]; then
        ok "Release target runbook present for $target: $runbook"
      else
        warn "Release target runbook missing for $target: $runbook"
      fi
    fi

    if [[ -n "$scope_paths" ]]; then
      ok "Release target scope configured for $target: $scope_paths"
    else
      ok "Release target scope inferred by platform for $target"
    fi
  done <<< "$targets"
}

check_qa_tools() {
  local config=$1
  local tools
  local tool
  local enabled
  local use_for

  tools=$(collect_qa_tool_names "$config")
  if [[ -z "$tools" ]]; then
    ok "No QA tools configured"
    return
  fi

  while IFS= read -r tool; do
    [[ -n "$tool" ]] || continue
    enabled=$(read_qa_tool_scalar "$config" "$tool" "enabled")
    use_for=$(read_qa_tool_scalar "$config" "$tool" "use_for")

    if [[ -n "$enabled" ]]; then
      ok "QA tool configured: $tool (enabled=$enabled)"
    else
      warn "QA tool missing enabled flag: $tool"
    fi

    if [[ -n "$use_for" ]]; then
      ok "QA tool use_for configured: $tool -> $use_for"
    else
      warn "QA tool use_for missing: $tool"
    fi

    if [[ "$tool" == "playwright_mcp" ]] && [[ "$enabled" == "true" ]]; then
      if [[ "$use_for" != *"web_feature_qa"* ]]; then
        warn "QA tool playwright_mcp does not include web_feature_qa in use_for"
      fi
    fi
  done <<< "$tools"
}

check_product_hooks() {
  local dir=$1
  local hooks_path

  hooks_path=$(git -C "$dir" config --local --get core.hooksPath 2>/dev/null || true)

  if [[ "$hooks_path" == ".githooks" ]] && [[ -x "$dir/.githooks/pre-push" ]]; then
    ok "Forge pre-push hook installed"
  else
    warn "Forge pre-push hook missing; run bash $SCRIPT_DIR/install-claude-commands.sh product $dir"
  fi

  if [[ -f "$dir/.gitignore" ]] && grep -Fxq ".forge/active-run.env" "$dir/.gitignore"; then
    ok ".forge/active-run.env ignored by git"
  else
    warn ".forge/active-run.env is not ignored; add it to .gitignore"
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

check_labels() {
  local repo_dir=$1
  local config=$2
  local stage_prefix
  local priority_prefix
  local labels

  stage_prefix=$(read_tracking_label_prefix "$config" "stage_prefix")
  priority_prefix=$(read_tracking_label_prefix "$config" "priority_prefix")

  if ! command -v gh >/dev/null 2>&1; then
    warn "GitHub CLI not installed; label validation skipped"
    return
  fi

  if ! labels=$(gh label list --limit 200 --repo "$(git -C "$repo_dir" remote get-url origin 2>/dev/null || true)" 2>/dev/null); then
    warn "Unable to read GitHub labels; label validation skipped"
    return
  fi

  if [[ -n "$stage_prefix" ]] && ! printf '%s\n' "$labels" | awk '{print $1}' | grep -q "^${stage_prefix}"; then
    warn "No GitHub labels found with stage prefix '$stage_prefix'"
  else
    ok "GitHub stage labels match prefix '$stage_prefix'"
  fi

  if [[ -n "$priority_prefix" ]] && ! printf '%s\n' "$labels" | awk '{print $1}' | grep -q "^${priority_prefix}"; then
    warn "No GitHub labels found with priority prefix '$priority_prefix'"
  else
    ok "GitHub priority labels match prefix '$priority_prefix'"
  fi
}

doctor_self() {
  local dir=$1
  local skill
  local stage_skills=(
    strategy
    discovery
    prd
    design
    architecture
    test-plan
    implementation
    test-coverage
    qa
    staging-deploy
    canary-deploy
    product-analytics
    tech-monitoring
  )
  local entry_skills=(
    product-entry
    self-entry
  )
  local self_skills=(
    scout
  )

  printf '== SELF doctor ==\n'
  printf 'Target: %s\n' "$dir"

  [[ -f "$dir/README.md" ]] && ok "README.md present" || err "README.md missing"
  [[ -f "$dir/QUICKSTART.md" ]] && ok "QUICKSTART.md present" || err "QUICKSTART.md missing"
  [[ -f "$dir/docs/design.md" ]] && ok "docs/design.md present" || err "docs/design.md missing"
  [[ -f "$dir/docs/operating-playbook.md" ]] && ok "docs/operating-playbook.md present" || err "docs/operating-playbook.md missing"
  [[ -f "$dir/core/pipeline/orchestrator.md" ]] && ok "core/pipeline/orchestrator.md present" || err "core/pipeline/orchestrator.md missing"
  [[ -f "$dir/core/templates/project-context.yaml" ]] && ok "project context template present" || err "project context template missing"
  [[ -f "$dir/core/templates/CLAUDE.md.template" ]] && ok "CLAUDE.md template present" || err "CLAUDE.md template missing"
  [[ -f "$dir/core/templates/project-overlay-skill.md" ]] && ok "project overlay template present" || err "project overlay template missing"
  [[ -f "$dir/core/templates/project-reviewer-prompt.md" ]] && ok "project reviewer prompt template present" || err "project reviewer prompt template missing"
  [[ -f "$dir/core/templates/pipeline-state.yaml" ]] && ok "pipeline state template present" || err "pipeline state template missing"
  [[ -f "$dir/core/templates/scout-note-template.md" ]] && ok "scout note template present" || err "scout note template missing"
  [[ -f "$dir/core/templates/checkpoint-template.md" ]] && ok "checkpoint template present" || err "checkpoint template missing"
  [[ -f "$dir/core/templates/gate-template.md" ]] && ok "gate template present" || err "gate template missing"
  [[ -f "$dir/scripts/forge-doctor.sh" ]] && ok "forge-doctor.sh present" || err "forge-doctor.sh missing"
  [[ -f "$dir/scripts/forge-status.sh" ]] && ok "forge-status.sh present" || err "forge-status.sh missing"
  [[ -f "$dir/scripts/forge-init.sh" ]] && ok "forge-init.sh present" || err "forge-init.sh missing"
  [[ -f "$dir/scripts/forge-stage-agent.sh" ]] && ok "forge-stage-agent.sh present" || err "forge-stage-agent.sh missing"
  [[ -f "$dir/scripts/forge-release-target.sh" ]] && ok "forge-release-target.sh present" || err "forge-release-target.sh missing"
  [[ -f "$dir/scripts/forge-release-scope.sh" ]] && ok "forge-release-scope.sh present" || err "forge-release-scope.sh missing"
  [[ -f "$dir/scripts/forge-issue-trail.sh" ]] && ok "forge-issue-trail.sh present" || err "forge-issue-trail.sh missing"
  [[ -f "$dir/bin/forge" ]] && ok "bin/forge present" || err "bin/forge missing"

  for skill in "${stage_skills[@]}"; do
    if [[ -f "$dir/core/skills/$skill/SKILL.md" ]]; then
      ok "Stage skill present: $skill"
    else
      err "Stage skill missing: $skill"
    fi
  done

  for skill in "${entry_skills[@]}"; do
    if [[ -f "$dir/core/skills/$skill/SKILL.md" ]]; then
      ok "Entry skill present: $skill"
    else
      err "Entry skill missing: $skill"
    fi
  done

  for skill in "${self_skills[@]}"; do
    if [[ -f "$dir/core/skills/$skill/SKILL.md" ]]; then
      ok "Self skill present: $skill"
    else
      err "Self skill missing: $skill"
    fi
  done

  check_self_mcp_setup
}

doctor_product() {
  local dir=$1
  local config="$dir/.forge/config.yaml"
  local state="$dir/.forge/pipeline-state.yaml"
  local project_name
  local issue
  local issue_labels
  local stage_prefix
  local stage
  local gate_status
  local missing_stage
  local expected_stages=(
    strategy
    discovery
    prd
    design
    architecture
    test_plan
    implementation
    code_review
    test_coverage
    qa
    staging_deploy
    canary_deploy
    product_analytics
    tech_monitoring
  )

  printf '== PRODUCT doctor ==\n'
  printf 'Target: %s\n' "$dir"

  [[ -f "$config" ]] && ok ".forge/config.yaml present" || err ".forge/config.yaml missing"
  [[ -f "$dir/CLAUDE.md" ]] && ok "CLAUDE.md present" || err "CLAUDE.md missing"

  if [[ -f "$config" ]]; then
    project_name=$(read_project_name "$config")
    [[ -n "$project_name" ]] && ok "Project name: $project_name" || warn "Project name not set in .forge/config.yaml"

    while IFS= read -r path; do
      [[ -z "$path" ]] && continue
      if [[ -f "$dir/$path" || -d "$dir/$path" ]]; then
        ok "Required path exists: $path"
      else
        err "Required path missing: $path"
      fi
    done < <(collect_required_paths "$config" | sort -u)

    for stage in "${expected_stages[@]}"; do
      missing_stage=1
      while IFS= read -r configured_stage; do
        if [[ "$configured_stage" == "$stage" ]]; then
          missing_stage=0
          break
        fi
      done < <(collect_stage_names "$config")

      if [[ "$missing_stage" == "1" ]]; then
        warn "Stage config missing: $stage"
      fi
    done

    check_labels "$dir" "$config"
    stage_prefix=$(read_tracking_label_prefix "$config" "stage_prefix")
  fi

  if [[ -f "$dir/REVIEW.md" ]]; then
    ok "REVIEW.md present"
  else
    warn "REVIEW.md missing; code review stage will have weaker project-specific rules"
  fi

  if [[ -f "$state" ]]; then
    ok "pipeline-state.yaml present"
    issue=$(read_top_level_scalar "$state" "issue")
    stage=$(read_top_level_scalar "$state" "current_stage")
    gate_status=$(read_top_level_scalar "$state" "current_gate_status")
    if [[ -n "$issue" ]] && command -v gh >/dev/null 2>&1; then
      if gh issue view "$issue" --repo "$(git -C "$dir" remote get-url origin 2>/dev/null || true)" >/dev/null 2>&1; then
        ok "Current pipeline issue exists: #$issue"
        issue_labels=$(gh issue view "$issue" \
          --repo "$(git -C "$dir" remote get-url origin 2>/dev/null || true)" \
          --json labels \
          --jq '.labels | map(.name) | join(",")' 2>/dev/null || true)
        if [[ -n "$stage_prefix" ]] && [[ -n "$stage" ]]; then
          if [[ "$issue_labels" == *"${stage_prefix}$(stage_name "$stage")"* ]]; then
            ok "Issue stage label matches current_stage"
          else
            warn "Issue stage label does not match current_stage (${stage_prefix}$(stage_name "$stage") expected)"
          fi
        fi
      else
        warn "Current pipeline issue not accessible via gh: #$issue"
      fi
    fi
    if is_gated_stage "$stage"; then
      case "$gate_status" in
        pending_approval|approved|approved_with_changes|rejected)
          ok "current_gate_status set for gated stage: $gate_status"
          ;;
        "")
          warn "current_gate_status missing for gated stage $(stage_name "$stage"); agents should treat it as pending approval"
          ;;
        *)
          warn "current_gate_status has unexpected value: $gate_status"
          ;;
      esac
    fi
  else
    warn "pipeline-state.yaml missing"
  fi

  if [[ -d "$dir/.forge/skills" ]]; then
    ok "Project overlay skills directory present"
    while IFS= read -r file; do
      [[ -n "$file" ]] && printf '     overlay: %s\n' "${file#$dir/}"
    done < <(collect_overlay_files "$dir")
  else
    warn ".forge/skills missing; no project overlay skills found"
  fi

  check_stage_agents "$dir" "$config"
  check_qa_tools "$config"
  check_release_targets "$dir" "$config"
  check_product_hooks "$dir"
}

MODE=${1:-}
TARGET=${2:-.}
WARNINGS=0
ERRORS=0

if [[ -z "$MODE" ]]; then
  usage
  exit 1
fi

if [[ ! -d "$TARGET" ]]; then
  printf 'ERR  Target directory not found: %s\n' "$TARGET"
  exit 1
fi

TARGET=$(cd "$TARGET" && pwd -P)

case "$MODE" in
  self)
    doctor_self "$TARGET"
    ;;
  product)
    doctor_product "$TARGET"
    ;;
  *)
    usage
    exit 1
    ;;
esac

printf '\n'
printf 'Summary: %s error(s), %s warning(s)\n' "$ERRORS" "$WARNINGS"

if [[ "$ERRORS" -gt 0 ]]; then
  exit 1
fi
