#!/usr/bin/env bash
# forge-reconcile.test.sh — functional tests for forge-reconcile.sh.
#
# GitHub is stubbed via a fake `gh` on PATH that answers from JSON fixtures, so
# these tests are deterministic and run offline. Each case builds a throwaway
# git repo with a .forge/ cache and asserts the drift verdict + exit code.
#
# Usage:   bash scripts/forge-reconcile.test.sh
# Exit:    0 all pass, 1 any fail
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
RECONCILE="$SCRIPT_DIR/forge-reconcile.sh"

PASS=0
FAIL=0

# Build a fake `gh` that the script will pick up first on PATH. It reads the
# scenario from $GH_STUB_DIR (set per-case) and answers issue/pr queries.
make_gh_stub() {
  local bindir=$1
  mkdir -p "$bindir"
  cat > "$bindir/gh" <<'STUB'
#!/usr/bin/env bash
# Fake gh: answers from $GH_STUB_DIR/{issues.json,prs.json} + per-issue state map.
set -euo pipefail
SUB=${1:-}; shift || true
DIR=${GH_STUB_DIR:?GH_STUB_DIR not set}

if [[ "$SUB" == "issue" && "${1:-}" == "list" ]]; then
  cat "$DIR/issues.json"
  exit 0
fi
if [[ "$SUB" == "pr" && "${1:-}" == "list" ]]; then
  cat "$DIR/prs.json"
  exit 0
fi
if [[ "$SUB" == "issue" && "${1:-}" == "view" ]]; then
  num=$2
  # crude flag scan for --jq value
  want_state=0; want_labels=0
  for a in "$@"; do
    [[ "$a" == ".state" ]] && want_state=1
    [[ "$a" == *"startswith"* ]] && want_labels=1
  done
  state=$(awk -F'\t' -v n="$num" '$1==n{print $2}' "$DIR/states.tsv")
  labels=$(awk -F'\t' -v n="$num" '$1==n{print $3}' "$DIR/states.tsv")
  if [[ "$want_state" == 1 ]]; then printf '%s\n' "${state:-}"; exit 0; fi
  if [[ "$want_labels" == 1 ]]; then printf '%s\n' "${labels:-}"; exit 0; fi
  printf '%s\n' "${state:-}"
  exit 0
fi
exit 0
STUB
  chmod +x "$bindir/gh"
}

setup_project() {
  local root=$1
  mkdir -p "$root/.forge"
  cat > "$root/.forge/config.yaml" <<'CFG'
project:
  name: testproj
  repo: https://github.com/acme/testproj
tracking:
  provider: github
  labels:
    stage_prefix: "stage/"
CFG
  git -C "$root" init -q
  git -C "$root" config user.email t@t.t
  git -C "$root" config user.name t
}

assert() {
  local name=$1 got_exit=$2 want_exit=$3 output=$4 want_grep=$5
  local ok=1
  if [[ "$got_exit" != "$want_exit" ]]; then ok=0; fi
  if [[ -n "$want_grep" ]] && ! grep -qF "$want_grep" <<< "$output"; then ok=0; fi
  if [[ "$ok" == 1 ]]; then
    printf 'PASS %s\n' "$name"
    PASS=$((PASS + 1))
  else
    printf 'FAIL %s (exit got=%s want=%s; grep=%s)\n' "$name" "$got_exit" "$want_exit" "$want_grep"
    printf '----\n%s\n----\n' "$output"
    FAIL=$((FAIL + 1))
  fi
}

# ---------------------------------------------------------------------------
# Case 1: cache points at an OPEN issue with a matching stage label -> no drift.
# ---------------------------------------------------------------------------
run_case_clean() {
  local tmp; tmp=$(mktemp -d)
  local proj="$tmp/proj" stub="$tmp/bin"
  setup_project "$proj"
  cat > "$proj/.forge/pipeline-state.yaml" <<'ST'
current_feature: 50
current_stage: implementation
issue: 50
ST
  export GH_STUB_DIR="$tmp/gh"
  mkdir -p "$GH_STUB_DIR"
  printf '[]\n' > "$GH_STUB_DIR/issues.json"
  printf '[]\n' > "$GH_STUB_DIR/prs.json"
  printf '50\tOPEN\tstage/implementation\n' > "$GH_STUB_DIR/states.tsv"
  make_gh_stub "$stub"
  local out exit
  out=$(PATH="$stub:$PATH" bash "$RECONCILE" "$proj" 2>&1) && exit=0 || exit=$?
  assert "clean: open issue, matching label" "$exit" 0 "$out" "No drift"
  rm -rf "$tmp"; unset GH_STUB_DIR
}

# ---------------------------------------------------------------------------
# Case 2: cache points at a CLOSED issue -> ISSUE_CLOSED drift, exit 2.
# ---------------------------------------------------------------------------
run_case_closed() {
  local tmp; tmp=$(mktemp -d)
  local proj="$tmp/proj" stub="$tmp/bin"
  setup_project "$proj"
  cat > "$proj/.forge/pipeline-state.yaml" <<'ST'
current_feature: 312
current_stage: implementation
issue: 312
ST
  export GH_STUB_DIR="$tmp/gh"
  mkdir -p "$GH_STUB_DIR"
  printf '[]\n' > "$GH_STUB_DIR/issues.json"
  printf '[]\n' > "$GH_STUB_DIR/prs.json"
  printf '312\tCLOSED\t\n' > "$GH_STUB_DIR/states.tsv"
  make_gh_stub "$stub"
  local out exit
  out=$(PATH="$stub:$PATH" bash "$RECONCILE" "$proj" 2>&1) && exit=0 || exit=$?
  assert "drift: closed issue" "$exit" 2 "$out" "ISSUE_CLOSED"
  rm -rf "$tmp"; unset GH_STUB_DIR
}

# ---------------------------------------------------------------------------
# Case 3: stage label alias (code_review vs stage/review) -> NO drift.
# ---------------------------------------------------------------------------
run_case_alias() {
  local tmp; tmp=$(mktemp -d)
  local proj="$tmp/proj" stub="$tmp/bin"
  setup_project "$proj"
  cat > "$proj/.forge/pipeline-state.yaml" <<'ST'
current_feature: 366
current_stage: code_review
issue: 366
ST
  export GH_STUB_DIR="$tmp/gh"
  mkdir -p "$GH_STUB_DIR"
  printf '[]\n' > "$GH_STUB_DIR/issues.json"
  printf '[]\n' > "$GH_STUB_DIR/prs.json"
  printf '366\tOPEN\tstage/review\n' > "$GH_STUB_DIR/states.tsv"
  make_gh_stub "$stub"
  local out exit
  out=$(PATH="$stub:$PATH" bash "$RECONCILE" "$proj" 2>&1) && exit=0 || exit=$?
  assert "alias: code_review == stage/review" "$exit" 0 "$out" "No drift"
  rm -rf "$tmp"; unset GH_STUB_DIR
}

# ---------------------------------------------------------------------------
# Case 4: genuine stage label mismatch -> STAGE_LABEL_MISMATCH, exit 2.
# ---------------------------------------------------------------------------
run_case_mismatch() {
  local tmp; tmp=$(mktemp -d)
  local proj="$tmp/proj" stub="$tmp/bin"
  setup_project "$proj"
  cat > "$proj/.forge/pipeline-state.yaml" <<'ST'
current_feature: 77
current_stage: implementation
issue: 77
ST
  export GH_STUB_DIR="$tmp/gh"
  mkdir -p "$GH_STUB_DIR"
  printf '[]\n' > "$GH_STUB_DIR/issues.json"
  printf '[]\n' > "$GH_STUB_DIR/prs.json"
  printf '77\tOPEN\tstage/qa\n' > "$GH_STUB_DIR/states.tsv"
  make_gh_stub "$stub"
  local out exit
  out=$(PATH="$stub:$PATH" bash "$RECONCILE" "$proj" 2>&1) && exit=0 || exit=$?
  assert "drift: genuine stage mismatch" "$exit" 2 "$out" "STAGE_LABEL_MISMATCH"
  rm -rf "$tmp"; unset GH_STUB_DIR
}

# ---------------------------------------------------------------------------
# Case 5: --apply rewrites the cache from durable state.
# ---------------------------------------------------------------------------
run_case_apply() {
  local tmp; tmp=$(mktemp -d)
  local proj="$tmp/proj" stub="$tmp/bin"
  setup_project "$proj"
  cat > "$proj/.forge/pipeline-state.yaml" <<'ST'
current_feature: 312
current_stage: implementation
issue: 312
ST
  export GH_STUB_DIR="$tmp/gh"
  mkdir -p "$GH_STUB_DIR"
  printf '[{"number":99,"title":"open feature","labels":[{"name":"stage/implementation"}],"state":"OPEN"}]\n' > "$GH_STUB_DIR/issues.json"
  printf '[]\n' > "$GH_STUB_DIR/prs.json"
  printf '312\tCLOSED\t\n99\tOPEN\tstage/implementation\n' > "$GH_STUB_DIR/states.tsv"
  make_gh_stub "$stub"
  local out exit
  out=$(PATH="$stub:$PATH" bash "$RECONCILE" "$proj" --apply 2>&1) && exit=0 || exit=$?
  local rewritten=0
  grep -q 'DERIVED CACHE' "$proj/.forge/pipeline-state.yaml" && \
    grep -q 'open_stage_issues' "$proj/.forge/pipeline-state.yaml" && rewritten=1
  if [[ "$exit" == 0 && "$rewritten" == 1 ]]; then
    printf 'PASS apply: rewrote derived cache\n'; PASS=$((PASS + 1))
  else
    printf 'FAIL apply: exit=%s rewritten=%s\n' "$exit" "$rewritten"
    printf '%s\n' "$out"; FAIL=$((FAIL + 1))
  fi
  rm -rf "$tmp"; unset GH_STUB_DIR
}

# ---------------------------------------------------------------------------
# Case 6: --json emits valid JSON with a drift array.
# ---------------------------------------------------------------------------
run_case_json() {
  local tmp; tmp=$(mktemp -d)
  local proj="$tmp/proj" stub="$tmp/bin"
  setup_project "$proj"
  cat > "$proj/.forge/pipeline-state.yaml" <<'ST'
current_feature: 312
current_stage: implementation
issue: 312
ST
  export GH_STUB_DIR="$tmp/gh"
  mkdir -p "$GH_STUB_DIR"
  printf '[]\n' > "$GH_STUB_DIR/issues.json"
  printf '[]\n' > "$GH_STUB_DIR/prs.json"
  printf '312\tCLOSED\t\n' > "$GH_STUB_DIR/states.tsv"
  make_gh_stub "$stub"
  local out exit
  out=$(PATH="$stub:$PATH" bash "$RECONCILE" "$proj" --json 2>&1) && exit=0 || exit=$?
  if printf '%s' "$out" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["drift_count"]>=1; assert d["drift"][0]["code"]=="ISSUE_CLOSED"' 2>/dev/null; then
    printf 'PASS json: valid JSON drift summary\n'; PASS=$((PASS + 1))
  else
    printf 'FAIL json: invalid or unexpected JSON\n'; printf '%s\n' "$out"; FAIL=$((FAIL + 1))
  fi
  rm -rf "$tmp"; unset GH_STUB_DIR
}

# ---------------------------------------------------------------------------
# Case 7: gh hard-fails (auth/network) -> exit 1, NOT a false "no drift".
# ---------------------------------------------------------------------------
run_case_gh_failure() {
  local tmp; tmp=$(mktemp -d)
  local proj="$tmp/proj" stub="$tmp/bin"
  setup_project "$proj"
  cat > "$proj/.forge/pipeline-state.yaml" <<'ST'
current_feature: 50
current_stage: implementation
issue: 50
ST
  mkdir -p "$stub"
  printf '#!/usr/bin/env bash\necho "error connecting to api.github.com" >&2\nexit 1\n' > "$stub/gh"
  chmod +x "$stub/gh"
  local out exit
  out=$(PATH="$stub:$PATH" bash "$RECONCILE" "$proj" --quiet 2>&1) && exit=0 || exit=$?
  assert "gh failure: fail-hard (not false-clean)" "$exit" 1 "$out" "required GitHub read failed"
  rm -rf "$tmp"
}

# ---------------------------------------------------------------------------
# Case 8: list calls succeed but a PR-ref issue lookup hits a non-404 error
# (Drift 4) -> fail-hard, not a false clean. Uses a custom gh that succeeds for
# list/primary-issue but errors on the PR-referenced issue lookup.
# ---------------------------------------------------------------------------
run_case_drift4_failure() {
  local tmp; tmp=$(mktemp -d)
  local proj="$tmp/proj" stub="$tmp/bin"
  setup_project "$proj"
  cat > "$proj/.forge/pipeline-state.yaml" <<'ST'
current_feature: 50
current_stage: implementation
issue: 50
ST
  mkdir -p "$stub"
  cat > "$stub/gh" <<'GH'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "issue" && "${2:-}" == "list" ]]; then echo '[]'; exit 0; fi
if [[ "${1:-}" == "pr" && "${2:-}" == "list" ]]; then
  echo '[{"number":7,"title":"x","headRefName":"fix/312-grace","state":"OPEN","isDraft":false}]'; exit 0
fi
if [[ "${1:-}" == "issue" && "${2:-}" == "view" ]]; then
  num=$3
  if [[ "$num" == "50" ]]; then
    for a in "$@"; do [[ "$a" == ".state" ]] && { echo OPEN; exit 0; }; done
    echo "stage/implementation"; exit 0
  fi
  # PR-referenced issue 312: simulate a network error (non-404).
  echo "error connecting to api.github.com" >&2
  exit 1
fi
exit 0
GH
  chmod +x "$stub/gh"
  local out exit
  out=$(PATH="$stub:$PATH" bash "$RECONCILE" "$proj" --quiet 2>&1) && exit=0 || exit=$?
  assert "drift4 gh failure: fail-hard" "$exit" 1 "$out" "required GitHub read failed"
  rm -rf "$tmp"
}

# ---------------------------------------------------------------------------
# Case 9: the Drift-4 python helper crashes (malformed PR-list JSON) -> the
# script fails hard instead of skipping PR-ref drift and exiting 0 false-clean.
# ---------------------------------------------------------------------------
run_case_drift4_crash() {
  local tmp; tmp=$(mktemp -d)
  local proj="$tmp/proj" stub="$tmp/bin"
  setup_project "$proj"
  cat > "$proj/.forge/pipeline-state.yaml" <<'ST'
current_feature: 50
current_stage: implementation
issue: 50
ST
  mkdir -p "$stub"
  cat > "$stub/gh" <<'GH'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "issue" && "${2:-}" == "list" ]]; then echo '[]'; exit 0; fi
# Return invalid JSON for the PR list so the Drift-4 python json.loads crashes.
if [[ "${1:-}" == "pr" && "${2:-}" == "list" ]]; then echo 'NOT JSON {{{'; exit 0; fi
if [[ "${1:-}" == "issue" && "${2:-}" == "view" ]]; then
  num=$3
  for a in "$@"; do [[ "$a" == ".state" ]] && { echo OPEN; exit 0; }; done
  echo "stage/implementation"; exit 0
fi
exit 0
GH
  chmod +x "$stub/gh"
  local out exit
  out=$(PATH="$stub:$PATH" bash "$RECONCILE" "$proj" --quiet 2>&1) && exit=0 || exit=$?
  assert "drift4 helper crash: fail-hard" "$exit" 1 "$out" "Drift-4 ref extractor crashed"
  rm -rf "$tmp"
}

run_case_clean
run_case_closed
run_case_alias
run_case_mismatch
run_case_apply
run_case_json
run_case_gh_failure
run_case_drift4_failure
run_case_drift4_crash

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
