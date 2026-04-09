#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash scripts/forge-stage-agent.sh show <project-dir> <stage> <role>
  bash scripts/forge-stage-agent.sh run <project-dir> <stage> <role>

Examples:
  bash scripts/forge-stage-agent.sh show /path/to/project code_review reviewer
  bash scripts/forge-stage-agent.sh run /path/to/project code_review reviewer
EOF
}

trim_quotes() {
  sed -E 's/^[[:space:]]*//; s/[[:space:]]*$//; s/^"//; s/"$//'
}

extract_final_review_from_log() {
  local log_file=$1

  awk '
    /^codex$/ {
      capture = 1
      buffer = ""
      next
    }
    /^Warning: no last agent message/ {
      capture = 0
      next
    }
    capture {
      buffer = buffer $0 ORS
    }
    END {
      printf "%s", buffer
    }
  ' "$log_file"
}

canonical_repo_root() {
  local dir=$1
  if git -C "$dir" rev-parse --show-toplevel >/dev/null 2>&1; then
    git -C "$dir" rev-parse --show-toplevel
  else
    printf '%s\n' "$dir"
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

resolve_transport() {
  local config=$1
  local stage=$2
  local role=$3
  local transport

  transport=$(read_stage_agent_scalar "$config" "$stage" "$role" "transport")
  if [[ -z "$transport" ]]; then
    transport="local_cli"
  fi
  printf '%s\n' "$transport"
}

default_reviewer_prompt() {
  cat <<'EOF'
Review the current repository change as the forge code-review stage reviewer.

Use these rules:
- Review mindset first: bugs, regressions, missing tests, rollout/process gaps.
- Findings first, ordered by severity.
- Use REVIEW.md and project-local instructions as the review contract.
- Check the current issue acceptance criteria explicitly; call out any required item that is still not proven.
- Scope yourself to the current diff first. Treat `.forge/active-run.env` or `.forge/pipeline-state.yaml` as context, not as a reason to reload the whole product pipeline.
- Do not run `forge-doctor.sh` or `forge-status.sh` from inside this review handoff.
- Do not read broad strategy/backlog docs unless a concrete finding depends on them.
- Review the current uncommitted change, not the entire product backlog.
- Do not modify repository files. This is a review-only handoff.
- Treat deploy scripts, shell automation, rollback flow, and runbooks that alter behavior as reviewable implementation, not as "just docs".
- For rollout changes, distinguish liveness/public checks from required authenticated smoke, and distinguish warning-only preflights from blocking guards.
- Flag docs or issue comments that overclaim what the implementation actually does.
- Flag any secret or credential exposure in code, commands, logs, or durable issue/chat artifacts; recommend rotation if exposure happened.
- If there are no findings, say that explicitly and mention residual risks or testing gaps.
- Pay special attention to issue discipline, gate discipline, and docs-sensitive changes.
EOF
}

run_codex_review() {
  local repo_dir=$1
  local prompt_file=$2
  local prompt
  local output_file
  local log_file
  local timeout_flag
  local before_status
  local after_status
  local review_commit=${FORGE_CODE_REVIEW_COMMIT:-}
  local review_base=${FORGE_CODE_REVIEW_BASE:-}
  local timeout_seconds=${FORGE_STAGE_AGENT_TIMEOUT_SECONDS:-900}
  local -a codex_cmd
  local codex_pid=
  local watchdog_pid=
  local cmd_rc=0

  if ! command -v codex >/dev/null 2>&1; then
    printf 'Configured reviewer adapter requires `codex`, but it is not installed in PATH.\n' >&2
    exit 1
  fi

  prompt=$(default_reviewer_prompt)
  if [[ -n "$prompt_file" ]]; then
    if [[ ! -f "$repo_dir/$prompt_file" ]]; then
      printf 'Configured prompt file not found: %s\n' "$repo_dir/$prompt_file" >&2
      exit 1
    fi
    prompt=$(
      {
        printf '%s\n\n' "$prompt"
        printf 'Project-specific reviewer prompt (%s):\n' "$prompt_file"
        cat "$repo_dir/$prompt_file"
      }
    )
  fi

  before_status=$(git -C "$repo_dir" status --porcelain=v1 --untracked-files=all)
  output_file=$(mktemp "${TMPDIR:-/tmp}/forge-codex-review-output.XXXXXX")
  log_file=$(mktemp "${TMPDIR:-/tmp}/forge-codex-review-log.XXXXXX")
  timeout_flag=$(mktemp "${TMPDIR:-/tmp}/forge-codex-review-timeout.XXXXXX")
  rm -f "$timeout_flag"
  trap 'rm -f "$output_file" "$log_file" "$timeout_flag"; if [[ -n "${watchdog_pid:-}" ]]; then kill "$watchdog_pid" 2>/dev/null || true; fi' RETURN

  codex_cmd=(
    codex exec review
    --full-auto
    --ephemeral
    -o "$output_file"
  )

  if [[ -n "$review_commit" ]]; then
    codex_cmd+=(--commit "$review_commit")
  elif [[ -n "$review_base" ]]; then
    codex_cmd+=(--base "$review_base")
  else
    # Auto-detect base: merge-base of HEAD against origin/<branch>.
    # --uncommitted cannot accept a prompt, so prefer --base when possible.
    local auto_base current_branch
    current_branch=$(git -C "$repo_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
    auto_base=$(git -C "$repo_dir" merge-base HEAD "origin/$current_branch" 2>/dev/null || echo "")
    if [[ -n "$auto_base" ]]; then
      codex_cmd+=(--base "$auto_base")
    else
      codex_cmd+=(--uncommitted)
    fi
  fi

  # codex exec review: [PROMPT] is incompatible with --base, --commit, and --uncommitted.
  # When a scope flag is used, codex reads REVIEW.md from the repo automatically.
  # Custom prompt is only passed when no scope flag is set (standalone review).
  if [[ -z "$review_commit" && -z "$review_base" && "${codex_cmd[*]}" != *"--base"* && "${codex_cmd[*]}" != *"--uncommitted"* ]]; then
    codex_cmd+=("$prompt")
  fi

  (
    cd "$repo_dir"
    "${codex_cmd[@]}"
  ) > >(tee "$log_file" >&2) 2>&1 &
  codex_pid=$!

  if [[ "$timeout_seconds" =~ ^[0-9]+$ ]] && (( timeout_seconds > 0 )); then
    (
      sleep "$timeout_seconds"
      if kill -0 "$codex_pid" 2>/dev/null; then
        printf 'timed_out\n' >"$timeout_flag"
        kill "$codex_pid" 2>/dev/null || true
      fi
    ) &
    watchdog_pid=$!
  fi

  set +e
  wait "$codex_pid"
  cmd_rc=$?
  set -e

  if [[ -n "$watchdog_pid" ]]; then
    kill "$watchdog_pid" 2>/dev/null || true
    wait "$watchdog_pid" 2>/dev/null || true
  fi

  if [[ -f "$timeout_flag" ]]; then
    printf 'Codex reviewer timed out after %ss.\n' "$timeout_seconds" >&2
    exit 1
  fi

  if (( cmd_rc != 0 )); then
    exit 1
  fi

  after_status=$(git -C "$repo_dir" status --porcelain=v1 --untracked-files=all)
  if [[ "$after_status" != "$before_status" ]]; then
    printf 'External reviewer modified the working tree; refusing to accept review output.\n' >&2
    printf 'Reviewer worktree drift:\n' >&2
    git -C "$repo_dir" --no-pager diff --stat >&2 || true
    exit 1
  fi

  if [[ ! -s "$output_file" ]]; then
    local fallback_output
    fallback_output=$(extract_final_review_from_log "$log_file")
    if [[ -n "$fallback_output" ]]; then
      printf '%s' "$fallback_output"
      return
    fi
    printf 'Codex reviewer completed without a final message.\n' >&2
    exit 1
  fi

  cat "$output_file"
}

MODE=${1:-}
TARGET=${2:-}
STAGE=${3:-}
ROLE=${4:-}

if [[ -z "$MODE" || -z "$TARGET" || -z "$STAGE" || -z "$ROLE" ]]; then
  usage
  exit 1
fi

TARGET=$(canonical_repo_root "$TARGET")
CONFIG="$TARGET/.forge/config.yaml"

if [[ ! -f "$CONFIG" ]]; then
  printf 'Project config not found: %s\n' "$CONFIG" >&2
  exit 1
fi

ADAPTER=$(read_stage_agent_scalar "$CONFIG" "$STAGE" "$ROLE" "adapter")
PROMPT_FILE=$(read_stage_agent_scalar "$CONFIG" "$STAGE" "$ROLE" "prompt_file")
TRANSPORT=$(resolve_transport "$CONFIG" "$STAGE" "$ROLE")

case "$MODE" in
  show)
    if [[ -z "$ADAPTER" ]]; then
      printf 'No stage agent configured for %s/%s\n' "$STAGE" "$ROLE"
      exit 0
    fi
    printf 'Configured stage agent:\n'
    printf '  stage: %s\n' "$STAGE"
    printf '  role: %s\n' "$ROLE"
    printf '  transport: %s\n' "$TRANSPORT"
    printf '  adapter: %s\n' "$ADAPTER"
    if [[ -n "$PROMPT_FILE" ]]; then
      printf '  prompt_file: %s\n' "$PROMPT_FILE"
    fi
    ;;
  run)
    if [[ -z "$ADAPTER" ]]; then
      printf 'No stage agent configured for %s/%s\n' "$STAGE" "$ROLE"
      exit 0
    fi
    printf '== Stage Agent ==\n'
    printf 'Project: %s\n' "$TARGET"
    printf 'Stage: %s\n' "$STAGE"
    printf 'Role: %s\n' "$ROLE"
    printf 'Transport: %s\n' "$TRANSPORT"
    printf 'Adapter: %s\n' "$ADAPTER"
    if [[ -n "$PROMPT_FILE" ]]; then
      printf 'Prompt file: %s\n' "$PROMPT_FILE"
    fi
    printf '\n'
    if [[ "$TRANSPORT" != "local_cli" ]]; then
      printf 'Configured transport `%s` is not implemented by forge runtime yet.\n' "$TRANSPORT" >&2
      printf 'Current supported transport: local_cli\n' >&2
      exit 1
    fi
    case "$ADAPTER" in
      codex-review)
        run_codex_review "$TARGET" "$PROMPT_FILE"
        ;;
      none)
        printf 'Stage agent explicitly disabled for %s/%s\n' "$STAGE" "$ROLE"
        ;;
      *)
        printf 'Unknown stage agent adapter: %s\n' "$ADAPTER" >&2
        exit 1
        ;;
    esac
    ;;
  *)
    usage
    exit 1
    ;;
esac
