#!/usr/bin/env bash
# forge-config-check.test.sh — fixture tests for forge-config-check.sh
#
# Per codex W0 P1.5 — shell/awk YAML parsing is brittle; fixtures are the safety belt.
# 3 fixtures cover: (a) all-valid config, (b) missing required path, (c) edge cases
# (comments mid-block, quoted paths, anchored runbook, empty if_exists, disabled
# stage agent with no prompt_file).
#
# Usage:
#   bash scripts/forge-config-check.test.sh
#
# Exit codes:
#   0 — all fixtures pass
#   1 — at least one fixture failed expectations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHECK="$SCRIPT_DIR/forge-config-check.sh"
FIXTURES="$SCRIPT_DIR/fixtures/forge-config-check"

if [[ ! -x "$CHECK" ]]; then
  chmod +x "$CHECK" 2>/dev/null || true
fi

PASS=0
FAIL=0

run_fixture() {
  local name="$1"
  local expected_exit="$2"
  local expected_grep="$3"

  local dir="$FIXTURES/$name"
  if [[ ! -d "$dir" ]]; then
    printf 'FAIL %-20s — fixture dir missing: %s\n' "$name" "$dir"
    FAIL=$((FAIL + 1))
    return
  fi

  local out
  local rc=0
  out=$(bash "$CHECK" "$dir" 2>&1) || rc=$?

  if [[ "$rc" != "$expected_exit" ]]; then
    printf 'FAIL %-20s — expected exit %s, got %s\n' "$name" "$expected_exit" "$rc"
    printf '%s\n' "$out" | sed 's/^/     /'
    FAIL=$((FAIL + 1))
    return
  fi

  if [[ -n "$expected_grep" ]]; then
    if ! printf '%s\n' "$out" | grep -q -- "$expected_grep"; then
      printf 'FAIL %-20s — output missing expected substring: %s\n' "$name" "$expected_grep"
      printf '%s\n' "$out" | sed 's/^/     /'
      FAIL=$((FAIL + 1))
      return
    fi
  fi

  printf 'PASS %-20s (exit %s)\n' "$name" "$rc"
  PASS=$((PASS + 1))
}

printf '== forge-config-check fixture tests ==\n\n'

# Fixture 1: all-valid config — script must exit 0 with no errors
run_fixture "valid" 0 "errors:   0"

# Fixture 2: required path missing — script must exit 1 and name the missing path
run_fixture "missing-required" 1 "docs/does-not-exist.md"

# Fixture 3: edge cases (quoted paths, anchors, commented entries, empty if_exists)
#  — script must exit 0 AND must not warn about the commented-out baseline / disabled legal-reviewer
run_fixture "edge-cases" 0 "errors:   0"

# Extra check on edge-cases output: commented baseline must NOT appear
EDGE_OUT=$(bash "$CHECK" "$FIXTURES/edge-cases" 2>&1 || true)
if printf '%s\n' "$EDGE_OUT" | grep -q "docs/old-baseline.md"; then
  printf 'FAIL %-20s — picked up commented-out baseline path\n' "edge-cases-comments"
  FAIL=$((FAIL + 1))
else
  printf 'PASS %-20s (commented baseline ignored)\n' "edge-cases-comments"
  PASS=$((PASS + 1))
fi

# Extra check: anchored runbook resolves correctly
if printf '%s\n' "$EDGE_OUT" | grep -q "release_targets.ios_testflight.runbook → docs/runbook.md#testflight"; then
  printf 'PASS %-20s (anchored runbook resolved)\n' "edge-cases-anchor"
  PASS=$((PASS + 1))
else
  printf 'FAIL %-20s (anchored runbook NOT resolved)\n' "edge-cases-anchor"
  printf '%s\n' "$EDGE_OUT" | sed 's/^/     /'
  FAIL=$((FAIL + 1))
fi

printf '\n== summary ==\n'
printf 'pass: %d\n' "$PASS"
printf 'fail: %d\n' "$FAIL"

if (( FAIL > 0 )); then
  exit 1
fi
exit 0
