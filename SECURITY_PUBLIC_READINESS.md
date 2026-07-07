# Security Public Readiness — InkScroller Flutter

> Documento de referencia para evaluar qué está listo para ser público y qué requiere acción antes de publicar el repositorio.

---

## 1. Clasificación: public-safe vs private-only

### ✅ Public-safe (puede ir en repo público sin cambios)

| Archivo / Artefacto | Razón |
|---------------------|-------|
| `lib/**` (código fuente Dart) | No contiene secrets hardcodeados — URLs via `--dart-define` |
| `pubspec.yaml` / `pubspec.lock` | Dependencias públicas, sin tokens |
| `analysis_options.yaml` | Configuración de linting |
| `test/` / `integration_test/` | Tests sin fixtures sensibles |
| `docs/` (arquitectura, PRD, API, CI) | Documentación técnica |
| `assets/` | Assets estáticos de la app |
| `.run/` | Run configs — no contienen secrets reales |
| `README.md` | Doc pública |
| `firebase.json` | Config de proyecto Firebase (IDs de proyecto sí son públicos por diseño de Firebase) |

### 🔴 Private-only / Requiere acción antes de publicar

| Archivo / Artefacto | Riesgo | Acción requerida |
|---------------------|--------|------------------|
| `android/app/src/*/google-services.json` | API keys de Firebase (aunque limitadas por reglas de seguridad, son rastreables) | Nunca commitear — usar CI injection |
| `ios/config/*/GoogleService-Info.plist` | Equivalente iOS de Firebase config | Nunca commitear — usar CI injection |
| `android/app/*.jks` / `*.keystore` | Keystore de firma de la app | Nunca commitear — usar GitHub Secrets |
| `android/key.properties` | Contraseña del keystore + alias | Nunca commitear — usar CI injection |
| `.dart-defines/*.json` | Podría contener URLs o flags internos | Excluido por `.gitignore` |
| Cualquier archivo con API keys hardcodeadas | Exposición de credenciales | Auditá `lib/` antes de publicar |

---

## 2. Política de rotación antes de hacer público

Antes de cambiar la visibilidad del repo a **público**, ejecutar en este orden:

1. **Rotar Firebase API Keys** en Firebase Console → Project Settings → API Keys
   - Regenerar las keys de cada flavor (dev / staging / pro)
   - Actualizar los `google-services.json` y `GoogleService-Info.plist` en el sistema de secretos de CI/CD
2. **Rotar el keystore de firma** (si alguna vez se commiteó accidentalmente)
   - Generar nuevo keystore
   - Actualizar Google Play Console con el nuevo certificado
   - Actualizar `KEYSTORE_BASE64` en GitHub Secrets
3. **Auditar el historial de git** con `git log -S "<string-sospechosa>"` para detectar secrets commiteados en el pasado
   - Si se encuentran: usar `git filter-repo` para purgar el historial ANTES de hacer público
4. **Verificar Firebase Security Rules** — asegurar que las reglas de Firestore/Auth no dependan de oscuridad

> **Regla de oro**: Si un secret fue commiteado en algún momento del historial, asumirlo como comprometido y rotarlo. Hacer público el repo solo expone lo que ya fue.

---

## 3. Instrucciones de CI: inyección de secrets en runtime

### Firebase config (google-services.json / GoogleService-Info.plist)

Los archivos de configuración de Firebase **no se commitean**. Se inyectan en CI desde GitHub Secrets codificados en base64.

#### Paso 1 — Codificar el archivo (se hace una sola vez, localmente)

```bash
# Android
base64 -i android/app/src/dev/google-services.json | pbcopy

# iOS
base64 -i ios/config/dev/GoogleService-Info.plist | pbcopy
```

#### Paso 2 — Guardar en GitHub Secrets

| Secret Name | Contenido |
|-------------|-----------|
| `GOOGLE_SERVICES_DEV_BASE64` | base64 del `google-services.json` dev |
| `GOOGLE_SERVICES_STAGING_BASE64` | base64 del `google-services.json` staging |
| `GOOGLE_SERVICES_PRO_BASE64` | base64 del `google-services.json` pro |
| `GOOGLE_SERVICE_INFO_IOS_DEV_BASE64` | base64 del `GoogleService-Info.plist` dev |
| `GOOGLE_SERVICE_INFO_IOS_STAGING_BASE64` | base64 del `GoogleService-Info.plist` staging |
| `GOOGLE_SERVICE_INFO_IOS_PRO_BASE64` | base64 del `GoogleService-Info.plist` pro |
| `KEYSTORE_BASE64` | base64 del archivo `.jks` |
| `KEYSTORE_PASSWORD` | Contraseña del keystore |
| `KEY_ALIAS` | Alias de la key |
| `KEY_PASSWORD` | Contraseña de la key |

#### Paso 3 — Reconstruir en el workflow de CI

```yaml
# .github/workflows/ci.yml (fragmento)
- name: Restore Firebase config (Android dev)
  run: |
    echo "${{ secrets.GOOGLE_SERVICES_DEV_BASE64 }}" | base64 --decode \
      > android/app/src/dev/google-services.json

- name: Restore Firebase config (iOS dev)
  run: |
    echo "${{ secrets.GOOGLE_SERVICE_INFO_IOS_DEV_BASE64 }}" | base64 --decode \
      > ios/config/dev/GoogleService-Info.plist

- name: Restore keystore
  run: |
    echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 --decode > android/app/release.jks
    cat > android/key.properties <<EOF
    storePassword=${{ secrets.KEYSTORE_PASSWORD }}
    keyPassword=${{ secrets.KEY_PASSWORD }}
    keyAlias=${{ secrets.KEY_ALIAS }}
    storeFile=../release.jks
    EOF
```

---

## 4. Checklist pre-publicación (portfolio/public release)

Ejecutar esta checklist antes de cambiar el repo a público:

### Secretos y configuración

- [ ] `android/app/src/*/google-services.json` **NO está commiteado** en ningún branch
- [ ] `ios/config/*/GoogleService-Info.plist` **NO está commiteado** en ningún branch
- [ ] `android/*.jks` / `android/*.keystore` / `android/app/*.jks` / `android/app/*.keystore` **NO está commiteado**
- [ ] `android/key.properties` **NO está commiteado**
- [ ] `.dart-defines/` **NO está commiteado** (cubierto por `.gitignore`)
- [ ] `.dart-defines/firebase.example.json` se mantiene como template seguro (sin valores reales)
- [ ] No hay API keys hardcodeadas en `lib/` — verificar con: `grep -r "AIza\|sk-\|Bearer " lib/`
- [ ] Historial de git auditado con `git log --all --full-history -- "**google-services*"`

### Firebase Security Rules

- [ ] Reglas de Firestore revisadas — no confían solo en autenticación por UID sin validación
- [ ] Reglas de Storage revisadas (si aplica)
- [ ] Firebase Auth providers configurados correctamente (no permitir anonymous sin control)

### CI/CD

- [ ] GitHub Actions workflows funcionan con secrets inyectados (sin archivos locales)
- [ ] Ningún workflow loguea variables de entorno con `echo $SECRET`
- [ ] `GOOGLE_SERVICES_*_BASE64` secrets están cargados en GitHub → Settings → Secrets

### Documentación

- [ ] README.md menciona que `google-services.json` debe obtenerse de Firebase Console
- [ ] `.env.example` (si aplica) no tiene valores reales
- [ ] `CONTRIBUTING.md` o sección equivalente explica el setup de secrets para contributors

### Licencia y atribución

- [ ] Licencia definida en `LICENSE` (actualmente TBD en README)
- [ ] Atribución a MangaDex y Jikan presente en README ✅ (ya existe)
- [ ] Verificar compliance con ToS de MangaDex antes de hacer público

### Código

- [ ] No hay `TODO: remove before release` o `FIXME: hardcoded` en el código
- [ ] No hay URLs de staging/dev hardcodeadas fuera de los entry points de flavor
- [ ] Versión en `pubspec.yaml` refleja el estado real del proyecto

---

## 5. Firebase example config (estructura sin valores reales)

Ver [`docs/firebase-config-example.md`](docs/firebase-config-example.md) para la estructura exacta de `google-services.json` y `GoogleService-Info.plist` que se espera en cada ruta.

### Nota sobre FlutterFire + nativo

Aunque `.dart-defines/firebase.json` configure parte del runtime en Dart, para integraciones nativas actuales/futuras (por ejemplo Google Sign-In) pueden seguir siendo requeridos `google-services.json` y `GoogleService-Info.plist` por flavor.

---

_Última actualización: 2026-04-08 — baseline inicial para public-ready mode_
