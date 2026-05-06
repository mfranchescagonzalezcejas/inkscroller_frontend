import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_reading_preferences.dart';
import '../repositories/preferences_repository.dart';

/// Retrieves the authenticated user's reading preferences.
class GetPreferences {
  final PreferencesRepository repository;

  const GetPreferences(this.repository);

  /// Executes the fetch.
  Future<Either<Failure, UserReadingPreferences>> call() {
    return repository.getPreferences();
  }
}
