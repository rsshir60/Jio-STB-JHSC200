# install_top_apps.ps1 - Automated Downloader and Installer for Top Android TV Suite
param(
    [string]$Target = ""
)

$ErrorActionPreference = "Continue"

# Auto-detect target if not specified
if (-not $Target) {
    $devices = adb devices | Where-Object { $_ -match "\s+device$" } | ForEach-Object { ($_ -split "\s+")[0] }
    if ($devices.Count -eq 1) {
        $Target = $devices[0]
        Write-Host "[*] Auto-detected active target: $Target" -ForegroundColor Cyan
    } elseif ($devices.Count -gt 1) {
        $Target = $devices[0]
        Write-Host "[*] Multiple devices detected. Using first device: $Target" -ForegroundColor Cyan
    } else {
        $Target = Read-Host "Enter STB IP and port (e.g., 192.168.1.50:5555)"
    }
}

if (-not $Target) {
    Write-Host "[ERROR] No valid target specified." -ForegroundColor Red
    exit 1
}

$appsDir = Join-Path $PSScriptRoot "top_apps"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Android TV Power Suite Installation" -ForegroundColor Yellow
Write-Host " Target Device: $Target" -ForegroundColor Cyan
Write-Host " Repository Path: $appsDir" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Verify ADB connection
$adbState = adb -s $Target get-state 2>&1
if ($adbState -notmatch "device") {
    Write-Host "[ERROR] STB not reachable at $Target ($adbState)" -ForegroundColor Red
    exit 1
}

# 2. Create apps directory
if (!(Test-Path $appsDir)) {
    New-Item -ItemType Directory -Path $appsDir -Force | Out-Null
}

$apps = @(
    @{
        Name = "SmartTube Stable"
        File = "$appsDir\SmartTube_stable_armeabi-v7a.apk"
        Url  = "https://github.com/yuliskov/SmartTube/releases/download/32.68s/SmartTube_stable_32.68_armeabi-v7a.apk"
        Pkg  = "com.teamsmart.videomanager.tv"
    },
    @{
        Name = "TV Bro Web Browser"
        File = "$appsDir\tvbro_armeabi-v7a.apk"
        Url  = "https://github.com/truefedex/tv-bro/releases/download/v2.1.6/tvbro-2.1.6-generic-geckoIncluded-armeabi-v7a.apk"
        Pkg  = "com.phlox.tvwebbrowser"
    },
    @{
        Name = "VLC Media Player"
        File = "$appsDir\VLC-Android-armeabi-v7a.apk"
        Url  = "https://downloads.videolan.org/pub/videolan/vlc-android/last/VLC-Android-3.7.1-armeabi-v7a.apk"
        Pkg  = "org.videolan.vlc"
    },
    @{
        Name = "Kodi 21 Omega"
        File = "$appsDir\kodi-Omega-armeabi-v7a.apk"
        Url  = "https://mirrors.kodi.tv/releases/android/arm/kodi-21.2-Omega-armeabi-v7a.apk"
        Pkg  = "org.xbmc.kodi"
    },
    @{
        Name = "Stremio TV"
        File = "$appsDir\stremio-tv-armeabi-v7a.apk"
        Url  = "https://dl.strem.io/android/v1.10.4-androidTV/com.stremio.one-1.10.4-31048580-armeabi-v7a.apk"
        Pkg  = "com.stremio.one"
    },
    @{
        Name = "MATVT Virtual Mouse"
        File = "$appsDir\matvt-release.apk"
        Url  = "https://github.com/virresh/matvt/releases/download/v1.0.6/matvt-app-release-v1.0.6.apk"
        Pkg  = "com.virresh.matvt"
    },
    @{
        Name = "TVFileBox"
        File = "$appsDir\TVFileBox-armeabi-v7a.apk"
        Url  = "https://github.com/w1lli4m666-droid/TVFileBox/releases/download/v1.2.5/TVFileBox-v1.2.5-armeabi-v7a.apk"
        Pkg  = "com.willi4m.tvfilebox"
    }
)

Write-Host ""
Write-Host "[*] Step 1: Downloading and Installing Applications..." -ForegroundColor Yellow

$installed = 0
foreach ($app in $apps) {
    Write-Host ""
    Write-Host "----------------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host "[>] Processing: $($app.Name)" -ForegroundColor Cyan
    
    $needDownload = $true
    if (Test-Path $app.File) {
        $size = (Get-Item $app.File).Length
        if ($size -gt 100000) {
            $mb = [math]::Round($size / 1MB, 2)
            Write-Host "  [*] Using existing cached binary: $mb MB" -ForegroundColor Gray
            $needDownload = $false
        }
    }
    
    if ($needDownload) {
        Write-Host "  [*] Downloading from: $($app.Url)" -ForegroundColor Gray
        curl.exe -L -s -S --connect-timeout 20 --max-time 300 -o $app.File $app.Url
        if (!(Test-Path $app.File) -or (Get-Item $app.File).Length -lt 100000) {
            Write-Host "  [!] Download failed or file corrupted for $($app.Name)" -ForegroundColor Red
            continue
        }
        $dlSize = (Get-Item $app.File).Length
        $dlMb = [math]::Round($dlSize / 1MB, 2)
        Write-Host "  [+] Downloaded successfully: $dlMb MB" -ForegroundColor Green
    }

    Write-Host "  [*] Installing via ADB to STB..." -ForegroundColor Yellow
    $installRes = adb -s $Target install -r $app.File 2>&1
    if ($installRes -match "Success") {
        Write-Host "  [+] Installation Successful: $($app.Name)" -ForegroundColor Green
        $installed++
    } else {
        Write-Host "  [!] Installation failed: $installRes" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host " Installation Finished: $installed of $($apps.Count) apps installed." -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
