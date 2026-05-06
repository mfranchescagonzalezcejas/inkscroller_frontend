# Firebase Config — Estructura de ejemplo

> Este documento muestra la **estructura** de los archivos de configuración de Firebase sin valores reales.
> Nunca commitear archivos con valores reales.

---

## google-services.json (Android)

Ubicación esperada por flavor:

```
android/app/src/dev/google-services.json
android/app/src/staging/google-services.json
android/app/src/pro/google-services.json
```

Estructura (sin valores reales):

```json
{
  "project_info": {
    "project_number": "YOUR_PROJECT_NUMBER",
    "project_id": "your-firebase-project-id",
    "storage_bucket": "your-firebase-project-id.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:YOUR_PROJECT_NUMBER:android:YOUR_APP_ID",
        "android_client_info": {
          "package_name": "com.yourcompany.inkscroller.dev"
        }
      },
      "oauth_client": [
        {
          "client_id": "YOUR_CLIENT_ID.apps.googleusercontent.com",
          "client_type": 3
        }
      ],
      "api_key": [
        {
          "current_key": "REDACTED_FIREBASE_API_KEY"
        }
      ],
      "services": {
        "appinvite_service": {
          "other_platform_oauth_client": []
        }
      }
    }
  ],
  "configuration_version": "1"
}
```

### Cómo obtenerlo

1. Firebase Console → seleccionar proyecto → ⚙️ Project settings
2. Tab **General** → sección **Your apps** → seleccionar la app Android
3. Descargar `google-services.json`
4. Moverlo a `android/app/src/<flavor>/google-services.json`

---

## GoogleService-Info.plist (iOS)

Ubicación esperada por flavor (actual):

```
ios/config/dev/GoogleService-Info.plist
ios/config/staging/GoogleService-Info.plist
ios/config/pro/GoogleService-Info.plist
```

Estructura (sin valores reales):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>API_KEY</key>
  <string>REDACTED_FIREBASE_API_KEY</string>
  <key>GCM_SENDER_ID</key>
  <string>YOUR_PROJECT_NUMBER</string>
  <key>PLIST_VERSION</key>
  <string>1</string>
  <key>BUNDLE_ID</key>
  <string>com.yourcompany.inkscroller.dev</string>
  <key>PROJECT_ID</key>
  <string>your-firebase-project-id</string>
  <key>STORAGE_BUCKET</key>
  <string>your-firebase-project-id.appspot.com</string>
  <key>IS_ADS_ENABLED</key>
  <false/>
  <key>IS_ANALYTICS_ENABLED</key>
  <false/>
  <key>IS_APPINVITE_ENABLED</key>
  <true/>
  <key>IS_GCM_ENABLED</key>
  <true/>
  <key>IS_SIGNIN_ENABLED</key>
  <true/>
  <key>GOOGLE_APP_ID</key>
  <string>1:YOUR_PROJECT_NUMBER:ios:YOUR_APP_ID</string>
</dict>
</plist>
```

### Cómo obtenerlo

1. Firebase Console → seleccionar proyecto → ⚙️ Project settings
2. Tab **General** → sección **Your apps** → seleccionar la app iOS
3. Descargar `GoogleService-Info.plist`
4. Moverlo a `ios/config/<flavor>/GoogleService-Info.plist`

> El build phase de iOS copia el archivo correcto al bundle de Runner según flavor.

---

## Rutas excluidas por .gitignore

Las siguientes rutas están cubiertas en `.gitignore` para prevenir commits accidentales:

```
android/app/src/dev/google-services.json
android/app/src/staging/google-services.json
android/app/src/pro/google-services.json
android/app/google-services.json
ios/Runner/GoogleService-Info*.plist
ios/config/dev/GoogleService-Info.plist
ios/config/staging/GoogleService-Info.plist
ios/config/pro/GoogleService-Info.plist
android/*.jks
android/*.keystore
android/key.properties
```

---

## Bootstrap local y CI (dev / staging / pro)

### Artefactos requeridos para compilar/ejecutar

Estos archivos pueden ser requeridos por integraciones nativas de Firebase (y por Google Sign-In cuando se habilite), aunque **NO sean artefactos commiteables**:

- Android: `android/app/src/<flavor>/google-services.json`
- iOS: `ios/config/<flavor>/GoogleService-Info.plist`

### Flujo local (developer machine)

1. Obtener archivos reales por flavor desde:
   - Firebase Console (Project settings → Your apps), o
   - Secret store interno del equipo.
2. Guardarlos en las rutas esperadas por flavor (arriba).
3. Verificar que no se versionen (`git status` debe permanecer limpio para esos paths).

Si los archivos se guardan como variables base64, se pueden restaurar con:

```powershell
./scripts/restore_firebase_config.ps1 -Flavor staging
./scripts/restore_firebase_config.ps1 -Flavor all
```

En Linux/macOS:

```bash
scripts/restore_firebase_config.sh --flavor staging
scripts/restore_firebase_config.sh --flavor all
```

El script espera estas variables de entorno según flavor:

- Android: `GOOGLE_SERVICES_<FLAVOR>_BASE64`
- iOS: `GOOGLE_SERVICE_INFO_IOS_<FLAVOR>_BASE64`

Para restaurar `all`, deben existir las seis variables:

- `GOOGLE_SERVICES_DEV_BASE64`
- `GOOGLE_SERVICES_STAGING_BASE64`
- `GOOGLE_SERVICES_PRO_BASE64`
- `GOOGLE_SERVICE_INFO_IOS_DEV_BASE64`
- `GOOGLE_SERVICE_INFO_IOS_STAGING_BASE64`
- `GOOGLE_SERVICE_INFO_IOS_PRO_BASE64`

También permite restaurar solo una plataforma:

```powershell
./scripts/restore_firebase_config.ps1 -Flavor staging -AndroidOnly
./scripts/restore_firebase_config.ps1 -Flavor staging -IosOnly
```

```bash
scripts/restore_firebase_config.sh --flavor staging --android-only
scripts/restore_firebase_config.sh --flavor staging --ios-only
```

### Flujo CI (inyección desde base64)

En CI, los archivos se reconstruyen en runtime desde secrets base64 y se escriben en las mismas rutas esperadas:

- `GOOGLE_SERVICES_<FLAVOR>_BASE64` → `android/app/src/<flavor>/google-services.json`
- `GOOGLE_SERVICE_INFO_IOS_<FLAVOR>_BASE64` → `ios/config/<flavor>/GoogleService-Info.plist`

### Relación con `.dart-defines/firebase.json`

- `.dart-defines/firebase.json` puede contener configuración consumida por Flutter en Dart.
- Aun así, para integraciones nativas y futuro Google Sign-In, los archivos nativos de Firebase pueden seguir siendo obligatorios.
- `.dart-defines/firebase.json` permanece ignorado.
- `.dart-defines/firebase.example.json` permanece como template seguro para compartir estructura.

---

_Ver [`SECURITY_PUBLIC_READINESS.md`](../SECURITY_PUBLIC_READINESS.md) para instrucciones de inyección vía CI._
