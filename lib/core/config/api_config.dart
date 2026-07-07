import 'app_environment.dart';
import '../../flavors/flavor_config.dart';

/// Centralizes API-level configuration derived from the active [FlavorConfig].
///
/// Widgets and data-layer classes should read from here rather than accessing
/// [FlavorConfig] directly, keeping API concerns isolated.
class ApiConfig {
  /// The base URL for all HTTP requests, resolved from the current [FlavorConfig].
  static String get baseUrl => FlavorConfig.instance.apiBaseUrl;

  /// Ordered base URL candidates for local fallback retries.
  static List<String> get baseUrlCandidates {
    final candidates = <String>[];

    void addCandidate(String value) {
      if (!candidates.contains(value)) {
        candidates.add(value);
      }
    }

    addCandidate(baseUrl);
    for (final candidate in AppEnvironment.apiBaseUrlCandidates) {
      addCandidate(candidate);
    }

    return candidates;
  }
}
