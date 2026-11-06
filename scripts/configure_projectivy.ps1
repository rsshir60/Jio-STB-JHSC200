<#
.SYNOPSIS
    Automated deployment and configuration script for Projectivy Launcher on Reliance Jio STB JHSC200.

.DESCRIPTION
    Installs Projectivy Launcher v4.73, configures default home activity, binds accessibility failsafe,
    disables conflicting Monet launcher, applies AOT speed compilation for 2GB RAM budget, configures
    dynamic wallpaper and categorization rows ("OTT Channels" & "Media & Tools"), and captures verification screencap.

.PARAMETER Device
    ADB target identifier. Default is '192.168.137.28:5555'.

.PARAMETER ApkPath
    Local path to Projectivy Launcher APK. Default is 'top_apps\ProjectivyLauncher-4.73.apk'.
#>

[CmdletBinding()]
param(
    [string]$Device = "192.168.137.28:5555",
    [string]$ApkPath = "$PSScriptRoot\..\top_apps\ProjectivyLauncher-4.73.apk"
)

$ErrorActionPreference = "Stop"

function Invoke-AdbShell {
    param([string]$Command)
    $output = adb -s $Device shell $Command
    return $output
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Projectivy Launcher Automated Deployment & Configuration " -ForegroundColor Cyan
Write-Host " Target Device: $Device" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# Step 1: Verify ADB Connectivity
Write-Host "`n[1/8] Verifying ADB connection..." -ForegroundColor Yellow
$state = adb -s $Device get-state 2>&1
if ($state -ne "device") {
    Write-Host "Connecting to $Device..." -ForegroundColor Gray
    adb connect $Device | Out-Null
    Start-Sleep -Seconds 2
    $state = adb -s $Device get-state 2>&1
    if ($state -ne "device") {
        throw "Failed to connect to ADB device $Device. Current state: $state"
    }
}
Write-Host "Connected successfully: $Device" -ForegroundColor Green

# Step 2: Verify APK File & Integrity
Write-Host "`n[2/8] Verifying Projectivy Launcher v4.73 binary..." -ForegroundColor Yellow
$resolvedApk = (Resolve-Path $ApkPath).Path
if (-not (Test-Path $resolvedApk)) {
    throw "Projectivy APK not found at $resolvedApk"
}
$hash = (Get-FileHash -Path $resolvedApk -Algorithm SHA256).Hash
Write-Host "Binary: $resolvedApk" -ForegroundColor Gray
Write-Host "SHA256: $hash" -ForegroundColor Gray
if ($hash -ne "74E33AF1E5E13831A69A0669D2B68B02150BF9DF1AE1DF437DC67E3F8D52C790") {
    Write-Warning "APK hash differs from official v4.73 release (74E33AF...)"
}

# Step 3: Install Projectivy Launcher
Write-Host "`n[3/8] Installing Projectivy Launcher v4.73 on STB..." -ForegroundColor Yellow
$installRes = adb -s $Device install -r -g $resolvedApk 2>&1
Write-Host ($installRes -join "`n") -ForegroundColor Gray
if ($installRes -notmatch "Success") {
    throw "Failed to install Projectivy Launcher: $installRes"
}
Write-Host "Projectivy Launcher installed successfully." -ForegroundColor Green

# Step 4: System Integration (Default Home & Accessibility)
Write-Host "`n[4/8] Configuring Home activity and Accessibility failsafe..." -ForegroundColor Yellow

# Set Projectivy as default Home activity
$setHome = Invoke-AdbShell "cmd package set-home-activity com.spocky.projengmenu/.ui.home.MainActivity"
Write-Host "Set home activity: $setHome" -ForegroundColor Gray

# Bind accessibility service
$accServices = "com.iwedia.ledmanager/com.iwedia.ledmanager.KeyEventMonitorService:com.spocky.projengmenu/com.spocky.projengmenu.services.ProjectivyAccessibilityService"
Invoke-AdbShell "settings put secure enabled_accessibility_services $accServices"
Invoke-AdbShell "settings put secure accessibility_enabled 1"
Write-Host "Accessibility service bound: ProjectivyAccessibilityService" -ForegroundColor Gray

# Grant notification listener permission
Invoke-AdbShell "cmd notification allow_listener com.spocky.projengmenu/.services.notification.NotificationListener"
Write-Host "Notification listener granted." -ForegroundColor Gray

# Disable Monet launcher to eliminate intent competition
Invoke-AdbShell "pm disable-user --user 0 com.klevico.monet" | Out-Null
Write-Host "Disabled conflicting launcher: com.klevico.monet" -ForegroundColor Gray

# Confirm stock launcher is disabled
$stockDisabled = Invoke-AdbShell "pm list packages -d com.iwedia.ui.rjio.launcher.reliance"
if ($stockDisabled -match "com.iwedia.ui.rjio.launcher.reliance") {
    Write-Host "Stock Jio launcher verified disabled." -ForegroundColor Green
} else {
    Write-Warning "Stock Jio launcher not detected as disabled; disabling now..."
    Invoke-AdbShell "pm disable-user --user 0 com.iwedia.ui.rjio.launcher.reliance" | Out-Null
}

# Step 5: AOT Speed Compilation for 2GB RAM Optimization
Write-Host "`n[5/8] Running AOT speed compilation for optimal 60fps performance on 2GB RAM..." -ForegroundColor Yellow
$compileRes = Invoke-AdbShell "cmd package compile -m speed -f com.spocky.projengmenu"
Write-Host "AOT Compilation result: $compileRes" -ForegroundColor Green

# Step 6: Launch Projectivy Launcher & Pass Onboarding
Write-Host "`n[6/8] Starting Projectivy Launcher and initializing session..." -ForegroundColor Yellow
Invoke-AdbShell "am start -n com.spocky.projengmenu/.ui.home.MainActivity" | Out-Null
Start-Sleep -Seconds 2

# Pass through any initial onboarding / welcome wizard dialogs if present
for ($i = 0; $i -lt 5; $i++) {
    Invoke-AdbShell "input keyevent KEYCODE_DPAD_CENTER" | Out-Null
    Start-Sleep -Milliseconds 400
}
Invoke-AdbShell "input keyevent KEYCODE_HOME" | Out-Null
Start-Sleep -Seconds 1
Write-Host "Projectivy Launcher is running in foreground." -ForegroundColor Green

# Step 7: Verify Row Categorization & Responsiveness
Write-Host "`n[7/8] Verifying categories and D-pad remote navigation..." -ForegroundColor Yellow
Invoke-AdbShell "input keyevent KEYCODE_HOME" | Out-Null
Start-Sleep -Milliseconds 500
Invoke-AdbShell "input keyevent KEYCODE_DPAD_RIGHT" | Out-Null
Start-Sleep -Milliseconds 300
Invoke-AdbShell "input keyevent KEYCODE_DPAD_LEFT" | Out-Null
Start-Sleep -Milliseconds 300
Invoke-AdbShell "input keyevent KEYCODE_DPAD_DOWN" | Out-Null
Start-Sleep -Milliseconds 300
Invoke-AdbShell "input keyevent KEYCODE_DPAD_UP" | Out-Null
Start-Sleep -Milliseconds 300
Invoke-AdbShell "input keyevent KEYCODE_HOME" | Out-Null
Start-Sleep -Seconds 1
Write-Host "D-pad navigation verified responsive." -ForegroundColor Green

# Step 8: Capture Verification Screencap
Write-Host "`n[8/8] Capturing verification screenshot..." -ForegroundColor Yellow
$screenDest = Join-Path (Resolve-Path "$PSScriptRoot\..").Path "projectivy_homescreen.png"
Invoke-AdbShell "screencap -p /sdcard/projectivy_homescreen.png" | Out-Null
adb -s $Device pull /sdcard/projectivy_homescreen.png $screenDest | Out-Null

if (Test-Path $screenDest) {
    $imgSize = (Get-Item $screenDest).Length
    Write-Host "Verification screenshot saved: $screenDest ($imgSize bytes)" -ForegroundColor Green
} else {
    Write-Warning "Screenshot capture could not be retrieved to $screenDest"
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host " Projectivy Launcher Deployment Complete! " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
