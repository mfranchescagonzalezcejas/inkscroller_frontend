# Running on a Physical Android Device

This document covers everything you need to run InkScroller against the local backend on a USB-connected Android device.

---

## Prerequisites

| Tool | Required | Purpose |
|------|----------|---------|
| `adb` | ✅ Yes | USB device detection & communication |
| `scrcpy` | Optional | Low-latency screen mirroring — no root required |
| `fvm` | ✅ Yes | Flutter version manager — all commands use `fvm flutter` |

### Install adb (Linux)

```bash
sudo apt install adb
```

### Install scrcpy (Linux)

```bash
sudo apt install scrcpy
```

---

## How the backend is reachable

The backend runs with:

```bash
uvicorn main:app --host 0.0.0.0 --port 8000
```

`0.0.0.0` means it accepts connections from any interface on the network — including your phone over LAN.

The physical `.run` configs use the **direct LAN IP** of the development machine:

```
API_BASE_URL=http://192.168.1.38:8000
```

> ⚠️ If your LAN IP changes (router reassignment, different network), update the `.run` files.  
> The IP is hardcoded — this is the tradeoff for simplicity over portability.

---

## Shared .run configurations

The repo includes ready-to-use Android Studio / IntelliJ run configs under `.run/`:

| Config name | Flavor | API_BASE_URL |
|-------------|--------|--------------|
| `Flutter Dev Physical` | `dev` | `http://192.168.1.38:8000` |
| `Flutter Staging Physical` | `staging` | `http://192.168.1.38:8000` |
| `Flutter Pro Physical` | `pro` | `http://192.168.1.38:8000` |
| `Flutter Dev Emulator` | `dev` | `http://10.0.2.2:8000` |
| `Flutter Staging Emulator` | `staging` | `http://10.0.2.2:8000` |
| `Flutter Pro Emulator` | `pro` | `http://10.0.2.2:8000` |

> Emulator configs are unchanged — they use `10.0.2.2` (the Android emulator's alias for host localhost).

---

## Manual command

If you prefer running from the terminal instead of the IDE:

```bash
fvm flutter run --flavor dev \
  --dart-define=API_BASE_URL=http://192.168.1.38:8000 \
  -t lib/main_dev.dart
```

For staging:

```bash
fvm flutter run --flavor staging \
  --dart-define=API_BASE_URL=http://192.168.1.38:8000 \
  -t lib/main_staging.dart
```

---

## Recommended workflow with scrcpy

Open two terminal tabs:

**Tab 1 — Screen mirror:**

```bash
scrcpy
```

**Tab 2 — Flutter with hot reload:**

```bash
fvm flutter run --flavor dev \
  --dart-define=API_BASE_URL=http://192.168.1.38:8000 \
  -t lib/main_dev.dart
```

`scrcpy` shows the device screen on your machine in real time. Combined with Flutter's hot reload (`r` in the terminal), this is a tight feedback loop without needing to pick up the phone.

---

## Why LAN IP instead of `adb reverse`

`adb reverse tcp:8000 tcp:8000` tunnels the phone's `localhost:8000` to the host machine. It's clean but requires `adb` to be connected and the tunnel active at all times.

**LAN IP was chosen because:**

- `adb` wasn't installed when the Physical configs were first set up
- LAN is simpler: start the backend, run Flutter, done — no tunnel to manage

**Tradeoff:** The IP is hardcoded in `.run` files. If the dev machine's LAN IP changes, update the three Physical config files.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `SocketException: Connection refused` | Backend not running | Start backend with `--host 0.0.0.0` |
| `SocketException: Network unreachable` | Wrong LAN IP | Check `ip addr` / `ifconfig` and update `.run` configs |
| `adb: no devices/emulators found` | USB debugging off | Enable USB debugging in developer options |
| scrcpy shows blank screen | Device not authorized | Accept the authorization dialog on the device |
| App builds but hits wrong API | Emulator config used on device | Make sure you're running a `Physical` config |

---

## Related

- [ANDROID_STUDIO_SETUP.md](ANDROID_STUDIO_SETUP.md) — IDE setup and bootstrap script
- [API_INTEGRATION.md](API_INTEGRATION.md) — API layer architecture
