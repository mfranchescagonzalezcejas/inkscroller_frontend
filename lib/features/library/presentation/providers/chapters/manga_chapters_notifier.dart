import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/chapter.dart';
import '../../../domain/usecases/get_manga_chapters.dart';
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

  /// ponytail: in-memory per-manga chapter cache for stale-while-revalidate.
  /// Cleared on app restart. Persists across manga detail navigations so
  /// returning to a previously viewed manga shows chapters instantly.
  final Map<String, List<Chapter>> _chapterCache = {};

  MangaChaptersNotifier({
    required this.getMangaChapters,
  }) : super(const MangaChaptersState());

  Future<void> loadChapters(String mangaId) async {
    debugPrint('[ChaptersNotifier] loadChapters(mangaId=$mangaId) hash=${identityHashCode(this)}');
    final cached = _chapterCache[mangaId];

    if (cached != null) {
      // Stale-while-revalidate: serve cached data immediately, no loading.
      state = state.copyWith(
        chapters: cached,
        isLoading: false,
        clearFailure: true,
      );
    } else {
      // First load for this manga: show shimmer until API responds.
      // Clear any stale chapters from a previous manga so the error branch
      // below correctly detects an empty state if the API call fails.
      state = state.copyWith(
        chapters: const [],
        isLoading: true,
        clearFailure: true,
      );
    }

    final result = await getMangaChapters(mangaId);

    result.fold(
      (failure) {
        // Only show error when we have absolutely nothing to display.
        if (state.chapters.isEmpty) {
          state = state.copyWith(isLoading: false, failure: failure);
        }
        // When cached chapters exist, keep them silently — the user is
        // already seeing useful content.
      },
      (chapters) {
        _chapterCache[mangaId] = chapters;
        state = state.copyWith(
          chapters: chapters,
          isLoading: false,
          clearFailure: true,
        );
      },
    );
  }

  /// Clears the in-memory per-manga chapter cache.
  ///
  /// Called from the settings "Clear cached data" action so that stale
  /// in-memory chapters are not served after the user explicitly clears
  /// all persisted cache.
  void clearCache() {
    _chapterCache.clear();
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
