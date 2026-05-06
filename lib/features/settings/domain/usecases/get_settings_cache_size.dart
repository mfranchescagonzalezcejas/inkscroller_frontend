import '../repositories/settings_cache_repository.dart';

/// Use case to obtain the total persisted library cache size.
class GetSettingsCacheSize {
  /// Creates the use case with its repository dependency.
  const GetSettingsCacheSize(this._repository);

  final SettingsCacheRepository _repository;

  /// Returns cache size in bytes.
  int call() {
    return _repository.getLibraryCacheSize();
  }
}
