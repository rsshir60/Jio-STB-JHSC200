#!/system/bin/sh
# TVFileBox Scoped Storage Auto-Sync Daemon
# Bypasses Android 11 scoped storage sandbox restrictions by monitoring uploads
# and moving files into standard /storage/emulated/0/Movies, triggering media scanner.

UPLOADS_DIR="/storage/emulated/0/Android/data/com.example.tvfilebox/files/uploads"
TARGET_DIR="/storage/emulated/0/Movies"

mkdir -p "$TARGET_DIR"

echo "[*] TVFileBox Auto-Sync Daemon running..."
echo "[*] Watching: $UPLOADS_DIR"
echo "[*] Syncing to: $TARGET_DIR"

while true; do
    if [ -d "$UPLOADS_DIR" ]; then
        for f in "$UPLOADS_DIR"/*; do
            if [ -f "$f" ]; then
                fname="${f##*/}"
                echo "[+] Ingesting new file: $fname"
                mv "$f" "$TARGET_DIR/$fname"
                am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d "file://$TARGET_DIR/$fname" >/dev/null 2>&1
            fi
        done
    fi
    sleep 3
done
