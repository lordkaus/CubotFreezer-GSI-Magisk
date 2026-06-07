# ❄️ CubotFreezer GSI Magisk

**Congela o fingerprint HAL em GSIs no Cubot P80 (Mediatek).**

Elimina o **FingerprintHand thread** que consome **75% da CPU** no system_server, causando superaquecimento, travamentos e bootloop em GSIs. Dispositivo roda **frio como stock** após instalar.

---

## 🔥 O Problema

GSIs (Generic System Images) no Cubot P80 sofrem de um bug no fingerprint HAL:
- O driver físico não existe (sensor quebrado/ausente em GSIs)
- Mesmo assim, o system_server cria a thread **FingerprintHand**
- Essa thread entra em loop consumindo **75% da CPU** constantemente
- Resultado: **superaquecimento, bateria drenada, UI travada, possível bootloop**

## ❄️ A Solução

Este módulo Magisk faz 3 coisas:

1. **Overlays** (via Magic Mount) — substitui arquivos de permissão e manifesto do fingerprint por versões vazias no boot
2. **service.sh** — aplica bind mounts, regras SELinux, e reinicia o system_server se necessário (apenas se CPU > 10%)
3. **apply.sh** — aplica todas as correções **sem reiniciar** o dispositivo

### Resultado

| Métrica | Antes | Depois |
|---|---|---|
| FingerprintHand CPU | **75%** 🔥 | **0%** ❄️ |
| system_server CPU | 75-78% | ~3% |
| CPU Idle | **0%** | **~97%** |
| Temperatura vídeo | Quente (45°C+) | Frio (~38°C) |

---

## 📦 Instalação

### Método 1 — Magisk Manager (recomendado)
1. Baixe o ZIP da [última release](https://github.com/lordkaus/CubotFreezer-GSI-Magisk/releases)
2. Abra o Magisk Manager → Módulos → Instalar do armazenamento
3. Selecione o ZIP e reinicie

### Método 2 — ADB (instalação remota)
```bash
adb push P80_GSI_Booster_v1.3.zip /sdcard/Download/
adb shell "su -c 'magisk --install-module /sdcard/Download/P80_GSI_Booster_v1.3.zip'"
adb reboot
```

### Aplicar sem reiniciar
```bash
adb shell "su -c 'sh /data/adb/modules/p80_gsi_booster/apply.sh'"
```

---

## 🔧 Como funciona

### Estrutura do módulo

```
/data/adb/modules/p80_gsi_booster/
├── module.prop          ← Identificação do módulo
├── post-fs-data.sh      ← Agenda service.sh em background (seguro)
├── service.sh           ← Aplica correções após boot + monitor background
├── apply.sh             ← Aplica correções manualmente (sem reboot)
├── vendor/
│   └── etc/
│       ├── permissions/
│       │   └── android.hardware.fingerprint.xml  ← Vazio (remove permissão)
│       └── vintf/manifest/
│           └── android.hardware.biometrics.fingerprint@2.1-service.xml ← Vazio
└── system/
    ├── etc/
    │   ├── vintf/manifest.xml                    ← System manifest limpo
    │   └── permissions/android.hardware.fingerprint.xml ← Vazio
    ├── bin/power-mode-monitor.sh                 ← Otimizado (phh GSIs)
    └── vendor/etc/vintf/manifest/...             ← Fallback vendor manifest
```

### Fluxo de boot

1. **Magisk Magic Mount** → sobrepõe arquivos de permissão/manifest (fingerprint removido)
2. **post-fs-data.sh** → lança service.sh em background (sem risco de bootloop)
3. **service.sh** → aguarda boot_completed → bind mounts → detecta FingerprintHand → se CPU>10%, reinicia system_server
4. **system_server renasce** → sem fingerprint → FingerprintHand dorme em 0% CPU

---

## 📋 Compatibilidade

| Dispositivo | Status |
|---|---|
| Cubot P80 (MT8781) | ✅ Testado |
| Outros Mediatek com GSI | ✅ Provável (universal) |

| Android | Status |
|---|---|
| GSI Android 16.2 (Vanilla) | ✅ Testado |
| GSI Android 14+ | ✅ Deve funcionar |
| Stock ROM | ⚠️ Não necessário (fingerprint funciona) |

---

## 🧪 Testes

### Temperatura durante vídeo (YouTube 1080p60)

```
Antes (sem módulo):  45°C+ 🔥
Depois (com módulo): 38°C ❄️
Stock ROM:           37°C ❄️
```

### CPU durante uso normal

```
Antes: FingerprintHand 75%  + Chrome 100% = 175% CPU 🔥
Depois: FingerprintHand 0%  + Chrome 100% = 100% CPU ❄️
Stock:  FingerprintHand N/A + Chrome 100% = 100% CPU ❄️
```

---

## 📜 Changelog

Veja [CHANGELOG.md](CHANGELOG.md)

---

## 📄 Licença

MIT — use, modifique e compartilhe à vontade.
