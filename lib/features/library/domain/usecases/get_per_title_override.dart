import '../../domain/entities/reading_preferences.dart';
import '../../domain/repositories/per_title_override_repository.dart';

/// Retrieves a per-title reader mode override for a specific manga.
class GetPerTitleOverride {
  final PerTitleOverrideRepository repository;

  const GetPerTitleOverride(this.repository);

  Future<PerTitleOverride?> call(String mangaId) async {
    return repository.getOverride(mangaId);
  }
}
