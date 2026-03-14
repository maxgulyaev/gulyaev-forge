#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash scripts/forge-init.sh --project <project-dir> [--labels] [--no-claude-commands] [--force] [--dry-run]
  bash scripts/forge-init.sh <project-dir> [--labels] [--no-claude-commands] [--force] [--dry-run]

Examples:
  bash scripts/forge-init.sh --project /Users/maxgulyaev/Documents/Dev/my-project
  bash scripts/forge-init.sh . --labels
EOF
}

note() {
  printf '%s\n' "${1-}"
}

warn() {
  printf 'WARN %s\n' "$1" >&2
}

copy_template() {
  local src=$1
  local dest=$2
  local mode=${3:-0644}

  if [[ -e "$dest" && "$FORCE" -eq 0 ]]; then
    note "skip  $dest (already exists)"
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    note "create $dest"
    return
  fi

  mkdir -p "$(dirname "$dest")"
  install -m "$mode" "$src" "$dest"
  note "create $dest"
}

write_text_file() {
  local dest=$1
  local mode=${2:-0644}
  local content=$3

  if [[ -e "$dest" && "$FORCE" -eq 0 ]]; then
    note "skip  $dest (already exists)"
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    note "create $dest"
    return
  fi

  mkdir -p "$(dirname "$dest")"
  printf '%s' "$content" >"$dest"
  chmod "$mode" "$dest"
  note "create $dest"
}

ensure_line_in_file() {
  local file=$1
  local line=$2

  if [[ -f "$file" ]] && grep -Fxq "$line" "$file"; then
    note "skip  $file (already contains $line)"
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    if [[ -f "$file" ]]; then
      note "update $file (+ $line)"
    else
      note "create $file"
    fi
    return
  fi

  mkdir -p "$(dirname "$file")"
  touch "$file"
  printf '%s\n' "$line" >>"$file"
  note "update $file (+ $line)"
}

is_git_repo() {
  git -C "$1" rev-parse --git-dir >/dev/null 2>&1
}

create_label() {
  local repo=$1
  local name=$2
  local color=$3
  local description=$4

  if gh label create "$name" --color "$color" --description "$description" --repo "$repo" >/dev/null 2>&1; then
    note "label  $name"
  else
    note "skip  label $name"
  fi
}

create_standard_labels() {
  local repo=$1

  create_label "$repo" "level/epic" "7B68EE" "Feature/initiative"
  create_label "$repo" "level/story" "4169E1" "User-facing behavior"
  create_label "$repo" "level/task" "2E8B57" "Concrete work item"

  create_label "$repo" "stage/strategy" "E0E0E0" "Strategy in progress"
  create_label "$repo" "stage/discovery" "E0E0E0" "Discovery in progress"
  create_label "$repo" "stage/prd" "E0E0E0" "Requirements defined"
  create_label "$repo" "stage/design" "E0E0E0" "Design in progress"
  create_label "$repo" "stage/architecture" "E0E0E0" "Architecture defined"
  create_label "$repo" "stage/implementation" "E0E0E0" "In development"
  create_label "$repo" "stage/review" "E0E0E0" "In code review"
  create_label "$repo" "stage/qa" "E0E0E0" "In QA"
  create_label "$repo" "stage/shipped" "E0E0E0" "Deployed to production"

  create_label "$repo" "discipline/design" "F0C0FF" "UI/UX work"
  create_label "$repo" "discipline/backend" "C0F0C0" "API/DB work"
  create_label "$repo" "discipline/frontend" "C0E0FF" "Web UI work"
  create_label "$repo" "discipline/mobile" "FFE0C0" "iOS/Android work"
  create_label "$repo" "discipline/test" "FFC0C0" "Test/QA work"
  create_label "$repo" "discipline/devops" "E0E0E0" "Deploy/infra work"
  create_label "$repo" "discipline/analytics" "FFF0C0" "Metrics/monitoring work"

  create_label "$repo" "source/prd" "FFFFFF" "From PRD"
  create_label "$repo" "source/bug" "FFFFFF" "From bug report"
  create_label "$repo" "source/analytics" "FFFFFF" "From product analytics"
  create_label "$repo" "source/monitoring" "FFFFFF" "From tech monitoring"
  create_label "$repo" "source/scout" "FFFFFF" "From technology evaluation"

  create_label "$repo" "type/feature" "FFFFFF" "New functionality"
  create_label "$repo" "type/bug" "FFFFFF" "Defect"
  create_label "$repo" "type/improvement" "FFFFFF" "Enhancement"
  create_label "$repo" "type/tech-debt" "FFFFFF" "Internal quality"
  create_label "$repo" "type/research" "FFFFFF" "Discovery task"
}

PROJECT=''
DRY_RUN=0
FORCE=0
INSTALL_LABELS=0
INSTALL_CLAUDE_COMMANDS=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      PROJECT=${2:-}
      shift 2
      ;;
    --labels)
      INSTALL_LABELS=1
      shift
      ;;
    --no-claude-commands)
      INSTALL_CLAUDE_COMMANDS=0
      shift
      ;;
    --force)
      FORCE=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      usage
      exit 1
      ;;
    *)
      if [[ -z "$PROJECT" ]]; then
        PROJECT=$1
        shift
      else
        usage
        exit 1
      fi
      ;;
  esac
done

if [[ -z "$PROJECT" ]]; then
  usage
  exit 1
fi

if [[ ! -d "$PROJECT" ]]; then
  printf 'Target directory not found: %s\n' "$PROJECT" >&2
  exit 1
fi

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
FORGE_DIR=$(cd "$SCRIPT_DIR/.." && pwd -P)
PROJECT=$(cd "$PROJECT" && pwd -P)

note "== forge init =="
note "Project: $PROJECT"
if [[ "$DRY_RUN" -eq 1 ]]; then
  note "Mode: dry-run"
fi

copy_template "$FORGE_DIR/core/templates/project-context.yaml" "$PROJECT/.forge/config.yaml"
copy_template "$FORGE_DIR/core/templates/pipeline-state.yaml" "$PROJECT/.forge/pipeline-state.yaml"
copy_template "$FORGE_DIR/core/templates/CLAUDE.md.template" "$PROJECT/CLAUDE.md"
copy_template "$FORGE_DIR/core/templates/REVIEW.md.template" "$PROJECT/REVIEW.md"
copy_template "$FORGE_DIR/core/templates/project-reviewer-prompt.md" "$PROJECT/.forge/reviewers/code-review.md"

copy_template "$FORGE_DIR/core/templates/project-overlay-skill.md" "$PROJECT/.forge/skills/strategy.md"
copy_template "$FORGE_DIR/core/templates/project-overlay-skill.md" "$PROJECT/.forge/skills/prd.md"
copy_template "$FORGE_DIR/core/templates/project-overlay-skill.md" "$PROJECT/.forge/skills/architecture.md"
copy_template "$FORGE_DIR/core/templates/project-overlay-skill.md" "$PROJECT/.forge/skills/implementation.md"
copy_template "$FORGE_DIR/core/templates/project-overlay-skill.md" "$PROJECT/.forge/skills/qa.md"

write_text_file "$PROJECT/.forge/skills/README.md" 0644 "# Project Overlay Skills\n\nХрани здесь тонкие stage-specific overlay инструкции для этого проекта.\nНе копируй целиком base skills из forge.\n"

write_text_file "$PROJECT/docs/strategy/README.md" 0644 "# Strategy\n\nСтратегические документы и обновления направления продукта.\n"
write_text_file "$PROJECT/docs/research/README.md" 0644 "# Research\n\nDiscovery-отчеты, конкурентный ресерч и исследовательские заметки по продукту.\n"
write_text_file "$PROJECT/docs/prd/README.md" 0644 "# PRD\n\nПолные продуктовые спецификации.\n"
write_text_file "$PROJECT/docs/prd/stories/README.md" 0644 "# Story Shards\n\nАтомарные story-файлы, подготовленные из PRD для дальнейшей реализации.\n"
write_text_file "$PROJECT/docs/architecture/README.md" 0644 "# Architecture\n\nТехнические дизайны, ADR и архитектурные решения.\n"
write_text_file "$PROJECT/docs/analytics/README.md" 0644 "# Analytics\n\nБазовые метрики, отчеты и post-ship аналитика.\n"

ensure_line_in_file "$PROJECT/.gitignore" ".forge/active-run.env"

if [[ "$INSTALL_CLAUDE_COMMANDS" -eq 1 ]]; then
  if [[ "$DRY_RUN" -eq 1 ]]; then
    note "run   bash $FORGE_DIR/scripts/install-claude-commands.sh product $PROJECT"
  else
    bash "$FORGE_DIR/scripts/install-claude-commands.sh" product "$PROJECT"
  fi
fi

if [[ "$INSTALL_LABELS" -eq 1 ]]; then
  if ! command -v gh >/dev/null 2>&1; then
    warn "GitHub CLI not installed; skipping label creation"
  elif ! is_git_repo "$PROJECT"; then
    warn "Project is not a git repo; skipping label creation"
  else
    REPO_URL=$(git -C "$PROJECT" remote get-url origin 2>/dev/null || true)
    if [[ -z "$REPO_URL" ]]; then
      warn "No git remote origin found; skipping label creation"
    elif [[ "$DRY_RUN" -eq 1 ]]; then
      note "labels $REPO_URL"
    else
      create_standard_labels "$REPO_URL"
    fi
  fi
fi

note
note "Next steps:"
note "- Fill in .forge/config.yaml with project metadata and stage inject paths"
note "- Review REVIEW.md and .forge/skills/*.md"
note "- If labels were skipped, create them later or rerun with --labels"
note "- Run: bash $FORGE_DIR/scripts/forge-doctor.sh product $PROJECT"
note "- Run: bash $FORGE_DIR/scripts/forge-status.sh product $PROJECT"
