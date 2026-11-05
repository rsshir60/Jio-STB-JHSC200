# Ultimate Jio STB Optimization, Debloat & Power Suite

An end-to-end, automated engineering guide and toolset to unlock **network ADB debugging**, surgically **debloat telemetry and background trackers**, apply **kernel-level performance tunings**, and deploy a **custom Android TV power suite** on carrier-locked Reliance Jio Set-Top Boxes.

---

## 🎯 Target Hardware & Tested Models

| Model Family | Target Model | Android / Kernel Base | Target Firmware | Exploit Vector |
| :--- | :--- | :--- | :--- | :--- |
| **JHS Series** | **JHSC200 v1** | JioOS 2.0 (AOSP 9/10 / Linux 4.9.269) | `stb-jhcs200-11.3.46` | TR-069 GenieACS MITM |
| **JMSC Series** | **JMSC200Av2** | AOSP 9 (Linux 4.9) | `22.1.09`, `24.1.39`, `25.1.9` | TR-069 GenieACS MITM |
| **JMSB Series** | **JMSB200A** | AOSP 9 (Linux 4.9) | `22.1.09`, `24.1.39`, `25.1.9` | TR-069 GenieACS MITM |

---

## 🔬 System Architecture & Why Default Sideloading Fails

Carrier-locked Jio STBs operate as managed enterprise Customer Premises Equipment (CPE). In production builds, Jio implements three distinct lockdown layers:

1. **Intent-Filter Hijacking & Stripped PackageInstaller:** The stock AOSP `com.android.packageinstaller` UI is removed or stripped of its default intent filters. In its place, Jio's home launcher registers a high-priority handler for `application/vnd.android.package-archive`, redirecting third-party file manager APK opens directly to JioStore or displaying an "Installation Blocked" toast.
2. **AppOps & User Restrictions:** All non-system UIDs have `REQUEST_INSTALL_PACKAGES` hardcoded to `MODE_IGNORED` or `MODE_ERRORED`, with `MANAGE_UNKNOWN_APP_SOURCES` removed from the settings UI. `UserManager.DISALLOW_INSTALL_UNKNOWN_SOURCES` is actively enforced.
3. **Audit Daemons & OTA Reversion:** Background services audit installed packages (`pm list packages -3`) against a cloud whitelist. Sideloaded apps are hidden from the stock launcher and can be purged during idle maintenance.

**The Solution:**
* **Bypass:** Exploit the local TR-069 ACS management endpoint to trigger a privileged command injection, enabling network ADB (port 5555) and persisting Shevery / Monet Launcher.
* **Debloat:** Use `uid=2000` (shell) commands via ADB to freeze 30+ telemetry daemons and ad engines without tripping SELinux or breaking DRM/Widevine.
* **Tuning:** Execute Ahead-Of-Time (AOT) speed compilation and process cache overrides.

---

## 📂 Repository Contents

```
├── debloat_stb.ps1        # Surgical debloat, UI animation scaling & ART speed compilation
├── install_top_apps.ps1   # Automated downloader & ADB installer for TV power suite
├── rollback_debloat.ps1   # 1-click restore script for all disabled system packages
├── run.bat                # Interactive Windows console menu
├── sideload-jiostb/       # TR-069 ACS MITM exploit engine (by @ilikechocopies)
└── top_apps/              # Local cache directory for downloaded APKs (auto-populated)
```

---

## 🚀 Step-by-Step Deployment Guide

### Phase 1: Prerequisites

Ensure your host machine has the following tools installed:
* **Windows 10/11 PC** connected to the same local Wi-Fi router as your Jio STB (do **not** use isolated Guest Wi-Fi).
* [Git for Windows](https://gitforwindows.org/)
* [Python 3.x](https://www.python.org/downloads/) (ensure **"Add Python to PATH"** is checked).
* [Docker Desktop](https://docs.docker.com/desktop/setup/install/windows-install/)
* [Technitium DNS Server](https://technitium.com/dns/)

---

### Phase 2: Unlock Network ADB & Custom Launcher

The initial unlock utilizes the TR-069 ACS MITM vector located in `sideload-jiostb/`:

1. **Obtain Host IP:** Run `ipconfig` in Command Prompt to identify your PC's local IPv4 (e.g., `192.168.1.15`).
2. **Configure STB DNS:** On the STB, navigate to Network Settings and set your primary DNS to your PC's IP address.
3. **Launch Local Services:**
   * Start Docker Desktop.
   * Start Technitium DNS and configure the local domain override rules matching your box variant.
   * Launch the proxy listener from `sideload-jiostb/` via Git Bash:
     ```bash
     cd sideload-jiostb
     ./stage1.sh
     ```
4. **Authorize ADB:** When prompted on the TV screen, accept the USB Debugging RSA fingerprint prompt.
5. **Verify Connectivity:**
   ```cmd
   adb connect <STB_IP>:5555
   adb devices
   ```

---

### Phase 3: Surgical Debloating & Performance Tuning

Once ADB connectivity is verified, run the debloat script:

```powershell
powershell -ExecutionPolicy Bypass -File .\debloat_stb.ps1
```
*(Alternatively, double-click `run.bat` and select Option 3).*

#### What This Does:
* **Tier 1 (Telemetry & Spyware):** Freezes daemons including `com.rjil.podlogservice`, `com.rjil.jiostblogservice`, `com.teamviewer.quicksupport.addon.jio`, `com.communitake.remotecontrolservice`, `com.jio.systemstats`, and `com.inn.nvengineer`.
* **Tier 2 (Jio Bloatware):** Freezes unused background services (`com.jiostb.jiogames`, `com.jio.jiocall`, `com.jio.store`, `com.jio.bioscopecontentservice`).
* **Tier 3 (Ad Engines):** Freezes ad injectors (`com.jio.adc.embedded`, `com.jio.adc.aka`, `com.jiostb.inactivitytimer`).
* **UI Scaling:** Adjusts `window_animation_scale`, `transition_animation_scale`, and `animator_duration_scale` to `0.5x` for responsive navigation.
* **Cache & Memory:** Sets `max_cached_processes` to 24 and clears persistent package manager caches.
* **ART AOT Speed Compilation:** Force compiles target apps (`Monet Launcher`, `Hotstar`, `Amazon Prime`, `Netflix`) to native machine code (`cmd package compile -m speed -f <pkg>`) to eliminate JIT compilation stutters.

---

### Phase 4: Deploy Top Android TV Power Suite

Install curated, open-source and lean TV media applications:

```powershell
powershell -ExecutionPolicy Bypass -File .\install_top_apps.ps1
```
*(Or choose Option 4 in `run.bat`).*

#### Included Suite:
* **SmartTube (Stable, ARMv7a):** Ad-free YouTube client with native 4K HDR playback and SponsorBlock integration.
* **TV Bro:** Lightweight web browser built specifically for Android TV with remote D-pad navigation.
* **VLC Media Player:** Universal video/audio player capable of decoding local and network streams.
* **Kodi 21 (Omega):** Full-featured home theater media center.
* **Stremio TV:** Modular streaming client for movies, series, and live channels.
* **MATVT Virtual Mouse:** On-screen mouse pointer toggled via remote control for touch-only apps.
* **TVFileBox:** Clean Android TV file manager with LAN/FTP/HTTP transfer support.

---

### Phase 5: Rollback & Recovery

To restore all factory packages and reset animation scales to default `1.0x`:

```powershell
powershell -ExecutionPolicy Bypass -File .\rollback_debloat.ps1
```

If the box exhibits issues or fails to connect:
* **Wi-Fi Issues:** Go to STB Settings $\rightarrow$ Network $\rightarrow$ Select Network $\rightarrow$ **Forget Network**, then re-enter the password.
* **Factory Reset:** Hold the physical reset pin on the rear of the STB or select **Factory Reset** in the system menu. This returns the box to stock firmware.

---

## 🛠 Manual ADB Commands Reference

To manually install an application APK:
```bash
adb -s <STB_IP>:5555 install -r "path/to/app.apk"
```

To list third-party installed packages:
```bash
adb -s <STB_IP>:5555 shell pm list packages -3
```

To launch an installed application directly:
```bash
adb -s <STB_IP>:5555 shell monkey -p <package_name> 1
```

---

## ⚠️ Important Operating Notes

1. **Do Not Sideload `.aab` Files:** Android App Bundles (.aab) are uncompiled protobuf distribution packages. They lack signed V2/V3 APK blocks and will fail to install. Extract `.apk` or split-APKs before installing.
2. **Package Installer UI Missing:** Because the stock package installer UI is stripped from JioOS, you cannot click APK files inside TV file managers. All installations must be routed through `adb install` or privileged managers like Shevery/Shizuku.
3. **Firmware Updates:** Running Phase 1 disables the auto-update services (`com.jio.*` / `com.iwedia.*`), preventing Jio from silently overwriting your configuration.

---

## 📜 Credits & Acknowledgments

* **Vishal Beniwal** ([@soloxsurfer](https://instagram.com/soloxsurfer) / [u/ilikechocopies](https://www.reddit.com/user/ilikechocopies)) — Original research, ACS exploit mechanics, and `sideload-jiostb` pipeline.
* **Yuliskov** — [SmartTube](https://github.com/yuliskov/SmartTube)
* **truefedex** — [TV Bro](https://github.com/truefedex/tv-bro)
* **virresh** — [MATVT Virtual Mouse](https://github.com/virresh/matvt)
* **w1lli4m666-droid** — [TVFileBox](https://github.com/w1lli4m666-droid/TVFileBox)
* **VideoLAN** — [VLC for Android](https://www.videolan.org/vlc/download-android.html)
* **Kodi Foundation** — [Kodi Media Center](https://kodi.tv/)
