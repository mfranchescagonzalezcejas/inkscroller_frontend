import '../models/chapter_model.dart';
import '../models/manga_model.dart';

/// Contract for local persistence of library payloads.
///
/// Stores and retrieves cacheable DTOs with TTL-aware reads.
abstract class LibraryLocalDataSource {
  /// Returns a cached manga page when present and not expired.
  Future<List<MangaModel>?> getCachedMangaList({
    required int limit,
    required int offset,
    Map<String, String>? order,
    String? genre,
    String? contentRating,
    List<String>? demographics,
    required Duration maxAge,
  });

  /// Persists a manga page cache entry.
  Future<void> cacheMangaList({
    required int limit,
    required int offset,
    Map<String, String>? order,
    String? genre,
    String? contentRating,
    List<String>? demographics,
    required List<MangaModel> mangas,
  });

  /// Returns a cached manga detail when present and not expired.
  Future<MangaModel?> getCachedMangaDetail(
    String mangaId, {
    required Duration maxAge,
  });

  /// Persists a manga detail cache entry.
  Future<void> cacheMangaDetail(String mangaId, MangaModel manga);

  /// Returns cached chapters when present and not expired.
  ///
  /// [mangaId] uniquely identifies the manga. When [language] is provided,
  /// the cache key is scoped to that language as well, preventing one
  /// language's chapters from serving as fallback for another.
  Future<List<ChapterModel>?> getCachedMangaChapters(
    String mangaId, {
    required Duration maxAge,
    String? language,
  });

  /// Persists a chapter list cache entry scoped by [mangaId] and optionally
  /// [language].
  Future<void> cacheMangaChapters(
    String mangaId,
    List<ChapterModel> chapters, {
    String? language,
  });

  /// Clears all cached library payloads.
  Future<void> clearLibraryCache();
}
