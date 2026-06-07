#!/system/bin/sh
# P80 GSI Booster — post-fs-data.sh (mínimo, apenas agenda service.sh)
# Sem mounts, sem kills — apenas lança service.sh em background

nohup sh ${0%/*}/service.sh >/dev/null 2>&1 &
