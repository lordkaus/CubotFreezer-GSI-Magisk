# Changelog

## v1.3 (2026-06-07)
- **post-fs-data.sh** seguro (sem mounts, só agenda service.sh via nohup)
- **service.sh** com detecção inteligente de FingerprintHand (só reinicia system_server se CPU > 10%)
- Bind mount do **vendor manifest vazio** (faltava na v1.2)
- **apply.sh** — script para aplicar correções sem reboot
- Guard `.ran` para evitar execução duplicada
- Módulo renomeado para **P80 GSI Booster**

## v1.2 (2026-06-07)
- Adicionado post-fs-data.sh apenas para agendar service.sh em background
- service.sh com detecção de FingerprintHand e restart do system_server
- Guard `.ran` para evitar execução duplicada

## v1.1 (2026-06-07)
- Removido post-fs-data.sh (causava bootloop)
- Apenas service.sh com delay de 15s após boot_completed
- Background monitor para fingerprint processes (loop kill 30s)

## v1.0 (2026-06-07)
- Versão inicial com post-fs-data.sh agressivo (bootloop)
