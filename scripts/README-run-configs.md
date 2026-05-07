# Run configs — uso recomendado (físico/emulador)

## Objetivo

Estandarizar cómo correr la app por flavor y evitar fallos por IP LAN cambiante.

## Configuraciones recomendadas (Android Studio)

- **Run Dev LAN (auto IP script)**
  - Usa backend local por LAN en dispositivo físico.
  - Antes de correr, detecta la IP actual y regenera `.dart-defines/lan.auto.json`.
  - Script: `scripts/run_dev_lan.sh`

- **Run Dev Cloud (script)**
  - Usa backend remoto de dev (Railway).
  - Script: `scripts/run_dev_cloud.sh`

- **Run Staging Cloud (script)**
  - Usa backend remoto de staging (Railway).
  - Script: `scripts/run_staging_cloud.sh`

- **Run Pro Cloud (script)**
  - Usa backend remoto de pro (Railway).
  - Script: `scripts/run_pro_cloud.sh`

## Scripts auxiliares

- `scripts/restore_firebase_config.ps1`
  - Restaura los archivos Firebase reales por flavor desde variables de entorno base64 en Windows.
- `scripts/restore_firebase_config.sh`
  - Restaura los mismos archivos en Linux/macOS.
  - Archivos de salida:
    - `android/app/src/<flavor>/google-services.json`
    - `ios/config/<flavor>/GoogleService-Info.plist`
  - Ejemplos:

```powershell
./scripts/restore_firebase_config.ps1 -Flavor staging
./scripts/restore_firebase_config.ps1 -Flavor all
```

```bash
scripts/restore_firebase_config.sh --flavor staging
scripts/restore_firebase_config.sh --flavor all
```

- `scripts/update_lan_dart_defines.sh`
  - Detecta IP LAN y genera:
    - `API_BASE_URL=http://<IP-LAN>:8000`
    - `API_FALLBACK_URL=http://127.0.0.1:8000`
  - Archivo de salida: `.dart-defines/lan.auto.json` (ignorando por git)

## Smoke tests automatizados

- `scripts/smoke_mobile_release.sh`
  - Valida en dispositivo físico:
    - flavor correcto
    - `API_BASE_URL` correcta en logs
  - Modos soportados: `pro`, `staging`, `dev-cloud`, `dev-lan`
  - Ejemplo:

```bash
scripts/smoke_mobile_release.sh pro
```

- `scripts/smoke_backend_release.sh`
  - Valida endpoints críticos de backend:
    - `/ping`
    - `/manga?limit=5`
    - `/chapters/latest?limit=8`
  - Modos soportados: `pro`, `staging`, `dev-cloud`
  - Ejemplo:

```bash
scripts/smoke_backend_release.sh pro
```

### Evidencia generada

Ambos scripts guardan salidas en `.qa-evidence/` (ignorado por git):
- logs
- respuestas JSON
- resumen markdown listo para pegar en Obsidian/QA

## Troubleshooting rápido

- Si cambia de red/WiFi y falla Dev LAN, volver a ejecutar:

```bash
scripts/update_lan_dart_defines.sh
```

- Si querés evitar dependencia LAN, usar directamente cualquier config `* Cloud (script)`.

- Para repetición rápida de validación release:

```bash
scripts/smoke_backend_release.sh pro && scripts/smoke_mobile_release.sh pro
```
