import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_reading_preferences.dart';

/// Domain contract for authenticated user reading preferences.
abstract class PreferencesRepository {
  /// Fetches current preferences from the backend.
  Future<Either<Failure, UserReadingPreferences>> getPreferences();

  /// Updates one or more preference fields and returns the stored preferences.
  Future<Either<Failure, UserReadingPreferences>> updatePreferences({
    String? defaultReaderMode,
    String? defaultLanguage,
  });
}
