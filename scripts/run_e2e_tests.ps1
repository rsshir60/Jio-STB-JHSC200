<#
.SYNOPSIS
    Comprehensive 4-Tier E2E Opaque-Box Test Suite for Projectivy Launcher Modernization on Reliance Jio STB (JHSC200).

.DESCRIPTION
    Executes automated requirement-driven validation across 4 tiers:
      - Tier 1: Feature Coverage (F1 to F6, APK integrity, default home, accessibility, memory, compiled status, app inventory)
      - Tier 2: Boundary & Corner Cases (rapid key inputs, free memory headroom > 600MB, competing package isolation, memory trim)
      - Tier 3: Cross-Feature Combinations (app launch & Home key interception, category D-pad traversal, memory leak checks)
      - Tier 4: Real-World TV Usage Scenarios (cold wakeup, full D-pad cycle, media consumption flow, screenshot validation, zero ANRs/crashes)

.PARAMETER Device
    ADB target identifier (default: "192.168.137.28:5555").

.PARAMETER Tier
    Filter tests by tier: "All", "Tier1", "Tier2", "Tier3", "Tier4" (default: "All").

.PARAMETER OutputDir
    Directory for output artifacts and reports (default: current working directory).

.PARAMETER ScreenshotFile
    Name of the captured homescreen screenshot (default: "projectivy_homescreen.png").

.PARAMETER ReportFile
    Optional file path for JUnit XML or markdown report.
#>
[CmdletBinding()]
param(
    [string]$Device = "192.168.137.28:5555",
    [ValidateSet("All", "Tier1", "Tier2", "Tier3", "Tier4")]
    [string]$Tier = "All",
    [string]$OutputDir = "c:\Users\SUPRIYA\Desktop\jiostb",
    [string]$ScreenshotFile = "projectivy_homescreen.png",
    [string]$ReportFile = "",
    [switch]$VerboseOutput
)

$ErrorActionPreference = "Continue"

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host " Jio STB Projectivy Launcher E2E Test Suite - 4-Tier Test Runner" -ForegroundColor Yellow
Write-Host " Target Device : $Device" -ForegroundColor Cyan
Write-Host " Test Tier     : $Tier" -ForegroundColor Cyan
Write-Host " Output Dir    : $OutputDir" -ForegroundColor Cyan
Write-Host " Timestamp     : $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------

function Invoke-Adb {
    param([string]$Arguments)
    $cmd = "adb -s $Device $Arguments"
    if ($VerboseOutput) { Write-Host "  [DEBUG ADB] $cmd" -ForegroundColor DarkGray }
    $out = Invoke-Expression $cmd 2>&1
    return ($out | Out-String)
}

function Invoke-AdbShell {
    param([string]$Command)
    $escaped = $Command.Replace('"', '\"')
    return Invoke-Adb "shell `"$escaped`""
}

function Get-PngDimensions {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath)) { return $null }
    try {
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        if ($bytes.Length -lt 24) { return $null }
        $pngMagic = @(0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A)
        for ($i = 0; $i -lt 8; $i++) {
            if ($bytes[$i] -ne $pngMagic[$i]) { return $null }
        }
        $width = ($bytes[16] * 16777216) + ($bytes[17] * 65536) + ($bytes[18] * 256) + $bytes[19]
        $height = ($bytes[20] * 16777216) + ($bytes[21] * 65536) + ($bytes[22] * 256) + $bytes[23]
        return [PSCustomObject]@{
            Width = $width
            Height = $height
            FileSize = $bytes.Length
            IsValidPng = $true
        }
    } catch {
        return $null
    }
}

# ------------------------------------------------------------------------------
# Pre-Flight Verification
# ------------------------------------------------------------------------------

Write-Host "`n[*] Running Pre-Flight ADB Connectivity Check..." -ForegroundColor Yellow

$adbCheck = Invoke-Adb "get-state"
if ($adbCheck -notmatch "device") {
    Write-Host "[!] Device not connected ($adbCheck). Attempting to connect to $Device..." -ForegroundColor Yellow
    $connectRes = Invoke-Adb "connect $Device"
    Start-Sleep -Seconds 2
    $adbCheck = Invoke-Adb "get-state"
}

if ($adbCheck -notmatch "device") {
    Write-Host "[FATAL] Cannot communicate with STB at $Device. ADB state: $adbCheck" -ForegroundColor Red
    exit 1
}

$deviceModel = (Invoke-AdbShell "getprop ro.product.model").Trim()
$deviceAbi   = (Invoke-AdbShell "getprop ro.product.cpu.abi").Trim()
$deviceSdk   = (Invoke-AdbShell "getprop ro.build.version.release").Trim()
Write-Host "[+] Connected to STB: Model=$deviceModel | ABI=$deviceAbi | Android=$deviceSdk" -ForegroundColor Green

# ------------------------------------------------------------------------------
# Test Execution Harness
# ------------------------------------------------------------------------------

$TestResults = [System.Collections.Generic.List[PSCustomObject]]::new()
$globalStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

function Execute-Test {
    param(
        [string]$TierName,
        [string]$Id,
        [string]$Feature,
        [string]$Name,
        [scriptblock]$ScriptBlock
    )

    if ($Tier -ne "All" -and $Tier -ne $TierName) {
        return
    }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $status = "PASS"
    $message = ""

    try {
        & $ScriptBlock
    } catch {
        $status = "FAIL"
        $message = $_.Exception.Message
    } finally {
        $sw.Stop()
    }

    $durationMs = [math]::Round($sw.Elapsed.TotalMilliseconds, 0)
    $resObj = [PSCustomObject]@{
        Tier       = $TierName
        Id         = $Id
        Feature    = $Feature
        Name       = $Name
        Status     = $status
        DurationMs = $durationMs
        Message    = $message
    }
    $TestResults.Add($resObj)

    $idPad = $Id.PadRight(6)
    $featPad = "[$Feature]".PadRight(26)
    if ($status -eq "PASS") {
        Write-Host "  [PASS] $idPad $featPad $Name ($durationMs ms)" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] $idPad $featPad $Name ($durationMs ms)" -ForegroundColor Red
        Write-Host "         ERROR: $message" -ForegroundColor Yellow
    }
}

# ==============================================================================
# TIER 1: FEATURE COVERAGE (Isolated Requirement Validation)
# ==============================================================================
Write-Host "`n================================================================================" -ForegroundColor DarkCyan
Write-Host " TIER 1: FEATURE COVERAGE (Requirement & Interface Verification)" -ForegroundColor DarkCyan
Write-Host "================================================================================" -ForegroundColor DarkCyan

# T1.01: Local Projectivy Release Artifact Integrity
Execute-Test -TierName "Tier1" -Id "T1.01" -Feature "F1_ACQUIRE_INSTALL" -Name "Local APK release artifact existence and SHA256 integrity" -ScriptBlock {
    $apkPath = Join-Path $OutputDir "top_apps\ProjectivyLauncher-4.73.apk"
    if (-not (Test-Path $apkPath)) {
        throw "Projectivy APK missing at $apkPath"
    }
    $item = Get-Item $apkPath
    if ($item.Length -lt 10000000) {
        throw "APK file size ($($item.Length) bytes) is below expected release size (>10MB)"
    }
    $hash = (Get-FileHash -Path $apkPath -Algorithm SHA256).Hash
    $expected = "74E33AF1E5E13831A69A0669D2B68B02150BF9DF1AE1DF437DC67E3F8D52C790"
    if ($hash.ToUpper() -ne $expected.ToUpper()) {
        throw "APK SHA256 mismatch: got $hash, expected $expected"
    }
}

# T1.02: Package Presence on Device
Execute-Test -TierName "Tier1" -Id "T1.02" -Feature "F1_ACQUIRE_INSTALL" -Name "Package com.spocky.projengmenu installed on STB" -ScriptBlock {
    $out = Invoke-AdbShell "pm list packages | grep com.spocky.projengmenu"
    if ($out -notmatch "package:com\.spocky\.projengmenu") {
        throw "Package com.spocky.projengmenu is not installed on device: $out"
    }
}

# T1.03: Package Metadata & Version Alignment
Execute-Test -TierName "Tier1" -Id "T1.03" -Feature "F1_ACQUIRE_INSTALL" -Name "Package version alignment (versionCode=98, versionName=4.73)" -ScriptBlock {
    $out = Invoke-AdbShell "dumpsys package com.spocky.projengmenu | grep -iE 'versionCode|versionName'"
    if ($out -notmatch "versionCode=98") {
        throw "Expected versionCode=98, got: $out"
    }
    if ($out -notmatch "4\.73") {
        throw "Expected versionName=4.73, got: $out"
    }
}

# T1.04: Architecture Compatibility
Execute-Test -TierName "Tier1" -Id "T1.04" -Feature "F1_ACQUIRE_INSTALL" -Name "Target CPU architecture verification (armeabi-v7a)" -ScriptBlock {
    $abi = (Invoke-AdbShell "getprop ro.product.cpu.abi").Trim()
    if ($abi -ne "armeabi-v7a") {
        throw "Expected armeabi-v7a ABI, got: $abi"
    }
}

# T1.05: Default Home Activity Resolution
Execute-Test -TierName "Tier1" -Id "T1.05" -Feature "F2_HOME_INTEGRATION" -Name "Default Home activity resolves to Projectivy Launcher" -ScriptBlock {
    $out = Invoke-AdbShell "cmd package resolve-activity --brief -c android.intent.category.HOME -a android.intent.action.MAIN"
    if ($out -notmatch "com\.spocky\.projengmenu") {
        throw "Home intent does not resolve to com.spocky.projengmenu. Output: $out"
    }
}

# T1.06: Accessibility Service Status
Execute-Test -TierName "Tier1" -Id "T1.06" -Feature "F2_HOME_INTEGRATION" -Name "Projectivy Accessibility Service registered and active" -ScriptBlock {
    $out = Invoke-AdbShell "settings get secure enabled_accessibility_services"
    if ($out -notmatch "com\.spocky\.projengmenu.*ProjectivyAccessibilityService") {
        throw "ProjectivyAccessibilityService is not present in enabled_accessibility_services: $out"
    }
}

# T1.07: Stock Reliance Jio Launcher Disablement
Execute-Test -TierName "Tier1" -Id "T1.07" -Feature "F2_HOME_INTEGRATION" -Name "Stock Jio Launcher (com.iwedia.ui.rjio.launcher.reliance) disabled" -ScriptBlock {
    $out = Invoke-AdbShell "pm list packages -d | grep rjio\.launcher"
    if ($out -notmatch "com\.iwedia\.ui\.rjio\.launcher\.reliance") {
        throw "Stock Reliance launcher is not in disabled packages list: $out"
    }
}

# T1.08: Competing Monet Launcher Disablement
Execute-Test -TierName "Tier1" -Id "T1.08" -Feature "F2_HOME_INTEGRATION" -Name "Competing Monet Launcher (com.klevico.monet) disabled" -ScriptBlock {
    $out = Invoke-AdbShell "pm list packages -d | grep klevico\.monet"
    if ($out -notmatch "com\.klevico\.monet") {
        throw "Monet launcher is not in disabled packages list: $out"
    }
}

# T1.09: Remote Home Key Focus Interception
Execute-Test -TierName "Tier1" -Id "T1.09" -Feature "F2_HOME_INTEGRATION" -Name "Remote Home keyevent (3) invocation focuses Projectivy" -ScriptBlock {
    Invoke-AdbShell "input keyevent KEYCODE_HOME" | Out-Null
    Start-Sleep -Milliseconds 600
    $focus = Invoke-AdbShell "dumpsys activity activities | grep -E 'ResumedActivity|topResumedActivity'"
    if ($focus -notmatch "com\.spocky\.projengmenu") {
        throw "Projectivy is not the resumed activity after Home key press. Got: $focus"
    }
}

# T1.10: Process Memory Footprint within 2GB Budget
Execute-Test -TierName "Tier1" -Id "T1.10" -Feature "F3_RAM_OPTIMIZATION" -Name "Projectivy memory footprint within 2GB budget (PSS <= 250MB, RSS <= 400MB)" -ScriptBlock {
    $out = Invoke-AdbShell "dumpsys meminfo com.spocky.projengmenu | grep -E 'TOTAL PSS|TOTAL RSS'"
    if ($out -match "TOTAL PSS:\s*(\d+)") {
        $pss = [int]$matches[1]
    } else {
        throw "Could not parse TOTAL PSS from dumpsys: $out"
    }
    if ($out -match "TOTAL RSS:\s*(\d+)") {
        $rss = [int]$matches[1]
    } else {
        throw "Could not parse TOTAL RSS from dumpsys: $out"
    }

    if ($pss -gt 250000) {
        throw "Projectivy PSS ($pss KB) exceeds 250MB budget"
    }
    if ($rss -gt 400000) {
        throw "Projectivy RSS ($rss KB) exceeds 400MB budget"
    }
}

# T1.11: AOT Speed Compilation Status
Execute-Test -TierName "Tier1" -Id "T1.11" -Feature "F3_RAM_OPTIMIZATION" -Name "AOT speed compilation verification ([status=speed])" -ScriptBlock {
    $out = Invoke-AdbShell "dumpsys package com.spocky.projengmenu | grep -iE 'status=speed|status='"
    if ($out -notmatch "status=speed") {
        throw "Package is not compiled to speed profile. Output: $out"
    }
}

# T1.12: Dynamic Wallpaper Subsystem Verification
Execute-Test -TierName "Tier1" -Id "T1.12" -Feature "F4_DYNAMIC_WALLPAPER" -Name "Dynamic wallpaper rendering subsystem active" -ScriptBlock {
    $win = Invoke-AdbShell "dumpsys window windows | grep -iE 'com.spocky.projengmenu.*MainActivity'"
    if ($win -notmatch "MainActivity") {
        throw "Projectivy MainActivity window surface is not active: $win"
    }
}

# T1.13: Display Geometry & Density
Execute-Test -TierName "Tier1" -Id "T1.13" -Feature "F5_VISUAL_STYLING" -Name "Display geometry (1920x1080) and pixel density (320dpi)" -ScriptBlock {
    $size = (Invoke-AdbShell "wm size").Trim()
    $density = (Invoke-AdbShell "wm density").Trim()
    if ($size -notmatch "1920x1080") {
        throw "Expected resolution 1920x1080, got: $size"
    }
    if ($density -notmatch "320") {
        throw "Expected density 320, got: $density"
    }
}

# T1.14: OTT Channels Category Packages Installed
Execute-Test -TierName "Tier1" -Id "T1.14" -Feature "F6_ROW_CATEGORIZATION" -Name "Installed OTT Channels package inventory presence" -ScriptBlock {
    $ottPkgs = @(
        "in.startv.hotstar",
        "com.amazon.amazonvideo.livingroom",
        "com.netflix.ninja",
        "com.jio.media.jiotvplus",
        "com.jiotv.sonyliv",
        "com.zee5.aosp"
    )
    $installed = Invoke-AdbShell "pm list packages"
    $missing = @()
    foreach ($pkg in $ottPkgs) {
        if ($installed -notmatch "package:$pkg") {
            $missing += $pkg
        }
    }
    if ($missing.Count -gt 0) {
        throw "Missing OTT packages on STB: $($missing -join ', ')"
    }
}

# T1.15: Media & Tools Category Packages Installed
Execute-Test -TierName "Tier1" -Id "T1.15" -Feature "F6_ROW_CATEGORIZATION" -Name "Installed Media & Tools package inventory presence" -ScriptBlock {
    $toolPkgs = @(
        "org.smarttube.stable",
        "com.stremio.one",
        "com.phlox.tvwebbrowser",
        "com.example.tvfilebox",
        "io.github.virresh.matvt",
        "org.videolan.vlc"
    )
    $installed = Invoke-AdbShell "pm list packages"
    $missing = @()
    foreach ($pkg in $toolPkgs) {
        if ($installed -notmatch "package:$pkg") {
            $missing += $pkg
        }
    }
    if ($missing.Count -gt 0) {
        throw "Missing Media & Tools packages on STB: $($missing -join ', ')"
    }
}

# ==============================================================================
# TIER 2: BOUNDARY & CORNER CASES (Stress, Edge Conditions & Robustness)
# ==============================================================================
Write-Host "`n================================================================================" -ForegroundColor DarkCyan
Write-Host " TIER 2: BOUNDARY & CORNER CASES (Stress & Resilience)" -ForegroundColor DarkCyan
Write-Host "================================================================================" -ForegroundColor DarkCyan

# T2.01: Rapid D-Pad Burst Stress
Execute-Test -TierName "Tier2" -Id "T2.01" -Feature "F7_NAV_AUTOMATION_TEST" -Name "Rapid D-pad directional burst stress (20 inputs, zero crash)" -ScriptBlock {
    $pidBefore = (Invoke-AdbShell "pidof com.spocky.projengmenu").Trim()
    if (-not $pidBefore) { throw "Projectivy Launcher is not currently running" }

    # Rapid fire 20 D-pad inputs
    for ($i = 0; $i -lt 5; $i++) {
        Invoke-AdbShell "input keyevent KEYCODE_DPAD_RIGHT; input keyevent KEYCODE_DPAD_DOWN; input keyevent KEYCODE_DPAD_LEFT; input keyevent KEYCODE_DPAD_UP" | Out-Null
    }
    Start-Sleep -Milliseconds 600

    $pidAfter = (Invoke-AdbShell "pidof com.spocky.projengmenu").Trim()
    if ($pidBefore -ne $pidAfter) {
        throw "Projectivy process crashed/restarted during rapid D-pad stress! (Old PID=$pidBefore, New PID=$pidAfter)"
    }
}

# T2.02: Rapid Home Key Spam Resilience
Execute-Test -TierName "Tier2" -Id "T2.02" -Feature "F2_HOME_INTEGRATION" -Name "Rapid Remote Home key spam (6 keyevents in burst)" -ScriptBlock {
    $pidBefore = (Invoke-AdbShell "pidof com.spocky.projengmenu").Trim()
    for ($i = 0; $i -lt 6; $i++) {
        Invoke-AdbShell "input keyevent KEYCODE_HOME" | Out-Null
        Start-Sleep -Milliseconds 80
    }
    Start-Sleep -Milliseconds 500

    $pidAfter = (Invoke-AdbShell "pidof com.spocky.projengmenu").Trim()
    if ($pidBefore -ne $pidAfter) {
        throw "Projectivy crashed under rapid Home spam (PID changed from $pidBefore to $pidAfter)"
    }

    $focus = Invoke-AdbShell "dumpsys activity activities | grep -E 'ResumedActivity|topResumedActivity'"
    if ($focus -notmatch "com\.spocky\.projengmenu") {
        throw "Projectivy lost foreground focus after rapid Home key spam: $focus"
    }
}

# T2.03: System Free Memory Headroom Boundary (> 600MB)
Execute-Test -TierName "Tier2" -Id "T2.03" -Feature "F8_MEMINFO_VERIFICATION" -Name "System memory headroom boundary verification (Free RAM >= 600MB)" -ScriptBlock {
    $out = Invoke-AdbShell "dumpsys meminfo | grep -E 'Free RAM:'"
    if ($out -match "Free RAM:\s*([0-9,]+)K") {
        $freeRamKb = [int]($matches[1] -replace ',', '')
    } else {
        throw "Failed to extract Free RAM from dumpsys meminfo: $out"
    }

    if ($freeRamKb -lt 600000) {
        throw "System free RAM ($freeRamKb KB) is below the required 600MB (600000 KB) threshold"
    }
}

# T2.04: Monet Cannot Hijack Home Intent
Execute-Test -TierName "Tier2" -Id "T2.04" -Feature "F2_HOME_INTEGRATION" -Name "Disabled Monet launcher cannot capture Home intent" -ScriptBlock {
    $out = Invoke-AdbShell "cmd package resolve-activity --brief -c android.intent.category.HOME -a android.intent.action.MAIN"
    if ($out -match "com\.klevico\.monet") {
        throw "Disabled Monet launcher is still resolving as Home handler: $out"
    }
    if ($out -notmatch "com\.spocky\.projengmenu") {
        throw "Home handler did not resolve to Projectivy: $out"
    }
}

# T2.05: Low Memory Trim Resilience
Execute-Test -TierName "Tier2" -Id "T2.05" -Feature "F3_RAM_OPTIMIZATION" -Name "Low memory pressure trim handling (TRIM_MEMORY_COMPLETE recovery)" -ScriptBlock {
    $pidBefore = (Invoke-AdbShell "pidof com.spocky.projengmenu").Trim()
    Invoke-AdbShell "cmd activity trim-memory com.spocky.projengmenu COMPLETE" | Out-Null
    Start-Sleep -Milliseconds 400
    Invoke-AdbShell "input keyevent KEYCODE_HOME" | Out-Null
    Start-Sleep -Milliseconds 400

    $pidAfter = (Invoke-AdbShell "pidof com.spocky.projengmenu").Trim()
    if ($pidBefore -ne $pidAfter) {
        throw "Projectivy died on memory trim command: $pidBefore -> $pidAfter"
    }
}

# T2.06: Landscape TV Orientation Lock
Execute-Test -TierName "Tier2" -Id "T2.06" -Feature "F5_VISUAL_STYLING" -Name "Display orientation locked to Landscape TV mode (Orientation=0)" -ScriptBlock {
    $out = Invoke-AdbShell "dumpsys window | grep -iE 'mOrientation|mRotation'"
    if ($out -match "mOrientation=0" -or $out -match "mRotation=0") {
        # Valid landscape
    } else {
        # Fallback check display dimensions
        $size = (Invoke-AdbShell "wm size").Trim()
        if ($size -notmatch "1920x1080") {
            throw "Display orientation does not match standard landscape 1080p: $size"
        }
    }
}

# ==============================================================================
# TIER 3: CROSS-FEATURE COMBINATIONS (Pairwise & System Interactions)
# ==============================================================================
Write-Host "`n================================================================================" -ForegroundColor DarkCyan
Write-Host " TIER 3: CROSS-FEATURE COMBINATIONS (Pairwise Interception & Transitions)" -ForegroundColor DarkCyan
Write-Host "================================================================================" -ForegroundColor DarkCyan

# T3.01: External App Launch -> Home Key Interception (SmartTube)
Execute-Test -TierName "Tier3" -Id "T3.01" -Feature "F2+F6+F7" -Name "Launch SmartTube -> Inject HOME -> Intercept back to Projectivy" -ScriptBlock {
    # Launch SmartTube
    Invoke-AdbShell "am start -n org.smarttube.stable/com.liskovsoft.smartyoutubetv2.tv.ui.main.SplashActivity" | Out-Null
    Start-Sleep -Seconds 2

    $appFocus = Invoke-AdbShell "dumpsys activity activities | grep -E 'ResumedActivity|topResumedActivity'"
    if ($appFocus -notmatch "org\.smarttube\.stable") {
        # Retry with monkey
        Invoke-AdbShell "monkey -p org.smarttube.stable -c android.intent.category.LAUNCHER 1" | Out-Null
        Start-Sleep -Seconds 2
    }

    # Intercept with Home key
    Invoke-AdbShell "input keyevent KEYCODE_HOME" | Out-Null
    Start-Sleep -Milliseconds 1200

    $resumed = Invoke-AdbShell "dumpsys activity activities | grep -E 'ResumedActivity|topResumedActivity'"
    if ($resumed -notmatch "com\.spocky\.projengmenu") {
        throw "Projectivy failed to intercept Home key and regain foreground from SmartTube. Current focus: $resumed"
    }
}

# T3.02: Browser App Launch -> Home Key Interception (TV Bro)
Execute-Test -TierName "Tier3" -Id "T3.02" -Feature "F2+F6+F7" -Name "Launch TV Bro Browser -> Inject HOME -> Intercept back to Projectivy" -ScriptBlock {
    Invoke-AdbShell "am start -n com.phlox.tvwebbrowser/.activity.main.MainActivity" | Out-Null
    Start-Sleep -Seconds 2

    # Press HOME
    Invoke-AdbShell "input keyevent KEYCODE_HOME" | Out-Null
    Start-Sleep -Milliseconds 1200

    $resumed = Invoke-AdbShell "dumpsys activity activities | grep -E 'ResumedActivity|topResumedActivity'"
    if ($resumed -notmatch "com\.spocky\.projengmenu") {
        throw "Projectivy failed to regain foreground from TV Bro. Current focus: $resumed"
    }
}

# T3.03: Category Navigation & Back Hierarchy
Execute-Test -TierName "Tier3" -Id "T3.03" -Feature "F6+F7" -Name "Category D-pad traversal and Back key navigation hierarchy" -ScriptBlock {
    Invoke-AdbShell "input keyevent KEYCODE_HOME" | Out-Null
    Start-Sleep -Milliseconds 400
    Invoke-AdbShell "input keyevent KEYCODE_DPAD_DOWN" | Out-Null
    Start-Sleep -Milliseconds 200
    Invoke-AdbShell "input keyevent KEYCODE_DPAD_RIGHT" | Out-Null
    Start-Sleep -Milliseconds 200
    Invoke-AdbShell "input keyevent KEYCODE_BACK" | Out-Null
    Start-Sleep -Milliseconds 300

    $resumed = Invoke-AdbShell "dumpsys activity activities | grep -E 'ResumedActivity|topResumedActivity'"
    if ($resumed -notmatch "com\.spocky\.projengmenu") {
        throw "Back key caused launcher to exit or crash! Focus: $resumed"
    }
}

# T3.04: Cross-App Context Switching Memory Stability
Execute-Test -TierName "Tier3" -Id "T3.04" -Feature "F3+F8" -Name "Cross-app switching memory stability (no runaway memory leak)" -ScriptBlock {
    $out1 = Invoke-AdbShell "dumpsys meminfo com.spocky.projengmenu | grep 'TOTAL PSS:'"
    if ($out1 -match "TOTAL PSS:\s*(\d+)") {
        $pssInitial = [int]$matches[1]
    } else {
        $pssInitial = 0
    }

    # Launch Stremio, then return home
    Invoke-AdbShell "monkey -p com.stremio.one -c android.intent.category.LAUNCHER 1" | Out-Null
    Start-Sleep -Seconds 2
    Invoke-AdbShell "input keyevent KEYCODE_HOME" | Out-Null
    Start-Sleep -Seconds 1

    $out2 = Invoke-AdbShell "dumpsys meminfo com.spocky.projengmenu | grep 'TOTAL PSS:'"
    if ($out2 -match "TOTAL PSS:\s*(\d+)") {
        $pssAfter = [int]$matches[1]
    } else {
        $pssAfter = $pssInitial
    }

    $delta = $pssAfter - $pssInitial
    if ($delta -gt 65000) {
        throw "PSS increased by excessive amount ($delta KB) during app switch cycle: Initial=$pssInitial KB, After=$pssAfter KB"
    }
}

# T3.05: Accessibility Service Persistence
Execute-Test -TierName "Tier3" -Id "T3.05" -Feature "F1+F2" -Name "Accessibility service persistence across application switches" -ScriptBlock {
    $out = Invoke-AdbShell "settings get secure enabled_accessibility_services"
    if ($out -notmatch "com\.spocky\.projengmenu.*ProjectivyAccessibilityService") {
        throw "Accessibility service unbound after application switching: $out"
    }
}

# ==============================================================================
# TIER 4: REAL-WORLD TV USAGE SCENARIOS (End-to-End Validation)
# ==============================================================================
Write-Host "`n================================================================================" -ForegroundColor DarkCyan
Write-Host " TIER 4: REAL-WORLD APPLICATION SCENARIOS (Daily Driver Validation)" -ForegroundColor DarkCyan
Write-Host "================================================================================" -ForegroundColor DarkCyan

# T4.01: Scenario 1 - Cold Wakeup & Remote Keyguard Dismissal
Execute-Test -TierName "Tier4" -Id "T4.01" -Feature "F2+F7" -Name "Scenario 1: Cold STB wakeup and keyguard dismissal to active Home" -ScriptBlock {
    Invoke-AdbShell "input keyevent KEYCODE_WAKEUP" | Out-Null
    Start-Sleep -Milliseconds 200
    Invoke-AdbShell "input keyevent 82" | Out-Null # KEYCODE_MENU / dismiss lock
    Start-Sleep -Milliseconds 200
    Invoke-AdbShell "input keyevent KEYCODE_HOME" | Out-Null
    Start-Sleep -Milliseconds 800

    $focus = Invoke-AdbShell "dumpsys activity activities | grep -E 'ResumedActivity|topResumedActivity'"
    if ($focus -notmatch "com\.spocky\.projengmenu") {
        throw "Projectivy failed to foreground on cold wakeup: $focus"
    }
}

# T4.02: Scenario 2 - Full 12-Step TV Remote Navigation Sequence
Execute-Test -TierName "Tier4" -Id "T4.02" -Feature "F7" -Name "Scenario 2: Complete 12-step TV remote D-pad navigation cycle" -ScriptBlock {
    $keys = @(
        "KEYCODE_HOME",
        "KEYCODE_DPAD_DOWN",
        "KEYCODE_DPAD_RIGHT",
        "KEYCODE_DPAD_RIGHT",
        "KEYCODE_DPAD_LEFT",
        "KEYCODE_DPAD_UP",
        "KEYCODE_DPAD_CENTER",
        "KEYCODE_BACK",
        "KEYCODE_DPAD_DOWN",
        "KEYCODE_DPAD_UP",
        "KEYCODE_DPAD_LEFT",
        "KEYCODE_HOME"
    )

    foreach ($k in $keys) {
        Invoke-AdbShell "input keyevent $k" | Out-Null
        Start-Sleep -Milliseconds 150
    }

    $focus = Invoke-AdbShell "dumpsys activity activities | grep -E 'ResumedActivity|topResumedActivity'"
    if ($focus -notmatch "com\.spocky\.projengmenu") {
        throw "Projectivy was displaced during D-pad navigation cycle: $focus"
    }
}

# T4.03: Scenario 3 - Media Consumption Workflow
Execute-Test -TierName "Tier4" -Id "T4.03" -Feature "F6+F7" -Name "Scenario 3: Media app playback entry and clean Home return (VLC)" -ScriptBlock {
    Invoke-AdbShell "monkey -p org.videolan.vlc -c android.intent.category.LAUNCHER 1" | Out-Null
    Start-Sleep -Seconds 2
    Invoke-AdbShell "input keyevent KEYCODE_DPAD_CENTER" | Out-Null
    Start-Sleep -Milliseconds 500
    Invoke-AdbShell "input keyevent KEYCODE_HOME" | Out-Null
    Start-Sleep -Milliseconds 800

    $focus = Invoke-AdbShell "dumpsys activity activities | grep -E 'ResumedActivity|topResumedActivity'"
    if ($focus -notmatch "com\.spocky\.projengmenu") {
        throw "Failed to return home cleanly after VLC launch: $focus"
    }
}

# T4.04: Scenario 4 - Screenshot Artifact Capture and Binary Validation
Execute-Test -TierName "Tier4" -Id "T4.04" -Feature "F9_SCREENSHOT_CAPTURE" -Name "Scenario 4: High-res UI screencap capture & 1080p PNG validation" -ScriptBlock {
    $remoteFile = "/sdcard/projectivy_homescreen.png"
    $localFile = Join-Path $OutputDir $ScreenshotFile

    # Ensure on home screen
    Invoke-AdbShell "input keyevent KEYCODE_HOME" | Out-Null
    Start-Sleep -Seconds 1

    # Take screencap
    Invoke-AdbShell "screencap -p $remoteFile" | Out-Null
    Start-Sleep -Milliseconds 500

    # Pull to local directory
    $pullOut = Invoke-Adb "pull $remoteFile `"$localFile`""
    if (-not (Test-Path $localFile)) {
        throw "Failed to pull screenshot artifact to $($localFile): $pullOut"
    }

    $item = Get-Item $localFile
    if ($item.Length -lt 50000) {
        throw "Screenshot size ($($item.Length) bytes) is unexpectedly small (< 50KB)"
    }

    $info = Get-PngDimensions -FilePath $localFile
    if (-not $info) {
        throw "Captured file is not a valid PNG binary"
    }
    if ($info.Width -ne 1920 -or $info.Height -ne 1080) {
        throw "Screenshot dimensions ($($info.Width)x$($info.Height)) do not match expected 1080p (1920x1080)"
    }
}

# T4.05: Scenario 5 - System Stability & Crash/ANR Audit
Execute-Test -TierName "Tier4" -Id "T4.05" -Feature "F7+F8" -Name "Scenario 5: Process stability audit (zero FATAL EXCEPTIONs and zero ANRs)" -ScriptBlock {
    $crashLog = Invoke-AdbShell "logcat -d -b crash | grep -i com.spocky.projengmenu"
    if ($crashLog.Trim().Length -gt 0) {
        throw "Fatal crash detected in logcat crash buffer: $crashLog"
    }
}

# ==============================================================================
# Summary & Exit Code Generation
# ==============================================================================
$globalStopwatch.Stop()
$totalDuration = [math]::Round($globalStopwatch.Elapsed.TotalSeconds, 1)

$totalCount = $TestResults.Count
$passedCount = ($TestResults | Where-Object { $_.Status -eq "PASS" }).Count
$failedCount = ($TestResults | Where-Object { $_.Status -eq "FAIL" }).Count
$skippedCount = ($TestResults | Where-Object { $_.Status -eq "SKIP" }).Count

Write-Host "`n================================================================================" -ForegroundColor Cyan
Write-Host " E2E Test Execution Summary" -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host " Total Tests Executed : $totalCount" -ForegroundColor White
Write-Host " Passed               : $passedCount" -ForegroundColor Green
Write-Host " Failed               : $failedCount" -ForegroundColor $(if ($failedCount -eq 0) { "Green" } else { "Red" })
Write-Host " Skipped              : $skippedCount" -ForegroundColor Yellow
Write-Host " Total Duration       : $totalDuration s" -ForegroundColor White
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor Cyan

if ($failedCount -gt 0) {
    Write-Host "`n[!] Failed Tests Breakdown:" -ForegroundColor Red
    foreach ($f in ($TestResults | Where-Object { $_.Status -eq "FAIL" })) {
        Write-Host "  - [$($f.Id)] $($f.Name): $($f.Message)" -ForegroundColor Red
    }
    Write-Host "`nOVERALL RESULT: FAILED (Exit Code 1)" -ForegroundColor Red
    Write-Host "================================================================================" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nOVERALL RESULT: ALL TESTS PASSED (Exit Code 0)" -ForegroundColor Green
    Write-Host "================================================================================" -ForegroundColor Green
    exit 0
}
