#!/usr/bin/env bash
# commit-msg.test.sh — proves the L4 hook is ADVISORY (never blocks) and warns
# on the right conditions. gh is stubbed; a real temp git repo wires the hook
# via core.hooksPath and we assert the actual `git commit` outcome.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
HOOK="$SCRIPT_DIR/commit-msg"
PASS=0
FAIL=0
ok()  { printf 'PASS %s\n' "$1"; PASS=$((PASS + 1)); }
bad() { printf 'FAIL %s\n' "$1"; shift; printf '%s\n' "$*"; FAIL=$((FAIL + 1)); }

make_gh_stub() {
  local bindir=$1
  mkdir -p "$bindir"
  # states.tsv: <num>\t<STATE>\t<labels-csv>
  cat > "$bindir/gh" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
DIR=${GH_STUB_DIR:?}
if [[ "${1:-}" == "issue" && "${2:-}" == "view" ]]; then
  num=$3
  row=$(awk -F'\t' -v n="$num" '$1==n{print $2"\t"$3}' "$DIR/states.tsv")
  [[ -n "$row" ]] || { exit 1; }   # unknown issue -> nonzero, hook stays quiet
  printf '%s\n' "$row"
  exit 0
fi
exit 0
STUB
  chmod +x "$bindir/gh"
}

setup_repo() {
  local root=$1 stub=$2
  mkdir -p "$root/.forge" "$root/.githooks"
  cat > "$root/.forge/config.yaml" <<'CFG'
project:
  name: t
  repo: https://github.com/acme/t
tracking:
  labels:
    stage_prefix: "stage/"
CFG
  install -m 0755 "$HOOK" "$root/.githooks/commit-msg"
  git -C "$root" init -q
  git -C "$root" config user.email t@t.t
  git -C "$root" config user.name t
  git -C "$root" config core.hooksPath .githooks
}

run() {
  local tmp; tmp=$(mktemp -d)
  local repo="$tmp/repo" stub="$tmp/bin"
  make_gh_stub "$stub"
  setup_repo "$repo" "$stub"
  export GH_STUB_DIR="$tmp/gh"; mkdir -p "$GH_STUB_DIR"
  printf '10\tCLOSED\t\n20\tOPEN\tP1\n30\tOPEN\tstage/qa,P1\n' > "$GH_STUB_DIR/states.tsv"

  # Case A: references CLOSED issue -> commit SUCCEEDS, warning printed.
  echo a > "$repo/a"; git -C "$repo" add a
  local out rc
  out=$(cd "$repo" && PATH="$stub:$PATH" git commit -m "fix something #10" 2>&1) && rc=0 || rc=$?
  if [[ "$rc" == 0 ]] && grep -q 'CLOSED' <<< "$out"; then ok "closed ref: commit succeeds + warns"; else bad "closed ref" "rc=$rc out=$out"; fi

  # Case B: references OPEN issue with NO stage label -> succeeds + warns.
  echo b > "$repo/b"; git -C "$repo" add b
  out=$(cd "$repo" && PATH="$stub:$PATH" git commit -m "wip #20" 2>&1) && rc=0 || rc=$?
  if [[ "$rc" == 0 ]] && grep -q 'no stage/' <<< "$out"; then ok "unlabelled ref: commit succeeds + warns"; else bad "unlabelled ref" "rc=$rc out=$out"; fi

  # Case C: references OPEN issue WITH stage label -> succeeds, NO warning.
  echo c > "$repo/c"; git -C "$repo" add c
  out=$(cd "$repo" && PATH="$stub:$PATH" git commit -m "feat #30" 2>&1) && rc=0 || rc=$?
  if [[ "$rc" == 0 ]] && ! grep -q 'forge (advisory)' <<< "$out"; then ok "labelled ref: succeeds, silent"; else bad "labelled ref" "rc=$rc out=$out"; fi

  # Case D: no issue ref at all -> succeeds, silent.
  echo d > "$repo/d"; git -C "$repo" add d
  out=$(cd "$repo" && PATH="$stub:$PATH" git commit -m "chore: tidy" 2>&1) && rc=0 || rc=$?
  if [[ "$rc" == 0 ]] && ! grep -q 'forge (advisory)' <<< "$out"; then ok "no ref: succeeds, silent"; else bad "no ref" "rc=$rc out=$out"; fi

  # Case E: gh missing entirely (PATH without stub) -> succeeds, silent.
  echo e > "$repo/e"; git -C "$repo" add e
  out=$(cd "$repo" && PATH="/usr/bin:/bin" git commit -m "fix #10" 2>&1) && rc=0 || rc=$?
  if [[ "$rc" == 0 ]]; then ok "no gh: commit still succeeds"; else bad "no gh" "rc=$rc out=$out"; fi

  unset GH_STUB_DIR
  rm -rf "$tmp"
}

run
printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]
