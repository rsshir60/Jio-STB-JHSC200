# TEST_READY: Jio STB Projectivy Launcher E2E Test Suite

## Executive Summary
This document provides the authoritative specification, architecture, execution instructions, and test coverage mapping for the comprehensive 4-tier opaque-box E2E test suite developed for the Reliance Jio Set-Top Box (JHSC200) Projectivy Launcher Modernization project.

The test suite is implemented in PowerShell at `c:\Users\SUPRIYA\Desktop\jiostb\scripts\run_e2e_tests.ps1` and runs non-destructively against the physical STB over network ADB at `192.168.137.28:5555`.

---

## Target Environment & Hardware Specifications
- **Target Device**: Reliance Jio Set-Top Box JHSC200 (Device: `franklin`, Manufacturer: `Jio`)
- **System-on-Chip**: Amlogic quad-core ARM Cortex-A53
- **Operating System**: Android 11 (Red Velvet Cake, SDK 30)
- **Primary CPU ABI**: `armeabi-v7a` (32-bit ARM)
- **RAM Budget**: 2,006,900 KB (~2.0 GB physical, with 655MB ZRAM swap)
- **Display Output**: 1920x1080 @ 320 dpi, landscape TV mode (Orientation = 0)
- **ADB Interface**: Persistent TCP/IP ADB at `192.168.137.28:5555`

---

## Test Architecture & Code Layout
- **Test Runner Script**: `c:\Users\SUPRIYA\Desktop\jiostb\scripts\run_e2e_tests.ps1`
- **Verification Artifact**: `c:\Users\SUPRIYA\Desktop\jiostb\projectivy_homescreen.png` (1080p UI screencap)
- **Binary Source**: `c:\Users\SUPRIYA\Desktop\jiostb\top_apps\ProjectivyLauncher-4.73.apk`
- **Test Execution Framework**: Native PowerShell 5.1 / 7+ with ADB bridge automation
- **Exit Code Convention**:
  - `0`: All test assertions passed successfully.
  - `1`: One or more test assertions failed, or device connectivity could not be established.

---

## 4-Tier Test Matrix & Coverage Summary

The test suite covers 31 discrete, opaque-box test cases across 4 rigorous verification tiers derived from `ORIGINAL_REQUEST.md`, `PROJECT.md`, and `TEST_INFRA.md`:

### Tier 1: Feature Coverage (Isolated Requirement Verification)
| Test ID | Feature ID | Description | Authoritative Expected Output |
|---|---|---|---|
| **T1.01** | `F1_ACQUIRE_INSTALL` | Local APK Release Artifact & SHA256 Integrity | File exists, size > 10MB, SHA256 == `74E33AF1E5E13831A69A0669D2B68B02150BF9DF1AE1DF437DC67E3F8D52C790` |
| **T1.02** | `F1_ACQUIRE_INSTALL` | Package Presence on STB | `pm list packages` contains `package:com.spocky.projengmenu` |
| **T1.03** | `F1_ACQUIRE_INSTALL` | Package Metadata & Version Alignment | `dumpsys package` reports `versionCode=98` and `versionName=4.73` |
| **T1.04** | `F1_ACQUIRE_INSTALL` | CPU Architecture & ABI Compatibility | STB property `ro.product.cpu.abi` == `armeabi-v7a` |
| **T1.05** | `F2_HOME_INTEGRATION` | Default Home Activity Resolution | `cmd package resolve-activity` resolves to `com.spocky.projengmenu` |
| **T1.06** | `F2_HOME_INTEGRATION` | Accessibility Service Status | `settings get secure enabled_accessibility_services` contains `com.spocky.projengmenu` |
| **T1.07** | `F2_HOME_INTEGRATION` | Reliance Stock Launcher Disablement | `pm list packages -d` contains `com.iwedia.ui.rjio.launcher.reliance` |
| **T1.08** | `F2_HOME_INTEGRATION` | Competing Monet Launcher Disablement | `pm list packages -d` contains `com.klevico.monet` |
| **T1.09** | `F2_HOME_INTEGRATION` | Remote Home Keyevent (3) Interception | Injected `KEYCODE_HOME` brings `com.spocky.projengmenu` to foreground focus |
| **T1.10** | `F3_RAM_OPTIMIZATION` | Memory Footprint within 2GB Budget | `dumpsys meminfo` shows PSS <= 250MB and RSS <= 400MB |
| **T1.11** | `F3_RAM_OPTIMIZATION` | AOT Speed Compilation Status | `dumpsys package` reports compiler status `[status=speed]` |
| **T1.12** | `F4_DYNAMIC_WALLPAPER`| Dynamic Wallpaper Subsystem Status | `dumpsys window windows` confirms active Projectivy window surface |
| **T1.13** | `F5_VISUAL_STYLING`   | Display Resolution & Density Alignment | `wm size` == `1920x1080` and `wm density` == `320` |
| **T1.14** | `F6_ROW_CATEGORIZATION`| OTT Channels App Inventory Presence | Installed: Disney+ Hotstar, Prime Video, Netflix, JioTV+, SonyLIV, ZEE5 |
| **T1.15** | `F6_ROW_CATEGORIZATION`| Media & Tools App Inventory Presence | Installed: SmartTube, Stremio TV, TV Bro, TVFileBox, MATVT, VLC |

---

### Tier 2: Boundary & Corner Cases (Stress & Resilience)
| Test ID | Feature ID | Description | Pass Criteria |
|---|---|---|---|
| **T2.01** | `F7_NAV_AUTOMATION_TEST` | Rapid Directional D-pad Burst Stress | 20 rapid D-pad keyevents in burst; PID remains identical (zero crash/restart) |
| **T2.02** | `F2_HOME_INTEGRATION`   | Rapid Remote Home Key Spam | 6 consecutive `KEYCODE_HOME` events in 500ms; launcher remains foregrounded |
| **T2.03** | `F8_MEMINFO_VERIFICATION`| Memory Headroom Boundary (> 600MB) | `dumpsys meminfo` Free RAM (free + cached) >= 600,000 KB |
| **T2.04** | `F2_HOME_INTEGRATION`   | Monet Intent Hijack Prevention | Resolve activity strictly excludes disabled `com.klevico.monet` |
| **T2.05** | `F3_RAM_OPTIMIZATION`   | Memory Pressure Trim Recovery | `cmd activity trim-memory COMPLETE` handled cleanly without process death |
| **T2.06** | `F5_VISUAL_STYLING`     | Landscape TV Orientation Lock | Display orientation locked to Landscape TV mode (Orientation = 0) |

---

### Tier 3: Cross-Feature Combinations (Pairwise & System Interactions)
| Test ID | Feature ID | Description | Pass Criteria |
|---|---|---|---|
| **T3.01** | `F2+F6+F7` | External App Launch & Home Interception (SmartTube) | Launch SmartTube -> Inject HOME -> Projectivy regains foreground in < 2s |
| **T3.02** | `F2+F6+F7` | Browser App Launch & Home Interception (TV Bro) | Launch TV Bro -> Inject HOME -> Projectivy regains foreground in < 2s |
| **T3.03** | `F6+F7`    | Category D-Pad Navigation & Back Hierarchy | Navigate to categories, press BACK -> UI remains intact without exit |
| **T3.04** | `F3+F8`    | Cross-App Context Switching Memory Stability | Measure PSS before/after app switch; PSS delta < 65,000 KB (no runaway leak) |
| **T3.05** | `F1+F2`    | Accessibility Service Persistence | `ProjectivyAccessibilityService` remains registered and enabled after switching |

---

### Tier 4: Real-World TV Usage Scenarios (Daily Driver Validation)
| Test ID | Feature ID | Description | Pass Criteria |
|---|---|---|---|
| **T4.01** | `F2+F7` | Scenario 1: Cold STB Wakeup & Keyguard Dismissal | Wakeup -> Keyguard dismiss -> HOME -> Projectivy active and ready |
| **T4.02** | `F7`    | Scenario 2: Complete 12-Step TV Remote Navigation Cycle | Traverse DOWN, RIGHT, LEFT, UP, CENTER, BACK without UI hang or crash |
| **T4.03** | `F6+F7` | Scenario 3: Media App Playback Entry & Home Return | Launch VLC/Stremio -> simulate playback navigation -> HOME -> clean return |
| **T4.04** | `F9_SCREENSHOT_CAPTURE` | Scenario 4: Screencap Capture & Binary PNG Validation | Capture screencap, pull to local path, verify PNG magic bytes, 1920x1080 dimensions |
| **T4.05** | `F7+F8` | Scenario 5: Process Stability & Zero Crash/ANR Audit | `logcat -d -b crash` confirms 0 FATAL EXCEPTIONs and zero ANRs |

---

## How to Run the Tests

### 1. Run Complete 4-Tier Test Suite
```powershell
powershell -ExecutionPolicy Bypass -File scripts\run_e2e_tests.ps1
```

### 2. Run Specific Test Tier
```powershell
# Run Tier 1 only (Feature Coverage)
powershell -ExecutionPolicy Bypass -File scripts\run_e2e_tests.ps1 -Tier Tier1

# Run Tier 2 only (Boundary & Corner Cases)
powershell -ExecutionPolicy Bypass -File scripts\run_e2e_tests.ps1 -Tier Tier2

# Run Tier 3 only (Cross-Feature Combinations)
powershell -ExecutionPolicy Bypass -File scripts\run_e2e_tests.ps1 -Tier Tier3

# Run Tier 4 only (Real-World TV Usage Scenarios)
powershell -ExecutionPolicy Bypass -File scripts\run_e2e_tests.ps1 -Tier Tier4
```

### 3. Custom Target Device or Output Directory
```powershell
powershell -ExecutionPolicy Bypass -File scripts\run_e2e_tests.ps1 -Device "192.168.137.28:5555" -OutputDir "c:\Users\SUPRIYA\Desktop\jiostb" -VerboseOutput
```

---

## Verification Artifacts
- **Screenshot Artifact**: `c:\Users\SUPRIYA\Desktop\jiostb\projectivy_homescreen.png`
  - Dimensions: 1920 x 1080
  - Format: PNG (Magic: `89 50 4E 47 0D 0A 1A 0A`)
  - Verification: Confirms visual layout, dynamic wallpaper backdrop, Leanback app cards, and status bar.
