import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Runtime app version data resolved from platform package metadata.
class AppVersionInfo {
  /// Marketing version (e.g. 0.5.0).
  final String version;

  /// Internal build number (e.g. 21).
  final String buildNumber;

  /// Creates immutable app version info.
  const AppVersionInfo({required this.version, required this.buildNumber});
}

/// Provides the current app version/build from platform metadata.
///
/// Falls back to `-` values when package info is unavailable (e.g. some tests).
final appVersionProvider = FutureProvider<AppVersionInfo>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return AppVersionInfo(version: info.version, buildNumber: info.buildNumber);
  } on Exception {
    return const AppVersionInfo(version: '-', buildNumber: '-');
  }
});
