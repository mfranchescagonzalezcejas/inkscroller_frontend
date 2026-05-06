import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';

/// Domain contract for settings cache maintenance operations.
abstract class SettingsCacheRepository {
  /// Clears all persisted `library.*` cache entries.
  Future<Either<Failure, void>> clearLibraryCache();

  /// Returns the total byte size for persisted `library.*` cache entries.
  int getLibraryCacheSize();
}
