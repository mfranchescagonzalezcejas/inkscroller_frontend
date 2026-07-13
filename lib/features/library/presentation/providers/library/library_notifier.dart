import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../domain/usecases/get_manga_list.dart';
import '../../../domain/usecases/search_manga.dart';
import 'dedupe_mangas.dart';
import 'library_state.dart';

/// Browsing mode that determines the sort order used by [LibraryNotifier].
enum LibraryMode { normal, popular }

/// Cache key for genre tabs - combines mode, genre, and contentRating for unique identification.
String _cacheKey(LibraryMode mode, String? genre, {String? contentRating}) =>
    '${mode.name}:$genre:cr:${contentRating ?? 'default'}';

/// Manages paginated manga list state with search, debounce, and deduplication.
///
/// Calls [GetMangaList] and [SearchManga] use cases and emits immutable
/// [LibraryState] snapshots consumed by [LibraryPage].
class LibraryNotifier extends StateNotifier<LibraryState> {
  LibraryNotifier(
    this._getMangaList,
    this._searchManga, {
    String? initialContentRating,
  })  : _mode = LibraryMode.normal,
        _contentRating = initialContentRating,
        super(LibraryState.initial()) {
    loadInitial(contentRating: initialContentRating);
  }

  final GetMangaList _getMangaList;
  final SearchManga _searchManga;

  LibraryMode _mode;
  String? _genre;
  String? _contentRating;

  int _offset = 0;
  static const int _limit = AppConstants.mangaPageLimit;

  Timer? _searchDebounce;
  String _activeQuery = '';

  int _searchOffset = 0;
  int _totalResults = 0;
  int _searchQueryVersion = 0;

  /// Cache for genre tabs - provides instant tab switching.
  final Map<String, LibraryState> _tabCache = {};

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> loadInitial({
    LibraryMode mode = LibraryMode.normal,
    String? genre,
    String? contentRating,
  }) async {
    final key = _cacheKey(mode, genre, contentRating: contentRating);

    // Return cached result immediately if available.
    if (_tabCache.containsKey(key)) {
      final cached = _tabCache[key]!;
      state = cached;
      _mode = mode;
      _genre = genre;
      _contentRating = contentRating;
      return;
    }

    state = state.copyWith(isLoading: true, clearFailure: true);

    _mode = mode;
    _genre = genre;
    _contentRating = contentRating;
    _offset = 0;

    final result = await _getMangaList(
      limit: _limit,
      offset: _offset,
      order: _mode == LibraryMode.popular ? {'followedCount': 'desc'} : null,
      genre: _genre,
      contentRating: _contentRating,
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          mangas: const [],
          hasMore: false,
          failure: failure,
        );
        // Skip caching failures so refresh() triggers a real network retry.
      },
      (mangas) {
        _offset += mangas.length;

        final newState = state.copyWith(
          mangas: dedupeMangas(mangas),
          isLoading: false,
          hasMore: _mode == LibraryMode.normal && mangas.length == _limit,
          clearFailure: true,
        );
        state = newState;
        _tabCache[key] = newState;
      },
    );
  }

  Future<void> loadMore() async {
    if (_mode != LibraryMode.normal) return;
    if (state.isSearching) return;
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, clearFailure: true);

    final result = await _getMangaList(
      limit: _limit,
      offset: _offset,
      genre: _genre,
      contentRating: _contentRating,
    );

    result.fold(
      (failure) {
        state = state.copyWith(isLoadingMore: false, failure: failure);
      },
      (newMangas) {
        _offset += newMangas.length;

        final combined = dedupeMangas([...state.mangas, ...newMangas]);

        state = state.copyWith(
          mangas: combined,
          isLoadingMore: false,
          hasMore: newMangas.length == _limit,
          clearFailure: true,
        );
      },
    );
  }

  /// UI hook: actualiza el texto del buscador y lanza debounce
  void setQuery(String query) {
    final trimmed = query.trim();
    // Invalidate any in-flight search response from a previous query so it
    // cannot mutate state when it arrives late (R4).
    _searchQueryVersion++;
    state = state.copyWith(query: query);

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (trimmed.isEmpty) {
        clearSearch();
        return;
      }
      _performSearch(trimmed);
    });
  }

  Future<void> clearSearch() async {
    _searchDebounce?.cancel();
    _searchQueryVersion++;
    _activeQuery = '';
    _searchOffset = 0;
    _totalResults = 0;
    state = state.copyWith(
      query: '',
      isSearching: false,
      isLoadingMore: false,
      hasMore: true,
      clearFailure: true,
    );
    await loadInitial(mode: _mode, genre: _genre, contentRating: _contentRating);
  }

  /// Reloads the current content from the first page.
  ///
  /// When a search query is active, re-runs the search from offset 0 instead
  /// of loading the catalogue, so pull-to-refresh refreshes search results.
  /// Clears the tab cache so catalogue refresh always fetches fresh data.
  Future<void> refresh({String? contentRating}) {
    final query = _activeQuery;
    if (query.isNotEmpty) {
      // ponytail: search refresh reuses _performSearch which resets offset
      // and version internally — no need to duplicate cursor reset here.
      _searchDebounce?.cancel();
      return _performSearch(query);
    }
    final effectiveCR = contentRating ?? _contentRating;
    final key = _cacheKey(_mode, _genre, contentRating: effectiveCR);
    _tabCache.remove(key);
    return loadInitial(
      mode: _mode,
      genre: _genre,
      contentRating: effectiveCR,
    );
  }

  /// Filter by genre — reloads from the first page with server-side genre filter.
  Future<void> setGenre(String? genre) {
    // Genre tabs are part of the normal catalogue flow, not the dedicated
    // popularity ranking mode. Reset mode to normal whenever a genre changes.
    return loadInitial(genre: genre, contentRating: _contentRating);
  }

  /// Resets Explore to its initial catalogue state.
  ///
  /// Cancels any pending search, invalidates in-flight responses, clears the
  /// active query, search cursors, genre filter, tab cache, and reloads the
  /// initial catalogue.
  Future<void> resetExplore() async {
    _searchDebounce?.cancel();
    _searchQueryVersion++;
    _activeQuery = '';
    _searchOffset = 0;
    _totalResults = 0;
    _offset = 0;
    _genre = null;
    _mode = LibraryMode.normal;
    _tabCache.clear();
    state = LibraryState.initial();
    await loadInitial(contentRating: _contentRating);
  }

  /// Loads the next page of search results.
  ///
  /// Early returns when there is no active query, a search/load-more is already
  /// in progress, results are exhausted, or the generation has moved on.
  Future<void> loadMoreSearch() async {
    final query = _activeQuery;
    if (query.isEmpty) return;
    if (state.isSearching) return;
    if (state.isLoadingMore || !state.hasMore) return;
    if (_searchOffset >= _totalResults) return;

    state = state.copyWith(isLoadingMore: true, clearFailure: true);

    _searchQueryVersion++;
    final capturedGeneration = _searchQueryVersion;

    final result = await _searchManga(
      query,
      limit: _limit,
      offset: _searchOffset,
      contentRating: _contentRating,
    );

    if (_searchQueryVersion != capturedGeneration) return;

    result.fold(
      (failure) {
        state = state.copyWith(isLoadingMore: false, failure: failure);
      },
      (result) {
        final combined = dedupeMangas([...state.mangas, ...result.mangas]);
        _searchOffset += result.mangas.length;
        _totalResults = result.total;

        // ponytail: guard against infinite loop when backend returns 0 items
        // with an inflated total — without this, _searchOffset never advances
        // and hasMore stays true forever.
        final exhausted = result.mangas.isEmpty;

        state = state.copyWith(
          mangas: combined,
          isLoadingMore: false,
          hasMore: !exhausted && combined.length < result.total,
          clearFailure: true,
        );
      },
    );
  }

  Future<void> _performSearch(String query) async {
    _searchQueryVersion++;
    final capturedGeneration = _searchQueryVersion;
    _activeQuery = query;
    _searchOffset = 0;
    _totalResults = 0;

    state = state.copyWith(
      isSearching: true,
      isLoadingMore: false,
      hasMore: false,
      clearFailure: true,
    );

    final result = await _searchManga(
      query,
      limit: _limit,
      offset: 0,
      contentRating: _contentRating,
    );

    if (_searchQueryVersion != capturedGeneration) return;

    result.fold(
      (failure) {
        state = state.copyWith(isSearching: false, failure: failure);
      },
      (result) {
        _totalResults = result.total;
        final mangas = dedupeMangas(result.mangas);
        _searchOffset = result.mangas.length;

        state = state.copyWith(
          mangas: mangas,
          isSearching: false,
          hasMore: mangas.length < result.total,
          clearFailure: true,
        );
      },
    );
  }
}
