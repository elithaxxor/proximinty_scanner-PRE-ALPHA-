#!/usr/bin/env bash
#
# Script Name : bluetooth_monitor.sh
# Description :
#   1) Spawns a separate terminal to run "sudo bluetoothctl scan on".
#   2) Performs an initial discovery phase using hcitool and logs devices:
#      - bluetoothctl info <MAC> (spawned as a subprocess)
#      - l2ping -c 11 <MAC> (time-stamped, logged to .txt and .csv)
#   3) Continues scanning periodically for new devices, logging them separately.
#   4) Never deletes old logs; each run is date/time stamped.

# ----------------------------------------------
# Configurable parameters
# ----------------------------------------------

# How often (in seconds) to rescan for new devices
SCAN_INTERVAL=60

# Use a timestamp so logs aren't overwritten
DATESTAMP="$(date +%Y%m%d_%H%M%S)"

# Base filenames (unique each run)
INITIAL_TXT_FILE="original_ble_${DATESTAMP}.txt"
INITIAL_CSV_FILE="original_ble_${DATESTAMP}.csv"
NEW_TXT_FILE="new_ble_${DATESTAMP}.txt"
NEW_CSV_FILE="new_ble_${DATESTAMP}.csv"

# ----------------------------------------------
# Initialization
# ----------------------------------------------

echo "Bluetooth Monitor Script - Starting"
echo "------------------------------------"
echo "Logs will be stored in:"
echo "  - $INITIAL_TXT_FILE"
echo "  - $INITIAL_CSV_FILE"
echo "  - $NEW_TXT_FILE"
echo "  - $NEW_CSV_FILE"
echo "Rescanning every $SCAN_INTERVAL seconds."
echo ""

# ----------------------------------------------
# Spawn separate terminal to run 'sudo bluetoothctl scan on'
# ----------------------------------------------
# Adjust 'xterm' to 'gnome-terminal -- bash -c' or another if needed.
if command -v xterm &> /dev/null; then
  echo "[INFO] Spawning a separate xterm for 'sudo bluetoothctl scan on'..."
  xterm -hold -e "sudo bluetoothctl scan on" &
else
  echo "[WARNING] xterm not found. Running 'sudo bluetoothctl scan on' in background."
  sudo bluetoothctl scan on &
fi

# ----------------------------------------------
# Helper function: Check if a device is in file
# ----------------------------------------------
device_in_file() {
  local mac="$1"
  local file="$2"
  
  if [[ -f "$file" ]]; then
    grep -iq "$mac" "$file" && return 0 || return 1
  else
    return 1
  fi
}

# ----------------------------------------------
# Pretty logger
# ----------------------------------------------
pretty_output() {
  local msg="$1"
  echo "--------------------------------------------------"
  echo "[INFO]: $msg"
  echo "--------------------------------------------------"
}

# ----------------------------------------------
# Gather local adapter info
# ----------------------------------------------
gather_local_info() {
  pretty_output "Gathering local Bluetooth adapter info ..."
  {
    echo "=== Local Bluetooth Adapter Info ==="
    hciconfig dev 2>&1
    echo ""
  } | tee -a "$INITIAL_TXT_FILE"
}

# ----------------------------------------------
# Scan for devices (hcitool)
# ----------------------------------------------
scan_for_devices() {
  pretty_output "Scanning for Bluetooth devices (hcitool) ..."

  # Temporary files
  tmp_scan=$(mktemp)
  tmp_inquiry=$(mktemp)

  {
    echo "=== hcitool scan ==="
    hcitool scan 2>&1
    echo ""
    echo "=== hcitool inq ==="
    hcitool inq 2>&1
    echo ""
  } | tee -a "$INITIAL_TXT_FILE" | tee "$tmp_scan"

  # Copy same data for inquiry because we are storing them together
  cp "$tmp_scan" "$tmp_inquiry"

  # Parse out MAC addresses
  mapfile -t found_macs < <(awk '/([0-9A-F]{2}:){5}[0-9A-F]{2}/ {print $1}' "$tmp_scan")

  rm -f "$tmp_scan" "$tmp_inquiry"

  # Remove duplicates
  unique_macs=($(echo "${found_macs[@]}" | tr ' ' '\n' | sort -u))
  
  echo "${unique_macs[@]}"
}

# ----------------------------------------------
# Gather detailed device info (including bluetoothctl info)
# ----------------------------------------------
gather_device_info() {
  local mac="$1"
  local output_file="$2"

  {
    echo ""
    echo "=== Detailed Info for $mac ==="
    echo ""
    echo "-> bluetoothctl info $mac"
  } | tee -a "$output_file"
  
  # Non-interactive call to bluetoothctl info
  bluetoothctl info "$mac" 2>&1 | tee -a "$output_file"
}

# ----------------------------------------------
# Function: Ping device (l2ping), log to .txt and .csv
# ----------------------------------------------
ping_device() {
  local mac="$1"
  local output_txt="$2"
  local output_csv="$3"
  
  local now
  now="$(date +'%Y-%m-%d %H:%M:%S')"
  
  echo "" | tee -a "$output_txt"
  echo "[$now] -> l2ping -c 11 $mac" | tee -a "$output_txt"
  
  # Capture ping results
  ping_result="$(l2ping -c 11 "$mac" 2>&1)"
  echo "$ping_result" | tee -a "$output_txt"
  
  # In .csv, we store a line with "ping,<date/time>,MAC,<ping_output>"
  # You can store the entire ping_result or just a summary, up to you.
  # For simplicity, let's store the entire result in one line (escaped):
  local safe_ping_result
  safe_ping_result="$(echo "$ping_result" | tr '\n' '|' | tr ',' ';')"
  # CSV format: ping,timestamp,MAC,ping_result
  echo "ping,$now,$mac,$safe_ping_result" >> "$output_csv"
}

# ----------------------------------------------
# Main Script
# ----------------------------------------------

# 1) Gather local info
gather_local_info

# 2) Perform initial scan
initial_macs=( $(scan_for_devices) )

# 3) Log the discovered devices in CSV and TXT
{
  echo "==================================================="
  echo "Initial Bluetooth Devices Discovered ($DATESTAMP)"
  echo "==================================================="
  printf "%-20s %s\n" "MAC_Address" "Name"
} >> "$INITIAL_TXT_FILE"

for mac in "${initial_macs[@]}"; do
  name=$(hcitool name "$mac" 2>/dev/null)
  
  # Write to CSV
  echo "$mac,$name" >> "$INITIAL_CSV_FILE"
  
  # Write to TXT
  printf "%-20s %s\n" "$mac" "$name" | tee -a "$INITIAL_TXT_FILE"
done

# 4) For each device: run bluetoothctl info + l2ping
for mac in "${initial_macs[@]}"; do
  gather_device_info "$mac" "$INITIAL_TXT_FILE"
  ping_device "$mac" "$INITIAL_TXT_FILE" "$INITIAL_CSV_FILE"
done

pretty_output "Initial discovery complete. Monitoring for new devices ..."

# 5) Continuous scanning for new devices
known_macs=( "${initial_macs[@]}" )

while true; do
  sleep "$SCAN_INTERVAL"
  
  pretty_output "Rescanning for new devices ..."
  current_macs=( $(scan_for_devices) )
  
  # Check for new devices
  for mac in "${current_macs[@]}"; do
    if ! printf '%s\n' "${known_macs[@]}" | grep -q -F "$mac"; then
      # Found new device
      pretty_output "NEW DEVICE FOUND: $mac"
      name=$(hcitool name "$mac" 2>/dev/null)

      # Add to known list
      known_macs+=( "$mac" )

      # Write to new_ble CSV
      echo "$mac,$name" >> "$NEW_CSV_FILE"
      
      # Write to new_ble TXT
      {
        echo "==================================================="
        echo "NEW DEVICE FOUND: $mac"
        echo "Name: $name"
        echo "Time: $(date +'%Y-%m-%d %H:%M:%S')"
        echo "==================================================="
        printf "%-20s %s\n" "MAC_Address" "Name"
        printf "%-20s %s\n" "$mac" "$name"
      } >> "$NEW_TXT_FILE"

      # Gather bluetoothctl info
      gather_device_info "$mac" "$NEW_TXT_FILE"
      
      # Ping device
      ping_device "$mac" "$NEW_TXT_FILE" "$NEW_CSV_FILE"
    fi
  done

  pretty_output "Scan cycle complete. Waiting $SCAN_INTERVAL seconds before next scan."
done
