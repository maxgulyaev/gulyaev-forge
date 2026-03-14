#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash scripts/forge-release-target.sh list <project-dir>
  bash scripts/forge-release-target.sh show <project-dir> <target-name>

Examples:
  bash scripts/forge-release-target.sh list /Users/maxgulyaev/Documents/Dev/spodi
  bash scripts/forge-release-target.sh show /Users/maxgulyaev/Documents/Dev/spodi ios_testflight
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

MODE=${1:-}
TARGET_DIR=${2:-}
TARGET_NAME=${3:-}

if [[ -z "$MODE" || -z "$TARGET_DIR" ]]; then
  usage
  exit 1
fi

TARGET_DIR=$(canonical_repo_root "$TARGET_DIR")
CONFIG="$TARGET_DIR/.forge/config.yaml"

if [[ ! -f "$CONFIG" ]]; then
  printf 'Project config not found: %s\n' "$CONFIG" >&2
  exit 1
fi

case "$MODE" in
  list)
    names=$(collect_release_target_names "$CONFIG")
    if [[ -z "$names" ]]; then
      printf 'No release targets configured\n'
      exit 0
    fi
    printf 'Configured release targets:\n'
    while IFS= read -r name; do
      [[ -n "$name" ]] || continue
      platform=$(read_release_target_scalar "$CONFIG" "$name" "platform")
      channel=$(read_release_target_scalar "$CONFIG" "$name" "channel")
      deploy_stage=$(read_release_target_scalar "$CONFIG" "$name" "deploy_stage")
      printf '  %s -> %s / %s / %s\n' "$name" "${platform:-unknown-platform}" "${channel:-unknown-channel}" "${deploy_stage:-unknown-stage}"
    done <<< "$names"
    ;;
  show)
    if [[ -z "$TARGET_NAME" ]]; then
      usage
      exit 1
    fi
    platform=$(read_release_target_scalar "$CONFIG" "$TARGET_NAME" "platform")
    channel=$(read_release_target_scalar "$CONFIG" "$TARGET_NAME" "channel")
    deploy_stage=$(read_release_target_scalar "$CONFIG" "$TARGET_NAME" "deploy_stage")
    runbook=$(read_release_target_scalar "$CONFIG" "$TARGET_NAME" "runbook")

    if [[ -z "$platform" && -z "$channel" && -z "$deploy_stage" && -z "$runbook" ]]; then
      printf 'Release target not configured: %s\n' "$TARGET_NAME" >&2
      exit 1
    fi

    printf 'Release target:\n'
    printf '  name: %s\n' "$TARGET_NAME"
    printf '  platform: %s\n' "${platform:-}"
    printf '  channel: %s\n' "${channel:-}"
    printf '  deploy_stage: %s\n' "${deploy_stage:-}"
    if [[ -n "$runbook" ]]; then
      printf '  runbook: %s\n' "$runbook"
    fi
    ;;
  *)
    usage
    exit 1
    ;;
esac
