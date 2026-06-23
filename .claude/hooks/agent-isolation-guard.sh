#!/usr/bin/env bash
# PreToolUse guard for the Agent tool — require worktree isolation for
# background subagents, to prevent working-tree git collisions between
# parallel non-isolated agents.
#
# Why: on 2026-06-22 two non-isolated background Agents ran on the same
# working tree; one agent's branch checkout discarded the other's
# uncommitted changes, losing all of issue #416's in-progress work. Any
# background subagent that may write MUST get its own git worktree.
#
# Policy: DENY when run_in_background == true AND isolation != "worktree"
# AND subagent_type is not a known read-only type. Foreground agents and
# read-only types (Explore, Plan, statusline-setup, claude-code-guide)
# pass — they cannot cause the parallel-mutation collision.
#
# Fail-OPEN: if jq is missing or the payload is unparseable, allow. This
# is a safety net for an orchestration mistake, not a security boundary;
# it must never wedge legitimate work.
set -uo pipefail

payload="$(cat)"

# No jq → cannot evaluate safely → allow (fail-open).
command -v jq >/dev/null 2>&1 || exit 0

# Capture jq's exit status: if jq errors (e.g. a valid object followed by
# trailing malformed input — jq can print a partial verdict for the first
# object AND exit nonzero), DISCARD whatever it printed and fail-open. The
# `if !` only takes the verdict when jq exited 0, so a partial deny on a
# malformed payload can never leak through as a real deny.
if ! verdict="$(printf '%s' "$payload" | jq -c '
  (.tool_input.subagent_type // "") as $t
  | (["Explore","Plan","statusline-setup","claude-code-guide"] | index($t)) as $ro
  | if (.tool_input.run_in_background == true)
       and ((.tool_input.isolation // "") != "worktree")
       and ($ro == null)
    then {
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: "Background subagents that may write MUST set isolation:\"worktree\". Non-isolated parallel background Agents collide on shared git state — this discarded all of issue #416 work on 2026-06-22. Re-issue this Agent call with isolation:\"worktree\"; or run it in the foreground; or, if it is strictly read-only, use subagent_type Explore or Plan."
      }
    }
    else empty end
' 2>/dev/null)"; then
  exit 0
fi

# jq exited 0: empty verdict → allow; non-empty → emit the deny.
[[ -n "$verdict" ]] && printf '%s\n' "$verdict"
exit 0
