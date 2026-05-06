import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/usecases/get_manga_chapters.dart';
import 'manga_chapter_state.dart';

/// Loads the chapter list for a given manga and tracks loading/error state.
///
/// Fetches chapters via [GetMangaChapters] and emits [MangaChaptersState]
/// snapshots consumed by [MangaDetailPage].
class MangaChaptersNotifier extends StateNotifier<MangaChaptersState> {
  final GetMangaChapters getMangaChapters;

  MangaChaptersNotifier({
    required this.getMangaChapters,
  }) : super(const MangaChaptersState());

  Future<void> loadChapters(String mangaId) async {
    state = state.copyWith(
      isLoading: true,
      clearFailure: true,
    );

    final result = await getMangaChapters(mangaId);

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, failure: failure);
      },
      (chapters) {
        state = state.copyWith(
          chapters: chapters,
          isLoading: false,
          clearFailure: true,
        );
      },
    );
  }
}
