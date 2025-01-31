#!/bin/bash

# Log file locations
LOG_FILE="/var/log/bluetooth_devices.log"
KNOWN_DEVICES_FILE="/tmp/known_bluetooth_devices.txt"
NEW_TXT_FILE="/var/log/bluetooth_device_info.txt"
NEW_CSV_FILE="/var/log/bluetooth_device_ping.csv"

# Ensure necessary files exist
touch "$LOG_FILE" "$KNOWN_DEVICES_FILE" "$NEW_TXT_FILE" "$NEW_CSV_FILE"
chmod 644 "$LOG_FILE" "$NEW_TXT_FILE" "$NEW_CSV_FILE"

# Define color codes
RESET="\e[0m"
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"

# Function to gather detailed Bluetooth info
gather_device_info() {
    local mac="$1"
    local output_txt="$2"

    local now
    now="$(date +'%Y-%m-%d %H:%M:%S')"

    echo -e "${YELLOW}[$now] Gathering info for $mac...${RESET}" | tee -a "$output_txt"
    
    # Run bluetoothctl info command
    device_info=$(bluetoothctl info "$mac" 2>&1)
    
    if [[ -n "$device_info" ]]; then
        echo -e "${BLUE}$device_info${RESET}" | tee -a "$output_txt"
    else
        echo -e "${RED}No additional info found for $mac.${RESET}" | tee -a "$output_txt"
    fi
}

# Function to ping Bluetooth device
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
  
    # Store ping result in CSV
    safe_ping_result="$(echo "$ping_result" | tr '\n' '|' | tr ',' ';')"
    echo "ping,$now,$mac,$safe_ping_result" >> "$output_csv"
}

# Start logging
echo -e "${CYAN}Bluetooth device logging started. Logging every 30 seconds...${RESET}"
echo "Press Ctrl+C to stop."

# Infinite loop to log devices every 30 seconds
while true; do
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "${YELLOW}[$TIMESTAMP] Scanning for Bluetooth devices...${RESET}" | tee -a "$LOG_FILE"
    
    # Run bluetoothctl devices and process output
    OUTPUT=$(bluetoothctl devices)

    if [[ -z "$OUTPUT" ]]; then
        echo -e "${RED}No devices found.${RESET}" | tee -a "$LOG_FILE"
    else
        NEW_DEVICES=()
        while IFS= read -r line; do
            DEVICE_MAC=$(echo "$line" | awk '{print $2}')
            DEVICE_NAME=$(echo "$line" | cut -d ' ' -f 3-)

            # Check if the device is new
            if ! grep -q "$DEVICE_MAC" "$KNOWN_DEVICES_FILE"; then
                NEW_DEVICES+=("$DEVICE_MAC - $DEVICE_NAME")
                echo "$DEVICE_MAC" >> "$KNOWN_DEVICES_FILE"
                echo -e "${GREEN}New Device Detected!${RESET} [$TIMESTAMP]" | tee -a "$LOG_FILE"
                echo -e "${GREEN}$DEVICE_MAC${RESET} - ${BLUE}$DEVICE_NAME${RESET}" | tee -a "$LOG_FILE"

                # Gather Bluetooth info
                gather_device_info "$DEVICE_MAC" "$NEW_TXT_FILE"

                # Ping device
                ping_device "$DEVICE_MAC" "$NEW_TXT_FILE" "$NEW_CSV_FILE"
            else
                echo -e "${GREEN}$DEVICE_MAC${RESET} - ${BLUE}$DEVICE_NAME${RESET}" | tee -a "$LOG_FILE"
            fi
        done <<< "$OUTPUT"
    fi

    echo -e "${CYAN}-----------------------------------${RESET}" | tee -a "$LOG_FILE"
    
    # Wait 30 seconds before the next run
    sleep 30
done
