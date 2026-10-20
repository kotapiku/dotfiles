#!/bin/bash
set -euo pipefail

DRY_RUN=false
case "${1:-}" in
  '') ;;
  --dry-run) DRY_RUN=true ;;
  *) printf 'Usage: bash setup-bluetooth-battery.sh [--dry-run]\n' >&2; exit 2 ;;
esac
[[ $# -le 1 ]] || exit 2
[[ "$(uname -s)" = Darwin ]] || { echo 'This setup requires macOS.' >&2; exit 1; }

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
SCRIPT="$ROOT/.config/scripts/check_bluetooth_keyboard_battery.sh"
LABEL=com.kotapiku.bluetooth-keyboard-battery-check
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
DOMAIN="gui/$(id -u)"
[[ -r "$SCRIPT" ]] || { echo "Missing script: $SCRIPT" >&2; exit 1; }

if [[ ! -x /opt/homebrew/bin/terminal-notifier && ! -x /usr/local/bin/terminal-notifier ]]; then
  echo 'Install terminal-notifier first: brew install terminal-notifier' >&2
  exit 1
fi

if [[ "$DRY_RUN" = true ]]; then
  printf 'Script: %s\nLaunchAgent: %s\nSchedule: daily at 22:00, threshold 20%%\n' "$SCRIPT" "$PLIST"
  printf 'Would back up an existing LaunchAgent, then register the new configuration.\n'
  exit 0
fi

xml_escape() {
  printf '%s' "$1" | /usr/bin/sed -e 's/\&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}

TEMP_PLIST="$(mktemp "${TMPDIR:-/tmp}/bluetooth-battery.XXXXXX")"
trap 'rm -f -- "$TEMP_PLIST"' EXIT
cat > "$TEMP_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/zsh</string>
    <string>$(xml_escape "$SCRIPT")</string>
    <string>20</string>
  </array>
  <key>StandardOutPath</key><string>$(xml_escape "$HOME/Library/Logs/bluetooth-keyboard-battery.stdout.log")</string>
  <key>StandardErrorPath</key><string>$(xml_escape "$HOME/Library/Logs/bluetooth-keyboard-battery.stderr.log")</string>
  <key>StartCalendarInterval</key>
  <dict><key>Hour</key><integer>22</integer><key>Minute</key><integer>0</integer></dict>
</dict>
</plist>
EOF
/usr/bin/plutil -lint "$TEMP_PLIST"
mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
if launchctl print "$DOMAIN/$LABEL" >/dev/null 2>&1; then
  launchctl bootout "$DOMAIN/$LABEL"
fi
if [[ -e "$PLIST" || -L "$PLIST" ]]; then
  BACKUP="$(mktemp -d "$HOME/Library/LaunchAgents/bluetooth-battery-backup.XXXXXX")"
  mv -- "$PLIST" "$BACKUP/$LABEL.plist"
  printf 'Previous configuration: %s\n' "$BACKUP/$LABEL.plist"
fi
chmod 644 "$TEMP_PLIST"
mv -- "$TEMP_PLIST" "$PLIST"
launchctl enable "$DOMAIN/$LABEL"
launchctl bootstrap "$DOMAIN" "$PLIST"
printf 'Installed: %s\nDaily at 22:00; notify at 20%% or below.\n' "$PLIST"
