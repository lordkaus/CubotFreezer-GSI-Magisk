#!/system/bin/sh
# P80 GSI Booster — service.sh

MODDIR=${0%/*}

# Evita execução duplicada
[ -f "$MODDIR/.ran" ] && exit 0
echo 1 > "$MODDIR/.ran"

log -t p80-booster "=== P80 GSI Booster ==="

until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 1
done

sleep 15

# ──────────────────────────────────────────────
# 1. REDUZ LOG BUFFER
# ──────────────────────────────────────────────
logcat -G 256K 2>/dev/null

# ──────────────────────────────────────────────
# 2. REGRAS SELINUX (seguras, universais)
# ──────────────────────────────────────────────
magiskpolicy --live "allow system_suspend sysfs file read" 2>/dev/null
magiskpolicy --live "allow system_suspend sysfs dir search" 2>/dev/null

# ──────────────────────────────────────────────
# 3. BIND MOUNTS — manifestos e permissões
# ──────────────────────────────────────────────

# Remove fingerprint do vendor manifest (v1 + v2 paths)
for manifest in \
    /vendor/etc/vintf/manifest/android.hardware.biometrics.fingerprint@2.1-service.xml \
    /system/vendor/etc/vintf/manifest/android.hardware.biometrics.fingerprint@2.1-service.xml; do
    if [ -f "$manifest" ] && grep -q "fingerprint" "$manifest" 2>/dev/null; then
        mount --bind "$MODDIR/vendor/etc/vintf/manifest/android.hardware.biometrics.fingerprint@2.1-service.xml" \
            "$manifest" 2>/dev/null
    fi
done

# Remove fingerprint das permissões vendor
if grep -q "fingerprint" /vendor/etc/permissions/android.hardware.fingerprint.xml 2>/dev/null; then
    mount --bind "$MODDIR/vendor/etc/permissions/android.hardware.fingerprint.xml" \
        /vendor/etc/permissions/android.hardware.fingerprint.xml 2>/dev/null
fi

# ──────────────────────────────────────────────
# 4. OTIMIZA POWER-MODE-MONITOR (phh GSIs)
# ──────────────────────────────────────────────
if [ -f /system/bin/power-mode-monitor.sh ]; then
    mount --bind "$MODDIR/system/bin/power-mode-monitor.sh" \
        /system/bin/power-mode-monitor.sh 2>/dev/null
    killall -9 power-mode-monitor.sh 2>/dev/null
fi

# ──────────────────────────────────────────────
# 5. DETECTOR — FingerprintHand no system_server
# ──────────────────────────────────────────────
FP_HAND=$(top -b -n 1 -H -p "$(pgrep system_server)" 2>/dev/null | grep FingerprintHand)
if [ -n "$FP_HAND" ]; then
    FP_CPU=$(echo "$FP_HAND" | awk '{print $9}' | head -1)
    FP_CPU_INT=${FP_CPU%.*}
    log -t p80-booster "FingerprintHand detectado (CPU=$FP_CPU%)"

    if [ "${FP_CPU_INT:-0}" -gt 10 ] 2>/dev/null; then
        log -t p80-booster "CPU alto ($FP_CPU%) — reiniciando system_server"
        mount --bind "$MODDIR/vendor/etc/permissions/android.hardware.fingerprint.xml" \
            /vendor/etc/permissions/android.hardware.fingerprint.xml 2>/dev/null

        OLD_PID=$(pgrep system_server)
        kill -9 "$OLD_PID" 2>/dev/null

        for i in $(seq 1 20); do
            NEW_PID=$(pgrep system_server)
            if [ -n "$NEW_PID" ] && [ "$NEW_PID" != "$OLD_PID" ]; then
                sleep 3
                log -t p80-booster "Novo system_server PID=$NEW_PID ativo"
                break
            fi
            sleep 1
        done
    else
        log -t p80-booster "CPU normal — sem restart necessário"
    fi
else
    log -t p80-booster "FingerprintHand não detectado"
fi

# ──────────────────────────────────────────────
# 6. MONITOR BACKGROUND — fingerprint recorrente
# ──────────────────────────────────────────────
(
    while true; do
        for proc in android.hardware.biometrics.fingerprint@2.1-service vendor.fps_hal fpsgo; do
            pid=$(pgrep -f "$proc" 2>/dev/null)
            [ -n "$pid" ] && kill -9 "$pid" 2>/dev/null
        done
        sleep 30
    done
) &

log -t p80-booster "=== P80 GSI Booster pronto ==="
