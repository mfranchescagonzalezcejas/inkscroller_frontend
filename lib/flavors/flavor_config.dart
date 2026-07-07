/// Application build flavors used to differentiate dev, staging, and production environments.
enum Flavor{
  /// Local development build — points to the pre-production API and shows a red debug banner.
  dev,
  /// Staging build — points to the production API and shows an orange debug banner.
  staging,
  /// Production build — no debug banner, uses the production API.
  pro
}

/// Singleton that holds environment-specific configuration for the current app flavor.
///
/// Must be initialized once at startup (in a `main_*.dart` entry point) before any other
/// code reads [instance]. Attempting to access [instance] before initialization throws.
class FlavorConfig {
  /// The active build flavor.
  final Flavor flavor;

  /// Base URL of the backend API for this flavor.
  final String apiBaseUrl;

  /// Human-readable app name shown in the UI (e.g., in the app bar title).
  final String name;

  static FlavorConfig? _instance;

  FlavorConfig._({required this.flavor, required this.apiBaseUrl, required this.name});

  /// Initializes the singleton with the given [flavor], [apiBaseUrl], and [name].
  ///
  /// Only the first call has any effect; subsequent calls return the existing instance unchanged.
  factory FlavorConfig({required Flavor flavor, required String apiBaseUrl, required String name}) {
    _instance ??= FlavorConfig._(flavor: flavor, apiBaseUrl: apiBaseUrl, name: name);
    return _instance!;
  }

  /// Returns the current [FlavorConfig] singleton.
  ///
  /// Throws if [FlavorConfig] has not been initialized yet.
  static FlavorConfig get instance {
    if(_instance == null) {
      throw Exception('FlavorConfig not initialized');
    }
    return _instance!;
  }

  /// Returns `true` when the active flavor is [Flavor.dev].
  static bool isDev() => instance.flavor == Flavor.dev;

  /// Returns `true` when the active flavor is [Flavor.staging].
  static bool isStaging() => instance.flavor == Flavor.staging;

  /// Returns `true` when the active flavor is [Flavor.pro].
  static bool isPro() => instance.flavor == Flavor.pro;
}
