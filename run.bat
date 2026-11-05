@echo off
setlocal
title Jio STB Toolkit - Management Console
cd /d "%~dp0"

:MENU
cls
echo ==============================================================
echo            JIO STB RECOVERY, DEBLOAT & POWER SUITE
echo ==============================================================
echo [1] Check Connected ADB Devices
echo [2] Connect to STB via Network ADB (IP:5555)
echo [3] Run Surgical Debloat & Performance Optimization
echo [4] Install Top Android TV Power Suite (Apps)
echo [5] Rollback Debloat (Restore Stock Packages)
echo [6] Open ADB Shell
echo [7] Exit
echo ==============================================================
set /p choice="Select an option (1-7): "

if "%choice%"=="1" (
    echo.
    adb devices
    pause
    goto MENU
)
if "%choice%"=="2" (
    echo.
    set /p stbip="Enter STB IP Address: "
    adb connect %stbip%:5555
    pause
    goto MENU
)
if "%choice%"=="3" (
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0debloat_stb.ps1"
    pause
    goto MENU
)
if "%choice%"=="4" (
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install_top_apps.ps1"
    pause
    goto MENU
)
if "%choice%"=="5" (
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0rollback_debloat.ps1"
    pause
    goto MENU
)
if "%choice%"=="6" (
    echo.
    adb shell
    goto MENU
)
if "%choice%"=="7" (
    exit /b 0
)

goto MENU
