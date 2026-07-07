import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../domain/chapter_progress_utils.dart';
import '../../domain/entities/chapter.dart';
import '../../domain/entities/manga_reading_progress.dart';
import '../../domain/repositories/reading_progress_repository.dart';

final readingProgressProvider =
    StateNotifierProvider<
      ReadingProgressNotifier,
      Map<String, MangaReadingProgress>
    >((ref) => ReadingProgressNotifier(sl<ReadingProgressRepository>()));

class ReadingProgressNotifier
    extends StateNotifier<Map<String, MangaReadingProgress>> {
  ReadingProgressNotifier(this._repository)
    : super(const <String, MangaReadingProgress>{}) {
    _load();
  }

  final ReadingProgressRepository _repository;

  Future<void> _load() async {
    state = await _repository.getAll();
  }

  MangaReadingProgress progressFor(String mangaId) {
    return state[mangaId] ?? MangaReadingProgress(mangaId: mangaId);
  }

  Future<void> syncChapters(String mangaId, List<Chapter> chapters) async {
    final current = progressFor(mangaId);
    final Set<String> validReadIds = current.readChapterIds
        .where(
          (chapterId) => chapters.any((chapter) => chapter.id == chapterId),
        )
        .toSet();

    final next = current.copyWith(
      readChapterIds: validReadIds,
      totalChaptersCount: chapters.length,
    );

    await _save(next);
  }

  Future<MangaReadingProgress?> markThrough({
    required String mangaId,
    required List<Chapter> chapters,
    required String targetChapterId,
  }) async {
    final current = progressFor(mangaId);
    final List<Chapter> chaptersToMark = chaptersUpToTarget(
      chapters,
      targetChapterId,
    );
    if (chaptersToMark.isEmpty) {
      return null;
    }

    final Set<String> nextReadIds = <String>{
      ...current.readChapterIds,
      ...chaptersToMark.map((chapter) => chapter.id),
    };

    if (nextReadIds.length == current.readChapterIds.length &&
        current.totalChaptersCount == chapters.length) {
      return null;
    }

    final previous = current;
    final next = current.copyWith(
      readChapterIds: nextReadIds,
      totalChaptersCount: chapters.length,
    );
    await _save(next);
    return previous;
  }

  Future<void> restore(MangaReadingProgress progress) {
    return _save(progress);
  }

  int unreadCountThrough({
    required String mangaId,
    required List<Chapter> chapters,
    required String targetChapterId,
  }) {
    final current = progressFor(mangaId);
    return chaptersUpToTarget(
      chapters,
      targetChapterId,
    ).where((chapter) => !current.isChapterRead(chapter.id)).length;
  }

  Future<void> _save(MangaReadingProgress progress) async {
    await _repository.save(progress);
    state = <String, MangaReadingProgress>{
      ...state,
      progress.mangaId: progress,
    };
  }
}
