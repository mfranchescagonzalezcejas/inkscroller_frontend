import 'manga.dart';

/// Paginated search result returned by the backend search endpoint.
///
/// This is a pure domain value object with no JSON or framework dependencies.
/// It carries both the current page of [mangas] and the pagination metadata
/// needed to derive whether more results are available.
class SearchResult {
  const SearchResult({
    required this.mangas,
    required this.limit,
    required this.offset,
    required this.total,
  });

  /// Manga items returned for the requested page.
  final List<Manga> mangas;

  /// Maximum number of items requested in this page.
  final int limit;

  /// Number of items skipped before this page.
  final int offset;

  /// Total number of matching manga available across all pages.
  final int total;
}
