import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/failures.dart';
import '../../domain/repositories/settings_cache_repository.dart';

/// SharedPreferences-backed implementation for settings cache operations.
class SettingsCacheRepositoryImpl implements SettingsCacheRepository {
  /// Creates repository with persisted key-value storage dependency.
  const SettingsCacheRepositoryImpl({required SharedPreferences sharedPreferences})
    : _sharedPreferences = sharedPreferences;

  static const String _libraryPrefix = 'library.';

  final SharedPreferences _sharedPreferences;

  @override
  Future<Either<Failure, void>> clearLibraryCache() async {
    try {
      final Iterable<String> keys = _sharedPreferences.getKeys().where(
        (key) => key.startsWith(_libraryPrefix),
      );

      for (final String key in keys) {
        await _sharedPreferences.remove(key);
      }

      return const Right(null);
    } on Exception catch (error) {
      return Left(CacheFailure(message: error.toString()));
    }
  }

  @override
  int getLibraryCacheSize() {
    final Iterable<String> keys = _sharedPreferences.getKeys().where(
      (key) => key.startsWith(_libraryPrefix),
    );

    int totalBytes = 0;
    for (final String key in keys) {
      final String? value = _sharedPreferences.getString(key);
      if (value != null) {
        totalBytes += value.length;
      }
    }

    return totalBytes;
  }
}
