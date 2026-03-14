#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash scripts/forge-issue-trail.sh show-bugfix <project-dir> <issue-number>
  bash scripts/forge-issue-trail.sh check-bugfix-qa <project-dir> <issue-number>
  bash scripts/forge-issue-trail.sh check-bugfix-ship <project-dir> <issue-number>
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

read_project_repo() {
  local file=$1
  awk '
    /^project:$/ { in_project=1; next }
    in_project && /^[^ ]/ { exit }
    in_project && /^  repo:/ {
      sub("^[^:]+:[[:space:]]*", "", $0)
      sub(/[[:space:]]+#.*/, "", $0)
      print $0
      exit
    }
  ' "$file" | trim_quotes
}

normalize_github_repo() {
  local value=$1
  value=${value#https://github.com/}
  value=${value#http://github.com/}
  value=${value#git@github.com:}
  value=${value%.git}
  printf '%s\n' "$value"
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

require_github_context() {
  local config=$1
  local repo_url

  if ! command -v gh >/dev/null 2>&1; then
    printf 'GitHub CLI is required for issue trail checks\n' >&2
    exit 1
  fi

  repo_url=$(read_project_repo "$config")
  if [[ -z "$repo_url" ]]; then
    printf 'Project repo URL missing in %s\n' "$config" >&2
    exit 1
  fi

  GH_REPO=$(normalize_github_repo "$repo_url")
  if [[ -z "$GH_REPO" ]]; then
    printf 'Could not normalize GitHub repo from %s\n' "$repo_url" >&2
    exit 1
  fi
}

collect_issue_comments() {
  local repo=$1
  local issue=$2

  gh issue view "$issue" --repo "$repo" --json comments --jq '.comments[].body'
}

has_regex() {
  local text=$1
  local regex=$2
  printf '%s\n' "$text" | grep -E -q "$regex"
}

report_trail_state() {
  local issue=$1
  local review_required=$2
  local comments=$3
  local qa_present=no
  local review_present=no
  local approval_present=no

  if has_regex "$comments" '(^## QA Gate|QA Gate —)'; then
    qa_present=yes
  fi
  if has_regex "$comments" '(^## Stage 6\.5|Stage 6\.5 — External Code Review)'; then
    review_present=yes
  fi
  if has_regex "$comments" '/gate approved(_with_changes)?'; then
    approval_present=yes
  fi

  printf 'Bugfix trail:\n'
  printf '  issue: #%s\n' "$issue"
  printf '  QA gate comment: %s\n' "$qa_present"
  printf '  Stage 6.5 review required: %s\n' "$review_required"
  printf '  Stage 6.5 review comment: %s\n' "$review_present"
  printf '  Gate approval recorded: %s\n' "$approval_present"
}

MODE=${1:-}
TARGET=${2:-}
ISSUE=${3:-}

if [[ -z "$MODE" || -z "$TARGET" || -z "$ISSUE" ]]; then
  usage
  exit 1
fi

TARGET=$(canonical_repo_root "$TARGET")
CONFIG="$TARGET/.forge/config.yaml"

if [[ ! -f "$CONFIG" ]]; then
  printf 'Project config not found: %s\n' "$CONFIG" >&2
  exit 1
fi

require_github_context "$CONFIG"
COMMENTS=$(collect_issue_comments "$GH_REPO" "$ISSUE")
REVIEW_ADAPTER=$(read_stage_agent_scalar "$CONFIG" "code_review" "reviewer" "adapter")
REVIEW_REQUIRED=no
if [[ -n "$REVIEW_ADAPTER" && "$REVIEW_ADAPTER" != "none" ]]; then
  REVIEW_REQUIRED=yes
fi

QA_PRESENT=no
REVIEW_PRESENT=no
APPROVAL_PRESENT=no

if has_regex "$COMMENTS" '(^## QA Gate|QA Gate —)'; then
  QA_PRESENT=yes
fi
if has_regex "$COMMENTS" '(^## Stage 6\.5|Stage 6\.5 — External Code Review)'; then
  REVIEW_PRESENT=yes
fi
if has_regex "$COMMENTS" '/gate approved(_with_changes)?'; then
  APPROVAL_PRESENT=yes
fi

case "$MODE" in
  show-bugfix)
    report_trail_state "$ISSUE" "$REVIEW_REQUIRED" "$COMMENTS"
    ;;
  check-bugfix-qa)
    if [[ "$QA_PRESENT" != "yes" ]]; then
      printf 'Missing durable QA gate comment for bugfix issue #%s\n' "$ISSUE" >&2
      exit 1
    fi
    if [[ "$REVIEW_REQUIRED" == "yes" && "$REVIEW_PRESENT" != "yes" ]]; then
      printf 'Missing durable Stage 6.5 review comment for bugfix issue #%s\n' "$ISSUE" >&2
      exit 1
    fi
    printf 'Bugfix QA trail present for issue #%s\n' "$ISSUE"
    ;;
  check-bugfix-ship)
    if [[ "$QA_PRESENT" != "yes" ]]; then
      printf 'Missing durable QA gate comment for bugfix issue #%s\n' "$ISSUE" >&2
      exit 1
    fi
    if [[ "$REVIEW_REQUIRED" == "yes" && "$REVIEW_PRESENT" != "yes" ]]; then
      printf 'Missing durable Stage 6.5 review comment for bugfix issue #%s\n' "$ISSUE" >&2
      exit 1
    fi
    if [[ "$APPROVAL_PRESENT" != "yes" ]]; then
      printf 'Missing durable /gate approved comment for bugfix issue #%s\n' "$ISSUE" >&2
      exit 1
    fi
    printf 'Bugfix ship trail present for issue #%s\n' "$ISSUE"
    ;;
  *)
    usage
    exit 1
    ;;
esac
