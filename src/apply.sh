#!/system/bin/sh
# P80 GSI Booster — apply.sh
# Uso: adb shell "su -c 'sh /data/adb/modules/p80_gsi_booster/apply.sh'"
# Aplica todas as correções SEM reiniciar

MODDIR=${0%/*}
log -t p80-booster "=== apply.sh — aplicação manual ==="

# 1. SELinux
magiskpolicy --live "allow system_suspend sysfs file read" 2>/dev/null
magiskpolicy --live "allow system_suspend sysfs dir search" 2>/dev/null

# 2. Bind mounts (manifest + permissions)
for manifest in \
    /vendor/etc/vintf/manifest/android.hardware.biometrics.fingerprint@2.1-service.xml \
    /system/vendor/etc/vintf/manifest/android.hardware.biometrics.fingerprint@2.1-service.xml; do
    if [ -f "$manifest" ] && grep -q "fingerprint" "$manifest" 2>/dev/null; then
        mount --bind "$MODDIR/vendor/etc/vintf/manifest/android.hardware.biometrics.fingerprint@2.1-service.xml" \
            "$manifest" 2>/dev/null && log -t p80-booster "Bind mount: $manifest OK"
    fi
done

if grep -q "fingerprint" /vendor/etc/permissions/android.hardware.fingerprint.xml 2>/dev/null; then
    mount --bind "$MODDIR/vendor/etc/permissions/android.hardware.fingerprint.xml" \
        /vendor/etc/permissions/android.hardware.fingerprint.xml 2>/dev/null && \
        log -t p80-booster "Bind mount: permissions OK"
fi

# 3. Power-mode-monitor
if [ -f /system/bin/power-mode-monitor.sh ]; then
    mount --bind "$MODDIR/system/bin/power-mode-monitor.sh" \
        /system/bin/power-mode-monitor.sh 2>/dev/null
    killall -9 power-mode-monitor.sh 2>/dev/null
fi

# 4. Remove .ran e executa service.sh (se necessário)
rm -f "$MODDIR/.ran"
sh "$MODDIR/service.sh" &

log -t p80-booster "=== apply.sh concluído ==="
