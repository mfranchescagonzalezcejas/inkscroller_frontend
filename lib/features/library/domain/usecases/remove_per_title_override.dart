import '../../domain/repositories/per_title_override_repository.dart';

/// Removes a per-title reader mode override.
class RemovePerTitleOverride {
  final PerTitleOverrideRepository repository;

  const RemovePerTitleOverride(this.repository);

  Future<void> call(String mangaId) async {
    await repository.removeOverride(mangaId);
  }
}
