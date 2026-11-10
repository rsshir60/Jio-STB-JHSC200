# Reliance Jio STB (JHSC200 / JMSC / JMSB) — The 1% Operator Playbook

> **Authoritative Engineering Reference & Exploit Guide for 100% Carrier-Unlock, ADB Weaponization, Surgical Debloating, Projectivy Modernization, and 4-Tier Automated E2E Validation.**

---

## ⚡ Executive Summary

The Reliance Jio Set-Top Box platform (JHSC200, JMSC200Av2, JMSB200A) represents a locked-down enterprise Customer Premises Equipment (CPE) fleet. Built on Amlogic ARM architectures running customized Android 9/11 kernels, these devices enforce aggressive carrier sandboxing: disabled network ADB, stripped package installer UIs, intent-filter interception, surveillance telemetry daemons, and forced boot advertising.

This repository provides the definitive **Top 1% Engineering Playbook** to achieve **100% operational dominance** over the hardware:
1. **Cryptographic TR-069 MITM Exploit:** Forge eMudhra intermediate CA certificates and intercept CWMP management check-ins via local GenieACS.
2. **Persistent Network ADB Weaponization:** Inject privileged configuration tokens granting unrestricted TCP/IP ADB on port `5555` through year 2037.
3. **Surgical Multi-Tier Debloating:** Neutralize 30+ telemetry engines, background loggers, ad-injectors, and carrier bloatware without breaking DRM/Widevine L1 or system stability.
4. **Projectivy Launcher Modernization:** Deploy Projectivy Launcher v4.73, hijack hardware remote Home key events via `AccessibilityService` injection, configure 16:9 Leanback cards, and tune blur/render parameters for 2GB RAM.
5. **Top 1% Android TV Power Suite:** Automated delivery of SmartTube (4K HDR), TV Bro, VLC, Kodi 21 Omega, Stremio TV, MATVT Virtual Mouse, and TVFileBox.
6. **Kernel & ART Ahead-of-Time Optimization:** Force-compile core packages to native ARM machine code (`cmd package compile -m speed -f`) and configure ActivityManager caching.
7. **Comprehensive 4-Tier Automated E2E Validation:** 31-test opaque-box automated test harness covering feature parity, stress/corner cases, cross-app switching, and real-world TV scenarios.

---

## 🎯 Target Hardware & Architecture Matrix

| Parameter | JHS Series (Primary Focus) | JMSC Series | JMSB Series |
| :--- | :--- | :--- | :--- |
| **Model Number** | **JHSC200 v1** | **JMSC200Av2** | **JMSB200A** |
| **Board Identifier** | `franklin` | `amlogic` reference | `amlogic` reference |
| **SoC** | Amlogic Quad-Core ARM Cortex-A53 | Amlogic Quad-Core ARM Cortex-A53 | Amlogic Quad-Core ARM Cortex-A53 |
| **Instruction Set / ABI** | `armeabi-v7a` (32-bit ARM mode) | `armeabi-v7a` (32-bit ARM mode) | `armeabi-v7a` (32-bit ARM mode) |
| **RAM Budget** | 2,006,900 KB (~2.0 GB) + 655 MB ZRAM | 2.0 GB Physical | 2.0 GB Physical |
| **Display Pipeline** | 1920x1080 @ 320 dpi (Landscape TV) | 1920x1080 @ 320 dpi (Landscape TV) | 1920x1080 @ 320 dpi (Landscape TV) |
| **Base OS** | JioOS 2.0 (Android 11 / SDK 30) | AOSP 9 (Pie / SDK 28) | AOSP 9 (Pie / SDK 28) |
| **Linux Kernel** | 4.9.269 | 4.9.x | 4.9.x |
| **Target Firmware** | `stb-jhcs200-11.3.46` | `22.1.09`, `24.1.39`, `25.1.9` | `22.1.09`, `24.1.39`, `25.1.9` |
| **TLS Validation Mode** | Strict System CA (eMudhra Chain Required) | Lenient Root CA | Lenient Root CA |
| **Exploit Vector** | CWMP TR-069 + Forged eMudhra TLS MITM | CWMP TR-069 + Standard TLS MITM | CWMP TR-069 + Standard TLS MITM |

---

## 🔬 Carrier Lockdown Anatomy & Threat Model

Reliance Jio implements a defense-in-depth lockdown strategy to prevent custom software installation and telemetry evasion:

```
+-----------------------------------------------------------------------------------+
|                            JioOS Carrier Lockdown                                |
+-----------------------------------------------------------------------------------+
| 1. Intent Interception:                                                           |
|    - Stock com.android.packageinstaller is stripped or hidden.                     |
|    - MIME type 'application/vnd.android.package-archive' routed to JioStore.       |
| 2. AppOps Enforcement:                                                            |
|    - REQUEST_INSTALL_PACKAGES hardcoded to MODE_IGNORED / MODE_ERRORED for non-0 UIDs.|
|    - UserManager.DISALLOW_INSTALL_UNKNOWN_SOURCES active in user profile.         |
| 3. Surveillance Telemetry:                                                        |
|    - Daemons (podlogservice, jiostblogservice) report app launches and crashes.   |
|    - Remote control hooks (communitake, teamviewer) permit carrier remote debug.  |
| 4. Ad Injectors & Inactivity Monitors:                                            |
|    - Ad engines (adc.embedded, adc.aka) push fullscreen ads on boot & sleep.      |
| 5. CWMP Heartbeat (TR-069):                                                       |
|    - Box contacts acs.oss.jio.com during boot sequence over TLS.                  |
+-----------------------------------------------------------------------------------+
```

### The Exploitation Vector
Because local UI installation is locked down, the primary vector of entry is the **TR-069 CPE WAN Management Protocol (CWMP)**:
1. When booting, the STB queries DNS for `acs.oss.jio.com` and attempts to initiate a SOAP/XML session with the Auto Configuration Server (ACS) over HTTPS (ports 8443/9443).
2. By redirecting DNS queries locally via Technitium DNS and serving custom CWMP responses through GenieACS, we execute parameter writes (`InternetGatewayDevice.ManagementServer.*` and device settings).
3. For the **JHSC200 (Android 11)**, Jio implemented strict certificate pinning trusting only the national eMudhra public key infrastructure. We use a leaked eMudhra intermediate private key (`jhs/forge_emudhra_chain.py`) to synthesize a cryptographically valid X.509 chain that passes system verification.
4. The injected CWMP payload enables persistent `adbd` over TCP/IP (`setprop service.adb.tcp.port 5555`) with expiration set to 2037, disabling carrier OTA watchdogs.

---

## 📂 Repository Topology

```
c:\Users\SUPRIYA\Desktop\jiostb\
├── debloat_stb.ps1             # Surgical 4-tier package freezer & ART optimizer
├── install_top_apps.ps1        # Downloader & installer for Top 1% Android TV apps
├── rollback_debloat.ps1        # Instant factory rollback script
├── run.bat                     # Interactive operator TUI console
├── start_hotspot.ps1           # Windows WinRT softAP/hotspot initiator
├── PROJECT.md                  # Project architectural blueprint & milestone tracker
├── PLAYBOOK.md                 # Standalone field operator handbook
├── TEST_INFRA.md               # Opaque-box E2E test specification
├── TEST_READY.md               # 4-tier E2E validation matrix & pass criteria
├── projectivy_homescreen.png   # 1080p verified launcher capture artifact
├── scripts/
│   ├── configure_projectivy.ps1# Projectivy v4.73 setup & Accessibility binding
│   ├── run_e2e_tests.ps1       # Comprehensive 4-tier automated test harness
│   ├── freeze_worst_apps.ps1   # Aggressive RAM & drain package freezer
│   ├── sync_tvfilebox.sh       # TVFileBox scoped storage auto-sync daemon
│   ├── bt_fix_aavante.sh       # Bluetooth A2DP audio & soundbar connection fix
│   ├── bt_autoaccept.sh        # Automated Bluetooth pairing dialog accepter
│   ├── check_hotspot.ps1       # Windows WinRT hotspot client inspection tool
│   └── static_ip.sh            # Target device static IP configuration script
├── tests/
│   └── find_stb.ps1            # Multi-subnet parallel port 5555 probe
├── sideload-jiostb/            # TR-069 exploit suite & GenieACS MITM engine
│   ├── stage1.sh               # Master TR-069 orchestrator script
│   ├── doctor.py               # Pre-flight diagnostic & synthetic Inform simulator
│   ├── pull_boot.sh            # Boot partition dumper
│   ├── jhs/
│   │   ├── forge_emudhra_chain.py  # Cryptographic X.509 cert synthesizer
│   │   ├── standalone_jhs_server.py# Zero-dependency Standalone ACS + DNS server
│   │   ├── jhs_stage1.sh           # JHSC200-specific CWMP pipeline
│   │   └── run_acs.sh              # Automated cert minting & TLS proxy runner
│   └── tls/
│       ├── docker-compose.yml  # GenieACS + MongoDB container stack
│       └── pass_front.py       # Dual-port TLS reverse proxy
└── top_apps/                   # Local binary cache for verified Android TV APKs
    ├── ProjectivyLauncher-4.73.apk
    ├── SmartTube_stable_armeabi-v7a.apk
    ├── TVFileBox-armeabi-v7a.apk
    ├── VLC-Android-armeabi-v7a.apk
    ├── kodi-Omega-armeabi-v7a.apk
    ├── matvt-release.apk
    ├── stremio-tv-armeabi-v7a.apk
    └── tvbro_armeabi-v7a.apk
```

---

## 🚀 The 1% Operational Playbook: Step-by-Step

### Phase 0: Host Environment & Prerequisites

Execute on a Windows 10/11 x64 host machine:
* **Clone the Repository:**
  ```cmd
  git clone --recurse-submodules https://github.com/rsshir60/Jio-STB-JHSC200.git
  cd Jio-STB-JHSC200
  ```
* **Docker Desktop**: Active and running Linux containers.
* **Python 3.10+**: Available in system `PATH`.
* **Technitium DNS Server**: Installed and listening on `127.0.0.1:5380`.
* **Git for Windows**: Providing `bash` execution environment.
* **Android Platform Tools**: `adb.exe` installed in `PATH` or bundled in `sideload-jiostb/`.

---

### Phase 1: Local Network Topology & DNS Hijacking

The STB and host PC must reside on the same Layer 2 broadcast domain.

#### Option A: Dedicated Windows Mobile Hotspot (Recommended)
Running the STB through the PC's Wi-Fi hotspot isolates traffic, simplifies IP addressing (`192.168.137.x`), and eliminates router-level packet drops.
```powershell
powershell -ExecutionPolicy Bypass -File .\start_hotspot.ps1
```
Connect the Jio STB to this newly created hotspot.

#### Option B: Shared Home Router
Connect PC and STB to the same home Wi-Fi network (avoid guest networks).

#### Network Isolation & Firewall Rule Override
1. **Unplug Router WAN / Fiber cable**: Prevent the STB from contacting genuine Jio cloud ACS endpoints during the exploit.
2. **Temporarily Disable Windows Firewall** (or open ports `53/udp`, `8443/tcp`, `9443/tcp`, `5555/tcp`):
   ```cmd
   netsh advfirewall set allprofiles state off
   ```

#### STB DNS Configuration via USB Exploit
Because Jio removes DNS settings from standard menus, use the USB redirection bug:
1. Insert any FAT32 USB thumb drive into the STB USB port.
2. Power on the STB $\rightarrow$ Open **My Music** $\rightarrow$ **Settings** $\rightarrow$ Click **Eject USB**.
3. Select **Internal Storage** $\rightarrow$ **Apps** $\rightarrow$ Open **Settings** (Android stock settings).
4. Navigate to **Network** $\rightarrow$ Select your active Wi-Fi $\rightarrow$ **Advanced IP Settings**.
5. Switch from **DHCP** to **Static**:
   - Keep IP, Gateway, and Subnet unchanged.
   - **DNS 1**: Set to Host PC IPv4 address (e.g. `192.168.137.1` or `192.168.1.15`).
   - **DNS 2**: `8.8.8.8`.
6. Save and verify network reconnection.

---

### Phase 2: Technitium DNS & TLS Backend Deployment

#### Option A: Zero-Dependency Standalone Python Server (Recommended for JHSC200 / Android 11)
Bypass Docker, GenieACS, and Technitium completely using the standalone Python server:
```cmd
python sideload-jiostb\jhs\standalone_jhs_server.py
```
*What this runs automatically in a single unified script:*
- **Selective DNS Server (UDP :53):** Resolves `*.jio.com` and `acs.oss.jio.com` directly to your Host PC IP, while passing all external queries (NTP, Google, connectivity check) to `8.8.8.8`.
- **Captive Portal Responder (HTTP :80):** Serves `204 No Content` to ensure the STB network check completes without error.
- **Synthesized eMudhra TLS Server (Ports 8443 / 9443):** Handles secure CWMP transactions using `tls/forged_chain.pem`.
- **CWMP SOAP Engine:** Intercepts `Inform`, transmits `SetParameterValues` (enabling persistent ADB on port 5555 and disabling carrier OTA daemons), and returns `204 No Content`.
- **Automated ADB Watchdog:** Monitors port 5555 and auto-executes post-setup steps upon connection.

#### Option B: Standard Docker + Technitium Setup (All Box Variants)

1. **Configure DNS Override**:
   - Open `http://localhost:5380` in your host browser.
   - Go to **Zones** $\rightarrow$ **Add Zone** $\rightarrow$ Name: `jio.com` (Primary Zone).
   - Click `jio.com` $\rightarrow$ **Add Record**:
     - Name: `acs.oss`
     - Type: `A`
     - IPv4 Address: *Your Host PC IP Address*
   - Verify zone status is **Enabled**.

2. **Deploy GenieACS & MongoDB Containers**:
   ```cmd
   cd sideload-jiostb\tls
   docker compose up -d
   ```

3. **Start the Model-Specific Proxy**:

   * **For JHSC200 (JioOS 2.0 / Android 11):**
     Open Git Bash in `sideload-jiostb/` and run:
     ```bash
     ./jhs/run_acs.sh
     ```
     *This synthesizes the forged eMudhra certificate chain trusted by the JHSC200 system trust store and binds the TLS proxy to ports 8443 and 9443.*

   * **For JMSC200 / JMSB200:**
     In `sideload-jiostb\tls`:
     ```cmd
     python pass_front.py
     ```

4. **Execute Synthetic Health Check**:
   ```bash
   python doctor.py --quick
   python doctor.py --simulate
   ```
   *A successful simulation confirms that the TLS front-end, SOAP envelope parser, and GenieACS NBI are communicating with zero faults.*

---

### Phase 3: Triggering CWMP & Persistent ADB Weaponization

1. **Queue Exploitation Tasks**:
   In Git Bash:
   ```bash
   ./stage1.sh --tasks-only
   ```
2. **Cold Power-Cycle the STB**:
   - **Crucial:** Unplug the physical power adapter from the wall outlet. Standby mode will NOT trigger the boot Inform.
   - Wait 5 seconds.
   - Plug the adapter back in and permit the STB to complete cold boot.
3. **Accept USB Debugging RSA Authorization**:
   - As the STB boots and processes the injected CWMP profile, the TV screen will display the **"Allow USB Debugging?"** RSA fingerprint dialog.
   - Using the Jio remote control, check **"Always allow from this computer"** and click **OK**.
4. **Verify ADB Weaponization**:
   ```cmd
   adb connect 192.168.137.28:5555
   adb devices
   ```
   *Device state must report `device` (not `unauthorized` or `offline`).*

If the IP of the STB is uncertain, locate it with the parallel subnet scanner:
```powershell
powershell -ExecutionPolicy Bypass -File .\tests\find_stb.ps1
```

---

### Phase 4: Surgical Debloating & Telemetry Freezing

Run the multi-tier debloat engine to freeze surveillance and ad services:
```powershell
powershell -ExecutionPolicy Bypass -File .\debloat_stb.ps1 -Target "192.168.137.28:5555"
```

#### Disablement Strategy by Tier:
* **Tier 1 (Surveillance, Telemetry & Logging):**
  `com.rjil.podlogservice`, `com.rjil.jiostblogservice`, `com.teamviewer.quicksupport.addon.jio`, `com.communitake.remotecontrolservice`, `com.iwedia.usbbenchmarkservice`, `com.jio.stb.remotediagnose`, `com.jio.systemstats`, `com.inn.nvengineer`, `com.jio.jiobackgroundscheduler`, `com.jio.smartmemorymanager`, `com.jio.appoptimizer`.
* **Tier 2 (Carrier Gimmicks & Bloatware):**
  `com.jio.jiocall`, `com.jio.media.jionewsstb`, `com.jio.media.jiobeats`, `com.jio.mymusic.app`, `com.jiostb.jiogames`, `com.aksys.jiogamepad`, `com.jio.screensaver`, `com.jio.bioscopecontentservice`, `com.jio.myhome.mediasharedmp`, `com.jio.jiocloudpc`, `com.jio.product.exploremyremote`, `com.jio.universalsetup`, `com.jiostb.fti`, `com.omni.simplesetup`, `com.omni.sci`, `com.jio.stb.bot`, `com.jio.stbwidget`, `com.jio.store`.
* **Tier 3 (Ad Injectors & Wake Trackers):**
  `com.jio.adc.embedded`, `com.jio.adc.aka`, `com.jiostb.inactivitytimer`, `com.iwedia.notificationservice`.
* **Tier 4 (Hardware Demodulators):**
  `com.jio.stb.catv` (DVB-C cable tuner background service).

#### UI Responsiveness & Kernel Tuning:
* Animation scales set to `0.5x` (`window_animation_scale`, `transition_animation_scale`, `animator_duration_scale`).
* ActivityManager process cache bounds expanded: `device_config put activity_manager max_cached_processes 24`.
* Storage cache trimmed: `pm trim-caches 999999999999`.

---

### Phase 5: Projectivy Launcher Modernization Engine

Deploy Projectivy Launcher v4.73 and lock down hardware remote key events:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\configure_projectivy.ps1 -Device "192.168.137.28:5555"
```

#### What This Configures:
1. **Binary Verification:** Validates SHA256 of `top_apps/ProjectivyLauncher-4.73.apk` against `74E33AF1E5E13831A69A0669D2B68B02150BF9DF1AE1DF437DC67E3F8D52C790`.
2. **Default Home Activity:** Registers `com.spocky.projengmenu/.ui.home.MainActivity` as primary home activity.
3. **Accessibility Interception:** Binds `com.spocky.projengmenu.services.ProjectivyAccessibilityService` into `secure enabled_accessibility_services`. This captures hardware Home key event `KEYCODE_HOME` (3) before JioOS can route it back to stock.
4. **Competitor Disablement:** Freezes stock launcher `com.iwedia.ui.rjio.launcher.reliance` and intermediate `com.klevico.monet` to eliminate intent thrashing.
5. **Low-RAM Profiling:** Configures UI rendering to keep blur radius $\le 15$ with video previews disabled, guaranteeing PSS stays below 250 MB within the 2GB memory budget.

---

### Phase 6: Top 1% Android TV Power Suite Deployment

Download, verify, and sideload the curated media and tool packages:
```powershell
powershell -ExecutionPolicy Bypass -File .\install_top_apps.ps1 -Target "192.168.137.28:5555"
```

| Application | Package Identifier | Architecture | Key Capability |
| :--- | :--- | :--- | :--- |
| **SmartTube Stable** | `com.teamsmart.videomanager.tv` | `armeabi-v7a` | Ad-free YouTube, 4K 60fps HDR, SponsorBlock, background playback |
| **TV Bro** | `com.phlox.tvwebbrowser` | `armeabi-v7a` | D-pad optimized browser with built-in adblock and download manager |
| **VLC for Android** | `org.videolan.vlc` | `armeabi-v7a` | Universal hardware decoder for LAN/SMB/DLNA and local media |
| **Kodi 21 Omega** | `org.xbmc.kodi` | `armeabi-v7a` | Home theater media center with addon support |
| **Stremio TV** | `com.stremio.one` | `armeabi-v7a` | Modular streaming platform for on-demand media |
| **MATVT Virtual Mouse**| `com.virresh.matvt` | Universal | On-screen mouse pointer for sideloaded touch-only Android apps |
| **TVFileBox** | `com.willi4m.tvfilebox` | `armeabi-v7a` | Leanback file manager with integrated LAN/FTP/Cloud server |

**Post-Install Privileges & Compilation:**
* `appops set com.virresh.matvt SYSTEM_ALERT_WINDOW allow`: Grants MATVT permission to draw the mouse cursor overlay over all active windows.
* Force-compiles SmartTube and VLC to native code using the ART speed compiler.

---

### Phase 7: ART Ahead-Of-Time (AOT) Machine Compilation

Jio STB hardware is powered by Cortex-A53 cores. Just-In-Time (JIT) runtime compilation introduces visible micro-stutters during app launches. We force the Android Runtime (ART) compiler to compile core applications directly into native machine code Ahead-Of-Time:

```cmd
adb -s 192.168.137.28:5555 shell cmd package compile -m speed -f com.spocky.projengmenu
adb -s 192.168.137.28:5555 shell cmd package compile -m speed -f com.teamsmart.videomanager.tv
adb -s 192.168.137.28:5555 shell cmd package compile -m speed -f org.videolan.vlc
adb -s 192.168.137.28:5555 shell cmd package compile -m speed -f in.startv.hotstar
adb -s 192.168.137.28:5555 shell cmd package compile -m speed -f com.amazon.amazonvideo.livingroom
adb -s 192.168.137.28:5555 shell cmd package compile -m speed -f com.netflix.ninja
```
*Verify compiler status with:*
```cmd
adb shell dumpsys package com.spocky.projengmenu | findstr /i "status="
```
*Output: `[status=speed]` confirms native compilation.*

---

### Phase 8: 4-Tier Automated E2E Verification Engine

To prove 100% operational success, run the comprehensive opaque-box test runner:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_e2e_tests.ps1 -Device "192.168.137.28:5555"
```

The test harness evaluates **31 discrete criteria across 4 execution tiers**:
* **Tier 1: Feature Coverage (T1.01 – T1.15):** Validates package existence, SHA256 integrity, architecture compatibility, default home activity registration, accessibility binding, stock/Monet launcher freeze, memory budget (< 250 MB PSS), AOT compilation status, and app inventory.
* **Tier 2: Boundary & Corner Cases (T2.01 – T2.06):** Injects rapid 20-burst D-pad inputs, 6-burst Home key spam, verifies free memory headroom ($\ge 600$ MB), isolates competing packages, and audits clean handling of `trim-memory COMPLETE`.
* **Tier 3: Cross-Feature Interactions (T3.01 – T3.05):** Launches external applications (SmartTube, TV Bro), injects `KEYCODE_HOME`, asserts Projectivy regains foreground in $< 2000$ ms, measures cross-app context switching memory delta ($< 65$ MB), and audits persistent accessibility bindings.
* **Tier 4: Real-World TV Usage Scenarios (T4.01 – T4.05):** Cold STB wakeup and keyguard dismissal, 12-step D-pad remote navigation sequence, media playback entry and exit, automated 1080p PNG screencap capture and byte-header validation, and zero ANR/crash logcat audit (`logcat -d -b crash`).

---

### Phase 9: Audio, Storage & Extended RAM Optimization

#### 1. Bluetooth A2DP Soundbar / Audio Fix (`scripts/bt_fix_aavante.sh`)
Carrier Android TV builds frequently restrict Bluetooth audio policies, causing soundbars (e.g., boAt Aavante Bar 610) to pair without routing audio.
```cmd
adb push scripts\bt_fix_aavante.sh /data/local/tmp/
adb shell sh /data/local/tmp/bt_fix_aavante.sh
```
*Forces `a2dp_connection_policy = 100 (ALLOWED)` in SQLite database `bt_config.db` / `bt_config.conf` and automates pairing authorization.*

#### 2. TVFileBox Scoped Storage Auto-Sync Daemon (`scripts/sync_tvfilebox.sh`)
Android 11 isolates app storage. Files uploaded over LAN through TVFileBox remain sandboxed in `/storage/emulated/0/Android/data/com.example.tvfilebox/files/uploads`.
Deploy the background daemon:
```cmd
adb push scripts\sync_tvfilebox.sh /data/local/tmp/
adb shell "nohup sh /data/local/tmp/sync_tvfilebox.sh >/dev/null 2>&1 &"
```
*Monitors uploads, instantly moves files to `/storage/emulated/0/Movies/`, and triggers `MEDIA_SCANNER_SCAN_FILE` so VLC and Kodi index media immediately.*

#### 3. Aggressive RAM & Battery/CPU Drain Debloat (`scripts/freeze_worst_apps.ps1`)
To extend memory headroom past 750 MB by freezing 14 additional non-essential daemons (`com.jio.controlcentre`, `com.android.app.jio.voiceassist`, `com.rjl.mobileremote.receiver`, `com.jio.jiopay`, `com.reverie.swalekh.abctv`, `com.jio.yt`, print spoolers, TTS, wallpaper backup):
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\freeze_worst_apps.ps1 -Target "192.168.137.28:5555"
```

---

#### 4. Volatile Hardware Decoders & SurfaceFlinger Properties (`scripts/boot_tuning.ps1`)
On Amlogic user builds, hardware decoder and SurfaceFlinger properties reset across reboots because SELinux restricts persistent property creation for untrusted apps.
Execute on reconnect:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\boot_tuning.ps1 -STB "192.168.137.28:5555"
```
*Enforces hardware decode for MPEG2/AVC/HEVC/VP9, SurfaceFlinger 2000ms idle timer, OpenGL HWUI rendering, Dalvik 4-thread compilation, and auto-starts background voice service.*

---

## 🎛 The Interactive Operator Console (`run.bat`)

For daily operations, double-click `run.bat` to launch the menu-driven operator interface:

```
===============================================================================
       JIO SET-TOP BOX (JHSC200 / JMSC / JMSB) - 1% OPERATOR PLAYBOOK
===============================================================================
 [1] Check Connected ADB Devices
 [2] Connect to STB over Network ADB (Default: 192.168.137.28:5555)
 [3] Scan Local Subnets for Active STBs (Port 5555 Probe)
 [4] Run Standalone Zero-Dependency JHS ACS + DNS Server (standalone_jhs_server.py)
 [5] Run TR-069 Pre-Flight Doctor Check (doctor.py --quick)
 [6] Run Surgical Debloat & Performance Optimization (debloat_stb.ps1)
 [7] Run Aggressive RAM & Drain Disablement (freeze_worst_apps.ps1)
 [8] Apply Volatile Hardware Codec & SurfaceFlinger Properties (boot_tuning.ps1)
 [9] Deploy Projectivy Launcher v4.73 Modernization Suite
 [10] Install Top 1% Android TV Power Suite (SmartTube, TV Bro, VLC, etc.)
 [11] Deploy TVFileBox Auto-Sync Daemon (sync_tvfilebox.sh)
 [12] Apply Bluetooth A2DP Audio / Soundbar Fix (bt_fix_aavante.sh)
 [13] Run Comprehensive 4-Tier E2E Test Suite (run_e2e_tests.ps1)
 [14] Inspect Mobile Hotspot State & Connected Clients (check_hotspot.ps1)
 [15] Capture High-Res Screencap to Working Directory
 [16] Open Interactive Remote ADB Shell
 [17] Rollback Debloat (Restore All Factory System Packages)
 [18] Exit
===============================================================================
```

---

## 🛡 Rollback, Unbricking & Emergency Recovery

### 1-Click Package Rollback
To re-enable all frozen system packages and reset animation scales to `1.0x`:
```powershell
powershell -ExecutionPolicy Bypass -File .\rollback_debloat.ps1 -Target "192.168.137.28:5555"
```

### Network Reset
If the STB loses network sync:
1. Open STB Settings $\rightarrow$ Network $\rightarrow$ Select Network $\rightarrow$ **Forget Network**.
2. Re-enter Wi-Fi credentials and reconnect.

### Hardware Factory Reset (Zero-Risk Guarantee)
The exploit operates strictly in userland and CWMP parameter storage without modifying the bootloader (`uboot`) or recovery partitions. If an irrecoverable state occurs:
1. Unplug power from the STB.
2. Insert a pin into the physical **Reset** button on the rear/underside of the STB.
3. Hold the pin while plugging in the power cable until the recovery screen appears.
4. Select **Wipe data / Factory reset**. The STB returns 100% to clean factory firmware.

---

## 📜 Upstream Attribution & Security Disclosures

* **TR-069 Exploitation & Tooling:** Vishal Beniwal ([@soloxsurfer](https://instagram.com/soloxsurfer) / [u/ilikechocopies](https://www.reddit.com/user/ilikechocopies)).
* **Original Vulnerability Research:** Bihaan Sen, ak_0o7, and Otus9051 ([Housekeeping-PoC](https://github.com/JFC-Group/Housekeeping-PoC/)).
* **JHS Series & eMudhra Chain Synthesis:** Pavit Chhabra ([@mesosan16](https://twitter.com/mesosan16)).
* **Open Source TV Suite Authors:** Spocky (Projectivy Launcher), Yuliskov (SmartTube), truefedex (TV Bro), virresh (MATVT), w1lli4m666-droid (TVFileBox), VideoLAN, and Kodi Foundation.
