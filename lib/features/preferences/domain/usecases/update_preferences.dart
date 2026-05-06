import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_reading_preferences.dart';
import '../repositories/preferences_repository.dart';

/// Updates the authenticated user's reading preferences.
class UpdatePreferences {
  final PreferencesRepository repository;

  const UpdatePreferences(this.repository);

  /// Executes the update.
  Future<Either<Failure, UserReadingPreferences>> call({
    String? defaultReaderMode,
    String? defaultLanguage,
  }) {
    return repository.updatePreferences(
      defaultReaderMode: defaultReaderMode,
      defaultLanguage: defaultLanguage,
    );
  }
}
