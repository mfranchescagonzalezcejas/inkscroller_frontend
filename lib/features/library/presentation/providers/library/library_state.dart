import '../../../../../core/error/failures.dart';
import '../../../domain/entities/manga.dart';

/// Immutable snapshot of the library browsing state.
///
/// Tracks the paginated manga list, loading/pagination flags, active search
/// query, and error state. Consumed by [LibraryPage] via [libraryProvider].
class LibraryState {
  final List<Manga> mangas;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Failure? failure;

  // 🔍 NUEVO
  final String query;
  final bool isSearching;

  const LibraryState({
    required this.mangas,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.query,
    required this.isSearching,
    this.failure,
  });

  factory LibraryState.initial() {
    return const LibraryState(
      mangas: [],
      isLoading: true,
      isLoadingMore: false,
      hasMore: true,
      query: '',
      isSearching: false,
    );
  }

  LibraryState copyWith({
    List<Manga>? mangas,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Failure? failure,
    bool clearFailure = false,
    String? query,
    bool? isSearching,
  }) {
    return LibraryState(
      mangas: mangas ?? this.mangas,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      query: query ?? this.query,
      isSearching: isSearching ?? this.isSearching,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}
