#!/usr/bin/env bash
# forge-reconcile.sh — rebuild the local .forge/pipeline-state.yaml view from
# DURABLE sources (GitHub issues + stage/* labels + open PRs + git tags) and
# loudly report drift between what the local cache claims and what GitHub knows.
#
# Design principle (anti-drift model):
#   The durable layer (GitHub issues/labels/PRs + git tags) is the source of
#   truth. .forge/* is a DERIVED, self-healing cache. When they disagree,
#   GitHub wins. This script is the self-heal step: read-only by default
#   (reports drift), --apply to actually rewrite the local cache.
#
# Exit codes:
#   0  no drift detected
#   2  drift detected (read-only mode) — callers like forge-status can surface it
#   1  usage / hard error (missing gh, bad project dir, etc.)
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash scripts/forge-reconcile.sh <project-dir> [--apply] [--json] [--quiet]

Rebuilds the local .forge/pipeline-state.yaml view from durable GitHub state
and reports drift between the local cache and GitHub.

Options:
  --apply    Rewrite .forge/pipeline-state.yaml from durable state (default: read-only)
  --json     Emit a machine-readable JSON drift summary instead of human text
  --quiet    Suppress the "no drift" banner (still prints drift findings)

Exit codes:
  0  no drift
  2  drift detected (read-only)
  1  usage / hard error
EOF
}

# ----- arg parsing -------------------------------------------------------------
PROJECT_DIR=""
APPLY=0
JSON=0
QUIET=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=1 ;;
    --json)  JSON=1 ;;
    --quiet) QUIET=1 ;;
    -h|--help) usage; exit 0 ;;
    --*) printf 'Unknown option: %s\n' "$1" >&2; usage; exit 1 ;;
    *)
      if [[ -z "$PROJECT_DIR" ]]; then
        PROJECT_DIR=$1
      else
        printf 'Unexpected argument: %s\n' "$1" >&2; usage; exit 1
      fi
      ;;
  esac
  shift
done

if [[ -z "$PROJECT_DIR" ]]; then
  usage
  exit 1
fi

if [[ ! -d "$PROJECT_DIR" ]]; then
  printf 'Target directory not found: %s\n' "$PROJECT_DIR" >&2
  exit 1
fi

PROJECT_DIR=$(cd "$PROJECT_DIR" && pwd -P)
if git -C "$PROJECT_DIR" rev-parse --show-toplevel >/dev/null 2>&1; then
  PROJECT_DIR=$(git -C "$PROJECT_DIR" rev-parse --show-toplevel)
fi

CONFIG_FILE="$PROJECT_DIR/.forge/config.yaml"
STATE_FILE="$PROJECT_DIR/.forge/pipeline-state.yaml"
ACTIVE_RUN_FILE="$PROJECT_DIR/.forge/active-run.env"

# ----- yaml/env scalar readers (no external yaml dep) --------------------------
trim_quotes() {
  sed -E 's/^[[:space:]]*//; s/[[:space:]]*$//; s/^"//; s/"$//; s/^'\''//; s/'\''$//'
}

read_top_level_scalar() {
  local file=$1 key=$2
  [[ -f "$file" ]] || return 0
  awk -v key="$key" '
    $0 ~ "^" key ":" {
      sub("^[^:]+:[[:space:]]*", "", $0)
      sub(/[[:space:]]+#.*/, "", $0)
      print $0
      exit
    }
  ' "$file" | trim_quotes
}

read_project_repo() {
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
  ' "$file" | trim_quotes
}

read_stage_prefix() {
  local file=$1
  [[ -f "$file" ]] || { printf 'stage/'; return 0; }
  local p
  p=$(awk '
    /^tracking:$/ { in_tracking=1; next }
    in_tracking && /^[^ ]/ { exit }
    in_tracking && /^  labels:$/ { in_labels=1; next }
    in_tracking && /^  [a-z_]+:/ && $0 !~ /^  labels:$/ { in_labels=0 }
    in_labels && /^    stage_prefix:/ {
      sub("^[^:]+:[[:space:]]*", "", $0)
      sub(/[[:space:]]+#.*/, "", $0)
      print $0
      exit
    }
  ' "$file" | trim_quotes)
  printf '%s' "${p:-stage/}"
}

read_active_run_value() {
  local file=$1 key=$2
  [[ -f "$file" ]] || return 0
  awk -v key="$key" '
    index($0, key "=") == 1 { print substr($0, length(key) + 2); exit }
  ' "$file"
}

decode_env_value() {
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

normalize_github_repo() {
  local value=$1
  value=${value#https://github.com/}
  value=${value#http://github.com/}
  value=${value#git@github.com:}
  value=${value%.git}
  printf '%s' "$value"
}

# Stage names drift between forge-internal names and the durable label aliases
# (e.g. forge "code_review" == label "stage/review"; "behavior_contract" == "prd").
# Collapse known aliases to a canonical token so legitimate naming differences
# are NOT reported as drift.
canonical_stage() {
  case "$1" in
    code_review|review) printf 'review' ;;
    prd|behavior_contract) printf 'prd' ;;
    canary_deploy|deployed|shipped) printf 'deploy' ;;
    *) printf '%s' "$1" ;;
  esac
}

# ----- preflight ---------------------------------------------------------------
if ! command -v gh >/dev/null 2>&1; then
  printf 'forge-reconcile: gh CLI is required to read durable GitHub state.\n' >&2
  exit 1
fi

REPO=$(normalize_github_repo "$(read_project_repo "$CONFIG_FILE")")
if [[ -z "$REPO" ]]; then
  # Fall back to the origin remote.
  REPO=$(normalize_github_repo "$(git -C "$PROJECT_DIR" remote get-url origin 2>/dev/null || true)")
fi
if [[ -z "$REPO" ]]; then
  printf 'forge-reconcile: could not determine GitHub repo (no .forge/config.yaml project.repo and no origin remote).\n' >&2
  exit 1
fi

STAGE_PREFIX=$(read_stage_prefix "$CONFIG_FILE")

# ----- local cache snapshot ----------------------------------------------------
CACHE_FEATURE=$(read_top_level_scalar "$STATE_FILE" "current_feature")
CACHE_STAGE=$(read_top_level_scalar "$STATE_FILE" "current_stage")
CACHE_ISSUE=$(read_top_level_scalar "$STATE_FILE" "issue")

ACTIVE_KIND=$(decode_env_value "$(read_active_run_value "$ACTIVE_RUN_FILE" "FORGE_RUN_KIND")")
ACTIVE_ISSUE=$(decode_env_value "$(read_active_run_value "$ACTIVE_RUN_FILE" "FORGE_RUN_ISSUE")")
ACTIVE_STAGE=$(decode_env_value "$(read_active_run_value "$ACTIVE_RUN_FILE" "FORGE_RUN_STAGE")")

# ----- durable state from GitHub ----------------------------------------------
# One JSON blob of all open issues carrying a stage/* label.
OPEN_STAGE_ISSUES_JSON=$(gh issue list --repo "$REPO" --state open \
  --json number,title,labels,state --limit 200 2>/dev/null || printf '[]')

# Open PRs and their head branches.
OPEN_PRS_JSON=$(gh pr list --repo "$REPO" --state open \
  --json number,title,headRefName,state,isDraft --limit 200 2>/dev/null || printf '[]')

# Recent prod-* tags (durable deploy markers).
PROD_TAGS=$(git -C "$PROJECT_DIR" tag --list 'prod-*' 2>/dev/null | sort | tail -5 || true)

# Helper: query a single issue's state/labels via gh (used for cache pointers
# that may already be CLOSED and therefore absent from the open-issue list).
issue_state() {
  local num=$1
  [[ -n "$num" && "$num" != "-" && "$num" != '""' ]] || { printf ''; return 0; }
  gh issue view "$num" --repo "$REPO" --json state --jq '.state' 2>/dev/null || printf ''
}

issue_stage_labels() {
  local num=$1
  [[ -n "$num" && "$num" != "-" && "$num" != '""' ]] || { printf ''; return 0; }
  gh issue view "$num" --repo "$REPO" --json labels \
    --jq "[.labels[].name | select(startswith(\"$STAGE_PREFIX\"))] | join(\",\")" 2>/dev/null || printf ''
}

# ----- drift detection ---------------------------------------------------------
DRIFT_COUNT=0
DRIFT_LINES=()      # human-readable
DRIFT_JSON_ITEMS=() # machine-readable

add_drift() {
  local code=$1 human=$2 cache_val=$3 github_val=$4
  DRIFT_COUNT=$((DRIFT_COUNT + 1))
  DRIFT_LINES+=("  [$code] $human")
  DRIFT_LINES+=("      cache says : ${cache_val:-<none>}")
  DRIFT_LINES+=("      GitHub says: ${github_val:-<none>}")
  # Build a JSON object using gh's bundled jq-free approach via python for safety.
  DRIFT_JSON_ITEMS+=("$(printf '%s\n%s\n%s\n%s' "$code" "$human" "${cache_val:-}" "${github_val:-}")")
}

# Drift 1: current_feature / issue points at a CLOSED issue.
PRIMARY_ISSUE="$CACHE_ISSUE"
[[ -n "$PRIMARY_ISSUE" && "$PRIMARY_ISSUE" != '""' && "$PRIMARY_ISSUE" != "-" ]] || PRIMARY_ISSUE="$CACHE_FEATURE"

if [[ -n "$PRIMARY_ISSUE" && "$PRIMARY_ISSUE" != '""' && "$PRIMARY_ISSUE" != "-" ]]; then
  ST=$(issue_state "$PRIMARY_ISSUE")
  if [[ "$ST" == "CLOSED" ]]; then
    add_drift "ISSUE_CLOSED" \
      "cache current issue #$PRIMARY_ISSUE is CLOSED on GitHub" \
      "issue #$PRIMARY_ISSUE (stage=${CACHE_STAGE:-?})" \
      "issue #$PRIMARY_ISSUE state=CLOSED"
  fi

  # Drift 2: stage/* label disagrees with the cached current_stage.
  if [[ "$ST" == "OPEN" || -z "$ST" ]]; then
    LABELS=$(issue_stage_labels "$PRIMARY_ISSUE")
    if [[ -n "$LABELS" && -n "$CACHE_STAGE" && "$CACHE_STAGE" != '""' && "$CACHE_STAGE" != "-" ]]; then
      # Cached stage may be a forge-internal name (e.g. code_review) while the
      # durable label may be an alias (e.g. stage/review). Canonicalize both
      # sides so legitimate naming aliases are NOT flagged as drift; report
      # only a genuine stage disagreement.
      CACHE_CANON=$(canonical_stage "$CACHE_STAGE")
      LABEL_MATCH=0
      IFS=',' read -ra _labels <<< "$LABELS"
      for _l in "${_labels[@]}"; do
        _stage=${_l#"$STAGE_PREFIX"}
        if [[ "$(canonical_stage "$_stage")" == "$CACHE_CANON" ]]; then
          LABEL_MATCH=1
          break
        fi
      done
      if [[ "$LABEL_MATCH" -eq 0 ]]; then
        add_drift "STAGE_LABEL_MISMATCH" \
          "issue #$PRIMARY_ISSUE stage label(s) disagree with cached stage '$CACHE_STAGE'" \
          "current_stage=$CACHE_STAGE" \
          "labels=$LABELS"
      fi
    fi
  fi
fi

# Drift 3: active-run.env issue is CLOSED or its fix already merged.
if [[ "$ACTIVE_KIND" == "bugfix" && -n "$ACTIVE_ISSUE" ]]; then
  AST=$(issue_state "$ACTIVE_ISSUE")
  if [[ "$AST" == "CLOSED" ]]; then
    add_drift "ACTIVE_RUN_CLOSED" \
      "active-run.env points at CLOSED issue #$ACTIVE_ISSUE (stale local-only run state)" \
      "active bugfix #$ACTIVE_ISSUE stage=${ACTIVE_STAGE:-?}" \
      "issue #$ACTIVE_ISSUE state=CLOSED"
  fi
fi

# Drift 4: an open PR's head branch references an issue that is already closed.
#          (PR title or branch like fix/<NNN>-* / feature/...#NNN)
PR_DRIFT=$(REPO="$REPO" STAGE_PREFIX="$STAGE_PREFIX" python3 - "$OPEN_PRS_JSON" <<'PY' 2>/dev/null || true
import json, re, sys, subprocess, os
prs = json.loads(sys.argv[1] or "[]")
repo = os.environ["REPO"]
seen = set()
for pr in prs:
    text = (pr.get("headRefName","") or "") + " " + (pr.get("title","") or "")
    for m in re.findall(r'#?(\d{2,6})', text):
        if m in seen:
            continue
        seen.add(m)
        try:
            out = subprocess.run(
                ["gh","issue","view",m,"--repo",repo,"--json","state","--jq",".state"],
                capture_output=True, text=True, timeout=20)
            state = out.stdout.strip()
        except Exception:
            state = ""
        if state == "CLOSED":
            print(f"PR_REFS_CLOSED|open PR #{pr['number']} ({pr['headRefName']}) references CLOSED issue #{m}|PR #{pr['number']} open|issue #{m} CLOSED")
PY
)
if [[ -n "$PR_DRIFT" ]]; then
  while IFS='|' read -r code human cval gval; do
    [[ -n "$code" ]] || continue
    add_drift "$code" "$human" "$cval" "$gval"
  done <<< "$PR_DRIFT"
fi

# ----- durable view (what the cache SHOULD say) --------------------------------
# Pick the most relevant open stage-labelled issue: prefer the cached primary
# issue if it is still open and labelled; otherwise leave a derived snapshot of
# all open stage-labelled issues for the human/--apply path.
DURABLE_SUMMARY=$(STAGE_PREFIX="$STAGE_PREFIX" python3 - "$OPEN_STAGE_ISSUES_JSON" <<'PY' 2>/dev/null || true
import json, os, sys
prefix = os.environ["STAGE_PREFIX"]
issues = json.loads(sys.argv[1] or "[]")
rows = []
for it in issues:
    labels = [l["name"] for l in it.get("labels",[]) if l["name"].startswith(prefix)]
    if labels:
        rows.append((it["number"], labels, it.get("title","")))
rows.sort(key=lambda r: -r[0])
for num, labels, title in rows:
    print(f"{num}\t{','.join(labels)}\t{title[:60]}")
PY
)

# ----- output ------------------------------------------------------------------
emit_json() {
  python3 - "$REPO" "$DRIFT_COUNT" "$DURABLE_SUMMARY" <<'PY'
import json, os, sys
repo = sys.argv[1]
drift_count = int(sys.argv[2])
durable_raw = sys.argv[3] if len(sys.argv) > 3 else ""
items = []
raw = os.environ.get("DRIFT_JSON_BLOB","")
for blob in raw.split("\x1e"):
    blob = blob.strip("\n")
    if not blob:
        continue
    parts = blob.split("\n")
    if len(parts) >= 4:
        items.append({"code":parts[0],"message":parts[1],"cache":parts[2],"github":parts[3]})
durable = []
for line in durable_raw.splitlines():
    if not line.strip():
        continue
    cols = line.split("\t")
    if len(cols) >= 2:
        durable.append({"issue":cols[0],"labels":cols[1],"title":cols[2] if len(cols)>2 else ""})
print(json.dumps({
    "repo": repo,
    "drift_count": drift_count,
    "drift": items,
    "durable_open_stage_issues": durable,
}, ensure_ascii=False, indent=2))
PY
}

if [[ "$JSON" -eq 1 ]]; then
  # Pass drift items to python via a record-separated env blob.
  DRIFT_JSON_BLOB=""
  for item in "${DRIFT_JSON_ITEMS[@]:-}"; do
    [[ -n "$item" ]] || continue
    DRIFT_JSON_BLOB+="$item"$'\x1e'
  done
  export DRIFT_JSON_BLOB
  emit_json
else
  if [[ "$DRIFT_COUNT" -gt 0 ]]; then
    printf '== forge drift report (%s) ==\n' "$REPO"
    printf 'DRIFT DETECTED: %s finding(s). Durable layer (GitHub) wins.\n\n' "$DRIFT_COUNT"
    for line in "${DRIFT_LINES[@]}"; do
      printf '%s\n' "$line"
    done
    printf '\nDurable open stage-labelled issues (GitHub source of truth):\n'
    if [[ -n "$DURABLE_SUMMARY" ]]; then
      printf '%s\n' "$DURABLE_SUMMARY" | sed 's/^/  #/'
    else
      printf '  (none)\n'
    fi
    if [[ "$APPLY" -eq 0 ]]; then
      printf '\nRun with --apply to rewrite .forge/pipeline-state.yaml from durable state.\n'
    fi
  elif [[ "$QUIET" -eq 0 ]]; then
    printf '== forge drift report (%s) ==\n' "$REPO"
    printf 'No drift: local cache agrees with GitHub.\n'
  fi
fi

# ----- apply (rewrite the derived cache) ---------------------------------------
if [[ "$APPLY" -eq 1 ]]; then
  mkdir -p "$(dirname "$STATE_FILE")"
  NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  TMP=$(mktemp)
  {
    printf '# Pipeline State (DERIVED CACHE — rebuilt by forge-reconcile.sh)\n'
    printf '# Reconciled at: %s\n' "$NOW"
    printf '# Source of truth = GitHub issues/labels/PRs + git tags. If this file\n'
    printf '# disagrees with GitHub, GitHub wins. Re-run: bash scripts/forge-reconcile.sh <dir> --apply\n'
    if [[ -n "$PRIMARY_ISSUE" && "$PRIMARY_ISSUE" != '""' && "$PRIMARY_ISSUE" != "-" ]]; then
      ST=$(issue_state "$PRIMARY_ISSUE")
      LBL=$(issue_stage_labels "$PRIMARY_ISSUE")
      if [[ "$ST" == "OPEN" ]]; then
        printf 'current_feature: %s\n' "$PRIMARY_ISSUE"
        printf 'issue: %s\n' "$PRIMARY_ISSUE"
        # Derive stage from the first stage/* label, stripping the prefix.
        FIRST_LABEL=${LBL%%,*}
        printf 'current_stage: "%s"\n' "${FIRST_LABEL#"$STAGE_PREFIX"}"
        printf 'current_gate_status: ""\n'
        printf 'durable_labels: "%s"\n' "$LBL"
      else
        printf 'current_feature: ""   # prior pointer #%s is %s on GitHub\n' "$PRIMARY_ISSUE" "${ST:-unknown}"
        printf 'issue: ""\n'
        printf 'current_stage: ""\n'
        printf 'current_gate_status: ""\n'
      fi
    else
      printf 'current_feature: ""\n'
      printf 'issue: ""\n'
      printf 'current_stage: ""\n'
      printf 'current_gate_status: ""\n'
    fi
    printf '\n# Open stage-labelled issues (durable snapshot):\n'
    printf 'open_stage_issues:\n'
    if [[ -n "$DURABLE_SUMMARY" ]]; then
      while IFS=$'\t' read -r num labels title; do
        [[ -n "$num" ]] || continue
        printf '  - issue: %s\n' "$num"
        printf '    labels: "%s"\n' "$labels"
        printf '    title: "%s"\n' "${title//\"/\'}"
      done <<< "$DURABLE_SUMMARY"
    else
      printf '  []\n'
    fi
    printf '\n# Recent prod deploy tags (durable):\n'
    printf 'prod_tags:\n'
    if [[ -n "$PROD_TAGS" ]]; then
      while IFS= read -r tag; do
        [[ -n "$tag" ]] || continue
        printf '  - %s\n' "$tag"
      done <<< "$PROD_TAGS"
    else
      printf '  []\n'
    fi
  } > "$TMP"
  mv "$TMP" "$STATE_FILE"
  printf '\nRewrote %s from durable state.\n' "${STATE_FILE#"$PROJECT_DIR"/}"
  exit 0
fi

# Read-only mode: nonzero exit signals drift to callers (e.g. forge-status).
if [[ "$DRIFT_COUNT" -gt 0 ]]; then
  exit 2
fi
exit 0
