#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash scripts/forge-run-state.sh show [project-dir]
  bash scripts/forge-run-state.sh begin-bugfix <project-dir> <issue-number> <title>
  bash scripts/forge-run-state.sh set-stage <project-dir> <stage>
  bash scripts/forge-run-state.sh set-gate <project-dir> <gate-status>
  bash scripts/forge-run-state.sh set-context7 <project-dir> <yes|no|unknown> <reason>
  bash scripts/forge-run-state.sh clear [project-dir]
EOF
}

state_file() {
  local dir=$1
  local root
  root=$(canonical_repo_root "$dir")
  printf '%s/.forge/active-run.env\n' "$root"
}

canonical_repo_root() {
  local dir=$1
  if git -C "$dir" rev-parse --show-toplevel >/dev/null 2>&1; then
    git -C "$dir" rev-parse --show-toplevel
  else
    printf '%s\n' "$dir"
  fi
}

load_state() {
  local file=$1
  if [[ ! -f "$file" ]]; then
    return 1
  fi

  FORGE_RUN_KIND=$(decode_state_value "$(read_state_value "$file" "FORGE_RUN_KIND")")
  FORGE_RUN_ISSUE=$(decode_state_value "$(read_state_value "$file" "FORGE_RUN_ISSUE")")
  FORGE_RUN_TITLE=$(decode_state_value "$(read_state_value "$file" "FORGE_RUN_TITLE")")
  FORGE_RUN_STAGE=$(decode_state_value "$(read_state_value "$file" "FORGE_RUN_STAGE")")
  FORGE_RUN_GATE_STATUS=$(decode_state_value "$(read_state_value "$file" "FORGE_RUN_GATE_STATUS")")
  FORGE_RUN_CONTEXT7_USED=$(decode_state_value "$(read_state_value "$file" "FORGE_RUN_CONTEXT7_USED")")
  FORGE_RUN_CONTEXT7_REASON=$(decode_state_value "$(read_state_value "$file" "FORGE_RUN_CONTEXT7_REASON")")
  FORGE_RUN_CREATED_AT=$(decode_state_value "$(read_state_value "$file" "FORGE_RUN_CREATED_AT")")
  FORGE_RUN_UPDATED_AT=$(decode_state_value "$(read_state_value "$file" "FORGE_RUN_UPDATED_AT")")
}

read_state_value() {
  local file=$1
  local key=$2
  awk -v key="$key" '
    index($0, key "=") == 1 {
      print substr($0, length(key) + 2)
      exit
    }
  ' "$file"
}

decode_state_value() {
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

write_state() {
  local file=$1
  mkdir -p "$(dirname "$file")"
  {
    printf 'FORGE_RUN_KIND=%q\n' "${FORGE_RUN_KIND:-}"
    printf 'FORGE_RUN_ISSUE=%q\n' "${FORGE_RUN_ISSUE:-}"
    printf 'FORGE_RUN_TITLE=%q\n' "${FORGE_RUN_TITLE:-}"
    printf 'FORGE_RUN_STAGE=%q\n' "${FORGE_RUN_STAGE:-}"
    printf 'FORGE_RUN_GATE_STATUS=%q\n' "${FORGE_RUN_GATE_STATUS:-}"
    printf 'FORGE_RUN_CONTEXT7_USED=%q\n' "${FORGE_RUN_CONTEXT7_USED:-unknown}"
    printf 'FORGE_RUN_CONTEXT7_REASON=%q\n' "${FORGE_RUN_CONTEXT7_REASON:-}"
    printf 'FORGE_RUN_CREATED_AT=%q\n' "${FORGE_RUN_CREATED_AT:-}"
    printf 'FORGE_RUN_UPDATED_AT=%q\n' "${FORGE_RUN_UPDATED_AT:-}"
  } > "$file"
}

show_state() {
  local file=$1
  if ! load_state "$file"; then
    printf 'No active forge run\n'
    return 0
  fi

  printf 'Active run:\n'
  printf '  kind: %s\n' "${FORGE_RUN_KIND:-unknown}"
  printf '  issue: #%s\n' "${FORGE_RUN_ISSUE:-unknown}"
  printf '  title: %s\n' "${FORGE_RUN_TITLE:-}"
  printf '  stage: %s\n' "${FORGE_RUN_STAGE:-unknown}"
  printf '  gate: %s\n' "${FORGE_RUN_GATE_STATUS:-none}"
  printf '  Context7 used: %s\n' "${FORGE_RUN_CONTEXT7_USED:-unknown}"
  if [[ -n "${FORGE_RUN_CONTEXT7_REASON:-}" ]]; then
    printf '  Context7 reason: %s\n' "${FORGE_RUN_CONTEXT7_REASON}"
  fi
  printf '  updated: %s\n' "${FORGE_RUN_UPDATED_AT:-unknown}"
}

MODE=${1:-}
TARGET=${2:-.}

if [[ -z "$MODE" ]]; then
  usage
  exit 1
fi

TARGET=$(cd "$TARGET" && pwd -P)
FILE=$(state_file "$TARGET")

case "$MODE" in
  show)
    show_state "$FILE"
    ;;
  begin-bugfix)
    ISSUE=${3:-}
    shift 3 || true
    TITLE=${*:-}
    if [[ -z "$ISSUE" || -z "$TITLE" ]]; then
      usage
      exit 1
    fi
    NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    FORGE_RUN_KIND=bugfix
    FORGE_RUN_ISSUE=$ISSUE
    FORGE_RUN_TITLE=$TITLE
    FORGE_RUN_STAGE=implementation
    FORGE_RUN_GATE_STATUS=none
    FORGE_RUN_CONTEXT7_USED=unknown
    FORGE_RUN_CONTEXT7_REASON=
    FORGE_RUN_CREATED_AT=$NOW
    FORGE_RUN_UPDATED_AT=$NOW
    write_state "$FILE"
    printf 'Started bugfix run for issue #%s\n' "$ISSUE"
    ;;
  set-stage)
    STAGE=${3:-}
    if [[ -z "$STAGE" ]]; then
      usage
      exit 1
    fi
    load_state "$FILE"
    FORGE_RUN_STAGE=$STAGE
    FORGE_RUN_UPDATED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    write_state "$FILE"
    printf 'Set active run stage: %s\n' "$STAGE"
    ;;
  set-gate)
    GATE=${3:-}
    if [[ -z "$GATE" ]]; then
      usage
      exit 1
    fi
    load_state "$FILE"
    FORGE_RUN_GATE_STATUS=$GATE
    FORGE_RUN_UPDATED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    write_state "$FILE"
    printf 'Set active run gate status: %s\n' "$GATE"
    ;;
  set-context7)
    USED=${3:-}
    shift 3 || true
    REASON=${*:-}
    if [[ -z "$USED" ]]; then
      usage
      exit 1
    fi
    load_state "$FILE"
    FORGE_RUN_CONTEXT7_USED=$USED
    FORGE_RUN_CONTEXT7_REASON=$REASON
    FORGE_RUN_UPDATED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    write_state "$FILE"
    printf 'Set active run Context7: %s\n' "$USED"
    ;;
  clear)
    rm -f "$FILE"
    printf 'Cleared active forge run\n'
    ;;
  *)
    usage
    exit 1
    ;;
esac
