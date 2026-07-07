import 'package:inkscroller_flutter/core/config/app_environment.dart';

import 'core/constants/app_constants.dart';
import 'main_common.dart';
import 'flavors/flavor_config.dart';

/// Entry point for the **dev** flavor.
///
/// Supports E2E test mode via compile-time flags:
/// - `--dart-define=E2E=true` — enables E2E mode (asserts dev flavor is used).
/// - `--dart-define=FIREBASE_WEB_API_KEY=<key>` — Firebase Web API key for
///   test cleanup via the Auth REST API.
///
/// Example:
/// ```bash
/// fvm flutter run --dart-define=E2E=true \
///   --dart-define=FIREBASE_WEB_API_KEY=AIza... \
///   -t lib/main_dev.dart
/// ```
Future<void> main() async {
  await mainCommon(
    flavor: Flavor.dev,
    apiBaseUrl: AppEnvironment.devApiBaseUrl,
    name: AppConstants.appName,
  );
}
