# Project: Jio STB Projectivy Launcher Modernization

## Architecture
- **Target Device**: Reliance Jio Set-Top Box JHSC200 (board: `franklin`, SoC: Amlogic quad-core Cortex-A53, Android 11 / SDK 30, ABI: `armeabi-v7a`, 2GB RAM).
- **Network Interface**: Persistent ADB over TCP/IP at `192.168.137.28:5555`.
- **Target Home Launcher**: Projectivy Launcher v4.73 (`com.spocky.projengmenu`), Home Activity: `com.spocky.projengmenu.ui.home.MainActivity`.
- **Failsafe System Interception**: `com.spocky.projengmenu.services.ProjectivyAccessibilityService` bound via secure settings to ensure hardware remote Home button presses always invoke Projectivy.
- **Visual Styling Subsystem**: Dynamic Reddit/Wikimedia high-resolution wallpaper backdrop with 16:9 Leanback cards, 12dp rounded corners, focus glow, and low-RAM tuning (blur <= 15, no video preview).
- **Categorization Structure**:
  - Row 1: **OTT Channels** (`in.startv.hotstar`, `com.amazon.amazonvideo.livingroom`, `com.netflix.ninja`, `com.jio.media.jiotvplus`, `com.jiotv.sonyliv`, `com.zee5.aosp`, `com.jio.media.livetv`).
  - Row 2: **Media & Tools** (`org.smarttube.stable`, `com.stremio.one`, `com.phlox.tvwebbrowser`, `com.example.tvfilebox`, `io.github.virresh.matvt`, `org.videolan.vlc`).

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | F1_ACQUIRE_INSTALL | Acquire Projectivy Launcher v4.73 APK with armeabi-v7a support and install on STB via ADB | M1 | ORIGINAL_REQUEST §R1 |
| 2 | F2_HOME_INTEGRATION | Set Projectivy Launcher as default home activity and bind ProjectivyAccessibilityService | M1 | ORIGINAL_REQUEST §R1 |
| 3 | F3_RAM_OPTIMIZATION | AOT speed compilation (`compile -m speed -f`) and tuning for 2GB RAM budget | M1 | ORIGINAL_REQUEST §R1 |
| 4 | F4_DYNAMIC_WALLPAPER | Configure dynamic high-resolution background wallpaper (Reddit feeds or Wikimedia/Unsplash) | M2 | ORIGINAL_REQUEST §R2 |
| 5 | F5_VISUAL_STYLING | Configure card dimensions (16:9), focus glow, rounded corners, and proper Leanback banner rendering | M2 | ORIGINAL_REQUEST §R2 |
| 6 | F6_ROW_CATEGORIZATION | Organize apps into dedicated rows: "OTT Channels" and "Media & Tools" | M2 | ORIGINAL_REQUEST §R3 |
| 7 | F7_NAV_AUTOMATION_TEST | Verify D-pad responsiveness and Home key handling via ADB keyevent injection | M3 | ORIGINAL_REQUEST §R4 |
| 8 | F8_MEMINFO_VERIFICATION | Verify memory footprint of Projectivy Launcher within 2GB budget via `dumpsys meminfo` | M3 | ORIGINAL_REQUEST §R4 |
| 9 | F9_SCREENSHOT_CAPTURE | Capture final PNG screenshot of active launcher UI to working directory | M3 | ORIGINAL_REQUEST §R4 |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Launcher Acquisition & System Integration | F1_ACQUIRE_INSTALL, F2_HOME_INTEGRATION, F3_RAM_OPTIMIZATION | none | PLANNED |
| M2 | Wallpaper Styling & App Categorization | F4_DYNAMIC_WALLPAPER, F5_VISUAL_STYLING, F6_ROW_CATEGORIZATION | M1 | PLANNED |
| M3 | E2E Testing & UI Inspection Verification | F7_NAV_AUTOMATION_TEST, F8_MEMINFO_VERIFICATION, F9_SCREENSHOT_CAPTURE | M2 | PLANNED |

## Interface Contracts
### M1 ↔ M2
- Projectivy Launcher package `com.spocky.projengmenu` must be installed, active as default home activity, and responding to `adb shell input keyevent KEYCODE_HOME`.
- Monet launcher (`com.klevico.monet`) must be disabled to prevent intent fighting.
- Accessibility service `com.spocky.projengmenu.services.ProjectivyAccessibilityService` must be enabled in `secure enabled_accessibility_services`.

### M2 ↔ M3
- Dynamic wallpaper and styled 16:9 banners must be rendering.
- Categories ("OTT Channels" and "Media & Tools") must be configured on the home screen.
- Screen must be active (wake/unlocked) and ready for D-pad navigation and automated screencap.

## Code Layout
- `top_apps/ProjectivyLauncher-4.73.apk`: Official v4.73 release binary.
- `scripts/configure_projectivy.ps1`: Automated deployment and configuration script.
- `scripts/verify_projectivy.ps1`: Automated E2E verification test script.
- `projectivy_homescreen.png`: Final verification artifact in project root.
