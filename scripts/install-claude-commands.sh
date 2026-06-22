#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash scripts/install-claude-commands.sh product <project-dir>
  bash scripts/install-claude-commands.sh self <forge-dir>
EOF
}

MODE=${1:-}
TARGET=${2:-}

if [[ -z "$MODE" || -z "$TARGET" ]]; then
  usage
  exit 1
fi

if [[ ! -d "$TARGET" ]]; then
  printf 'Target directory not found: %s\n' "$TARGET"
  exit 1
fi

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
FORGE_DIR=$(cd "$SCRIPT_DIR/.." && pwd -P)
TARGET=$(cd "$TARGET" && pwd -P)
DEST="$TARGET/.claude/commands/forge"
HOOK_DEST="$TARGET/.githooks"

mkdir -p "$DEST"

escape_sed_replacement() {
  printf '%s' "$1" | sed -e 's/[&|]/\\&/g'
}

render_file() {
  local src=$1
  local dest=$2
  local mode=${3:-0644}
  local forge_dir_escaped

  forge_dir_escaped=$(escape_sed_replacement "$FORGE_DIR")
  mkdir -p "$(dirname "$dest")"
  sed "s|__FORGE_DIR__|$forge_dir_escaped|g" "$src" >"$dest"
  chmod "$mode" "$dest"
}

copy_command() {
  local src=$1
  local dest_name=$2
  install -m 0644 "$src" "$DEST/$dest_name"
  printf 'Installed %s\n' "${DEST#$TARGET/}/$dest_name"
}

render_command() {
  local src=$1
  local dest_name=$2
  render_file "$src" "$DEST/$dest_name" 0644
  printf 'Installed %s\n' "${DEST#$TARGET/}/$dest_name"
}

install_product_hook() {
  mkdir -p "$HOOK_DEST"
  render_file "$FORGE_DIR/core/templates/githooks/pre-push" "$HOOK_DEST/pre-push" 0755
  printf 'Installed %s\n' "${HOOK_DEST#$TARGET/}/pre-push"
  # L4 — advisory (non-blocking) commit-msg hook. Warns on stale #NNN refs but
  # never exits non-zero, so it survives the manual/Codex/multi-machine workflow.
  if [[ -f "$FORGE_DIR/core/templates/githooks/commit-msg" ]]; then
    render_file "$FORGE_DIR/core/templates/githooks/commit-msg" "$HOOK_DEST/commit-msg" 0755
    printf 'Installed %s\n' "${HOOK_DEST#"$TARGET"/}/commit-msg"
  fi
  if git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1; then
    git -C "$TARGET" config core.hooksPath .githooks
    printf 'Configured git hooksPath: .githooks\n'
  else
    printf 'Skipped hooksPath config (not a git repo yet)\n'
  fi
}

# L3 — central drift sentinel. Drops the portable GitHub Actions workflow + its
# Python check into the target repo. Server-side, this is the only layer that
# catches drift introduced on any machine.
install_drift_sentinel() {
  local wf_src="$FORGE_DIR/templates/github/forge-drift-sentinel.yml"
  local py_src="$FORGE_DIR/templates/github/forge_drift_sentinel.py"
  if [[ ! -f "$wf_src" || ! -f "$py_src" ]]; then
    printf 'Skipped drift sentinel (templates missing)\n'
    return 0
  fi
  local wf_dest="$TARGET/.github/workflows/forge-drift-sentinel.yml"
  local py_dest="$TARGET/.github/forge/forge_drift_sentinel.py"
  mkdir -p "$(dirname "$wf_dest")" "$(dirname "$py_dest")"
  install -m 0644 "$wf_src" "$wf_dest"
  install -m 0755 "$py_src" "$py_dest"
  printf 'Installed %s\n' "${wf_dest#"$TARGET"/}"
  printf 'Installed %s\n' "${py_dest#"$TARGET"/}"
}

case "$MODE" in
  product)
    render_command "$FORGE_DIR/adapters/claude-code/commands/product/work.md" "work.md"
    render_command "$FORGE_DIR/adapters/claude-code/commands/product/bugfix.md" "bugfix.md"
    render_command "$FORGE_DIR/adapters/claude-code/commands/product/feature.md" "feature.md"
    render_command "$FORGE_DIR/adapters/claude-code/commands/product/investigate.md" "investigate.md"
    render_command "$FORGE_DIR/adapters/claude-code/commands/product/continue.md" "continue.md"
    render_command "$FORGE_DIR/adapters/claude-code/commands/product/gate.md" "gate.md"
    render_command "$FORGE_DIR/adapters/claude-code/commands/product/review.md" "review.md"
    render_command "$FORGE_DIR/adapters/claude-code/commands/product/release.md" "release.md"
    install_product_hook
    install_drift_sentinel
    ;;
  self)
    copy_command "$FORGE_DIR/adapters/claude-code/commands/self/self.md" "self.md"
    ;;
  *)
    usage
    exit 1
    ;;
esac
