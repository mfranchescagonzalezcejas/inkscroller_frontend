import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../domain/entities/manga.dart';
import '../../../domain/usecases/get_manga_list.dart';
import '../../../domain/usecases/search_manga.dart';
import 'dedupe_mangas.dart';
import 'library_state.dart';

/// Browsing mode that determines the sort order used by [LibraryNotifier].
enum LibraryMode { normal, popular }

/// Cache key for genre tabs - combines mode and genre for unique identification.
String _cacheKey(LibraryMode mode, String? genre) => '${mode.name}:$genre';

/// Manages paginated manga list state with search, debounce, and deduplication.
///
/// Calls [GetMangaList] and [SearchManga] use cases and emits immutable
/// [LibraryState] snapshots consumed by [LibraryPage].
class LibraryNotifier extends StateNotifier<LibraryState> {
  LibraryNotifier(this._getMangaList, this._searchManga)
      : _mode = LibraryMode.normal,
        super(LibraryState.initial()) {
    loadInitial();
  }

  final GetMangaList _getMangaList;
  final SearchManga _searchManga;

  LibraryMode _mode;
  String? _genre;

  int _offset = 0;
  int _total = 0;
  static const int _limit = AppConstants.mangaPageLimit;

  int _searchOffset = 0;
  int _searchTotal = 0;
  static const int _searchLimit = AppConstants.searchPageLimit;

  Timer? _searchDebounce;
  String _activeQuery = '';

  /// Cache for recent search results — keyed by query string.
  /// Returns cached (items, total) to avoid repeated API calls for the same term.
  final Map<String, (List<Manga> items, int total)> _searchCache = {};
  static const int _searchCacheMaxSize = 5;

  /// Cache for genre tabs - provides instant tab switching.
  final Map<String, LibraryState> _tabCache = {};

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> loadInitial({LibraryMode mode = LibraryMode.normal, String? genre}) async {
    final key = _cacheKey(mode, genre);

    // Return cached result immediately if available.
    if (_tabCache.containsKey(key)) {
      final cached = _tabCache[key]!;
      state = cached;
      _mode = mode;
      _genre = genre;
      return;
    }

    state = state.copyWith(isLoading: true, clearFailure: true);

    _mode = mode;
    _genre = genre;
    _offset = 0;

    final result = await _getMangaList(
      limit: _limit,
      offset: _offset,
      order: _mode == LibraryMode.popular ? {'followedCount': 'desc'} : null,
      genre: _genre,
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
      (pair) {
        final (mangas, total) = pair;
        _offset += mangas.length;
        _total = total;

        final newState = state.copyWith(
          mangas: dedupeMangas(mangas),
          isLoading: false,
          hasMore: _mode == LibraryMode.normal && _offset < _total,
          clearFailure: true,
        );
        state = newState;
        _tabCache[key] = newState;
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    if (state.isSearching) {
      await _loadMoreSearch();
      return;
    }

    if (_mode != LibraryMode.normal) return;

    state = state.copyWith(isLoadingMore: true, clearFailure: true);

    final result = await _getMangaList(limit: _limit, offset: _offset, genre: _genre);

    result.fold(
      (failure) {
        state = state.copyWith(isLoadingMore: false, failure: failure);
      },
      (pair) {
        final (newMangas, total) = pair;
        _offset += newMangas.length;
        _total = total;

        final combined = dedupeMangas([...state.mangas, ...newMangas]);

        state = state.copyWith(
          mangas: combined,
          isLoadingMore: false,
          hasMore: _offset < _total,
          clearFailure: true,
        );
      },
    );
  }

  Future<void> _loadMoreSearch() async {
    final requestQuery = _activeQuery;
    state = state.copyWith(isLoadingMore: true, clearFailure: true);

    final result = await _searchManga(
      requestQuery,
      limit: _searchLimit,
      offset: _searchOffset,
    );

    if (_activeQuery.isEmpty || _activeQuery != requestQuery) {
      state = state.copyWith(isLoadingMore: false);
      return;
    }

    result.fold(
      (failure) {
        state = state.copyWith(isLoadingMore: false, failure: failure);
      },
      (pair) {
        final (newItems, total) = pair;
        _searchOffset += newItems.length;
        _searchTotal = total;

        final beforeCount = state.mangas.length;
        final combined = dedupeMangas([...state.mangas, ...newItems]);
        final dedupedCount = combined.length - beforeCount;

        state = state.copyWith(
          mangas: combined,
          isLoadingMore: false,
          hasMore: dedupedCount > 0 && _searchOffset < _searchTotal,
          clearFailure: true,
        );
      },
    );
  }

  /// Directly triggers a search for [query], bypassing debounce.
  Future<void> search(String query) => _performSearch(query);

  /// UI hook: actualiza el texto del buscador y lanza debounce
  void setQuery(String query) {
    final trimmed = query.trim();
    state = state.copyWith(query: query);

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (trimmed.isEmpty) {
        clearSearch();
        return;
      }
      _performSearch(trimmed);
    });
  }

  Future<void> clearSearch() async {
    _searchDebounce?.cancel();
    _searchCache.clear();
    _activeQuery = '';
    _searchOffset = 0;
    _searchTotal = 0;
    state = state.copyWith(query: '', isSearching: false, clearFailure: true);
    await loadInitial(mode: _mode, genre: _genre);
  }

  /// Reloads the current mode from the first page.
  ///
  /// Clears the tab cache so pull-to-refresh always fetches fresh data.
  Future<void> refresh() {
    final key = _cacheKey(_mode, _genre);
    _tabCache.remove(key);
    return loadInitial(mode: _mode, genre: _genre);
  }

  /// Filter by genre — reloads from the first page with server-side genre filter.
  Future<void> setGenre(String? genre) {
    // Genre tabs are part of the normal catalogue flow, not the dedicated
    // popularity ranking mode. Reset mode to normal whenever a genre changes.
    return loadInitial(genre: genre);
  }

  Future<void> _performSearch(String query) async {
    _activeQuery = query;
    _searchOffset = 0;
    _searchTotal = 0;

    state = state.copyWith(
      isSearching: true,
      isLoadingMore: false,
      hasMore: false,
      clearFailure: true,
    );

    // Check cache first
    final cached = _searchCache[query];
    if (cached != null) {
      final (cachedItems, cachedTotal) = cached;
      _searchOffset = cachedItems.length;
      _searchTotal = cachedTotal;
      state = state.copyWith(
        mangas: dedupeMangas(cachedItems),
        isSearching: true,
        hasMore: _searchOffset < _searchTotal,
        clearFailure: true,
      );
      return;
    }

    final result = await _searchManga(query, limit: _searchLimit, offset: AppConstants.firstPageOffset);

    if (_activeQuery != query) return;

    result.fold(
      (failure) {
        state = state.copyWith(isSearching: false, failure: failure);
      },
      (pair) {
        final (items, total) = pair;
        _searchOffset = items.length;
        _searchTotal = total;

        // Cache the result, evict oldest if over limit
        _searchCache[query] = (items, total);
        if (_searchCache.length > _searchCacheMaxSize) {
          final oldest = _searchCache.keys.first;
          _searchCache.remove(oldest);
        }

        state = state.copyWith(
          mangas: dedupeMangas(items),
          isSearching: true,
          hasMore: _searchOffset < _searchTotal,
          clearFailure: true,
        );
      },
    );
  }
}
