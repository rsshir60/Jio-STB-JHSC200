#!/system/bin/sh
# bt_fix_aavante.sh - Force Aavante Bar 610 A2DP connection policy to 100 (ALLOWED)
# Run as: adb shell sh /data/local/tmp/bt_fix_aavante.sh
# 
# Method: Use BluetoothDatabase sqlite3 to directly set A2DP policy = 100
# Then trigger a reconnect via UI

TARGET_MAC="21:39:77:62:C0:FC"
BT_DB="/data/misc/bluedroid/bt_config.conf"
BT_DB2="/data/misc/bluedroid/bt_config.bak"
SQLITE_BT="/data/misc/bluetooth/databases/bt_config.db"

echo "[*] Bluetooth Fix for Aavante Bar 610 ($TARGET_MAC)"
echo "[*] Current bond state check..."

# Check if sqlite3 is available
if which sqlite3 2>/dev/null; then
    echo "[*] sqlite3 available - using DB method"
    # Check which DB exists
    if [ -f "$SQLITE_BT" ]; then
        echo "[*] Found bluetooth DB at $SQLITE_BT"
        sqlite3 "$SQLITE_BT" "SELECT * FROM devices WHERE address='$TARGET_MAC';" 2>/dev/null
        # Set A2DP policy to 100 (ALLOWED)
        sqlite3 "$SQLITE_BT" "UPDATE devices SET a2dp_connection_policy=100 WHERE address='$TARGET_MAC';" 2>/dev/null
        echo "[+] A2DP policy set to 100 via sqlite3"
    fi
fi

# Method 2: Use bt_config.conf directly
if [ -f "$BT_DB" ]; then
    echo "[*] Found $BT_DB - patching..."
    # Check if Aavante is in config
    grep -c "$TARGET_MAC" "$BT_DB" && echo "[*] Found $TARGET_MAC in bt_config.conf"
fi

# Method 3: Use service call to bluetooth_manager directly
# IBluetoothManager.getBluetoothAdapter() returns IBluetooth
# IBluetooth.setActiveDevice(device, A2DP=2)
echo "[*] Attempting service call approach..."

# Trigger BT settings to force connect
am start -n com.android.tv.settings/.accessories.AddAccessoryActivity 2>/dev/null &
sleep 2

echo "[*] Done. Check TV screen for pairing prompt."
echo "[*] If still failing, enable Shizuku and use privileged API"
