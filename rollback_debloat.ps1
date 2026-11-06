# rollback_debloat.ps1 - Instant Restoration of All Debloated Packages on Jio STB JHSC200 / JMSC200
param(
    [string]$Target = ""
)

$ErrorActionPreference = "Continue"

if (-not $Target) {
    if ($env:STB_TARGET) {
        $Target = $env:STB_TARGET
    } else {
        $devices = adb devices | Where-Object { $_ -match "\s+device$" } | ForEach-Object { ($_ -split "\s+")[0] }
        if ($devices.Count -ge 1) {
            $Target = $devices[0]
            Write-Host "[*] Auto-detected active target: $Target" -ForegroundColor Cyan
        } else {
            $Target = "192.168.137.28:5555"
            Write-Host "[*] Defaulting target to: $Target" -ForegroundColor Cyan
        }
    }
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Jio STB Debloat Rollback Script" -ForegroundColor Yellow
Write-Host " Target: $Target" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# Test ADB connectivity
$adbCheck = adb -s $Target get-state 2>&1
if ($adbCheck -notmatch "device") {
    Write-Host "[*] Target not in ready state ($adbCheck). Attempting connection..." -ForegroundColor Yellow
    adb connect $Target | Out-Null
    Start-Sleep -Seconds 2
    $adbCheck = adb -s $Target get-state 2>&1
    if ($adbCheck -notmatch "device") {
        Write-Host "[ERROR] ADB device not responding at $Target. Output: $adbCheck" -ForegroundColor Red
        exit 1
    }
}

$packagesToEnable = @(
    "com.rjil.podlogservice",
    "com.rjil.jiostblogservice",
    "com.teamviewer.quicksupport.addon.jio",
    "com.communitake.remotecontrolservice",
    "com.iwedia.usbbenchmarkservice",
    "com.jio.stb.remotediagnose",
    "com.jio.systemstats",
    "com.inn.nvengineer",
    "com.jio.jiobackgroundscheduler",
    "com.jio.smartmemorymanager",
    "com.jio.appoptimizer",
    "com.jio.jiocall",
    "com.jio.media.jionewsstb",
    "com.jio.media.jiobeats",
    "com.jio.mymusic.app",
    "com.jiostb.jiogames",
    "com.aksys.jiogamepad",
    "com.jio.screensaver",
    "com.jio.bioscopecontentservice",
    "com.jio.myhome.mediasharedmp",
    "com.jio.jiocloudpc",
    "com.jio.product.exploremyremote",
    "com.jio.universalsetup",
    "com.jiostb.fti",
    "com.omni.simplesetup",
    "com.omni.sci",
    "com.jio.stb.bot",
    "com.jio.stbwidget",
    "com.jio.store",
    "com.jio.adc.embedded",
    "com.jio.adc.aka",
    "com.jiostb.inactivitytimer",
    "com.iwedia.notificationservice",
    "com.jio.stb.catv"
)

Write-Host "`n[*] Restoring all debloated packages..." -ForegroundColor Yellow
$restoredCount = 0
foreach ($pkg in $packagesToEnable) {
    $res = adb -s $Target shell "pm enable $pkg" 2>&1
    if ($res -match "enabled" -or $res -match "new state: enabled") {
        Write-Host "  [+] Enabled: $pkg" -ForegroundColor Green
        $restoredCount++
    } else {
        Write-Host "  [-] $pkg : $res" -ForegroundColor Gray
    }
}
Write-Host "[+] Total packages restored: $restoredCount of $($packagesToEnable.Count)" -ForegroundColor Green

Write-Host "`n[*] Resetting animation scales to default 1.0x..." -ForegroundColor Yellow
adb -s $Target shell "settings put global window_animation_scale 1.0"
adb -s $Target shell "settings put global transition_animation_scale 1.0"
adb -s $Target shell "settings put global animator_duration_scale 1.0"
Write-Host "  [+] UI animations reset to 1.0x" -ForegroundColor Green

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host " Rollback Complete! STB restored to factory package states." -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
