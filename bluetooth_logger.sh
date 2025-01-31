#!/bin/bash

# Log file location
LOG_FILE="./bluetooth_devices.log"
KNOWN_DEVICES_FILE="./known_bluetooth_devices.txt"

# Ensure log file exists and is writable
touch "$LOG_FILE"
chmod 644 "$LOG_FILE"

# Ensure known devices file exists
touch "$KNOWN_DEVICES_FILE"

# Define color codes
RESET="\e[0m"
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"

echo -e "${CYAN}Bluetooth device logging started. Logging every 30 seconds...${RESET}"
echo "Press Ctrl+C to stop."

# Infinite loop to log devices every 30 seconds
while true; do
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "${YELLOW}[$TIMESTAMP] Scanning for Bluetooth devices...${RESET}" | tee -a "$LOG_FILE"
    
    # Run bluetoothctl devices, process output, and log
    OUTPUT=$(bluetoothctl devices)

    if [[ -z "$OUTPUT" ]]; then
        echo -e "${RED}No devices found.${RESET}" | tee -a "$LOG_FILE"
    else
        NEW_DEVICES=()
        while IFS= read -r line; do
            # Extracting device MAC address and name
            DEVICE_MAC=$(echo "$line" | awk '{print $2}')
            DEVICE_NAME=$(echo "$line" | cut -d ' ' -f 3-)

            # Check if the device is new
            if ! grep -q "$DEVICE_MAC" "$KNOWN_DEVICES_FILE"; then
                NEW_DEVICES+=("$DEVICE_MAC - $DEVICE_NAME")
                echo "$DEVICE_MAC" >> "$KNOWN_DEVICES_FILE"
                echo -e "${GREEN}New Device Detected!${RESET} [$TIMESTAMP]" | tee -a "$LOG_FILE"
                echo -e "${GREEN}$DEVICE_MAC${RESET} - ${BLUE}$DEVICE_NAME${RESET}" | tee -a "$LOG_FILE"
            else
                echo -e "${GREEN}$DEVICE_MAC${RESET} - ${BLUE}$DEVICE_NAME${RESET}" | tee -a "$LOG_FILE"
            fi
        done <<< "$OUTPUT"

        # Save new devices to log file
        if [[ ${#NEW_DEVICES[@]} -gt 0 ]]; then
            echo -e "${YELLOW}New devices detected:${RESET}" | tee -a "$LOG_FILE"
            for DEVICE in "${NEW_DEVICES[@]}"; do
                echo -e "${GREEN}$DEVICE${RESET}" | tee -a "$LOG_FILE"
            done
        fi
    fi

    echo -e "${CYAN}-----------------------------------${RESET}" | tee -a "$LOG_FILE"
    
    # Wait 30 seconds before the next run
    sleep 30
done
