import '../models/chapter_model.dart';
import '../models/manga_model.dart';
import '../models/search_result_model.dart';
import '../../domain/entities/manga_tags.dart';
import '../../domain/entities/manga_capabilities.dart';

/// Contract for the remote data source that communicates with the backend API.
///
/// Returns raw data models (DTOs) rather than domain entities. Mapping to domain
/// objects is performed at the repository level.
abstract class LibraryRemoteDataSource {
  /// Reads the backend demographic filtering capability contract.
  Future<MangaCapabilities> getMangaCapabilities();

  /// Fetches a paginated, optionally sorted and filtered list of manga models.
  ///
  /// [limit] and [offset] control pagination; [order] provides sort parameters.
  /// [genre] filters by genre name (e.g. "romance", "action") — resolved to
  /// a MangaDex tag UUID on the backend.
  /// [demographics] filters by publication demographic (e.g. shounen).
  Future<List<MangaModel>> getMangaList({
    required int limit,
    required int offset,
    Map<String, String>? order,
    String? genre,
    String? contentRating,
    List<MangaDemographic>? demographics,
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
  ///
  /// [limit] and [offset] control pagination. The response envelope is parsed
  /// into a [SearchResultModel] containing both the page items and metadata.
  /// [demographics] filters by publication demographic, including `unspecified`
  /// when the backend advertises support.
  Future<SearchResultModel> searchManga(
    String query, {
    required int limit,
    required int offset,
    String? contentRating,
    List<MangaDemographic>? demographics,
  });
}
