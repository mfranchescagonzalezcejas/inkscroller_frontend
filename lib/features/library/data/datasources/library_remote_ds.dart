import '../models/chapter_model.dart';
import '../models/manga_model.dart';

/// Contract for the remote data source that communicates with the backend API.
///
/// Returns raw data models (DTOs) rather than domain entities. Mapping to domain
/// objects is performed at the repository level.
abstract class LibraryRemoteDataSource {
  /// Fetches a paginated, optionally sorted and filtered list of manga models.
  ///
  /// [limit] and [offset] control pagination; [order] provides sort parameters.
  /// [genre] filters by genre name (e.g. "romance", "action") — resolved to
  /// a MangaDex tag UUID on the backend.
  Future<List<MangaModel>> getMangaList({
    required int limit,
    required int offset,
    Map<String, String>? order,
    String? genre,
  });

  /// Fetches the full detail model for a single manga by [mangaId].
  Future<MangaModel> getMangaDetail(String mangaId);

  /// Fetches the list of chapter models for the manga identified by [mangaId].
  Future<List<ChapterModel>> getMangaChapters(String mangaId);

  /// Fetches the ordered list of page image URLs for the chapter [chapterId].
  ///
  /// Throws if the chapter is marked as external-only on the backend.
  Future<List<String>> getChapterPages(String chapterId);

  /// Searches the API for manga matching [query] and returns matching models.
  Future<List<MangaModel>> searchManga(String query);
}
