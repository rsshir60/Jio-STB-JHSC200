# debloat_stb.ps1 - Surgical Debloat & Performance Optimization for Jio STB JHSC200 / JMSC200
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
Write-Host " Jio STB Surgical Debloat & Optimization Script" -ForegroundColor Yellow
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

$packagesToDisable = @(
    # Tier 1: Telemetry, Surveillance & Logging Daemons
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

    # Tier 2: Unused Jio Value-Added & Gimmick Bloat
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

    # Tier 3: Ad Engines & Inactivity Trackers
    "com.jio.adc.embedded",
    "com.jio.adc.aka",
    "com.jiostb.inactivitytimer",
    "com.iwedia.notificationservice",

    # Tier 4: Hardware Specific Tunings (DVB-C CATV Tuner)
    "com.jio.stb.catv"
)

Write-Host "`n[*] Step 1: Disabling bloatware packages..." -ForegroundColor Yellow
$disabledCount = 0
foreach ($pkg in $packagesToDisable) {
    $res = adb -s $Target shell "pm disable-user --user 0 $pkg" 2>&1
    if ($res -match "disabled-user" -or $res -match "disabled") {
        Write-Host "  [+] Disabled: $pkg" -ForegroundColor Green
        $disabledCount++
    } else {
        Write-Host "  [-] $pkg : $res" -ForegroundColor Gray
    }
}
Write-Host "[+] Total packages disabled: $disabledCount of $($packagesToDisable.Count)" -ForegroundColor Green

Write-Host "`n[*] Step 2: Applying Animation Scaling (0.5x instant response)..." -ForegroundColor Yellow
adb -s $Target shell "settings put global window_animation_scale 0.5"
adb -s $Target shell "settings put global transition_animation_scale 0.5"
adb -s $Target shell "settings put global animator_duration_scale 0.5"
Write-Host "  [+] UI animations set to 0.5x" -ForegroundColor Green

Write-Host "`n[*] Step 3: Background Process & Cache Tuning..." -ForegroundColor Yellow
adb -s $Target shell "device_config put activity_manager max_cached_processes 24"
adb -s $Target shell "pm trim-caches 999999999999"
Write-Host "  [+] ActivityManager cache bounds & storage cache trimmed" -ForegroundColor Green

Write-Host "`n[*] Step 4: ART Ahead-Of-Time (AOT) Machine Compilation..." -ForegroundColor Yellow
$aotApps = @(
    "com.spocky.projengmenu",
    "com.klevico.monet",
    "in.startv.hotstar",
    "com.amazon.amazonvideo.livingroom",
    "com.netflix.ninja",
    "com.teamsmart.videomanager.tv",
    "org.videolan.vlc"
)
foreach ($app in $aotApps) {
    Write-Host "  [*] Pre-compiling $app to native speed profile..." -ForegroundColor Cyan
    adb -s $Target shell "cmd package compile -m speed -f $app"
}

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host " Debloat & Tuning Complete!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
