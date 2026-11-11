# boot_tuning.ps1 — Run after ADB reconnect to re-apply volatile setprops & services
# These are runtime-only on Amlogic user builds (persist.* blocked by selinux)
param(
    [string]$STB = ""
)

if (-not $STB) {
    if ($env:STB_TARGET) {
        $STB = $env:STB_TARGET
    } else {
        $devices = adb devices | Where-Object { $_ -match "\s+device$" } | ForEach-Object { ($_ -split "\s+")[0] }
        if ($devices.Count -ge 1) {
            $STB = $devices[0]
            Write-Host "[*] Auto-detected active target: $STB" -ForegroundColor Cyan
        } else {
            $STB = "192.168.137.28:5555"
            Write-Host "[*] Defaulting target to: $STB" -ForegroundColor Cyan
        }
    }
}

Write-Host "[boot_tuning] Connecting and applying runtime tuning to $STB..." -ForegroundColor Cyan

$props = @{
    # Hardware decoders
    "media.decoder.mpeg2"           = "hardware"
    "media.decoder.avc"             = "hardware"
    "media.decoder.hevc"            = "hardware"
    "media.decoder.vp9"             = "hardware"
    "media.stagefright.thumbnail.prefer_hw_codecs" = "true"
    # SurfaceFlinger
    "debug.sf.set_idle_timer_ms"    = "2000"
    "debug.sf.enable_gl_backpressure" = "1"
    "debug.sf.latch_unsignaled"     = "1"
    # HWUI
    "debug.hwui.renderer"           = "opengl"
    "debug.hwui.use_gpu_pixel_buffers" = "true"
    # Dalvik
    "dalvik.vm.dex2oat-threads"     = "4"
    "dalvik.vm.image-dex2oat-threads" = "4"
    "dalvik.vm.gctype"              = "SS"
    "dalvik.vm.checkjni"            = "false"
}

foreach ($k in $props.Keys) {
    adb -s $STB shell "setprop $k $($props[$k])" | Out-Null
    Write-Host "  SET $k = $($props[$k])" -ForegroundColor Green
}

# 1. Start Shizuku server if not running
$shizukuRunning = adb -s $STB shell "ps -A | grep -c shizuku_server" 2>&1
if ($shizukuRunning -and $shizukuRunning.Trim() -eq "0") {
    Write-Host "  Starting Shizuku server..." -ForegroundColor Yellow
    adb -s $STB shell "/data/local/tmp/shizuku" | Out-Null
} else {
    Write-Host "  Shizuku server is ALIVE." -ForegroundColor Green
}

# 2. Re-apply Voice Assist services
adb -s $STB shell "am startservice -n com.android.app.jio.voiceassist/.jiohome.JioHomeMobileRemoteService" 2>&1 | Out-Null
adb -s $STB shell "am startservice -n com.android.app.jio.voiceassist/.voice.VoiceService.VoiceServiceWrapper" 2>&1 | Out-Null

# 3. Ensure accessibility services are active
$svcs = "com.iwedia.ledmanager/com.iwedia.ledmanager.KeyEventMonitorService:com.spocky.projengmenu/com.spocky.projengmenu.services.ProjectivyAccessibilityService:io.github.virresh.matvt/.services.MouseEventService"
adb -s $STB shell "settings put secure enabled_accessibility_services $svcs" | Out-Null
adb -s $STB shell "settings put secure accessibility_enabled 1" | Out-Null

# 4. Kill JioTV+ background resource hog
adb -s $STB shell "am force-stop com.jio.media.jiotvplus" 2>&1 | Out-Null

Write-Host "[boot_tuning] Done. STB: $STB tuned." -ForegroundColor Green
