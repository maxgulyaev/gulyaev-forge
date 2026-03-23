#!/usr/bin/env bash
set -euo pipefail

# forge-rules-check.sh — parse BUSINESS_RULES.md and verify tested rules
#
# Usage:
#   bash forge-rules-check.sh <project-dir>              # full report
#   bash forge-rules-check.sh <project-dir> --summary    # counts only
#   bash forge-rules-check.sh <project-dir> --verify     # check test files exist
#   bash forge-rules-check.sh <project-dir> --gate       # gate-ready summary for QA

PROJ=${1:-.}
MODE=${2:-}

RULES_FILE="$PROJ/docs/BUSINESS_RULES.md"

if [[ ! -f "$RULES_FILE" ]]; then
  printf 'No BUSINESS_RULES.md found at %s\n' "$RULES_FILE" >&2
  printf 'Skipping rules check.\n' >&2
  exit 0
fi

# --- Parse rules ---

total=0
tested=0
untested=0
missing_tests=0
missing_test_files=()
tested_rules=()
untested_rules=()

current_section=""

while IFS= read -r line; do
  # Track section headers
  if [[ "$line" =~ ^##[[:space:]] ]]; then
    current_section=$(printf '%s' "$line" | sed 's/^##[[:space:]]*//')
  fi
  if [[ "$line" =~ ^###[[:space:]] ]]; then
    current_section=$(printf '%s' "$line" | sed 's/^###[[:space:]]*//')
  fi

  # Match tested rules: - [x] `platform` Description → test_ref
  if [[ "$line" =~ ^-[[:space:]]\[x\] ]]; then
    total=$((total + 1))
    tested=$((tested + 1))

    # Extract test reference after →
    if [[ "$line" =~ →[[:space:]]*\`?([^\`]+)\`? ]]; then
      test_ref="${BASH_REMATCH[1]}"
      # Extract just the filename part (before :)
      test_file=$(printf '%s' "$test_ref" | cut -d: -f1)
      tested_rules+=("$current_section|$test_file|$line")
    else
      tested_rules+=("$current_section|NO_REF|$line")
    fi
  fi

  # Match untested rules: - [ ] `platform` Description
  if [[ "$line" =~ ^-[[:space:]]\[[[:space:]]\] ]]; then
    total=$((total + 1))
    untested=$((untested + 1))
    untested_rules+=("$current_section|$line")
  fi
done < "$RULES_FILE"

# --- Verify test files exist ---

verify_tests() {
  for entry in "${tested_rules[@]}"; do
    IFS='|' read -r section test_file rule <<< "$entry"
    if [[ "$test_file" == "NO_REF" ]]; then
      printf '  WARN  [%s] Rule has [x] but no test reference: %s\n' "$section" "$rule"
      missing_tests=$((missing_tests + 1))
      continue
    fi

    # Search for the test file in the project
    found=$(find "$PROJ" -name "$test_file" \
      -not -path "*/node_modules/*" \
      -not -path "*/.build/*" \
      -not -path "*/.git/*" \
      -not -path "*/Pods/*" \
      2>/dev/null | head -1)

    if [[ -z "$found" ]]; then
      printf '  FAIL  [%s] Test file not found: %s\n' "$section" "$test_file"
      missing_test_files+=("$test_file")
      missing_tests=$((missing_tests + 1))
    else
      if [[ "$MODE" != "--summary" && "$MODE" != "--gate" ]]; then
        printf '  OK    [%s] %s -> %s\n' "$section" "$test_file" "$found"
      fi
    fi
  done
}

# --- Output ---

if [[ "$total" -eq 0 ]]; then
  printf 'No rules found in %s\n' "$RULES_FILE"
  exit 0
fi

coverage_pct=$((tested * 100 / total))

case "$MODE" in
  --summary)
    printf 'Rules: %d total, %d tested [x], %d untested [ ], coverage %d%%\n' \
      "$total" "$tested" "$untested" "$coverage_pct"
    ;;

  --verify)
    printf '== Rules Verification ==\n'
    printf 'File: %s\n\n' "$RULES_FILE"
    verify_tests
    printf '\nSummary: %d total, %d tested, %d untested, %d missing/broken test refs\n' \
      "$total" "$tested" "$untested" "$missing_tests"
    printf 'Coverage: %d%%\n' "$coverage_pct"
    if [[ "$missing_tests" -gt 0 ]]; then
      exit 1
    fi
    ;;

  --gate)
    printf '## Business Rules Coverage\n\n'
    printf '| Metric | Value |\n'
    printf '|--------|-------|\n'
    printf '| Total rules | %d |\n' "$total"
    printf '| Tested `[x]` | %d |\n' "$tested"
    printf '| Untested `[ ]` | %d |\n' "$untested"
    printf '| Coverage | %d%% |\n\n' "$coverage_pct"

    # Verify and report missing
    verify_output=$(verify_tests 2>&1) || true
    fails=$(printf '%s' "$verify_output" | grep -c 'FAIL' || true)
    warns=$(printf '%s' "$verify_output" | grep -c 'WARN' || true)

    if [[ "$fails" -gt 0 || "$warns" -gt 0 ]]; then
      printf '### Issues\n\n'
      printf '%s\n' "$verify_output" | grep -E 'FAIL|WARN' || true
      printf '\n'
    fi

    if [[ "$untested" -gt 0 ]]; then
      printf '### Untested Rules\n\n'
      for entry in "${untested_rules[@]}"; do
        IFS='|' read -r section rule <<< "$entry"
        printf '- [%s] %s\n' "$section" "$rule"
      done
      printf '\n'
    fi
    ;;

  *)
    printf '== Business Rules Report ==\n'
    printf 'File: %s\n\n' "$RULES_FILE"
    printf 'Total: %d | Tested: %d | Untested: %d | Coverage: %d%%\n\n' \
      "$total" "$tested" "$untested" "$coverage_pct"

    if [[ "${#tested_rules[@]}" -gt 0 ]]; then
      printf '--- Tested Rules ---\n'
      verify_tests
    fi

    if [[ "${#untested_rules[@]}" -gt 0 ]]; then
      printf '\n--- Untested Rules ---\n'
      for entry in "${untested_rules[@]}"; do
        IFS='|' read -r section rule <<< "$entry"
        printf '  GAP   [%s] %s\n' "$section" "$rule"
      done
    fi

    printf '\n'
    ;;
esac
