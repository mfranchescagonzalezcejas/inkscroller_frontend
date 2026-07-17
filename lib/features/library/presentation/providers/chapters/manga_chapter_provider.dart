import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/di/injection.dart';
import '../../../domain/usecases/get_manga_chapters.dart';
import '../../../domain/usecases/get_manga_chapters_with_languages.dart';
import '../../../domain/usecases/get_manga_languages.dart';
import 'manga_chapter_state.dart';
import 'manga_chapters_notifier.dart';

/// Riverpod provider that wires [MangaChaptersNotifier] with its use cases.
///
/// Exposes [MangaChaptersState] to [MangaDetailPage] for rendering the chapter list.
final mangaChaptersProvider =
StateNotifierProvider<MangaChaptersNotifier, MangaChaptersState>((ref) {
  return MangaChaptersNotifier(
    getMangaChapters: sl<GetMangaChapters>(),
    getMangaLanguages: sl<GetMangaLanguages>(),
    getMangaChaptersWithLanguages: sl<GetMangaChaptersWithLanguages>(),
  );
});
