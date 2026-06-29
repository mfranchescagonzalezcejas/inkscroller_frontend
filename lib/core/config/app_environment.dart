import 'dart:io';

import 'package:flutter/foundation.dart';

/// Compile-time environment helpers used by the flavor entry points.
///
/// Values are provided with `--dart-define`. When `API_BASE_URL` is omitted,
/// each flavor uses its cloud backend custom domain by default.
abstract final class AppEnvironment {
  /// Local backend URL for developer machines.
  static const String localBaseUrl = 'http://127.0.0.1:8000';

  /// Android emulator loopback alias for the host machine.
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:8000';

  /// Dev backend custom domain.
  static const String devCloudBaseUrl =
      'https://api.dev.inkscroller.devdigi.dev';

  /// Staging backend custom domain.
  static const String stagingCloudBaseUrl =
      'https://api.stg.inkscroller.devdigi.dev';

  /// Production backend custom domain.
  static const String proCloudBaseUrl = 'https://api.inkscroller.devdigi.dev';

  /// Explicit backend base URL override for the current app run.
  ///
  /// Override with `--dart-define=API_BASE_URL=http://<host>:<port>`.
  static const String apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );

  /// Dev backend base URL, preferring the explicit `API_BASE_URL` override.
  static String get devApiBaseUrl => _resolveApiBaseUrl(devCloudBaseUrl);

  /// Staging backend base URL, preferring the explicit `API_BASE_URL` override.
  static String get stagingApiBaseUrl =>
      _resolveApiBaseUrl(stagingCloudBaseUrl);

  /// Production backend base URL, preferring the explicit `API_BASE_URL` override.
  static String get proApiBaseUrl => _resolveApiBaseUrl(proCloudBaseUrl);

  /// Backward-compatible default backend URL for callers that are not flavor-aware.
  static String get apiBaseUrl => devApiBaseUrl;

  /// Optional fallback backend URL for local development.
  ///
  /// Useful when the same build should work on Android emulator and on a
  /// tethered physical device (for example with `adb reverse tcp:8000 tcp:8000`).
  static const String apiFallbackBaseUrl = String.fromEnvironment(
    'API_FALLBACK_URL',
  );

  /// Ordered candidate base URLs used by the local network fallback strategy.
  static List<String> get apiBaseUrlCandidates {
    final candidates = <String>[];

    void addCandidate(String value) {
      final normalized = value.trim();
      if (normalized.isEmpty || candidates.contains(normalized)) {
        return;
      }

      candidates.add(normalized);
    }

    addCandidate(apiBaseUrlOverride);
    addCandidate(apiFallbackBaseUrl);

    if (!kIsWeb && Platform.isAndroid) {
      addCandidate(androidEmulatorBaseUrl);
    }

    addCandidate(localBaseUrl);
    addCandidate('http://localhost:8000');

    return candidates;
  }

  /// Whether the app is running in E2E test mode.
  ///
  /// Enable with `--dart-define=E2E=true` at compile time.
  /// When `false` (default), the app behaves identically to a normal run.
  static const bool kIsE2E = bool.fromEnvironment('E2E', defaultValue: false);

  static String _resolveApiBaseUrl(String defaultBaseUrl) {
    final normalizedOverride = apiBaseUrlOverride.trim();
    if (normalizedOverride.isNotEmpty) {
      return normalizedOverride;
    }

    return defaultBaseUrl;
  }
}
