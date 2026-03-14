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

default_reviewer_prompt() {
  cat <<'EOF'
Review the current repository change as the forge code-review stage reviewer.

Use these rules:
- Review mindset first: bugs, regressions, missing tests, rollout/process gaps.
- Findings first, ordered by severity.
- Use REVIEW.md and project-local instructions as the review contract.
- Scope yourself to the current diff first. Treat `.forge/active-run.env` or `.forge/pipeline-state.yaml` as context, not as a reason to reload the whole product pipeline.
- Do not run `forge-doctor.sh` or `forge-status.sh` from inside this review handoff.
- Do not read broad strategy/backlog docs unless a concrete finding depends on them.
- Review the current uncommitted change, not the entire product backlog.
- Do not modify repository files. This is a review-only handoff.
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
  local before_status
  local after_status

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
  trap 'rm -f "$output_file" "$log_file"' RETURN

  if ! codex exec \
    -C "$repo_dir" \
    -s workspace-write \
    --ephemeral \
    --color never \
    -o "$output_file" \
    "$prompt" >"$log_file" 2>&1; then
    cat "$log_file" >&2
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
    printf 'Codex reviewer completed without a final message.\n' >&2
    if [[ -s "$log_file" ]]; then
      cat "$log_file" >&2
    fi
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

case "$MODE" in
  show)
    if [[ -z "$ADAPTER" ]]; then
      printf 'No stage agent configured for %s/%s\n' "$STAGE" "$ROLE"
      exit 0
    fi
    printf 'Configured stage agent:\n'
    printf '  stage: %s\n' "$STAGE"
    printf '  role: %s\n' "$ROLE"
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
    printf 'Adapter: %s\n' "$ADAPTER"
    if [[ -n "$PROMPT_FILE" ]]; then
      printf 'Prompt file: %s\n' "$PROMPT_FILE"
    fi
    printf '\n'
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
