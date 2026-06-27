# P0-F5 — Evidence: No Hardcoded Secrets Audit

> **Status**: ✅ CLOSED — 2026-04-09  
> **Checklist item**: 6.1 — No hay secrets ni API keys hardcodeadas en el código Dart  
> **Refs**: TASK-022 (#49)

---

## Summary

Exhaustive static audit of `lib/**/*.dart` confirms **no secrets, API keys, bearer tokens, or credentials are hardcoded** in Dart source files beyond known-safe Firebase configuration (documented and justified below).

---

## Audit Methodology

Full scan of every `.dart` file in `lib/` using the following patterns:

```bash
# 1. Google/Firebase API keys
rg -rn "REDACTED_FIREBASE_API_KEY[A-Za-z0-9_-]{33}" lib/ --glob "*.dart"

# 2. OpenAI / Stripe / generic secret keys
rg -rn '\bsk-[A-Za-z0-9]{20,}' lib/ --glob "*.dart"

# 3. GitHub tokens
rg -rn 'gh[poa]_[A-Za-z0-9]{36,}' lib/ --glob "*.dart"

# 4. AWS access keys
rg -rn 'AKIA[0-9A-Z]{16}' lib/ --glob "*.dart"

# 5. Slack tokens
rg -rn 'xox[baprs]-[0-9A-Za-z-]{8,}' lib/ --glob "*.dart"

# 6. SendGrid API keys
rg -rn 'SG\.[A-Za-z0-9_-]{22,}\.[A-Za-z0-9_-]{43,}' lib/ --glob "*.dart"

# 7. GitLab personal access tokens
rg -rn 'glpat-[A-Za-z0-9_-]{20,}' lib/ --glob "*.dart"

# 8. Hardcoded Bearer token values (not prefix)
rg -rn '[Bb]earer\s+[A-Za-z0-9+/=_-]{20,}' lib/ --glob "*.dart"

# 9. Hardcoded password assignments
rg -rn "password\s*=\s*['\"][^'\"]{3,}" lib/ --glob "*.dart"

# 10. Direct third-party API calls
rg -rn 'https?://api\.(mangadex|jikan)\.org' lib/ --glob "*.dart"

# 11. All HTTP URLs (full inventory)
rg -rn 'https?://' lib/ --glob "*.dart"
```

---

## Findings

### Pattern 1–9: No secrets found

| Pattern | Result |
|---------|--------|
| `sk-...` (OpenAI/Stripe) | ✅ 0 matches |
| `gh[poa]_...` (GitHub tokens) | ✅ 0 matches |
| `AKIA...` (AWS keys) | ✅ 0 matches |
| `xox[baprs]-...` (Slack tokens) | ✅ 0 matches |
| `SG....` (SendGrid keys) | ✅ 0 matches |
| `glpat-...` (GitLab tokens) | ✅ 0 matches |
| `Bearer <value>` (hardcoded) | ✅ 0 matches (see note) |
| `password = "..."` | ✅ 0 matches |

### Pattern 10: No direct third-party API calls

```
rg 'https?://api\.(mangadex|jikan)\.org' lib/ --glob "*.dart"
→ 0 matches
```

### Pattern 11: Full HTTP URL inventory (6 URLs total)

```text
lib/core/config/app_environment.dart:
  - 'http://127.0.0.1:8000'        ← localhost dev
  - 'http://10.0.2.2:8000'         ← Android emulator loopback
  - 'https://api.dev.inkscroller.devdigi.dev'  ← dev backend
  - 'https://api.stg.inkscroller.devdigi.dev'  ← staging backend
  - 'https://api.inkscroller.devdigi.dev'      ← pro backend
  - 'http://localhost:8000'         ← localhost fallback
```

All 6 URLs are **InkScroller backend endpoints only**. No third-party URLs.

---

## Known-Safe: Firebase API Keys

**File**: `lib/firebase_options.dart`

**Finding**: 6 Firebase API keys (`REDACTED_FIREBASE_API_KEY...` pattern), 2 per flavor (Android + iOS).

**Risk assessment**: **KNOWN-SAFE — no action required.**

Firebase mobile API keys are **by design public** and embedded in the compiled binary:

> "Unlike how API keys are typically used, API keys for Firebase services are not used to control access to backend resources; that can only be done with Firebase Security Rules. For this reason, Firebase API keys can safely be committed to version control or even embedded publicly."  
> — Firebase documentation: https://firebase.google.com/docs/projects/api-keys

**Why they are safe:**
1. **Cannot access Firebase resources without Security Rules authorization** — the key alone is insufficient.
2. **Restricted by platform**: Android keys require SHA-1 certificate fingerprint; iOS keys require bundle ID. A key from a leaked APK/IPA cannot be used by an unauthorized app.
3. **Already in the compiled binary**: Anyone who downloads the app can extract these keys. Their security model does not depend on them being secret.
4. **Scoped per flavor**: `dev`, `staging`, and `pro` each have distinct keys pointing to separate Firebase projects.

**Location**: Confirmed ONLY in `lib/firebase_options.dart` — not scattered across the codebase.

**Pre-public-release action**: Rotate all keys before making the repository public (see `SECURITY_PUBLIC_READINESS.md §2`).

---

## Bearer Token Note

`lib/core/network/dio_client.dart` contains the string `'Bearer '` (with trailing space). This is a **static HTTP Authorization header prefix**, not a token value. The actual token is:

```dart
options.headers['Authorization'] = 'Bearer $token';
```

Where `$token` is obtained at runtime via `FirebaseAuth.instance.currentUser?.getIdToken()`. No token value is ever hardcoded.

---

## `.env.example` Audit

**File**: `.env.example`  
**Result**: Contains only public backend custom-domain examples (`https://api*.inkscroller.devdigi.dev`).
No real API keys, tokens, or credentials present. ✅

---

## Formal Test Evidence

**Test file**: `test/core/compliance/p0_f5_secrets_audit_test.dart`  
**Tests**: 12/12 PASS

| Test | Result |
|------|--------|
| `no OpenAI/Anthropic/Stripe secret keys (sk-...)` | ✅ PASS |
| `no GitHub personal access tokens (ghp_\|gho_\|ghs_)` | ✅ PASS |
| `no AWS access keys (AKIA...)` | ✅ PASS |
| `no Slack tokens (xox[baprs]-)` | ✅ PASS |
| `no SendGrid API keys (SG.)` | ✅ PASS |
| `no GitLab personal access tokens (glpat-)` | ✅ PASS |
| `no hardcoded Bearer token values` | ✅ PASS |
| `no hardcoded password assignments` | ✅ PASS |
| `no direct calls to third-party APIs (mangadex, jikan)` | ✅ PASS |
| `Firebase apiKeys in firebase_options.dart are known-safe` | ✅ PASS |
| `all hardcoded HTTP URLs are InkScroller backend or localhost` | ✅ PASS |
| `.env.example contains only placeholder values` | ✅ PASS |

**Full suite**: 151/151 tests PASS  
**`fvm flutter analyze`**: No issues found

---

## Decision

**No secrets found requiring remediation.** The single finding (Firebase API keys) is documented as known-safe per Firebase architecture guidelines. Pre-publication rotation is noted as a pre-release action item in `SECURITY_PUBLIC_READINESS.md §2`.

---

_Audit date: 2026-04-09_  
_Auditor: automated (this session) + static analysis_
