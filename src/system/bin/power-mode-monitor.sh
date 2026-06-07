#!/system/bin/sh
PROP="persist.sys.phh.blocked_power_modes"
existing="$(getprop "$PROP")"
log -t p80-booster "power-mode-monitor iniciado"
logcat -b all -d -v brief 2>/dev/null | grep -E "(unknown|unsupported)" | \
while IFS= read -r line; do
    type=$(echo "$line" | sed -n 's/.*type:\([0-9]\+\).*/\1/p')
    [ -n "$type" ] && {
        if ! echo ",$existing," | grep -q ",$type,"; then
            [ -z "$existing" ] && existing="$type" || existing="$existing,$type"
            setprop "$PROP" "$existing"
        fi
    }
done
log -t p80-booster "power-mode-monitor concluído"
