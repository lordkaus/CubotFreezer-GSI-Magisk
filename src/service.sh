#!/system/bin/sh
# P80 GSI Booster — service.sh

MODDIR=${0%/*}

if [ "$(getprop sys.p80_booster.ran)" = "1" ]; then exit 0; fi
setprop sys.p80_booster.ran 1

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
# 2. SELINUX
# ──────────────────────────────────────────────
magiskpolicy --live "allow system_suspend sysfs file read" 2>/dev/null
magiskpolicy --live "allow system_suspend sysfs dir search" 2>/dev/null

# ──────────────────────────────────────────────
# 3. BIND MOUNTS — sempre tentar (falham se já overlay)
# ──────────────────────────────────────────────

# Vendor manifest (todos os paths possíveis)
for manifest in \
    /vendor/etc/vintf/manifest/android.hardware.biometrics.fingerprint@2.1-service.xml \
    /system/vendor/etc/vintf/manifest/android.hardware.biometrics.fingerprint@2.1-service.xml; do
    [ -f "$manifest" ] && mount --bind "$MODDIR/vendor/etc/vintf/manifest/android.hardware.biometrics.fingerprint@2.1-service.xml" "$manifest" 2>/dev/null
done

# Vendor permissions
[ -f /vendor/etc/permissions/android.hardware.fingerprint.xml ] && \
    mount --bind "$MODDIR/vendor/etc/permissions/android.hardware.fingerprint.xml" \
        /vendor/etc/permissions/android.hardware.fingerprint.xml 2>/dev/null

# ──────────────────────────────────────────────
# 4. POWER-MODE-MONITOR
# ──────────────────────────────────────────────
if [ -f /system/bin/power-mode-monitor.sh ]; then
    mount --bind "$MODDIR/system/bin/power-mode-monitor.sh" \
        /system/bin/power-mode-monitor.sh 2>/dev/null
    killall -9 power-mode-monitor.sh 2>/dev/null
fi

# ──────────────────────────────────────────────
# 5. PARA O SERVIÇO FINGERPRINT VIA INIT
# ──────────────────────────────────────────────
FP_PID=$(pgrep -f android.hardware.biometrics.fingerprint 2>/dev/null)
if [ -n "$FP_PID" ]; then
    FP_SVC=$(getprop init.svc.$(cat /proc/$FP_PID/cmdline 2>/dev/null | tr '\0' '\n' | head -1) 2>/dev/null)
    setprop ctl.stop vendor.fps_hal 2>/dev/null
    setprop ctl.stop android.hardware.biometrics.fingerprint@2.1-service 2>/dev/null
    kill -9 "$FP_PID" 2>/dev/null
    log -t p80-booster "Serviço fingerprint parado"
fi

# ──────────────────────────────────────────────
# 6. DETECTOR — FingerprintHand
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

log -t p80-booster "=== P80 GSI Booster pronto ==="
