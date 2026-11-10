# scripts/freeze_worst_apps.ps1 - Aggressive RAM/Battery Drain Debloat Suite for Jio STB
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
Write-Host " Jio STB Aggressive RAM & Drain Disablement Suite" -ForegroundColor Yellow
Write-Host " Target Device: $Target" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# Test ADB connectivity
$adbCheck = adb -s $Target get-state 2>&1
if ($adbCheck -notmatch "device") {
    Write-Host "[*] Target not ready ($adbCheck). Attempting to connect..." -ForegroundColor Yellow
    adb connect $Target | Out-Null
    Start-Sleep -Seconds 2
    $adbCheck = adb -s $Target get-state 2>&1
    if ($adbCheck -notmatch "device") {
        Write-Host "[ERROR] STB not reachable at $Target ($adbCheck)" -ForegroundColor Red
        exit 1
    }
}

$pkgs = @(
    "com.jio.controlcentre",
    "com.android.app.jio.voiceassist",
    "com.rjl.mobileremote.receiver",
    "com.jio.jiopay",
    "com.reverie.swalekh.abctv",
    "com.jio.yt",
    "com.android.printspooler",
    "com.android.bips",
    "com.android.printservice.recommendation",
    "com.svox.pico",
    "com.android.dreams.basic",
    "com.android.companiondevicemanager",
    "com.android.wallpaperbackup",
    "com.android.sharedstoragebackup"
)

$frozenCount = 0
foreach ($p in $pkgs) {
    $out = adb -s $Target shell "pm disable-user --user 0 $p" 2>&1
    if ($out -match "disabled-user" -or $out -match "disabled") {
        Write-Host "  [+] Disabled: $p" -ForegroundColor Green
        $frozenCount++
    } else {
        Write-Host "  [-] $p : $out" -ForegroundColor Gray
    }
}

Write-Host "`n[+] Completed: $frozenCount of $($pkgs.Count) aggressive packages frozen." -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
