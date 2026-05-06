import '../../../domain/entities/manga.dart';

/// Removes duplicate [Manga] entries by [Manga.id], keeping the last occurrence.
///
/// Uses map semantics where each [manga.id] maps to its value, so repeated IDs
/// are overwritten — resulting in the last encountered instance being retained.
/// Order of unique entries reflects the insertion order of the last occurrence.
List<Manga> dedupeMangas(List<Manga> source) {
  return {for (final manga in source) manga.id: manga}.values.toList();
}
