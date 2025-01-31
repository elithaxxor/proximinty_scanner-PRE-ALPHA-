# Wi-Fi Scanner Script & BLE Scan Sript

This **Bash script** scans for **nearby Wi-Fi networks**, extracting each network’s **SSID** and **signal strength**. It then displays the results in a **colorized table**, making it easy to **quickly identify** available networks and compare their signal strengths.

---

## **Features**
- **Automated Wi-Fi Scanning**: Uses `iw dev <interface> scan` to list wireless networks.  
- **Signal & SSID Extraction**: Filters lines containing `signal:` and `SSID:`.  
- **Neat Table Output**: Displays a **column-aligned** view of each network’s SSID and its signal strength in dBm.  
- **Colorized Output**: Leverages ANSI color codes for a more **readable** experience.

---

## **Usage**
1. **Make the script executable**:
   ```bash
   chmod +x wifi_scanner.sh
   ```
2. **Run the script** (requires `sudo` for interface scanning):
   ```bash
   sudo ./wifi_scanner.sh
   ```
   - By default, it references the interface `wlx0013eff5483f`.  
   - Replace with your **actual Wi-Fi interface** name if necessary (e.g., `wlan0`).

---

## **Output Example**
```
hi

Nearby Wi-Fi Networks
------------------------------------
SSID                           SIGNAL (dBm)
------------------------------------
MyAwesomeNetwork               -45
GuestWiFi                      -70

bye
```
  
- The **signal** value is in **dBm** (negative values; closer to zero means stronger signal).  
- **SSID** is left-aligned, **signal** is right-aligned.

---

## **Notes**
- **Interface Name**: Change `wlx0013eff5483f` to match your actual Wi-Fi interface.  
- **sudo**: Scanning requires elevated privileges. If you don’t run as root, you might get permission errors.  
- **Dependencies**: You’ll need the `iw` command. Typically installed by default on many Linux distributions, or install via your package manager (e.g., `sudo apt-get install iw`).

---

**Enjoy scanning your local wireless environment in a clean, colorized layout!**


Here’s a **README.md** file for your **Bluetooth Monitoring Script**. It provides instructions on what the script does, how to use it, and additional notes for troubleshooting.

---

### 📡 Bluetooth Monitoring Script

#### 📝 Description
This **Bluetooth Monitoring Script** continuously scans for **nearby Bluetooth devices**, logs their information, and monitors for new devices in real time. 

During discovery, it gathers:
- **Local Bluetooth Adapter Information**
- **Discovered Devices** (using `hcitool scan` and `hcitool inq`)
- **Device Details** (using `bluetoothctl info <MAC>` and `hcitool info <MAC>`)
- **Service Details** (using `sdptool browse` and `sdptool records`)
- **Ping Tests** (`l2ping -c 11 <MAC>`, results logged)
- **Live Scanning** (`sudo bluetoothctl scan on` runs in a separate terminal)

The script continuously monitors for **new devices**, logging any new MAC addresses it discovers.

---

## 📂 Log Files
The script generates timestamped log files for each run to avoid overwriting previous data.

| Log File Type | Purpose |
|--------------|---------|
| `original_ble_<timestamp>.txt` | Human-readable log of the **initial scan** |
| `original_ble_<timestamp>.csv` | CSV log of the **initial scan** |
| `new_ble_<timestamp>.txt` | Human-readable log of **newly discovered devices** |
| `new_ble_<timestamp>.csv` | CSV log of **newly discovered devices** |

> **Example file names:**
> - `original_ble_20250131_120000.txt`
> - `new_ble_20250131_120000.csv`

Each run logs **new devices separately**, so no old logs are deleted.

---

## 🔧 Requirements
Ensure your system has the necessary tools installed:

- **BlueZ utilities** (`bluetoothctl`, `hcitool`, `l2ping`, `sdptool`)
- **xterm** (or another terminal emulator like `gnome-terminal`)

### 📥 Installation (for Debian-based systems)
If you don’t have the required utilities, install them using:

```bash
sudo apt update
sudo apt install bluez xterm
```

---

## 🚀 Usage
### 1️⃣ **Make the script executable**
```bash
chmod +x bluetooth_monitor.sh
```

### 2️⃣ **Run the script**
```bash
./bluetooth_monitor.sh
```
> You may need to run it with `sudo` depending on your system:
```bash
sudo ./bluetooth_monitor.sh
```

### 3️⃣ **Stop the script**
Press **CTRL+C** to stop the monitoring process.

---

## 🛠 Features

✅ **Initial Discovery Phase**
- Collects **Bluetooth adapter info**
- Runs `hcitool scan` and `hcitool inq` to find nearby devices
- Retrieves device info with `bluetoothctl info <MAC>`
- Logs device data in `original_ble_<timestamp>.txt` and `.csv`

✅ **Continuous Monitoring**
- Runs `sudo bluetoothctl scan on` in a separate terminal
- Periodically scans for new devices
- Logs any **new** device in `new_ble_<timestamp>.txt` and `.csv`

✅ **Pinging Devices**
- Sends an **l2ping** signal to each device
- Logs the response with **timestamp** in both `.txt` and `.csv` logs

✅ **Does Not Overwrite Logs**
- Uses timestamps (`YYYYMMDD_HHMMSS`) to keep all logs **separate**
- Allows for long-term monitoring and record-keeping

---

## 🔍 Example Output
### 📜 `original_ble_20250131_120000.txt`
```
===================================================
Initial Bluetooth Devices Discovered (2025-01-31 12:00:00)
===================================================
MAC_Address           Name
12:34:56:78:9A:BC     My Bluetooth Speaker
AA:BB:CC:DD:EE:FF     Wireless Headphones

=== Detailed Info for 12:34:56:78:9A:BC ===
-> bluetoothctl info 12:34:56:78:9A:BC
...
-> l2ping -c 11 12:34:56:78:9A:BC
Ping sent...
Reply received (64 bytes)...
```

### 📜 `new_ble_20250131_123000.txt` (New Device Found Later)
```
===================================================
NEW DEVICE FOUND: 99:88:77:66:55:44
===================================================
Name: Unknown Device
Time: 2025-01-31 12:30:00

-> bluetoothctl info 99:88:77:66:55:44
...
-> l2ping -c 11 99:88:77:66:55:44
Ping sent...
Reply received (64 bytes)...
```

---

## ⚠️ Troubleshooting

🔹 **"Command not found" errors?**
- Ensure `bluez` and `xterm` are installed:
  ```bash
  sudo apt install bluez xterm
  ```

🔹 **"Permission denied" running Bluetooth commands?**
- Try running the script with `sudo`:
  ```bash
  sudo ./bluetooth_monitor.sh
  ```

🔹 **"hcitool deprecated" message?**
- Some Linux distros have deprecated `hcitool`. Use `bluetoothctl devices` instead.

🔹 **"xterm not found" on Ubuntu?**
- Replace `xterm` with:
  ```bash
  gnome-terminal -- bash -c "sudo bluetoothctl scan on"
  ```

---

## 🏗️ Future Improvements
- Add live parsing of `bluetoothctl` scan results
- Implement a GUI interface for easier monitoring
- Support JSON logging format

---

## 📜 License
This script is **open-source**. Feel free to modify and improve it! 😊

---

This **README.md** should help users quickly understand the script, how to use it, and troubleshoot any issues. Let me know if you’d like any modifications! 🚀
