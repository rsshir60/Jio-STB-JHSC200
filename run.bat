@echo off
setlocal EnableDelayedExpansion
title Jio STB JHSC200 / JMSC / JMSB - Operator Console
cd /d "%~dp0"

:MENU
cls
echo ===============================================================================
echo        JIO SET-TOP BOX (JHSC200 / JMSC / JMSB) - 1%% OPERATOR PLAYBOOK
echo ===============================================================================
echo  [1] Check Connected ADB Devices
echo  [2] Connect to STB over Network ADB (Default: 192.168.137.28:5555)
echo  [3] Scan Local Subnets for Active STBs (Port 5555 Probe)
echo  [4] Run Standalone Zero-Dependency JHS ACS + DNS Server (standalone_jhs_server.py)
echo  [5] Run TR-069 Pre-Flight Doctor Check (doctor.py --quick)
echo  [6] Run Surgical Debloat & Performance Optimization (debloat_stb.ps1)
echo  [7] Run Aggressive RAM & Drain Disablement (freeze_worst_apps.ps1)
echo  [8] Deploy Projectivy Launcher v4.73 Modernization Suite
echo  [9] Install Top 1%% Android TV Power Suite (SmartTube, TV Bro, VLC, etc.)
echo  [10] Deploy TVFileBox Auto-Sync Daemon (sync_tvfilebox.sh)
echo  [11] Apply Bluetooth A2DP Audio / Soundbar Fix (bt_fix_aavante.sh)
echo  [12] Run Comprehensive 4-Tier E2E Test Suite (run_e2e_tests.ps1)
echo  [13] Inspect Mobile Hotspot State & Connected Clients (check_hotspot.ps1)
echo  [14] Capture High-Res Screencap to Working Directory
echo  [15] Open Interactive Remote ADB Shell
echo  [16] Rollback Debloat (Restore All Factory System Packages)
echo  [17] Exit
echo ===============================================================================
set /p choice="Select an operational task [1-17]: "

if "%choice%"=="1" (
    echo.
    echo [*] Polling ADB devices...
    adb devices
    echo.
    pause
    goto MENU
)

if "%choice%"=="2" (
    echo.
    set "stbip=192.168.137.28"
    set /p userip="Enter STB IP Address [Enter for 192.168.137.28]: "
    if not "!userip!"=="" set "stbip=!userip!"
    echo [*] Connecting to !stbip!:5555...
    adb connect !stbip!:5555
    echo.
    pause
    goto MENU
)

if "%choice%"=="3" (
    echo.
    echo [*] Launching subnet probe for STB on port 5555...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tests\find_stb.ps1"
    echo.
    pause
    goto MENU
)

if "%choice%"=="4" (
    echo.
    echo [*] Launching Standalone JHS ACS + Selective DNS Server...
    python "%~dp0sideload-jiostb\jhs\standalone_jhs_server.py"
    echo.
    pause
    goto MENU
)

if "%choice%"=="5" (
    echo.
    echo [*] Executing TR-069 Pre-Flight Doctor Check...
    cd /d "%~dp0sideload-jiostb"
    python doctor.py --quick
    cd /d "%~dp0"
    echo.
    pause
    goto MENU
)

if "%choice%"=="6" (
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0debloat_stb.ps1"
    echo.
    pause
    goto MENU
)

if "%choice%"=="7" (
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\freeze_worst_apps.ps1"
    echo.
    pause
    goto MENU
)

if "%choice%"=="8" (
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\configure_projectivy.ps1"
    echo.
    pause
    goto MENU
)

if "%choice%"=="9" (
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install_top_apps.ps1"
    echo.
    pause
    goto MENU
)

if "%choice%"=="10" (
    echo.
    echo [*] Pushing TVFileBox Scoped Storage Sync Daemon to STB...
    adb push "%~dp0scripts\sync_tvfilebox.sh" /data/local/tmp/sync_tvfilebox.sh
    adb shell chmod +x /data/local/tmp/sync_tvfilebox.sh
    echo [*] Starting sync daemon in background...
    adb shell "nohup sh /data/local/tmp/sync_tvfilebox.sh >/dev/null 2>&1 &"
    echo [+] Daemon started. Uploads to TVFileBox will auto-move to /sdcard/Movies.
    echo.
    pause
    goto MENU
)

if "%choice%"=="11" (
    echo.
    echo [*] Applying Bluetooth A2DP Soundbar Fix to STB...
    adb push "%~dp0scripts\bt_fix_aavante.sh" /data/local/tmp/bt_fix_aavante.sh
    adb shell chmod +x /data/local/tmp/bt_fix_aavante.sh
    adb shell sh /data/local/tmp/bt_fix_aavante.sh
    echo.
    pause
    goto MENU
)

if "%choice%"=="12" (
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\run_e2e_tests.ps1"
    echo.
    pause
    goto MENU
)

if "%choice%"=="13" (
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\check_hotspot.ps1"
    echo.
    pause
    goto MENU
)

if "%choice%"=="14" (
    echo.
    echo [*] Grabbing framebuffer screencap from STB...
    adb shell screencap -p /sdcard/stb_screencap.png
    adb pull /sdcard/stb_screencap.png "%~dp0stb_screencap.png"
    adb shell rm /sdcard/stb_screencap.png
    echo [+] Saved to %~dp0stb_screencap.png
    echo.
    pause
    goto MENU
)

if "%choice%"=="15" (
    echo.
    echo [*] Spawning remote interactive shell (Type 'exit' to return)...
    adb shell
    goto MENU
)

if "%choice%"=="16" (
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0rollback_debloat.ps1"
    echo.
    pause
    goto MENU
)

if "%choice%"=="17" (
    exit /b 0
)

goto MENU
