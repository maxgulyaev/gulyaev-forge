#!/usr/bin/env bash
# glm-review — headless GLM-5.2 (z.ai) reviewer: the THIRD independent model
# family alongside Claude (orchestrator) and Codex (`codex exec`). Mirrors the
# Codex shape so it slots into the same triple-review flow:
#
#   git diff origin/main...HEAD | glm-review "Review per REVIEW.md, list P0/P1/P2"
#
# First arg = the review/explore prompt. Optional diff/context piped on stdin
# is appended. Prints GLM's text answer to stdout; non-zero exit on API error.
#
# Official path: z.ai GLM Coding Plan via the Anthropic-compatible endpoint.
# Key lives in ~/.config/spodi/env (ZAI_API_KEY=...), NEVER in a repo.
#
# ⚠ PRIVACY: z.ai is China-hosted. Do NOT feed auth/billing/secret-bearing
#   diffs to this reviewer — keep those on Claude + Codex only.
set -uo pipefail

CONF="${HOME}/.config/spodi/env"
# shellcheck disable=SC1090
[ -f "$CONF" ] && source "$CONF"
: "${ZAI_API_KEY:?ZAI_API_KEY not set — add 'export ZAI_API_KEY=...' to ~/.config/spodi/env}"

BASE="${ZAI_ANTHROPIC_BASE:-https://api.z.ai/api/anthropic}"
MODEL="${ZAI_MODEL:-glm-5.2}"
MAXTOK="${ZAI_MAX_TOKENS:-8192}"

PROMPT="${1:?usage: glm-review \"<prompt>\" [< diff-on-stdin]}"

# Fold any piped diff/context into the user turn.
if [ ! -t 0 ]; then
  DIFF="$(cat)"
  [ -n "$DIFF" ] && PROMPT="${PROMPT}

--- DIFF / CONTEXT ---
${DIFF}"
fi

PAYLOAD="$(jq -nc --arg m "$MODEL" --argjson mt "$MAXTOK" --arg p "$PROMPT" \
  '{model:$m, max_tokens:$mt, messages:[{role:"user", content:$p}]}')"

RESP="$(curl -sS -m 600 "${BASE}/v1/messages" \
  -H "Authorization: Bearer ${ZAI_API_KEY}" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d "$PAYLOAD")" || { echo "glm-review: curl failed reaching ${BASE}" >&2; exit 1; }

# Anthropic response: {content:[{type:"text",text:...}]}. On error z.ai returns
# {error:{message:...}} (or {type:"error",...}) — surface it and fail.
TEXT="$(printf '%s' "$RESP" | jq -r '
  if (.content? // empty) then ([.content[] | select(.type=="text") | .text] | join("\n"))
  else empty end' 2>/dev/null)"

if [ -n "$TEXT" ]; then
  printf '%s\n' "$TEXT"
else
  echo "glm-review: no text in response — API error or unexpected shape:" >&2
  printf '%s\n' "$RESP" | jq -r '.error.message // .message // .' 2>/dev/null >&2 || printf '%s\n' "$RESP" >&2
  exit 1
fi
