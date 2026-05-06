# Android Studio setup

This project uses a **shared + local** setup model.

- **Shared in git** → `.run/` run configurations
- **Local per machine** → `android/local.properties`

Do **not** commit `android/local.properties`. It contains machine-specific SDK paths.

## Shared run configurations

The repo includes these shared Android Studio / IntelliJ configs:

- `Flutter Dev Emulator`
- `Flutter Dev Physical`
- `Flutter Staging Emulator`
- `Flutter Staging Physical`
- `Flutter Pro Emulator`
- `Flutter Pro Physical`

They live under `.run/`, so Android Studio can detect them when the project is opened.

## Local bootstrap

From the project root:

```powershell
pwsh -File .\scripts\bootstrap_android_studio.ps1
```

Optional explicit Android SDK path:

```powershell
pwsh -File .\scripts\bootstrap_android_studio.ps1 -AndroidSdkPath "C:\Users\<user>\AppData\Local\Android\sdk"
```

The script will:

1. resolve `fvm`
2. run `fvm use --force`
3. resolve `.fvm\flutter_sdk`
4. detect the Android SDK path
5. generate `android/local.properties`

## `API_BASE_URL` default used by shared configs

### Emulator configs

Use:

```text
--dart-define=API_BASE_URL=http://10.0.2.2:8000
--dart-define=API_FALLBACK_URL=http://127.0.0.1:8000
```

### Physical-device configs

Use:

```text
--dart-define=API_BASE_URL=http://192.168.1.38:8000
```

The physical-device variant uses the **direct LAN IP** of the development machine.
The backend must be started with `--host 0.0.0.0` so it accepts LAN connections.

> ⚠️ If the dev machine's LAN IP changes, update the three Physical `.run` files.

### Why both exist

Emulator and physical device do **not** resolve localhost the same way. Keeping
separate configs removes ambiguity and avoids accidental misconfiguration.

### Why LAN IP instead of `adb reverse`

`adb reverse` tunnels the phone's localhost to the host — cleaner but requires
the tunnel to be active at all times. Direct LAN IP was chosen for simplicity:
start the backend, run Flutter, done — no tunnel to manage.

If you run on:

- **physical device** → LAN IP (`http://192.168.1.38:8000`) — see [PHYSICAL_DEVICE.md](PHYSICAL_DEVICE.md)
- **emulator** → `http://10.0.2.2:8000`
- **desktop** → `http://127.0.0.1:8000`
- **remote backend** → use that backend URL

## Physical Android device note

See [PHYSICAL_DEVICE.md](PHYSICAL_DEVICE.md) for the full setup guide, including
`adb`, `scrcpy`, the recommended workflow, and troubleshooting.

## If PowerShell cannot find `fvm`

Add this to the current session:

```powershell
$env:Path += ';C:\Users\<user>\AppData\Local\Pub\Cache\bin'
```

For a permanent fix, add that folder to your Windows user PATH.
