#!/bin/bash
set -euo pipefail

DOT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
TARGET_DIRECTORY="$HOME"
CONFIG_DIRECTORY="${XDG_CONFIG_HOME:-$HOME/.config}"
OVERWRITE=false
DRY_RUN=false
SKIP_BREW=false
SKIP_MACOS=false
TARGET_SPECIFIED=false
BACKUP_DIRECTORY=""

usage() {
  cat <<'EOF'
Usage: deploy.sh [options]

  -f, --force       Back up conflicting files before replacing them with links
  -n, --dry-run     Print planned changes without changing files or settings
  --skip-brew       Skip Homebrew installation and brew bundle
  --skip-macos      Skip macOS settings, default apps, and battery notifications
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
      [[ $# -ge 2 && "$2" = /* ]] || fail '--target requires an absolute directory other than /'
      TARGET_DIRECTORY="$2"
      TARGET_SPECIFIED=true
      CONFIG_DIRECTORY="$TARGET_DIRECTORY/.config"
      shift
      ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; fail "unknown option: $1" ;;
  esac
  shift
done

# Resolve existing symlinks and . / .. components without creating directories.
# Checking only the spelling of --target would also accept // or /usr/.. as /.
canonical_directory() {
  local remaining="$1" resolved=/ component
  [[ "$remaining" = /* ]] || fail "directory must be an absolute path: $remaining"
  while [[ -n "$remaining" ]]; do
    component="${remaining%%/*}"
    if [[ "$remaining" = */* ]]; then
      remaining="${remaining#*/}"
    else
      remaining=""
    fi
    case "$component" in
      ''|.) continue ;;
      ..) resolved="$(dirname -- "$resolved")" ;;
      *) resolved="${resolved%/}/$component" ;;
    esac
    if [[ -d "$resolved" ]]; then
      resolved="$(cd -- "$resolved" && pwd -P)" || fail "cannot access directory: $resolved"
    else
      [[ ! -e "$resolved" && ! -L "$resolved" ]] || fail "not a directory: $resolved"
    fi
  done
  printf '%s\n' "$resolved"
}

TARGET_DIRECTORY="$(canonical_directory "$TARGET_DIRECTORY")"
[[ "$TARGET_DIRECTORY" != / ]] || fail 'target directory must not resolve to /'
[[ "$CONFIG_DIRECTORY" = /* ]] || fail 'XDG_CONFIG_HOME must be an absolute path'
CONFIG_DIRECTORY="$(canonical_directory "$CONFIG_DIRECTORY")"
[[ "$CONFIG_DIRECTORY" != / ]] || fail 'config directory must not resolve to /'

PLATFORM="$(uname -s)"
SETUP_BATTERY=false
SETUP_DEFAULT_APPS=false
DEFAULT_APP_EXTENSIONS=()
DEFAULT_APP_BUNDLE_IDS=()
if [[ "$SKIP_MACOS" != true && "$PLATFORM" = Darwin && "$TARGET_SPECIFIED" != true ]]; then
  SETUP_BATTERY=true
  SETUP_DEFAULT_APPS=true
  [[ -r "$DOT_DIRECTORY/setup-bluetooth-battery.sh" ]] || fail 'missing source: setup-bluetooth-battery.sh'
  [[ -r "$DOT_DIRECTORY/.config/scripts/check_bluetooth_keyboard_battery.sh" ]] || fail 'missing source: Bluetooth battery check script'
  [[ -f "$DOT_DIRECTORY/default-apps.tsv" && -r "$DOT_DIRECTORY/default-apps.tsv" ]] || fail 'missing or unreadable source: default-apps.tsv'
  line_number=0
  while read -r extension bundle_id extra || [[ -n "$extension" ]]; do
    line_number=$((line_number + 1))
    case "$extension" in
      ''|\#*) continue ;;
    esac
    [[ "$extension" = .?* && -n "$bundle_id" && -z "$extra" ]] || fail "default-apps.tsv:$line_number: expected an extension starting with . and an application bundle ID"
    DEFAULT_APP_EXTENSIONS+=("$extension")
    DEFAULT_APP_BUNDLE_IDS+=("$bundle_id")
  done < "$DOT_DIRECTORY/default-apps.tsv"
fi
if [[ "$SKIP_BREW" != true ]]; then
  [[ "$PLATFORM" = Darwin ]] || fail 'this Brewfile requires macOS; use --skip-brew for links only'
  [[ -f "$DOT_DIRECTORY/Brewfile" && -r "$DOT_DIRECTORY/Brewfile" ]] || fail 'missing or unreadable source: Brewfile'
fi

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
  parent="$(canonical_directory "$(dirname -- "$destination")")"
  # The legacy ~/.config -> checkout/.config layout is safe only when the
  # destination already is the managed source. Never create links in the checkout.
  if [[ ! "$DOT_DIRECTORY/$relative" -ef "$destination" ]]; then
    case "$parent/${destination##*/}" in
      "$DOT_DIRECTORY"/*) fail "destination would modify the checkout: $destination" ;;
    esac
  fi
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

find_brew() {
  BREW="$(command -v brew || true)"
  [[ -z "$BREW" ]] || return 0
  local candidate
  for candidate in "${HOMEBREW_PREFIX:-}/bin/brew" /opt/homebrew/bin/brew /usr/local/bin/brew; do
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
      installer="$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || fail 'Homebrew installer download failed'
      /bin/bash -c "$installer" || fail 'Homebrew installation failed'
      find_brew || fail 'Homebrew was not found after installation'
    fi
  fi
  # An absolute brew path alone does not put tools such as mas in bundle's PATH.
  # shellenv itself can create Homebrew files, so never invoke it in a dry run.
  if [[ "$DRY_RUN" = true ]]; then
    run "${BREW:-brew}" shellenv bash
  else
    brew_environment="$("$BREW" shellenv bash)" || fail 'could not load the Homebrew environment'
    eval "$brew_environment"
  fi
  run "${BREW:-brew}" bundle --file="$DOT_DIRECTORY/Brewfile" || fail 'brew bundle failed; resolve the reported errors and rerun deploy.sh'
fi

if [[ "$SETUP_DEFAULT_APPS" = true && "$DRY_RUN" != true ]]; then
  command -v duti >/dev/null 2>&1 || fail 'duti not found; run brew install duti or use --skip-macos'
fi

# Install dependencies first: a failed bundle must not replace the working
# configuration or apply macOS preferences.
for relative in "${MANAGED_FILES[@]}"; do
  deploy_link "$relative"
done

if [[ "$SKIP_MACOS" != true && "$PLATFORM" = Darwin ]]; then
  run defaults write -g ApplePressAndHoldEnabled -bool false
  run defaults write net.sourceforge.skim-app.skim AppleWindowTabbingMode -string always
  nvim_command="$(command -v nvim || true)"
  if [[ -n "$nvim_command" ]]; then
    # An empty preset selects Custom; Skim's default preset targets TextMate.
    run defaults write net.sourceforge.skim-app.skim SKTeXEditorPreset -string ''
    run defaults write net.sourceforge.skim-app.skim SKTeXEditorCommand -string "$nvim_command"
    run defaults write net.sourceforge.skim-app.skim SKTeXEditorArguments -string "--headless -c \"VimtexInverseSearch %line '%file'\""
  else
    printf 'Skipping Skim inverse search: install Neovim and rerun deploy.sh.\n' >&2
  fi
fi

if [[ "$SETUP_DEFAULT_APPS" = true ]]; then
  for index in "${!DEFAULT_APP_EXTENSIONS[@]}"; do
    extension="${DEFAULT_APP_EXTENSIONS[$index]}"
    bundle_id="${DEFAULT_APP_BUNDLE_IDS[$index]}"
    run duti -s "$bundle_id" "$extension" all || fail "could not set $extension to open with $bundle_id; check the duti error and installed applications, then rerun deploy.sh"
  done
fi

if [[ "$SETUP_BATTERY" = true ]]; then
  run /bin/bash "$DOT_DIRECTORY/setup-bluetooth-battery.sh"
fi

if [[ "$DRY_RUN" = true ]]; then
  printf 'Dry run complete. No changes made.\n'
else
  printf 'Dotfiles deployment complete.\n'
fi
