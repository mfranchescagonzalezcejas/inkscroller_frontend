import 'dart:io';

import 'package:flutter/foundation.dart';

/// Compile-time environment helpers used by the flavor entry points.
///
/// Values are provided with `--dart-define` and fall back to the current local
/// backend for developer convenience.
abstract final class AppEnvironment {
  /// Default backend URL used when no `--dart-define=API_BASE_URL` is provided.
  ///
  /// Points to localhost so it works across developer machines without leaking
  /// any internal network addresses. Override with a LAN IP or remote URL via
  /// `--dart-define=API_BASE_URL=http://<host>:<port>` or a `launch.json` entry.
  static const String localBaseUrl = 'http://127.0.0.1:8000';

  /// Android emulator loopback alias for the host machine.
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:8000';

  /// Backend API URLs by environment (deployed on devdigi.dev).
  ///
  /// These are the production endpoints. For local development, use `--dart-define`
  /// or the default localhost fallback.
  ///
  ///   dev:     https://api.dev.inkscroller.devdigi.dev
  ///   staging: https://api.stg.inkscroller.devdigi.dev
  ///   pro:     https://api.inkscroller.devdigi.dev
  static const String cloudRunBaseUrl = 'https://api.dev.inkscroller.devdigi.dev';

  /// Backend base URL for the current app run.
  ///
  /// Override with `--dart-define=API_BASE_URL=http://<host>:<port>`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: localBaseUrl,
  );

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

    addCandidate(apiBaseUrl);
    addCandidate(apiFallbackBaseUrl);

    if (!kIsWeb && Platform.isAndroid) {
      addCandidate(androidEmulatorBaseUrl);
    }

    addCandidate(localBaseUrl);
    addCandidate('http://localhost:8000');

    return candidates;
  }
}
