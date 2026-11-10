#!/system/bin/sh
# Auto-accept BT pairing for Aavante Bar 610
TARGET="21:39:77:62:C0:FC"
echo "[*] Monitoring for BT pairing request from $TARGET..."
for i in $(seq 1 30); do
    # Check if pairing dialog is showing
    state=$(dumpsys activity top 2>/dev/null | grep -c "AccessoryActivity\|PairingRequest\|bluetooth")
    if [ "$state" -gt "0" ]; then
        echo "[*] BT activity detected, sending ENTER to confirm..."
        input keyevent 23  # DPAD_CENTER / OK / confirm
        sleep 1
        input keyevent 23
    fi
    sleep 2
done
echo "[*] Monitor done"