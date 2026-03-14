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

copy_command() {
  local src=$1
  local dest_name=$2
  install -m 0644 "$src" "$DEST/$dest_name"
  printf 'Installed %s\n' "${DEST#$TARGET/}/$dest_name"
}

install_product_hook() {
  mkdir -p "$HOOK_DEST"
  install -m 0755 "$FORGE_DIR/core/templates/githooks/pre-push" "$HOOK_DEST/pre-push"
  printf 'Installed %s\n' "${HOOK_DEST#$TARGET/}/pre-push"
  if git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1; then
    git -C "$TARGET" config core.hooksPath .githooks
    printf 'Configured git hooksPath: .githooks\n'
  else
    printf 'Skipped hooksPath config (not a git repo yet)\n'
  fi
}

case "$MODE" in
  product)
    copy_command "$FORGE_DIR/adapters/claude-code/commands/product/bugfix.md" "bugfix.md"
    copy_command "$FORGE_DIR/adapters/claude-code/commands/product/feature.md" "feature.md"
    copy_command "$FORGE_DIR/adapters/claude-code/commands/product/investigate.md" "investigate.md"
    copy_command "$FORGE_DIR/adapters/claude-code/commands/product/continue.md" "continue.md"
    copy_command "$FORGE_DIR/adapters/claude-code/commands/product/gate.md" "gate.md"
    copy_command "$FORGE_DIR/adapters/claude-code/commands/product/review.md" "review.md"
    copy_command "$FORGE_DIR/adapters/claude-code/commands/product/release.md" "release.md"
    install_product_hook
    ;;
  self)
    copy_command "$FORGE_DIR/adapters/claude-code/commands/self/self.md" "self.md"
    ;;
  *)
    usage
    exit 1
    ;;
esac
