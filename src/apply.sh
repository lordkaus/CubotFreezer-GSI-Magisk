#!/system/bin/sh
# P80 GSI Booster — apply.sh
# Uso: adb shell "su -c 'sh /data/adb/modules/p80_gsi_booster/apply.sh'"
# Aplica todas as correções SEM reiniciar

MODDIR=${0%/*}
log -t p80-booster "=== apply.sh — aplicação manual ==="

# 1. SELinux
magiskpolicy --live "allow system_suspend sysfs file read" 2>/dev/null
magiskpolicy --live "allow system_suspend sysfs dir search" 2>/dev/null

# 2. Bind mounts (unconditional — falham se overlay já ativo)
for manifest in \
    /vendor/etc/vintf/manifest/android.hardware.biometrics.fingerprint@2.1-service.xml \
    /system/vendor/etc/vintf/manifest/android.hardware.biometrics.fingerprint@2.1-service.xml; do
    [ -f "$manifest" ] && \
        mount --bind "$MODDIR/vendor/etc/vintf/manifest/android.hardware.biometrics.fingerprint@2.1-service.xml" \
            "$manifest" 2>/dev/null && log -t p80-booster "Bind mount: $manifest OK"
done

[ -f /vendor/etc/permissions/android.hardware.fingerprint.xml ] && \
    mount --bind "$MODDIR/vendor/etc/permissions/android.hardware.fingerprint.xml" \
        /vendor/etc/permissions/android.hardware.fingerprint.xml 2>/dev/null && \
        log -t p80-booster "Bind mount: permissions OK"

# 3. Power-mode-monitor
if [ -f /system/bin/power-mode-monitor.sh ]; then
    mount --bind "$MODDIR/system/bin/power-mode-monitor.sh" \
        /system/bin/power-mode-monitor.sh 2>/dev/null
    killall -9 power-mode-monitor.sh 2>/dev/null
fi

# 4. Reseta guard e executa service.sh (se necessário)
setprop sys.p80_booster.ran 0
sh "$MODDIR/service.sh" &

log -t p80-booster "=== apply.sh concluído ==="
