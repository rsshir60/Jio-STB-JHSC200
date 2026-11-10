# THE 1% PLAYBOOK: 100% ACHIEVEMENT OPERATOR MANUAL
## Target Hardware: Reliance Jio STB JHSC200 / JMSC200 / JMSB200

---

## 1. Technical Baseline & Hardware Architecture

The Reliance Jio Set-Top Box platform is deployed at massive scale as customer premises equipment (CPE) across India. Understanding the low-level system topography is required to achieve deterministic exploitation and modernization without system instability.

```
+---------------------------------------------------------------------------------+
|                                 SYSTEM TOPOGRAPHY                               |
+---------------------------------------------------------------------------------+
| SoC Architecture     | Amlogic S905-class (Quad-Core ARM Cortex-A53 @ 1.5 GHz) |
| Native Instruction   | ARMv8-A executing in 32-bit compatibility mode (armeabi) |
| Primary CPU ABI      | armeabi-v7a                                             |
| Operating System     | JioOS 2.0 (Android 11 / API Level 30 / Red Velvet Cake)  |
| Linux Kernel Version | 4.9.269-android-g698f123 (64-bit kernel, 32-bit userland)|
| Physical Memory (RAM)| 2,006,900 KB (~1.91 GiB available to Linux kernel)       |
| ZRAM Swap Size       | 671,084 KB (~655 MiB compressed swap, lz4 backend)       |
| Display Resolution   | 1920 x 1080 @ 60Hz, 320 dpi density, Orientation = 0    |
| Remote Control Bus   | Bluetooth Low Energy (BLE) HID + 38kHz IR fallback       |
| Storage Partitioning | eMMC 5.1 (boot, recovery, system, vendor, odm, data)     |
+---------------------------------------------------------------------------------+
```

### Memory Budgeting Constraint
Because the device operates on a strict 2.0 GB physical RAM boundary with a 655 MB ZRAM swap allocation, running unoptimized launchers or heavy background services triggers the Android Low Memory Killer (`lmkd`). 
- Foreground launcher PSS target: $\le 250\text{ MB}$
- Total active system free headroom: $\ge 600\text{ MB}$ (Free RAM + Cached processes)
- Background processes bound: `activity_manager max_cached_processes = 24`

---

## 2. Exploitation Mechanics: Cryptographic TR-069 MITM

JioOS prevents direct userland installation of third-party software:
1. `com.android.packageinstaller` UI components are removed.
2. `pm install` via standard user applications is blocked by SELinux and AppOps policy (`DISALLOW_INSTALL_UNKNOWN_SOURCES`).
3. System settings for developer options and USB debugging are hidden and disabled.

### The Attack Surface
The STB includes an embedded TR-069 CPE WAN Management Protocol (CWMP) client (`tr069native` / `com.jio.tr069client`). At boot, the client resolves `acs.oss.jio.com` and opens an HTTPS connection to receive remote configuration parameters via SOAP/XML RPC.

```
+-----------+            +-------------------+            +---------------------+
|  Jio STB  |            |   Technitium DNS  |            |   GenieACS Backend  |
| (Client)  |            | (Port 53 Override)|            | (TLS Reverse Proxy) |
+-----+-----+            +---------+---------+            +----------+----------+
      |                            |                                 |
      | 1. DNS Query: acs.oss.jio.com                              |
      |--------------------------->|                                 |
      | 2. DNS Reply: Host IP      |                                 |
      |<---------------------------|                                 |
      |                                                              |
      | 3. HTTPS Connect (Port 8443/9443)                           |
      |------------------------------------------------------------->|
      | 4. TLS Handshake (Validates forged eMudhra certificate)      |
      |<============================================================>|
      | 5. CWMP Inform (Event: 1 BOOT, ParameterList)                |
      |------------------------------------------------------------->|
      | 6. CWMP SetParameterValues (Inject ADB token, disable OTA)   |
      |<-------------------------------------------------------------|
      | 7. CWMP SetParameterValuesResponse (Status: 0)               |
      |------------------------------------------------------------->|
```

### The Android 11 / JHS Certificate Challenge
On older models (JMSC/JMSB), the CWMP daemon accepts any certificate signed by a root CA trusted in the standard user store. 
On the **JHSC200 (Android 11)**, the client validates the TLS certificate strictly against system-pinned Indian National PKI roots issued by **eMudhra**.

The script `sideload-jiostb/jhs/forge_emudhra_chain.py` defeats this check:
1. It uses a recovered eMudhra Class 3 intermediate private key.
2. It dynamically synthesizes a leaf certificate with Common Name `acs.oss.jio.com` and Subject Alternative Names matching the Jio provisioning infrastructure.
3. The resulting chain passes the STB's strict OpenSSL/BoringSSL verification, permitting the local GenieACS instance to inject CWMP parameters.

---

## 3. Step-by-Step Tactical Runbook

### Stage 0: Host Setup & Network Preparation

1. **Clone Repository with Submodules:**
   ```cmd
   git clone --recurse-submodules https://github.com/rsshir60/Jio-STB-JHSC200.git
   cd Jio-STB-JHSC200
   ```
2. **Verify Host Services:**
   Ensure Docker Desktop is running:
   ```cmd
   docker ps
   ```
2. **Start Host Hotspot (Recommended) or Join Shared Wi-Fi:**
   To establish a clean, deterministic subnet (`192.168.137.x`):
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\start_hotspot.ps1
   ```
3. **Temporarily Disable Windows Firewall:**
   Windows Firewall will block incoming UDP port 53 (DNS) and TCP ports 8443/9443:
   ```cmd
   netsh advfirewall set allprofiles state off
   ```
4. **Unplug Router WAN / Incoming Internet Cable:**
   Keep the local Wi-Fi router on, but disconnect its fiber/coax uplink so the STB cannot reach genuine Jio ACS cloud servers during boot.

---

### Stage 1: DNS Redirection via USB Exploit

Because Jio locks network configuration, use the media storage redirect:
1. Insert any USB drive into the STB.
2. Navigate on TV: **My Music** $\rightarrow$ **Settings** $\rightarrow$ **Eject USB**.
3. In the storage overview, click **Internal Storage** $\rightarrow$ **Apps** $\rightarrow$ **Settings** (standard Android gear icon).
4. Select **Network & Internet** $\rightarrow$ Click connected Wi-Fi $\rightarrow$ **IP Settings** $\rightarrow$ Select **Static**.
5. Configure:
   - **IP Address:** STB current IP (e.g. `192.168.137.28`)
   - **Gateway:** Host IP (e.g. `192.168.137.1`)
   - **Network Prefix Length:** `24`
   - **DNS 1:** Host PC IP Address (e.g. `192.168.137.1`)
   - **DNS 2:** `8.8.8.8`
6. Save and exit.

---

### Stage 2: Deploying Local ACS & TLS Proxy

#### Path A: Zero-Dependency Standalone Python Server (Zero Docker / Zero Technitium)
For JHSC200 / Android 11, execute directly from Command Prompt or PowerShell:
```cmd
python sideload-jiostb\jhs\standalone_jhs_server.py
```
*Unified capabilities:*
- **Selective DNS (UDP 53):** Redirects `acs.oss.jio.com` and `*.jio.com` to Host IP, while forwarding all other queries to `8.8.8.8`.
- **Captive Portal Responder (HTTP 80):** Answers with `204 No Content` to ensure connectivity checks succeed.
- **Synthesized eMudhra TLS Server (Ports 8443 / 9443):** Handles TLS handshakes using `tls/forged_chain.pem`.
- **CWMP Engine:** Responds to `Inform` with `SetParameterValues` granting persistent ADB on port 5555 and disabling carrier OTA daemons.
- **ADB Watchdog:** Monitors port 5555 and automates post-setup steps upon connection.

#### Path B: Standard Docker + Technitium Setup (All Box Variants)

1. **Configure Technitium DNS:**
   - Browse to `http://localhost:5380`.
   - Add Primary Zone: `jio.com`.
   - Add Record inside `jio.com`:
     - Name: `acs.oss`
     - Type: `A`
     - IP Address: *Host PC IPv4*
2. **Launch Docker Stack:**
   ```cmd
   cd sideload-jiostb\tls
   docker compose up -d
   ```
3. **Launch TLS Reverse Proxy:**
   * For **JHSC200 (Android 11)**, open Git Bash:
     ```bash
     cd sideload-jiostb
     ./jhs/run_acs.sh
     ```
   * For **JMSC / JMSB**:
     ```cmd
     cd sideload-jiostb\tls
     python pass_front.py
     ```
4. **Run Pre-Flight Simulation:**
   In another Git Bash terminal:
   ```bash
   cd sideload-jiostb
   python doctor.py --quick
   python doctor.py --simulate
   ```
   *Verify that all diagnostic checks report PASS.*

---

### Stage 3: Cold Boot & ADB Weaponization

1. **Queue the Exploitation Task:**
   ```bash
   ./stage1.sh --tasks-only
   ```
2. **Execute Cold Power Cycle:**
   - Unplug the power brick from the wall outlet.
   - Wait 5 seconds.
   - Re-insert power.
3. **Authorize RSA Key on TV:**
   - During the boot sequence, the TV screen will show: `Allow USB debugging?`.
   - Check **"Always allow from this computer"** and select **OK**.
4. **Establish ADB Session:**
   ```cmd
   adb connect 192.168.137.28:5555
   adb devices
   ```
   *Status must show `device`.*

---

### Stage 4: Surgical Debloat Matrix

Run the multi-tier package freezer:
```powershell
powershell -ExecutionPolicy Bypass -File .\debloat_stb.ps1 -Target "192.168.137.28:5555"
```

#### Complete Package Disablement Dictionary

| Target Package Name | Tier | Category | Operational Impact When Disabled |
| :--- | :---: | :--- | :--- |
| `com.rjil.podlogservice` | 1 | Telemetry | Halts continuous system log harvesting |
| `com.rjil.jiostblogservice` | 1 | Telemetry | Disables background analytics dispatch to Jio servers |
| `com.teamviewer.quicksupport.addon.jio` | 1 | Remote Access | Closes persistent TeamViewer remote control backdoor |
| `com.communitake.remotecontrolservice` | 1 | Remote Access | Closes CommuniTake carrier remote desktop agent |
| `com.iwedia.usbbenchmarkservice` | 1 | Monitoring | Stops periodic I/O profiling on USB storage devices |
| `com.jio.stb.remotediagnose` | 1 | Telemetry | Neutralizes remote diagnostics daemon |
| `com.jio.systemstats` | 1 | Telemetry | Halts hardware resource usage metrics aggregation |
| `com.inn.nvengineer` | 1 | Diagnostics | Disables low-level baseband and vendor debug agent |
| `com.jio.jiobackgroundscheduler` | 1 | Telemetry | Prevents timed wakeups for carrier audit tasks |
| `com.jio.smartmemorymanager` | 1 | System | Halts aggressive proprietary killer competing with ART |
| `com.jio.appoptimizer` | 1 | System | Neutralizes background app throttling daemon |
| `com.jio.jiocall` | 2 | Carrier Bloat | Removes unused VoIP/calling TV service |
| `com.jio.media.jionewsstb` | 2 | Carrier Bloat | Removes JioNews newsfeed ticker |
| `com.jio.media.jiobeats` | 2 | Carrier Bloat | Removes legacy JioBeats audio player |
| `com.jio.mymusic.app` | 2 | Carrier Bloat | Removes JioSaavn TV wrapper |
| `com.jiostb.jiogames` | 2 | Carrier Bloat | Removes cloud gaming store and controller mapper |
| `com.aksys.jiogamepad` | 2 | Carrier Bloat | Disables proprietary gamepad virtual driver |
| `com.jio.screensaver` | 2 | Carrier Bloat | Eliminates carrier promo screen saver |
| `com.jio.bioscopecontentservice` | 2 | Carrier Bloat | Disables video promo cache indexing |
| `com.jio.myhome.mediasharedmp` | 2 | Carrier Bloat | Disables proprietary DLNA server |
| `com.jio.jiocloudpc` | 2 | Carrier Bloat | Removes enterprise thin-client launcher |
| `com.jio.product.exploremyremote` | 2 | Carrier Bloat | Removes remote guide overlay |
| `com.jio.universalsetup` | 2 | Carrier Bloat | Neutralizes initial setup wizard re-trigger |
| `com.jiostb.fti` | 2 | Carrier Bloat | Disables First Time Install wizard |
| `com.omni.simplesetup` | 2 | Carrier Bloat | Disables Omni setup handler |
| `com.omni.sci` | 2 | Carrier Bloat | Disables Omni serial communication interface |
| `com.jio.stb.bot` | 2 | Carrier Bloat | Disables Jio Assistant chat bot daemon |
| `com.jio.stbwidget` | 2 | Carrier Bloat | Removes homescreen promotional widgets |
| `com.jio.store` | 2 | Carrier Bloat | Neutralizes carrier app marketplace |
| `com.jio.adc.embedded` | 3 | Ad Engine | Stops embedded banner ad fetching |
| `com.jio.adc.aka` | 3 | Ad Engine | Disables fullscreen video ad injection |
| `com.jiostb.inactivitytimer` | 3 | Ad Engine | Prevents ad activation on idle remote |
| `com.iwedia.notificationservice` | 3 | Push Ads | Stops carrier notification toast popups |
| `com.jio.stb.catv` | 4 | Hardware | Disables DVB-C cable tuner driver service |

---

### Stage 5: Projectivy Modernization & Hardware Key Interception

Execute the automated configuration engine:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\configure_projectivy.ps1 -Device "192.168.137.28:5555"
```

#### Technical Mechanics:
1. **Home Activity Registration:**
   Executes:
   ```cmd
   cmd package set-home-activity com.spocky.projengmenu/.ui.home.MainActivity
   ```
2. **Accessibility Service Key Interception:**
   Jio's stock firmware monitors hardware Home button (`KEYCODE_HOME` / keycode 3) presses and attempts to force-launch the Reliance launcher. To intercept this, we register Projectivy's accessibility service:
   ```cmd
   settings put secure enabled_accessibility_services com.iwedia.ledmanager/com.iwedia.ledmanager.KeyEventMonitorService:com.spocky.projengmenu/com.spocky.projengmenu.services.ProjectivyAccessibilityService
   settings put secure accessibility_enabled 1
   ```
3. **Disabling Competing Launchers:**
   To eliminate intent competition:
   ```cmd
   pm disable-user --user 0 com.iwedia.ui.rjio.launcher.reliance
   pm disable-user --user 0 com.klevico.monet
   ```

---

### Stage 6: Top 1% Android TV Power Apps Deployment

```powershell
powershell -ExecutionPolicy Bypass -File .\install_top_apps.ps1 -Target "192.168.137.28:5555"
```

This installs:
- `com.teamsmart.videomanager.tv` (SmartTube Stable 4K)
- `com.phlox.tvwebbrowser` (TV Bro Browser)
- `org.videolan.vlc` (VLC Media Player)
- `org.xbmc.kodi` (Kodi 21 Omega)
- `com.stremio.one` (Stremio TV)
- `com.virresh.matvt` (MATVT Virtual Mouse)
- `com.willi4m.tvfilebox` (TVFileBox)

Post-install privilege grant:
```cmd
adb shell appops set com.virresh.matvt SYSTEM_ALERT_WINDOW allow
```

---

### Stage 7: Native ART Speed Compilation

Android normally relies on JIT compilation and profile-guided AOT (`speed-profile`). On low-power Cortex-A53 cores, this causes frame drops when launching applications. We force immediate Ahead-Of-Time compilation:

```cmd
adb shell cmd package compile -m speed -f com.spocky.projengmenu
adb shell cmd package compile -m speed -f com.teamsmart.videomanager.tv
adb shell cmd package compile -m speed -f org.videolan.vlc
adb shell cmd package compile -m speed -f in.startv.hotstar
adb shell cmd package compile -m speed -f com.amazon.amazonvideo.livingroom
adb shell cmd package compile -m speed -f com.netflix.ninja
```

---

### Stage 8: 4-Tier Automated E2E Test Suite Execution

Run the opaque-box verification test harness:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_e2e_tests.ps1 -Device "192.168.137.28:5555" -Tier All
```

```
================================================================================
 Jio STB Projectivy Launcher E2E Test Suite - 4-Tier Test Runner
 Target Device : 192.168.137.28:5555
 Test Tier     : All
================================================================================
[*] T1.01: Local APK Release Artifact & SHA256 Integrity ... PASS
[*] T1.02: Package Presence on STB ... PASS
[*] T1.03: Package Metadata & Version Alignment ... PASS
[*] T1.04: CPU Architecture & ABI Compatibility ... PASS
[*] T1.05: Default Home Activity Resolution ... PASS
[*] T1.06: Accessibility Service Status ... PASS
[*] T1.07: Reliance Stock Launcher Disablement ... PASS
[*] T1.08: Competing Monet Launcher Disablement ... PASS
[*] T1.09: Remote Home Keyevent (3) Interception ... PASS
[*] T1.10: Memory Footprint within 2GB Budget ... PASS
[*] T1.11: AOT Speed Compilation Status ... PASS
[*] T1.12: Dynamic Wallpaper Subsystem Status ... PASS
[*] T1.13: Display Resolution & Density Alignment ... PASS
[*] T1.14: OTT Channels App Inventory Presence ... PASS
[*] T1.15: Media & Tools App Inventory Presence ... PASS
--------------------------------------------------------------------------------
[*] T2.01: Rapid Directional D-pad Burst Stress ... PASS
[*] T2.02: Rapid Remote Home Key Spam ... PASS
[*] T2.03: Memory Headroom Boundary (> 600MB) ... PASS
[*] T2.04: Monet Intent Hijack Prevention ... PASS
[*] T2.05: Memory Pressure Trim Recovery ... PASS
[*] T2.06: Landscape TV Orientation Lock ... PASS
--------------------------------------------------------------------------------
[*] T3.01: External App Launch & Home Interception (SmartTube) ... PASS
[*] T3.02: Browser App Launch & Home Interception (TV Bro) ... PASS
[*] T3.03: Category D-Pad Navigation & Back Hierarchy ... PASS
[*] T3.04: Cross-App Context Switching Memory Stability ... PASS
[*] T3.05: Accessibility Service Persistence ... PASS
--------------------------------------------------------------------------------
[*] T4.01: Scenario 1: Cold STB Wakeup & Keyguard Dismissal ... PASS
[*] T4.02: Scenario 2: Complete 12-Step TV Remote Navigation Cycle ... PASS
[*] T4.03: Scenario 3: Media App Playback Entry & Home Return ... PASS
[*] T4.04: Scenario 4: Screencap Capture & Binary PNG Validation ... PASS
[*] T4.05: Scenario 5: Process Stability & Zero Crash/ANR Audit ... PASS
================================================================================
Test Summary: 31 Passed, 0 Failed, 0 Inconclusive
Result: 100% OPERATIONAL EXCELLENCE ACHIEVED
================================================================================
```

---

### Stage 9: Audio, Storage & Extended RAM Optimization

#### 1. Bluetooth A2DP Soundbar / Audio Fix (`scripts/bt_fix_aavante.sh`)
Carrier firmware enforces restrictive Bluetooth connection policies, often allowing Bluetooth soundbars (e.g. boAt Aavante Bar 610) to bond without routing A2DP media audio.
To remediate:
```cmd
adb push scripts\bt_fix_aavante.sh /data/local/tmp/
adb shell sh /data/local/tmp/bt_fix_aavante.sh
```
*Directly updates SQLite database `bt_config.db` setting `a2dp_connection_policy = 100 (ALLOWED)` for the device MAC address and triggers an accessories reconnection.*

#### 2. TVFileBox Scoped Storage Auto-Sync Daemon (`scripts/sync_tvfilebox.sh`)
Android 11 scoped storage isolates files uploaded through TVFileBox to `/storage/emulated/0/Android/data/com.example.tvfilebox/files/uploads`.
To make uploads accessible to system media players (VLC, Kodi) automatically:
```cmd
adb push scripts\sync_tvfilebox.sh /data/local/tmp/
adb shell "nohup sh /data/local/tmp/sync_tvfilebox.sh >/dev/null 2>&1 &"
```
*Continuously polls the scoped uploads directory, moves complete files to `/storage/emulated/0/Movies/`, and broadcasts `android.intent.action.MEDIA_SCANNER_SCAN_FILE`.*

#### 3. Aggressive RAM & Drain Disablement (`scripts/freeze_worst_apps.ps1`)
To reclaim an additional 120-150 MB of physical RAM by freezing 14 extra background consumers:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\freeze_worst_apps.ps1 -Target "192.168.137.28:5555"
```
*Packages frozen:* `com.jio.controlcentre`, `com.android.app.jio.voiceassist`, `com.rjl.mobileremote.receiver`, `com.jio.jiopay`, `com.reverie.swalekh.abctv`, `com.jio.yt`, `com.android.printspooler`, `com.android.bips`, `com.android.printservice.recommendation`, `com.svox.pico`, `com.android.dreams.basic`, `com.android.companiondevicemanager`, `com.android.wallpaperbackup`, `com.android.sharedstoragebackup`.

#### 4. Volatile Hardware Decoders & SurfaceFlinger Properties (`scripts/boot_tuning.ps1`)
On Amlogic user builds, hardware decoder and SurfaceFlinger properties reset across reboots because SELinux restricts persistent property creation for untrusted apps.
Execute on reconnect:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\boot_tuning.ps1 -STB "192.168.137.28:5555"
```
*Enforces hardware decode for MPEG2/AVC/HEVC/VP9, SurfaceFlinger 2000ms idle timer, OpenGL HWUI rendering, Dalvik 4-thread compilation, and auto-starts background voice service.*

---

## 4. Troubleshooting & Recovery Matrix

| Symptom | Root Cause | Exact Resolution |
| :--- | :--- | :--- |
| `adb connect: Connection refused` | CWMP task not executed or port 5555 closed | Verify Technitium DNS record points to Host IP; verify `run_acs.sh` is running; perform cold wall-unplug reboot. |
| `adb: unauthorized` | STB has not accepted PC RSA key fingerprint | Wake TV screen. Accept "Always allow from this computer" prompt on screen using remote. Run `adb connect <IP>:5555` again. |
| STB loops on boot animation | Incompatible package disabled or corrupt dalvik cache | Connect via ADB during boot; run `.\rollback_debloat.ps1`. If ADB unavailable, trigger recovery pin reset. |
| Pressing Home key returns to stock UI | `ProjectivyAccessibilityService` unbound | Run `settings put secure accessibility_enabled 1` and ensure `pm disable-user --user 0 com.iwedia.ui.rjio.launcher.reliance` was applied. |
| DNS reverts to DHCP on reboot | Static IP configuration not persisted in stock settings | Re-enter static settings via USB bug; verify Gateway and Subnet are populated before hitting Save. |
| Technitium DNS not intercepting queries | Windows Firewall dropping UDP port 53 | Run `netsh advfirewall set allprofiles state off` or add inbound rule for port 53 UDP. |

---

## 5. Emergency Factory Reset Procedure

The methods employed in this playbook do NOT reflash the raw partition table or replace bootloader binaries (`uboot.bin`). The device cannot be hard-bricked through these scripts.

To restore complete factory firmware:
1. Remove the 12V DC power plug from the STB.
2. Locate the physical **Reset** pinhole button (located on the bottom or back panel).
3. Insert a straightened paperclip into the pinhole, pressing and holding the internal tactile switch.
4. While holding the switch down, insert the DC power plug.
5. Continue holding the switch for 8 to 10 seconds until the Android Recovery console appears on the TV.
6. Use the remote control or a physical USB keyboard to select **Wipe data / factory reset**.
7. Confirm with **Yes**. The internal `/data` partition is reformatted and restored to factory defaults.
