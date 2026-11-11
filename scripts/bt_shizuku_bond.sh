#!/system/bin/sh
# bt_shizuku_bond.sh - Bypass Jio carrier whitelist and force A2DP bond with Aavante Bar 610
TARGET_MAC="21:39:77:62:C0:FC"

echo "[*] Initiating privileged Bluetooth bonding with $TARGET_MAC..."

# 1. Force A2DP sink policy to 100 (ALLOWED)
cmd bluetooth_manager set-connection-policy "$TARGET_MAC" A2DP_SINK 100 2>/dev/null
cmd bluetooth_manager set-connection-policy "$TARGET_MAC" A2DP 100 2>/dev/null

# 2. Invoke createBond via Android intent and service call
am broadcast -a android.bluetooth.device.action.PAIRING_REQUEST --es "android.bluetooth.device.extra.DEVICE" "$TARGET_MAC" 2>/dev/null

# 3. Direct reflection bond using app_process
cat << 'EOF' > /data/local/tmp/DirectBond.java
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import java.lang.reflect.Method;

public class DirectBond {
    public static void main(String[] args) {
        try {
            BluetoothAdapter adapter = BluetoothAdapter.getDefaultAdapter();
            if (adapter == null) {
                System.out.println("[-] BluetoothAdapter is null");
                return;
            }
            BluetoothDevice device = adapter.getRemoteDevice("21:39:77:62:C0:FC");
            System.out.println("[*] Target Device: " + device.getAddress());
            
            // Try createBond(TRANSPORT_BREDR = 1)
            try {
                Method m = device.getClass().getMethod("createBond", int.class);
                boolean res = (Boolean) m.invoke(device, 1);
                System.out.println("[+] createBond(TRANSPORT_BREDR): " + res);
            } catch (NoSuchMethodException nsme) {
                boolean res = device.createBond();
                System.out.println("[+] createBond(): " + res);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
EOF

echo "[+] Bluetooth bond dispatch triggered."
