#!/bin/bash
set -euo pipefail

DOT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
TARGET_DIRECTORY="$HOME"
CONFIG_DIRECTORY="${XDG_CONFIG_HOME:-$HOME/.config}"
OVERWRITE=false
DRY_RUN=false
SKIP_BREW=false
SKIP_MACOS=false
BACKUP_DIRECTORY=""

usage() {
  cat <<'EOF'
Usage: deploy.sh [options]

  -f, --force       Back up conflicting files before replacing them with links
  -n, --dry-run     Print planned changes without changing files or settings
  --skip-brew       Skip Homebrew installation and brew bundle
  --skip-macos      Skip macOS keyboard settings
  --target DIR     Deploy into an absolute directory (config goes in DIR/.config)
  -h, --help        Show this help
EOF
}

fail() {
  printf 'deploy: %s\n' "$*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--force) OVERWRITE=true ;;
    -n|--dry-run) DRY_RUN=true ;;
    --skip-brew) SKIP_BREW=true ;;
    --skip-macos) SKIP_MACOS=true ;;
    --target)
      [[ $# -ge 2 && "$2" = /* && "$2" != / ]] || fail '--target requires an absolute directory other than /'
      TARGET_DIRECTORY="${2%/}"
      CONFIG_DIRECTORY="$TARGET_DIRECTORY/.config"
      shift
      ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; fail "unknown option: $1" ;;
  esac
  shift
done

[[ "$CONFIG_DIRECTORY" = /* ]] || fail 'XDG_CONFIG_HOME must be an absolute path'

# Deploy only explicitly managed settings, leaving ~/.config itself and
# project-specific ~/.latexmkrc settings alone.
MANAGED_FILES=(
  .zshenv .zshrc .gitconfig .gitignore_global .vimrc .latexmkrc_platex
  .config/nvim .config/starship.toml
)
shopt -s nullglob
for ctags_file in "$DOT_DIRECTORY"/*.ctags; do
  MANAGED_FILES+=("${ctags_file##*/}")
done

destination_for() {
  case "$1" in
    .config/*) printf '%s/%s\n' "$CONFIG_DIRECTORY" "${1#.config/}" ;;
    *.ctags) printf '%s/.ctags.d/%s\n' "$TARGET_DIRECTORY" "$1" ;;
    *) printf '%s/%s\n' "$TARGET_DIRECTORY" "$1" ;;
  esac
}

# Validate every source and parent before making any changes.
for relative in "${MANAGED_FILES[@]}"; do
  [[ -e "$DOT_DIRECTORY/$relative" ]] || fail "missing source: $relative"
  destination="$(destination_for "$relative")"
  parent="$(dirname -- "$destination")"
  while [[ ! -d "$parent" ]]; do
    [[ ! -e "$parent" && ! -L "$parent" ]] || fail "not a directory: $parent"
    parent="$(dirname -- "$parent")"
  done
done

run() {
  if [[ "$DRY_RUN" = true ]]; then
    printf '[dry-run]'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

deploy_link() {
  local relative="$1" source destination backup
  source="$DOT_DIRECTORY/$relative"
  destination="$(destination_for "$relative")"

  # Also handle the old ~/.config -> dotfiles/.config layout without moving
  # any source files, even with --force.
  if [[ "$source" -ef "$destination" ]]; then
    printf 'Already linked: %s\n' "$destination"
    return
  fi

  if [[ -e "$destination" || -L "$destination" ]]; then
    if [[ "$OVERWRITE" != true ]]; then
      printf 'Keeping existing: %s (use --force to back up and replace)\n' "$destination"
      return
    fi
    if [[ -z "$BACKUP_DIRECTORY" ]]; then
      if [[ "$DRY_RUN" = true ]]; then
        BACKUP_DIRECTORY="$TARGET_DIRECTORY/.dotfiles-backups/<new-backup>"
      else
        mkdir -p -- "$TARGET_DIRECTORY/.dotfiles-backups"
        BACKUP_DIRECTORY="$(mktemp -d "$TARGET_DIRECTORY/.dotfiles-backups/$(date +%Y%m%d-%H%M%S).XXXXXX")"
      fi
      printf 'Backup directory: %s\n' "$BACKUP_DIRECTORY"
    fi
    backup="$BACKUP_DIRECTORY/$relative"
    run mkdir -p -- "$(dirname -- "$backup")"
    run mv -- "$destination" "$backup"
  fi

  run mkdir -p -- "$(dirname -- "$destination")"
  run ln -s -- "$source" "$destination"
  printf 'Link: %s -> %s\n' "$destination" "$source"
}

for relative in "${MANAGED_FILES[@]}"; do
  deploy_link "$relative"
done

if [[ "$SKIP_MACOS" != true && "$(uname -s)" = Darwin ]]; then
  run defaults write -g ApplePressAndHoldEnabled -bool false
fi

find_brew() {
  BREW="$(command -v brew || true)"
  [[ -z "$BREW" ]] || return 0
  local candidate
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if [[ -x "$candidate" ]]; then
      BREW="$candidate"
      return 0
    fi
  done
  return 1
}

if [[ "$SKIP_BREW" != true ]]; then
  if ! find_brew; then
    if [[ "$DRY_RUN" = true ]]; then
      printf '[dry-run] Install Homebrew using its official installer\n'
    else
      installer="$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      /bin/bash -c "$installer"
      find_brew || fail 'Homebrew was not found after installation'
    fi
  fi
  run "${BREW:-brew}" bundle --file="$DOT_DIRECTORY/Brewfile"
fi

if [[ "$DRY_RUN" = true ]]; then
  printf 'Dry run complete. No changes made.\n'
else
  printf 'Dotfiles deployment complete.\n'
fi
