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
echo  [4] Run TR-069 Pre-Flight Doctor Check (doctor.py --quick)
echo  [5] Run Surgical Debloat, Telemetry Freeze ^& Performance Tuning
echo  [6] Deploy Projectivy Launcher v4.73 Modernization Suite
echo  [7] Install Top 1%% Android TV Power Suite (SmartTube, TV Bro, VLC, etc.)
echo  [8] Run Comprehensive 4-Tier E2E Test Suite (run_e2e_tests.ps1)
echo  [9] Rollback Debloat (Restore All Factory System Packages)
echo  [10] Capture High-Res Screencap to Working Directory
echo  [11] Open Interactive Remote ADB Shell
echo  [12] Initialize Windows SoftAP / Hotspot (start_hotspot.ps1)
echo  [13] Exit
echo ===============================================================================
set /p choice="Select an operational task [1-13]: "

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
    echo [*] Executing TR-069 Pre-Flight Doctor Check...
    cd /d "%~dp0sideload-jiostb"
    python doctor.py --quick
    cd /d "%~dp0"
    echo.
    pause
    goto MENU
)

if "%choice%"=="5" (
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0debloat_stb.ps1"
    echo.
    pause
    goto MENU
)

if "%choice%"=="6" (
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\configure_projectivy.ps1"
    echo.
    pause
    goto MENU
)

if "%choice%"=="7" (
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install_top_apps.ps1"
    echo.
    pause
    goto MENU
)

if "%choice%"=="8" (
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\run_e2e_tests.ps1"
    echo.
    pause
    goto MENU
)

if "%choice%"=="9" (
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0rollback_debloat.ps1"
    echo.
    pause
    goto MENU
)

if "%choice%"=="10" (
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

if "%choice%"=="11" (
    echo.
    echo [*] Spawning remote interactive shell (Type 'exit' to return)...
    adb shell
    goto MENU
)

if "%choice%"=="12" (
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start_hotspot.ps1"
    echo.
    pause
    goto MENU
)

if "%choice%"=="13" (
    exit /b 0
)

goto MENU
