#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash scripts/forge-release-scope.sh show <project-dir> <target-name>
  bash scripts/forge-release-scope.sh dirty <project-dir> <target-name>

Examples:
  bash scripts/forge-release-scope.sh show /Users/maxgulyaev/Documents/Dev/spodi ios_testflight
  bash scripts/forge-release-scope.sh dirty /Users/maxgulyaev/Documents/Dev/spodi web_production
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

default_scope_paths_for_platform() {
  local platform=$1

  case "$platform" in
    ios)
      printf '%s\n' "apps/ios"
      ;;
    android)
      printf '%s\n' "apps/android"
      ;;
    web)
      printf '%s\n' "apps/web,apps/api,deploy,migrations"
      ;;
    *)
      printf '%s\n' ""
      ;;
  esac
}

scope_paths_csv() {
  local config=$1
  local target=$2
  local platform
  local configured

  configured=$(read_release_target_scalar "$config" "$target" "scope_paths")
  if [[ -n "$configured" ]]; then
    printf '%s\n' "$configured"
    return
  fi

  platform=$(read_release_target_scalar "$config" "$target" "platform")
  default_scope_paths_for_platform "$platform"
}

emit_scope_paths() {
  local csv=$1
  printf '%s\n' "$csv" | tr ',' '\n' | sed -E 's/^[[:space:]]*//; s/[[:space:]]*$//' | awk 'NF > 0'
}

matches_scope() {
  local path=$1
  shift
  local prefix

  for prefix in "$@"; do
    [[ -n "$prefix" ]] || continue
    if [[ "$path" == "$prefix" || "$path" == "$prefix/"* ]]; then
      return 0
    fi
  done
  return 1
}

collect_dirty_files() {
  local repo=$1
  {
    git -C "$repo" diff --name-only
    git -C "$repo" diff --cached --name-only
    git -C "$repo" ls-files --others --exclude-standard
  } | awk 'NF > 0' | sort -u
}

MODE=${1:-}
TARGET_DIR=${2:-}
TARGET_NAME=${3:-}

if [[ -z "$MODE" || -z "$TARGET_DIR" || -z "$TARGET_NAME" ]]; then
  usage
  exit 1
fi

TARGET_DIR=$(canonical_repo_root "$TARGET_DIR")
CONFIG="$TARGET_DIR/.forge/config.yaml"

if [[ ! -f "$CONFIG" ]]; then
  printf 'Project config not found: %s\n' "$CONFIG" >&2
  exit 1
fi

scope_csv=$(scope_paths_csv "$CONFIG" "$TARGET_NAME")
if [[ -z "$scope_csv" ]]; then
  printf 'No scope paths configured or inferred for release target: %s\n' "$TARGET_NAME" >&2
  exit 1
fi

scope_prefixes=()
while IFS= read -r prefix; do
  [[ -n "$prefix" ]] || continue
  scope_prefixes+=("$prefix")
done < <(emit_scope_paths "$scope_csv")

case "$MODE" in
  show)
    printf 'Release scope:\n'
    printf '  target: %s\n' "$TARGET_NAME"
    printf '  scope_paths:\n'
    for prefix in "${scope_prefixes[@]}"; do
      printf '    - %s\n' "$prefix"
    done
    ;;
  dirty)
    dirty_any=1
    while IFS= read -r path; do
      [[ -n "$path" ]] || continue
      if matches_scope "$path" "${scope_prefixes[@]}"; then
        if [[ $dirty_any -ne 0 ]]; then
          printf 'Dirty files in release scope:\n'
          dirty_any=0
        fi
        printf '  %s\n' "$path"
      fi
    done < <(collect_dirty_files "$TARGET_DIR")

    if [[ $dirty_any -ne 0 ]]; then
      printf 'No dirty files in release scope\n'
    else
      exit 2
    fi
    ;;
  *)
    usage
    exit 1
    ;;
esac
