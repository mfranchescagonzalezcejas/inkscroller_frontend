import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/failures.dart';
import '../../domain/usecases/clear_settings_cache.dart';
import '../../domain/usecases/get_settings_cache_size.dart';

/// Small controller for settings actions related to cached library data.
class SettingsCacheController {
  const SettingsCacheController({
    required this.clearSettingsCache,
    required this.getSettingsCacheSize,
  });

  final ClearSettingsCache clearSettingsCache;
  final GetSettingsCacheSize getSettingsCacheSize;

  /// Clears all persisted library cache entries.
  ///
  /// Returns [Right(null)] on success or [Left(Failure)] on error.
  Future<Either<Failure, void>> clearLibraryCache() async {
    return clearSettingsCache();
  }

  /// Returns total byte size of all `library.*` cache entries in SharedPreferences.
  int getCacheSize() {
    return getSettingsCacheSize();
  }
}

/// Provides cache maintenance actions for the settings screen.
final settingsCacheControllerProvider = Provider<SettingsCacheController>((
  ref,
) {
  return SettingsCacheController(
    clearSettingsCache: sl<ClearSettingsCache>(),
    getSettingsCacheSize: sl<GetSettingsCacheSize>(),
  );
});

/// Formatted cache size string (e.g. "12.4 KB", "1.2 MB").
final cacheSizeProvider = Provider<String>((ref) {
  final controller = ref.watch(settingsCacheControllerProvider);
  final bytes = controller.getCacheSize();
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / 1048576).toStringAsFixed(1)} MB';
});
