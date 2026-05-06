import '../../domain/entities/reading_preferences.dart';
import '../../domain/repositories/per_title_override_repository.dart';

/// Saves or updates a per-title reader mode override.
class SavePerTitleOverride {
  final PerTitleOverrideRepository repository;

  const SavePerTitleOverride(this.repository);

  Future<void> call(PerTitleOverride override) async {
    await repository.saveOverride(override);
  }
}
