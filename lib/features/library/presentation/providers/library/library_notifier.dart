import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_constants.dart';
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
  static const int _limit = AppConstants.mangaPageLimit;

  Timer? _searchDebounce;
  String _activeQuery = '';

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
        final failedState = state.copyWith(
          isLoading: false,
          mangas: const [],
          hasMore: false,
          failure: failure,
        );
        state = failedState;
        _tabCache[key] = failedState;
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

    final result = await _getMangaList(limit: _limit, offset: _offset, genre: _genre);

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
    _activeQuery = '';
    state = state.copyWith(query: '', isSearching: false, clearFailure: true);
    await loadInitial(mode: _mode, genre: _genre);
  }

  /// Reloads the current mode from the first page.
  Future<void> refresh() {
    return loadInitial(mode: _mode, genre: _genre);
  }

  /// Filter by genre — reloads from the first page with server-side genre filter.
  Future<void> setGenre(String? genre) {
    // Genre tabs are part of the normal catalogue flow, not the dedicated
    // popularity ranking mode. Reset mode to normal whenever a genre changes.
    return loadInitial(genre: genre);
  }

  Future<void> _performSearch(String query) async {
    // Evita resultados fuera de orden
    _activeQuery = query;

    state = state.copyWith(
      isSearching: true,
      isLoadingMore: false,
      hasMore: false,
      clearFailure: true,
    );

    final result = await _searchManga(query);

    // Si la query cambió mientras esperábamos, ignoramos este resultado.
    if (_activeQuery != query) return;

    result.fold(
      (failure) {
        state = state.copyWith(isSearching: false, failure: failure);
      },
      (results) {
        state = state.copyWith(
          mangas: dedupeMangas(results),
          isSearching: false,
          clearFailure: true,
        );
      },
    );
  }
}
