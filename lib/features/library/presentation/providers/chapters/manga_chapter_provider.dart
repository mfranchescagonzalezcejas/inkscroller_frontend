import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/di/injection.dart';
import '../../../domain/usecases/get_manga_chapters.dart';
import 'manga_chapter_state.dart';
import 'manga_chapters_notifier.dart';

/// Riverpod provider that wires [MangaChaptersNotifier] with [GetMangaChapters].
///
/// Exposes [MangaChaptersState] to [MangaDetailPage] for rendering the chapter list.
final mangaChaptersProvider =
StateNotifierProvider<MangaChaptersNotifier, MangaChaptersState>((ref) {
  return MangaChaptersNotifier(
    getMangaChapters: sl<GetMangaChapters>(),
  );
});
