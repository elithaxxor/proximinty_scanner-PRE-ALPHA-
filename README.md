# Wi-Fi Scanner Script

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
