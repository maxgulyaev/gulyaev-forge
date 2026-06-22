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

  # L2 — run-state durable on the issue (readable from any machine/session):
  bash scripts/forge-run-state.sh publish <project-dir>    # push local run -> issue comment
  bash scripts/forge-run-state.sh read-remote <project-dir> <issue-number>  # print issue-side JSON
  bash scripts/forge-run-state.sh hydrate <project-dir> <issue-number>      # issue -> local active-run.env

Durable model: the authoritative run stage is the issue's stage/* label; the
full run-state JSON lives in a single maintained issue comment marked with the
HTML sentinel <!--forge-run-state-->...JSON...<!--/forge-run-state-->. The local
.forge/active-run.env is a derived cache hydrated from that comment.
EOF
}

# HTML sentinel that brackets the run-state JSON inside one issue comment.
RUN_STATE_SENTINEL_OPEN='<!--forge-run-state-->'
RUN_STATE_SENTINEL_CLOSE='<!--/forge-run-state-->'

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

  # bash printf %q encodes the empty string as '' — restore it to empty.
  if [[ "$value" == "''" ]]; then
    printf ''
    return 0
  fi

  # $'...' ANSI-C form (rare; used by %q for non-printable bytes).
  if [[ "$value" == \$\'*\' ]] && [[ "$value" == *"'" ]]; then
    value=${value#\$\'}
    value=${value%\'}
  fi

  # General inverse of printf %q backslash-escaping: a backslash followed by any
  # single character is that literal character. Walk the string once so we never
  # double-decode (e.g. "\\" -> "\"). This covers space, comma, quotes, &, <, >,
  # |, (), and any other char %q chose to escape.
  local out='' i=0 ch
  local len=${#value}
  while (( i < len )); do
    ch=${value:i:1}
    if [[ "$ch" == $'\\' ]] && (( i + 1 < len )); then
      out+=${value:i+1:1}
      i=$(( i + 2 ))
    else
      out+=$ch
      i=$(( i + 1 ))
    fi
  done
  printf '%s' "$out"
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

# ----- L2: durable run-state on the issue -------------------------------------
trim_quotes_rs() {
  sed -E 's/^[[:space:]]*//; s/[[:space:]]*$//; s/^"//; s/"$//'
}

read_project_repo_rs() {
  local file=$1
  [[ -f "$file" ]] || return 0
  awk '
    /^project:$/ { in_project=1; next }
    in_project && /^[^ ]/ { exit }
    in_project && /^  repo:/ {
      sub("^[^:]+:[[:space:]]*", "", $0)
      sub(/[[:space:]]+#.*/, "", $0)
      print $0
      exit
    }
  ' "$file" | trim_quotes_rs
}

normalize_github_repo_rs() {
  local value=$1
  value=${value#https://github.com/}
  value=${value#http://github.com/}
  value=${value#git@github.com:}
  value=${value%.git}
  printf '%s' "$value"
}

resolve_repo() {
  local dir=$1
  local repo
  repo=$(normalize_github_repo_rs "$(read_project_repo_rs "$dir/.forge/config.yaml")")
  if [[ -z "$repo" ]]; then
    repo=$(normalize_github_repo_rs "$(git -C "$dir" remote get-url origin 2>/dev/null || true)")
  fi
  printf '%s' "$repo"
}

require_gh() {
  if ! command -v gh >/dev/null 2>&1; then
    printf 'forge-run-state: gh CLI is required for durable run-state.\n' >&2
    return 1
  fi
}

# Build the run-state JSON payload from the currently loaded FORGE_RUN_* vars.
# Values are passed via the environment (never interpolated into source) so a
# title containing quotes/newlines cannot break or inject into the JSON.
build_run_state_json() {
  RS_KIND="${FORGE_RUN_KIND:-}" \
  RS_ISSUE="${FORGE_RUN_ISSUE:-}" \
  RS_TITLE="${FORGE_RUN_TITLE:-}" \
  RS_STAGE="${FORGE_RUN_STAGE:-}" \
  RS_GATE="${FORGE_RUN_GATE_STATUS:-}" \
  RS_C7U="${FORGE_RUN_CONTEXT7_USED:-unknown}" \
  RS_C7R="${FORGE_RUN_CONTEXT7_REASON:-}" \
  RS_CREATED="${FORGE_RUN_CREATED_AT:-}" \
  RS_UPDATED="${FORGE_RUN_UPDATED_AT:-}" \
  python3 - <<'PY'
import json, os
def opt(v):
    return v if v else None
print(json.dumps({
    "kind":  opt(os.environ.get("RS_KIND")),
    "issue": opt(os.environ.get("RS_ISSUE")),
    "title": opt(os.environ.get("RS_TITLE")),
    "stage": opt(os.environ.get("RS_STAGE")),
    "gate":  opt(os.environ.get("RS_GATE")),
    "context7_used":   os.environ.get("RS_C7U", "unknown"),
    "context7_reason": os.environ.get("RS_C7R", ""),
    "created_at": os.environ.get("RS_CREATED", ""),
    "updated_at": os.environ.get("RS_UPDATED", ""),
}, ensure_ascii=False))
PY
}

# Find the comment id of the existing forge-run-state comment (or empty).
find_run_state_comment_id() {
  local repo=$1 issue=$2
  gh api "repos/$repo/issues/$issue/comments" --paginate \
    --jq "[.[] | select(.body | contains(\"$RUN_STATE_SENTINEL_OPEN\"))] | last | .id // empty" \
    2>/dev/null || true
}

# Extract the JSON between the sentinels in the issue's run-state comment.
read_remote_run_state() {
  local repo=$1 issue=$2
  local body
  body=$(gh api "repos/$repo/issues/$issue/comments" --paginate \
    --jq "[.[] | select(.body | contains(\"$RUN_STATE_SENTINEL_OPEN\"))] | last | .body // empty" \
    2>/dev/null || true)
  [[ -n "$body" ]] || return 1
  # Extract the region between the sentinels, then strip the ```json fences so
  # the caller gets pure JSON.
  local region
  region=$(printf '%s' "$body" | awk -v o="$RUN_STATE_SENTINEL_OPEN" -v c="$RUN_STATE_SENTINEL_CLOSE" '
    { buf = buf $0 "\n" }
    END {
      so = index(buf, o)
      if (so == 0) exit 1
      rest = substr(buf, so + length(o))
      sc = index(rest, c)
      if (sc == 0) { printf "%s", rest; exit 0 }
      printf "%s", substr(rest, 1, sc - 1)
    }
  ') || return 1
  printf '%s\n' "$region" | grep -v '^[[:space:]]*```' | sed '/^[[:space:]]*$/d'
}

publish_run_state() {
  local dir=$1
  local file
  file=$(state_file "$dir")
  if ! load_state "$file"; then
    printf 'No local active run to publish (%s missing).\n' "$file" >&2
    return 1
  fi
  require_gh || return 1
  local repo
  repo=$(resolve_repo "$dir")
  if [[ -z "$repo" ]]; then
    printf 'forge-run-state: could not resolve GitHub repo.\n' >&2
    return 1
  fi
  if [[ -z "${FORGE_RUN_ISSUE:-}" ]]; then
    printf 'forge-run-state: active run has no issue number; cannot publish.\n' >&2
    return 1
  fi

  local json marker body
  json=$(build_run_state_json)
  marker="${RUN_STATE_SENTINEL_OPEN}
\`\`\`json
${json}
\`\`\`
${RUN_STATE_SENTINEL_CLOSE}"
  body="**Forge run-state** (machine-maintained; durable across machines/sessions). Authoritative stage = the issue's stage/* label.

${marker}"

  local existing
  existing=$(find_run_state_comment_id "$repo" "$FORGE_RUN_ISSUE")
  if [[ -n "$existing" ]]; then
    gh api -X PATCH "repos/$repo/issues/comments/$existing" -f body="$body" >/dev/null
    printf 'Updated durable run-state comment on #%s (comment %s).\n' "$FORGE_RUN_ISSUE" "$existing"
  else
    gh issue comment "$FORGE_RUN_ISSUE" --repo "$repo" --body "$body" >/dev/null
    printf 'Posted durable run-state comment on #%s.\n' "$FORGE_RUN_ISSUE"
  fi
}

hydrate_run_state() {
  local dir=$1 issue=$2
  require_gh || return 1
  local repo
  repo=$(resolve_repo "$dir")
  if [[ -z "$repo" ]]; then
    printf 'forge-run-state: could not resolve GitHub repo.\n' >&2
    return 1
  fi
  local json
  if ! json=$(read_remote_run_state "$repo" "$issue"); then
    printf 'forge-run-state: no durable run-state comment found on #%s.\n' "$issue" >&2
    return 1
  fi
  # Parse JSON into env vars, then write the local derived cache. The JSON is
  # passed via the environment (not stdin) so the heredoc owns stdin.
  local parsed
  parsed=$(RS_JSON="$json" python3 - <<'PY'
import json, os, sys
try:
    d = json.loads(os.environ.get("RS_JSON", ""))
except Exception:
    sys.exit(1)
def g(k):
    v = d.get(k)
    return "" if v is None else str(v)
print("\n".join([
    "K\t"+g("kind"), "I\t"+g("issue"), "T\t"+g("title"), "S\t"+g("stage"),
    "G\t"+g("gate"), "CU\t"+g("context7_used"), "CR\t"+g("context7_reason"),
    "CA\t"+g("created_at"), "UA\t"+g("updated_at"),
]))
PY
) || { printf 'forge-run-state: could not parse durable run-state JSON.\n' >&2; return 1; }

  FORGE_RUN_KIND=$(awk -F'\t' '$1=="K"{print $2}' <<< "$parsed")
  FORGE_RUN_ISSUE=$(awk -F'\t' '$1=="I"{print $2}' <<< "$parsed")
  FORGE_RUN_TITLE=$(awk -F'\t' '$1=="T"{sub(/^T\t/,"");print}' <<< "$parsed")
  FORGE_RUN_STAGE=$(awk -F'\t' '$1=="S"{print $2}' <<< "$parsed")
  FORGE_RUN_GATE_STATUS=$(awk -F'\t' '$1=="G"{print $2}' <<< "$parsed")
  FORGE_RUN_CONTEXT7_USED=$(awk -F'\t' '$1=="CU"{print $2}' <<< "$parsed")
  FORGE_RUN_CONTEXT7_REASON=$(awk -F'\t' '$1=="CR"{sub(/^CR\t/,"");print}' <<< "$parsed")
  FORGE_RUN_CREATED_AT=$(awk -F'\t' '$1=="CA"{print $2}' <<< "$parsed")
  FORGE_RUN_UPDATED_AT=$(awk -F'\t' '$1=="UA"{print $2}' <<< "$parsed")
  local file
  file=$(state_file "$dir")
  write_state "$file"
  printf 'Hydrated %s from durable run-state on #%s.\n' "${file}" "$issue"
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
  publish)
    publish_run_state "$TARGET"
    ;;
  read-remote)
    ISSUE=${3:-}
    if [[ -z "$ISSUE" ]]; then
      usage
      exit 1
    fi
    require_gh || exit 1
    REPO=$(resolve_repo "$TARGET")
    if [[ -z "$REPO" ]]; then
      printf 'forge-run-state: could not resolve GitHub repo.\n' >&2
      exit 1
    fi
    if ! read_remote_run_state "$REPO" "$ISSUE"; then
      printf 'forge-run-state: no durable run-state comment found on #%s.\n' "$ISSUE" >&2
      exit 1
    fi
    ;;
  hydrate)
    ISSUE=${3:-}
    if [[ -z "$ISSUE" ]]; then
      usage
      exit 1
    fi
    hydrate_run_state "$TARGET" "$ISSUE"
    ;;
  *)
    usage
    exit 1
    ;;
esac
