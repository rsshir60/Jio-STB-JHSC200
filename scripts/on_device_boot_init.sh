#!/system/bin/sh
# on_device_boot_init.sh - Autonomous standalone boot persistence script for Jio STB JHSC200
# Run as: /data/local/tmp/on_device_boot_init.sh

echo "[*] Initializing JHSC200 10.0 autonomous tuning..."

# 1. Start Shizuku server locally if not running
if ! pgrep -f shizuku_server > /dev/null; then
    echo "[*] Starting Shizuku server..."
    /data/local/tmp/shizuku &
else
    echo "[+] Shizuku server is running."
fi

# 2. Hardware Decoder overrides
setprop media.decoder.mpeg2 hardware
setprop media.decoder.avc hardware
setprop media.decoder.hevc hardware
setprop media.decoder.vp9 hardware
setprop media.stagefright.thumbnail.prefer_hw_codecs true
setprop ro.media.scan.no_sdcard 1

# 3. SurfaceFlinger & HWUI tuning
setprop debug.sf.set_idle_timer_ms 2000
setprop debug.sf.enable_gl_backpressure 1
setprop debug.sf.latch_unsignaled 1
setprop debug.hwui.renderer opengl
setprop debug.hwui.use_gpu_pixel_buffers true
setprop debug.hwui.disable_scissor_opt false

# 4. Dalvik ART GC & Threading
setprop dalvik.vm.dex2oat-threads 4
setprop dalvik.vm.image-dex2oat-threads 4
setprop dalvik.vm.gctype SS
setprop dalvik.vm.checkjni false

# 5. Network buffer optimization
setprop net.tcp.buffersize.wifi "524288,1048576,2097152,262144,524288,1048576"

# 6. Audio/Video Settings
settings put global encoded_surround_output 2
settings put global encoded_surround_output_enabled_formats "1,2,5,6,7,8,10,14"
settings put global hdmi_control_auto_device_off_enabled 1
settings put global match_content_frame_rate 2

# 7. Service Keep-Alives & Accessibility
am startservice -n com.android.app.jio.voiceassist/.jiohome.JioHomeMobileRemoteService 2>/dev/null
am startservice -n com.android.app.jio.voiceassist/.voice.VoiceService.VoiceServiceWrapper 2>/dev/null

SVCS="com.iwedia.ledmanager/com.iwedia.ledmanager.KeyEventMonitorService:com.spocky.projengmenu/com.spocky.projengmenu.services.ProjectivyAccessibilityService:io.github.virresh.matvt/.services.MouseEventService"
settings put secure enabled_accessibility_services "$SVCS"
settings put secure accessibility_enabled 1

# 8. Clean up idle carrier RAM hogs
am force-stop com.jio.media.jiotvplus 2>/dev/null

echo "[+] Autonomous boot init completed successfully."
