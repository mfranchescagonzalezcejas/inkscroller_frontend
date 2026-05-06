import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/settings_cache_repository.dart';

/// Use case to clear persisted library cache entries from settings.
class ClearSettingsCache {
  /// Creates the use case with its repository dependency.
  const ClearSettingsCache(this._repository);

  final SettingsCacheRepository _repository;

  /// Executes cache removal.
  Future<Either<Failure, void>> call() {
    return _repository.clearLibraryCache();
  }
}
