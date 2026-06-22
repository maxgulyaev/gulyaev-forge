#!/usr/bin/env bash
# forge-run-state.test.sh — tests for the L2 durable run-state path.
#
# A fake `gh` on PATH stores the run-state comment body in a file so we can
# round-trip publish -> read-remote -> hydrate fully offline, including a title
# with embedded quotes (the injection-safety case).
#
# Usage:  bash scripts/forge-run-state.test.sh
# Exit:   0 all pass, 1 any fail
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
RS="$SCRIPT_DIR/forge-run-state.sh"
PASS=0
FAIL=0

ok()   { printf 'PASS %s\n' "$1"; PASS=$((PASS + 1)); }
bad()  { printf 'FAIL %s\n' "$1"; shift; printf '%s\n' "$*"; FAIL=$((FAIL + 1)); }

# Fake gh storing one comment body in $GH_COMMENT_FILE.
make_gh_stub() {
  local bindir=$1
  mkdir -p "$bindir"
  cat > "$bindir/gh" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
FILE=${GH_COMMENT_FILE:?GH_COMMENT_FILE not set}
sub=${1:-}; shift || true

# gh api repos/.../comments  (list) -> jq picks last with sentinel
if [[ "$sub" == "api" ]]; then
  # Find --jq value and -f body value.
  jq=""; body=""; method="GET"
  args=("$@")
  for ((i=0;i<${#args[@]};i++)); do
    case "${args[$i]}" in
      --jq) jq="${args[$((i+1))]}" ;;
      -X)   method="${args[$((i+1))]}" ;;
      -f)   kv="${args[$((i+1))]}"; [[ "$kv" == body=* ]] && body="${kv#body=}" ;;
    esac
  done
  if [[ "$method" == "PATCH" ]]; then
    printf '%s' "$body" > "$FILE"
    printf '{}\n'
    exit 0
  fi
  # GET list: emulate a comments array. If a comment exists, return it.
  if [[ -s "$FILE" ]]; then
    existing=$(cat "$FILE")
    # jq asks either for the body or the id.
    if [[ "$jq" == *".id"* ]]; then
      printf '101\n'
    else
      printf '%s\n' "$existing"
    fi
  else
    printf '\n'
  fi
  exit 0
fi

# gh issue comment <n> --repo R --body B
if [[ "$sub" == "issue" && "${1:-}" == "comment" ]]; then
  args=("$@")
  for ((i=0;i<${#args[@]};i++)); do
    [[ "${args[$i]}" == "--body" ]] && printf '%s' "${args[$((i+1))]}" > "$FILE"
  done
  printf 'https://example/comment\n'
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
CFG
  git -C "$root" init -q
  git -C "$root" config user.email t@t.t
  git -C "$root" config user.name t
}

# ---------------------------------------------------------------------------
# Round-trip with a quote-bearing title (injection safety).
# ---------------------------------------------------------------------------
run_roundtrip() {
  local tmp; tmp=$(mktemp -d)
  local proj="$tmp/proj" stub="$tmp/bin"
  setup_project "$proj"
  make_gh_stub "$stub"
  export GH_COMMENT_FILE="$tmp/comment.md"
  : > "$GH_COMMENT_FILE"

  local tricky='fix "quoted" & <html> title with, comma'
  # begin a run locally
  PATH="$stub:$PATH" bash "$RS" begin-bugfix "$proj" 369 "$tricky" >/dev/null
  PATH="$stub:$PATH" bash "$RS" set-stage "$proj" qa >/dev/null
  # publish to issue
  local pub
  pub=$(PATH="$stub:$PATH" bash "$RS" publish "$proj" 2>&1) || { bad "publish failed" "$pub"; rm -rf "$tmp"; return; }
  grep -q 'forge-run-state' "$GH_COMMENT_FILE" || { bad "publish: sentinel missing" "$(cat "$GH_COMMENT_FILE")"; rm -rf "$tmp"; return; }
  ok "publish: wrote sentinel comment"

  # read-remote returns valid JSON with the tricky title intact
  local remote
  remote=$(PATH="$stub:$PATH" bash "$RS" read-remote "$proj" 369 2>&1) || { bad "read-remote failed" "$remote"; rm -rf "$tmp"; return; }
  if printf '%s' "$remote" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["stage"]=="qa"; assert d["title"]=="fix \"quoted\" & <html> title with, comma"' 2>/dev/null; then
    ok "read-remote: valid JSON, tricky title intact"
  else
    bad "read-remote: JSON parse/title mismatch" "$remote"
  fi

  # hydrate a DIFFERENT (simulated other-machine) project from the same issue
  local proj2="$tmp/proj2"
  setup_project "$proj2"
  PATH="$stub:$PATH" bash "$RS" hydrate "$proj2" 369 >/dev/null 2>&1 || { bad "hydrate failed"; rm -rf "$tmp"; return; }
  local show
  show=$(PATH="$stub:$PATH" bash "$RS" show "$proj2" 2>&1)
  if grep -q 'stage: qa' <<< "$show" && grep -q 'issue: #369' <<< "$show"; then
    ok "hydrate: cross-machine cache rebuilt from issue"
  else
    bad "hydrate: derived cache wrong" "$show"
  fi

  unset GH_COMMENT_FILE
  rm -rf "$tmp"
}

run_roundtrip

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
