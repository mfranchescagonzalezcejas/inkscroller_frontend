import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/chapter.dart';
import '../../../domain/usecases/get_manga_chapters.dart';
import '../../../domain/usecases/get_manga_chapters_with_languages.dart';
import '../../../domain/usecases/get_manga_languages.dart';
import 'manga_chapter_state.dart';

/// Loads the chapter list for a given manga and tracks loading/error state.
///
/// Uses a stale-while-revalidate strategy: cached chapters (from a previous
/// fetch within the same session) are shown immediately while the network
/// call refreshes the data in the background. This eliminates the loading
/// shimmer on repeat visits within the session — the user sees chapters
/// instantly and the list updates silently when the API responds.
///
/// The in-memory cache is scoped to the provider lifetime (session-only).
/// The repository-level SharedPreferences cache still serves as the offline
/// fallback when the network is unavailable.
class MangaChaptersNotifier extends StateNotifier<MangaChaptersState> {
  final GetMangaChapters getMangaChapters;
  final GetMangaLanguages getMangaLanguages;
  final GetMangaChaptersWithLanguages getMangaChaptersWithLanguages;

  /// ponytail: in-memory per-manga chapter cache for stale-while-revalidate.
  /// Cleared on app restart. Persists across manga detail navigations so
  /// returning to a previously viewed manga shows chapters instantly.
  final Map<String, List<Chapter>> _chapterCache = {};

  /// Tracks the composite key (`mangaId:language`) of the most recent
  /// [loadChapters] call so stale responses from a previous navigation or
  /// language switch are discarded.
  String? _lastRequestKey;

  /// Tracks the last mangaId loaded. When it changes, the selected language
  /// resets to the default ('en') because each manga has its own available
  /// language set.
  String? _lastMangaId;

  MangaChaptersNotifier({
    required this.getMangaChapters,
    required this.getMangaLanguages,
    required this.getMangaChaptersWithLanguages,
  }) : super(const MangaChaptersState());

  Future<void> loadChapters(String mangaId, {String? language}) async {
    final bool mangaChanged = _lastMangaId != null && _lastMangaId != mangaId;
    _lastMangaId = mangaId;
    final lang = language ?? (mangaChanged ? 'en' : state.selectedLanguage);
    final requestKey = '$mangaId:$lang';

    debugPrint('[ChaptersNotifier] loadChapters(mangaId=$mangaId, lang=$lang)'
        ' hash=${identityHashCode(this)}');

    _lastRequestKey = requestKey;
    final cached = _chapterCache[requestKey];
    final bool isCacheHit = cached != null;

    if (isCacheHit) {
      // Stale-while-revalidate: serve cached data immediately, no loading.
      state = state.copyWith(
        chapters: cached,
        isLoading: false,
        clearFailure: true,
        selectedLanguage: lang,
      );
    } else {
      // First load for this manga/language: show shimmer until API responds.
      // Clear any stale chapters from a previous manga so the error branch
      // below correctly detects an empty state if the API call fails.
      state = state.copyWith(
        chapters: const [],
        isLoading: true,
        clearFailure: true,
        selectedLanguage: lang,
      );
    }

    final result = await getMangaChapters(mangaId, language: lang);

    // Guard: discard stale responses if the user navigated to another manga
    // or switched language while this request was in-flight.
    if (_lastRequestKey != requestKey) return;

    result.fold(
      (failure) {
        // On a cache hit (including a legitimate empty chapter list), keep
        // the cached data silently. Only show the error on a fresh load.
        if (!isCacheHit) {
          state = state.copyWith(isLoading: false, failure: failure);
        }
      },
      (chapters) {
        _chapterCache[requestKey] = chapters;
        state = state.copyWith(
          chapters: chapters,
          isLoading: false,
          clearFailure: true,
          selectedLanguage: lang,
        );
      },
    );
  }

  /// Loads the available chapter languages for [mangaId] along with chapters
  /// for the best-matching language — single call via the unified endpoint.
  ///
  /// [preferredLang] is the user's default language preference. The backend
  /// selects the best match (e.g. `es-la` when `es` is not available).
  Future<void> loadLanguages(String mangaId, {String? preferredLang}) async {
    final requestKey = '$mangaId:languages';

    // Clear previous manga's chapters immediately so stale data is never
    // visible when navigating between different manga.
    state = state.copyWith(
      chapters: const [],
      isLoading: true,
      isLanguageLoading: true,
      clearFailure: true,
    );

    _lastRequestKey = requestKey;
    final result = await getMangaChaptersWithLanguages(
      mangaId,
      preferredLang: preferredLang,
    );

    // Guard: discard stale response if user navigated to another manga
    // while this request was in-flight.
    if (_lastRequestKey != requestKey) return;

    result.fold(
      (failure) {
        state = state.copyWith(
          isLanguageLoading: false,
          isLoading: false,
          failure: failure,
          availableLanguages: const ['en'],
        );
      },
      (response) {
        _chapterCache['$mangaId:${response.matchedLanguage}'] =
            response.chapters;
        state = state.copyWith(
          isLanguageLoading: false,
          isLoading: false,
          availableLanguages: response.availableLanguages,
          selectedLanguage: response.matchedLanguage,
          chapters: response.chapters,
          clearFailure: true,
        );
      },
    );
  }

  /// Clears the in-memory per-manga chapter cache.
  ///
  /// Called from the settings "Clear cached data" action so that stale
  /// in-memory chapters are not served after the user explicitly clears
  /// all persisted cache. Unlike provider invalidation, this does not
  /// dispose the notifier, so in-flight requests remain safe.
  void clearCache() {
    _chapterCache.clear();
    // Reset the last-requested guard so any in-flight response arriving
    // after this point is discarded — it would otherwise repopulate the
    // cache with stale data from a request that started before clearing.
    _lastRequestKey = null;
    // Also reset the state so the next visit starts fresh.
    state = const MangaChaptersState();
  }

  void setSortDescending({required bool value}) {
    state = state.copyWith(sortDescending: value);
  }

  void setFilterUnreadOnly({required bool value}) {
    state = state.copyWith(filterUnreadOnly: value);
  }
}
