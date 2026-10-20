#!/bin/zsh
set -euo pipefail

threshold="${1:-20}"
mode="${2:-}"
log_file="${BATTERY_CHECK_LOG_FILE:-${HOME}/Library/Logs/bluetooth-keyboard-battery.log}"
state_dir="${BATTERY_CHECK_STATE_DIR:-${HOME}/Library/Caches/bluetooth-device-battery}"
repeat_seconds=86400

log() {
  if [[ "$mode" == "--dry-run" ]]; then
    printf '%s\n' "$*"
    return
  fi
  { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$log_file"; } 2>/dev/null || true
}

if [[ ! "$threshold" =~ '^[0-9]{1,3}$' ]] || (( threshold > 100 )); then
  echo "threshold must be an integer percentage from 0 to 100" >&2
  exit 2
fi
if (( $# > 2 )) || [[ -n "$mode" && "$mode" != "--always-notify" && "$mode" != "--dry-run" ]]; then
  echo "usage: $0 [threshold] [--dry-run|--always-notify]" >&2
  exit 2
fi

if [[ "$mode" != "--dry-run" ]]; then
  mkdir -p "${log_file:h}"
fi

get_bluetooth_batteries() {
  /usr/sbin/ioreg -r -c AppleDeviceManagementHIDEventService -l -d 1 | /usr/bin/awk '
  function trim(v) {
    sub(/^[[:space:]]+/, "", v)
    sub(/[[:space:]]+$/, "", v)
    return v
  }

  function flush() {
    if (!in_obj) return

    if (transport != "Bluetooth") return
    if (built_in != "No") return
    if (battery == "" || (battery + 0) < 0 || (battery + 0) > 100) return

    product_trimmed = trim(product)
    product_lc = tolower(product_trimmed)
    is_trackpad = (index(product_lc, "trackpad") > 0 || battery_notification == "TPLowBattery")
    is_keyboard = (index(product_lc, "keyboard") > 0 || battery_notification == "KBLowBattery")
    if (!is_trackpad && !is_keyboard && primary_usage != "11") return

    name = product_trimmed
    if (name == "") {
      name = is_trackpad ? "Bluetooth Trackpad" : (is_keyboard ? "Bluetooth Keyboard" : "Bluetooth Input Device")
    }

    device_id = device_address != "" ? device_address : (serial != "" ? serial : name)
    print name "\t" battery "\t" device_id
  }

  /^[[:space:]]*\+-o AppleDeviceManagementHIDEventService[[:space:]]/ {
    flush()
    in_obj = 1
    transport = ""
    built_in = ""
    primary_usage = ""
    battery = ""
    product = ""
    device_address = ""
    serial = ""
    battery_notification = ""
    next
  }

  in_obj {
    if ($0 ~ /^[[:space:]]*}[[:space:]]*$/) {
      flush()
      in_obj = 0
      next
    }

    if ($0 ~ /"Transport" = "/) {
      value = $0
      sub(/^.*"Transport" = "/, "", value)
      sub(/".*$/, "", value)
      transport = value
    } else if ($0 ~ /"Built-In" = /) {
      value = $0
      sub(/^.*"Built-In" = /, "", value)
      sub(/[[:space:]].*$/, "", value)
      built_in = value
    } else if ($0 ~ /"PrimaryUsage" = [0-9]+/) {
      value = $0
      sub(/^.*"PrimaryUsage" = /, "", value)
      sub(/[^0-9].*$/, "", value)
      primary_usage = value
    } else if ($0 ~ /"BatteryPercent" = [0-9]+/) {
      value = $0
      sub(/^.*"BatteryPercent" = /, "", value)
      sub(/[^0-9].*$/, "", value)
      battery = value
    } else if ($0 ~ /"BatteryLowNotificationType" = "/) {
      value = $0
      sub(/^.*"BatteryLowNotificationType" = "/, "", value)
      sub(/".*$/, "", value)
      battery_notification = value
    } else if ($0 ~ /"Product" = "/) {
      value = $0
      sub(/^.*"Product" = "/, "", value)
      sub(/".*$/, "", value)
      product = value
    } else if ($0 ~ /"Product" = [[:space:]]*$/) {
      product = ""
    } else if ($0 ~ /"DeviceAddress" = "/) {
      value = $0
      sub(/^.*"DeviceAddress" = "/, "", value)
      sub(/".*$/, "", value)
      device_address = value
    } else if ($0 ~ /"SerialNumber" = "/) {
      value = $0
      sub(/^.*"SerialNumber" = "/, "", value)
      sub(/".*$/, "", value)
      serial = value
    }
  }

  END {
    flush()
  }'
}

notify_devices=()
notify_state_files=()
now=$(date +%s)
device_count=0

if ! batteries=$(get_bluetooth_batteries); then
  log "failed to read Bluetooth battery levels"
  exit 1
fi

while IFS=$'\t' read -r device_name battery_percent device_id; do
  [[ -z "${device_name}" || -z "${battery_percent}" ]] && continue
  device_count=$((device_count + 1))
  log "observed ${device_name}: ${battery_percent}% (threshold=${threshold})"
  if [[ "$mode" == "--dry-run" ]]; then
    if (( battery_percent <= threshold )); then
      log "below threshold: ${device_name}"
    else
      log "above threshold: ${device_name}"
    fi
    continue
  fi
  if [[ "$mode" == "--always-notify" ]]; then
    notify_devices+=("${device_name}: ${battery_percent}%")
    continue
  fi

  state_key=$(printf '%s' "$device_id" | /usr/bin/cksum | /usr/bin/awk '{print $1}')
  state_file="${state_dir}/${state_key}"
  if (( battery_percent > threshold )); then
    # Rearm after charging; a later low battery should notify immediately.
    if [[ -f "$state_file" ]]; then
      printf '0\n' > "$state_file"
    fi
    continue
  fi
  last_notification=0
  if [[ -f "$state_file" ]]; then
    read -r last_notification < "$state_file" || true
  fi
  [[ "$last_notification" =~ '^[0-9]{1,12}$' ]] || last_notification=0
  if (( last_notification > 0 && now >= last_notification && now - last_notification < repeat_seconds )); then
    log "daily reminder already sent: ${device_name}"
    continue
  fi
  notify_devices+=("${device_name}: ${battery_percent}%")
  notify_state_files+=("$state_file")
done <<< "$batteries"

if (( ${#notify_devices[@]} == 0 )); then
  if (( device_count == 0 )); then
    log "no connected Bluetooth input device with battery data"
  elif [[ "$mode" != "--dry-run" ]]; then
    log "no notification needed"
  fi
  exit 0
fi

message=$(printf '%s; ' "${notify_devices[@]}")
message="${message%; }"
title="Bluetooth機器の充電が少なくなっています"
group="bluetooth-device-battery"
if [[ "$mode" == "--always-notify" ]]; then
  title="Bluetoothバッテリー（動作テスト）"
  group="bluetooth-device-battery-test"
else
  message="${message} — 充電してください。"
fi

notifier=""
for candidate in /opt/homebrew/bin/terminal-notifier /usr/local/bin/terminal-notifier; do
  if [[ -x "$candidate" ]]; then
    notifier="$candidate"
    break
  fi
done
if [[ -z "$notifier" ]]; then
  log "ERROR: terminal-notifier is not installed"
  exit 1
fi

if (( ${#notify_state_files[@]} > 0 )); then
  mkdir -p "$state_dir"
fi
log "notify target devices: ${message}"
if ! "$notifier" -title "$title" -message "$message" -group "$group"; then
  log "ERROR: terminal-notifier failed; will retry on next check"
  exit 1
fi
log "notification submitted via terminal-notifier"
# Test notifications must not suppress real low-battery warnings.
for state_file in "${notify_state_files[@]}"; do
  printf '%s\n' "$now" > "$state_file"
done
