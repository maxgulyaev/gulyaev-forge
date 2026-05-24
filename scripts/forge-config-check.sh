#!/usr/bin/env bash
# forge-config-check.sh — validate path references in .forge/config.yaml
#
# Built for Agent-Ready 2026 program W1.7 (codex W0 P1.5 fixture coverage).
# Validates that every path-like value in .forge/config.yaml points to a real file
# in the project. Fails on missing `required:` injects and missing
# stage_agents prompts/runbooks. Warns on missing `if_exists:` and optional fields.
#
# Usage:
#   bash scripts/forge-config-check.sh [project-dir]
#   bash scripts/forge-config-check.sh /path/to/spodi
#
# Exit codes:
#   0 — no errors (warnings allowed)
#   1 — at least one error (missing required path)
#   2 — usage error / config not found

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash scripts/forge-config-check.sh [project-dir]

Exit codes:
  0 — no errors (warnings allowed)
  1 — at least one error (missing required path)
  2 — usage error / config not found
EOF
}

PROJECT_DIR="${1:-.}"
if [[ "$PROJECT_DIR" == "-h" || "$PROJECT_DIR" == "--help" ]]; then
  usage
  exit 0
fi

if [[ ! -d "$PROJECT_DIR" ]]; then
  printf 'ERR  project dir not found: %s\n' "$PROJECT_DIR" >&2
  exit 2
fi

CONFIG="$PROJECT_DIR/.forge/config.yaml"
if [[ ! -f "$CONFIG" ]]; then
  printf 'ERR  .forge/config.yaml not found at %s\n' "$CONFIG" >&2
  exit 2
fi

ERRORS=0
WARNINGS=0

ok()   { printf 'OK   %s\n' "$1"; }
warn() { printf 'WARN %s\n' "$1"; WARNINGS=$((WARNINGS + 1)); }
err()  { printf 'ERR  %s\n' "$1"; ERRORS=$((ERRORS + 1)); }

# Strip leading/trailing whitespace and surrounding double quotes
trim() {
  sed -E 's/^[[:space:]]*//; s/[[:space:]]*$//; s/^"//; s/"$//'
}

# Strip `#section` anchor from a path-with-anchor like CLAUDE.md#testflight
strip_anchor() {
  sed -E 's/#.*$//'
}

# Resolve a path-or-anchor relative to project-dir and check existence
check_path() {
  local path="$1"
  local field="$2"
  local severity="$3"   # required | optional
  local stripped
  stripped=$(printf '%s' "$path" | strip_anchor)

  # Empty path after stripping → skip silently (commented-out entry)
  if [[ -z "$stripped" ]]; then
    return
  fi

  local full="$PROJECT_DIR/$stripped"
  if [[ -e "$full" ]]; then
    ok "$field → $path"
  else
    if [[ "$severity" == "required" ]]; then
      err "$field references missing path: $path"
    else
      warn "$field references missing path (optional): $path"
    fi
  fi
}

# Extract stage.inject paths. Emits lines: <stage>\t<required|if_exists>\t<path>
extract_stage_injects() {
  awk '
    BEGIN { in_stages=0; in_stage=""; in_inject=0; bucket="" }
    /^stages:$/ { in_stages=1; next }
    # Leaving stages block: any unindented non-empty non-comment line
    in_stages && /^[^[:space:]#]/ { exit }
    # New stage header: "  <name>:"
    in_stages && match($0, /^  [a-z_]+:[[:space:]]*$/) {
      in_stage=$0
      sub(/^  /, "", in_stage); sub(/:.*/, "", in_stage)
      in_inject=0; bucket=""
      next
    }
    # inject: marker (4-space indent inside stage)
    in_stages && in_stage != "" && match($0, /^    inject:[[:space:]]*$/) {
      in_inject=1; bucket=""
      next
    }
    # Leaving inject block: any line not indented at least 4 spaces
    in_inject && /^    [a-z_]+:/ && $0 !~ /^      / && $0 !~ /^    inject:/ {
      in_inject=0; bucket=""
    }
    # required: or if_exists: bucket header (6-space indent)
    in_inject && match($0, /^      (required|if_exists):/) {
      bucket=$0
      sub(/^      /, "", bucket); sub(/:.*/, "", bucket)
      next
    }
    # List entry under a bucket (8-space indent + "- ")
    in_inject && bucket != "" && match($0, /^        - /) {
      path=$0
      sub(/^        - /, "", path)
      sub(/[[:space:]]+#.*/, "", path)
      gsub(/^"|"$/, "", path)
      if (path != "") {
        printf "%s\t%s\t%s\n", in_stage, bucket, path
      }
      next
    }
  ' "$CONFIG"
}

# Extract metrics.baseline scalar
extract_metrics_baseline() {
  awk '
    /^metrics:$/ { in_metrics=1; next }
    in_metrics && /^[^[:space:]#]/ { exit }
    in_metrics && match($0, /^  baseline:[[:space:]]*/) {
      v=$0
      sub(/^  baseline:[[:space:]]*/, "", v)
      sub(/[[:space:]]+#.*/, "", v)
      gsub(/^"|"$/, "", v)
      print v
      exit
    }
  ' "$CONFIG"
}

# Extract release_targets.*.runbook entries
extract_release_runbooks() {
  awk '
    /^release_targets:$/ { in_rt=1; current=""; next }
    in_rt && /^[^[:space:]#]/ { exit }
    in_rt && match($0, /^  [a-z_]+:[[:space:]]*$/) {
      current=$0; sub(/^  /, "", current); sub(/:.*/, "", current)
      next
    }
    in_rt && current != "" && match($0, /^    runbook:[[:space:]]*/) {
      v=$0
      sub(/^    runbook:[[:space:]]*/, "", v)
      sub(/[[:space:]]+#.*/, "", v)
      gsub(/^"|"$/, "", v)
      if (v != "") printf "%s\t%s\n", current, v
    }
  ' "$CONFIG"
}

# Extract stage_agents.*.*.prompt_file entries
extract_stage_agent_prompts() {
  awk '
    /^stage_agents:$/ { in_sa=1; stage=""; role=""; next }
    in_sa && /^[^[:space:]#]/ { exit }
    in_sa && match($0, /^  [a-z_]+:[[:space:]]*$/) {
      stage=$0; sub(/^  /, "", stage); sub(/:.*/, "", stage)
      role=""; next
    }
    in_sa && match($0, /^    [a-z_-]+:[[:space:]]*$/) {
      role=$0; sub(/^    /, "", role); sub(/:.*/, "", role)
      next
    }
    in_sa && stage != "" && role != "" && match($0, /^      prompt_file:[[:space:]]*/) {
      v=$0
      sub(/^      prompt_file:[[:space:]]*/, "", v)
      sub(/[[:space:]]+#.*/, "", v)
      gsub(/^"|"$/, "", v)
      if (v != "") printf "%s/%s\t%s\n", stage, role, v
    }
  ' "$CONFIG"
}

printf '== forge-config-check ==\n'
printf 'project: %s\n' "$PROJECT_DIR"
printf 'config:  %s\n\n' "$CONFIG"

# 1. stages.*.inject — required (error) + if_exists (warn)
printf -- '-- stages.inject --\n'
while IFS=$'\t' read -r stage bucket path; do
  [[ -z "$path" ]] && continue
  if [[ "$bucket" == "required" ]]; then
    check_path "$path" "stages.$stage.inject.required" "required"
  else
    check_path "$path" "stages.$stage.inject.if_exists" "optional"
  fi
done < <(extract_stage_injects)

# 2. metrics.baseline (optional)
printf -- '\n-- metrics.baseline --\n'
baseline=$(extract_metrics_baseline | trim)
if [[ -n "$baseline" ]]; then
  check_path "$baseline" "metrics.baseline" "optional"
else
  printf 'OK   metrics.baseline not set (acceptable; defer real baseline)\n'
fi

# 3. release_targets.*.runbook (required, anchor-aware)
printf -- '\n-- release_targets.runbook --\n'
while IFS=$'\t' read -r target runbook; do
  [[ -z "$runbook" ]] && continue
  check_path "$runbook" "release_targets.$target.runbook" "required"
done < <(extract_release_runbooks)

# 4. stage_agents.*.*.prompt_file (required)
printf -- '\n-- stage_agents.prompt_file --\n'
while IFS=$'\t' read -r ident prompt; do
  [[ -z "$prompt" ]] && continue
  check_path "$prompt" "stage_agents.$ident.prompt_file" "required"
done < <(extract_stage_agent_prompts)

printf '\n== summary ==\n'
printf 'errors:   %d\n' "$ERRORS"
printf 'warnings: %d\n' "$WARNINGS"

if (( ERRORS > 0 )); then
  exit 1
fi
exit 0
