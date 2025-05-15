#!/bin/bash

# Function to check internet connectivity
check_internet() {
    ping -c 2 1.1.1.1 &> /dev/null
    return $?
}

TIMESTAMP() {
    date +"%Y-%m-%d %H:%M:%S"
}

echo "[$(TIMESTAMP)] 🔍 Checking Internet Connection..."

if check_internet; then
    echo "[$(TIMESTAMP)] ✅ Internet is working!"
    exit 0
else
    echo "[$(TIMESTAMP)] ⚠️ Internet not working. Trying to fix..."
fi

# Detect USB default route (interface and gateway)
USB_IF=$(ip route | grep "^default" | grep "usb" | awk '{print $5}')
USB_GATEWAY=$(ip route | grep "^default" | grep "$USB_IF" | awk '{print $3}')

# Remove USB default route if exists
if [[ -n "$USB_IF" && -n "$USB_GATEWAY" ]]; then
    echo "[$(TIMESTAMP)] 🧹 Removing USB default route (bad internet source)..."
    sudo ip route del default via $USB_GATEWAY dev $USB_IF
    echo "[$(TIMESTAMP)] ✅ USB default route removed."
else
    echo "[$(TIMESTAMP)] ℹ️ No USB default route found to remove."
fi

# Wait a bit for routing table to update
sleep 2

# Check internet again after removing USB route
if check_internet; then
    echo "[$(TIMESTAMP)] ✅ Internet fixed by removing bad route."
else
    echo "[$(TIMESTAMP)] ❌ Internet still not working."
fi

echo "[$(TIMESTAMP)] 🌐 Internet check completed."

# Ask user to connect Wi-Fi if internet still not working
read -p "Do you want to connect to a Wi-Fi network now? (y/n): " CONNECT_WIFI
if [[ "$CONNECT_WIFI" == "y" || "$CONNECT_WIFI" == "Y" ]]; then
    read -p "Enter your Wi-Fi SSID: " WIFI_SSID
    read -sp "Enter your Wi-Fi Password: " WIFI_PASS
    echo

    echo "[$(TIMESTAMP)] 🔌 Connecting to Wi-Fi: $WIFI_SSID..."
    
    # Check if NetworkManager is running
    if systemctl is-active --quiet NetworkManager; then
        # Use nmcli to connect to Wi-Fi
        nmcli dev wifi connect "$WIFI_SSID" password "$WIFI_PASS"
        if [ $? -eq 0 ]; then
            echo "[$(TIMESTAMP)] ✅ Successfully connected to $WIFI_SSID."
        else
            echo "[$(TIMESTAMP)] ❌ Failed to connect to $WIFI_SSID."
        fi
    else
        echo "[$(TIMESTAMP)] ❌ NetworkManager is not running. Cannot connect to Wi-Fi."
    fi
fi
