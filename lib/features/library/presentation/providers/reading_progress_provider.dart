import 'dart:math' as math;

import 'package:flutter/foundation.dart';
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
    debugPrint('[ProgressNotifier] _load: ${state.length} mangas loaded');
    for (final entry in state.entries) {
      debugPrint('[ProgressNotifier]   ${entry.key}: '
          'readChapterIds=${entry.value.readChapterIds.length} '
          'manual=${entry.value.manuallyMarkedCount} '
          'total=${entry.value.totalChaptersCount} '
          'effectiveRead=${entry.value.readChaptersCount}');
    }
  }

  MangaReadingProgress progressFor(String mangaId) {
    return state[mangaId] ?? MangaReadingProgress(mangaId: mangaId);
  }

  /// Adjusts [MangaReadingProgress.manuallyMarkedCount] by [delta].
  ///
  /// The count is clamped to `>= 0` so it never goes negative.
  Future<void> updateManuallyMarkedCount(String mangaId, int delta) async {
    final current = progressFor(mangaId);
    final nextCount = math.max(0, current.manuallyMarkedCount + delta);
    final next = current.copyWith(manuallyMarkedCount: nextCount);
    if (next == current) return;
    // Optimistic update: state changes immediately so rapid calls see the
    // latest count. The _save call below also re-applies state on completion.
    state = <String, MangaReadingProgress>{...state, mangaId: next};
    debugPrint('[ProgressNotifier] updateManuallyMarkedCount: '
        '$mangaId delta=$delta '
        '${current.manuallyMarkedCount} → $nextCount '
        'readChapterIds.len=${current.readChapterIds.length}');
    await _repository.save(next);
  }

  /// Sets [MangaReadingProgress.manuallyMarkedCount] to an exact [count].
  ///
  /// When [chapters] is provided, readChapterIds is rebuilt so only MangaDex
  /// chapters with number ≤ [count] are marked — chapters above are removed.
  /// When [count] is 0, manuallyMarkedCount and readChapterIds are reset but
  /// totalChaptersCount is preserved so the tracking section stays visible.
  Future<void> setManuallyMarkedCountTo(
    String mangaId,
    int count, {
    List<Chapter>? chapters,
  }) async {
    final current = progressFor(mangaId);

    // count = 0 resets manual progress but preserves totalChaptersCount
    // so the tracking section and batches stay visible.
    if (count <= 0) {
      debugPrint('[ProgressNotifier] setManuallyMarkedCountTo: '
          '$mangaId RESET count=0 '
          'preserving total=${current.totalChaptersCount}');
      final reset = current.copyWith(
        manuallyMarkedCount: 0,
        readChapterIds: const <String>{},
      );
      if (reset == current) return;
      state = <String, MangaReadingProgress>{...state, mangaId: reset};
      await _repository.save(reset);
      return;
    }

    final int effectiveCount = count;

    // Rebuild readChapterIds from scratch, deduplicating by chapter number.
    // MangaDex often returns multiple entries for the same number (different
    // scanlators). We only keep one ID per chapter number to avoid phantom
    // checkmarks and inflated batch counters.
    Set<String>? nextReadIds;
    if (chapters != null && chapters.isNotEmpty) {
      final Map<int, String> bestByNumber = <int, String>{};
      for (final chapter in chapters) {
        final num? n = chapter.number;
        if (n != null && n.toInt() <= effectiveCount) {
          // Prefer the first occurrence for each chapter number
          bestByNumber.putIfAbsent(n.toInt(), () => chapter.id);
        }
      }
      nextReadIds = bestByNumber.values.toSet();
    }

    debugPrint('[ProgressNotifier] setManuallyMarkedCountTo: '
        '$mangaId count=$effectiveCount '
        'readChapterIds.len=${nextReadIds?.length ?? current.readChapterIds.length} '
        'prevManual=${current.manuallyMarkedCount} '
        'newManual=$effectiveCount');

    final next = current.copyWith(
      manuallyMarkedCount: effectiveCount,
      readChapterIds: nextReadIds,
    );
    if (next == current) return;
    state = <String, MangaReadingProgress>{...state, mangaId: next};
    await _repository.save(next);
  }

  /// Sets the batch size for the batching UI on this manga.
  Future<void> setBatchSize(String mangaId, int batchSize) async {
    final current = progressFor(mangaId);
    final next = current.copyWith(batchSize: batchSize);
    if (next == current) return;
    state = <String, MangaReadingProgress>{...state, mangaId: next};
    await _repository.save(next);
  }

  /// Synchronises the total chapter count from the backend.
  ///
  /// When [backendTotal] is provided (e.g. from Jikan/MAL), the effective
  /// total becomes `max(maxChapterNumber, backendTotal, currentTotal)`.
  /// Without [backendTotal], the total is `max(chapterCount, currentTotal)`.
  Future<void> syncChapters(
    String mangaId,
    List<Chapter> chapters, {
    int? backendTotal,
  }) async {
    final current = progressFor(mangaId);

    // Compute max chapter number from the provided chapters.
    int maxChapterNumber = 0;
    for (final chapter in chapters) {
      final num? n = chapter.number;
      if (n != null && n.toInt() > maxChapterNumber) {
        maxChapterNumber = n.toInt();
      }
    }

    // ponytail: only grow totalChaptersCount, never shrink it — chapters
    // arriving from a language-specific request are a subset of the full
    // set. Never prune readChapterIds to prevent losing reading progress
    // when switching between chapter languages (P1 Codex finding).
    int nextTotal = current.totalChaptersCount;
    if (maxChapterNumber > nextTotal) nextTotal = maxChapterNumber;
    if (chapters.length > nextTotal) nextTotal = chapters.length;
    if (backendTotal != null && backendTotal > nextTotal) {
      nextTotal = backendTotal;
    }

    debugPrint('[ProgressNotifier] syncChapters: $mangaId '
        'maxChapterNumber=$maxChapterNumber '
        'chapters.length=${chapters.length} '
        'backendTotal=$backendTotal '
        'current.total=${current.totalChaptersCount} '
        'nextTotal=$nextTotal');

    final next = current.copyWith(totalChaptersCount: nextTotal);
    if (next == current) return;

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

    final int nextTotal = current.totalChaptersCount > chapters.length
        ? current.totalChaptersCount
        : chapters.length;

    if (nextReadIds.length == current.readChapterIds.length &&
        (nextTotal <= current.totalChaptersCount)) {
      return null;
    }

    final previous = current;
    final next = current.copyWith(
      readChapterIds: nextReadIds,
      totalChaptersCount: nextTotal,
    );
    await _save(next);
    return previous;
  }

  /// Toggles a single chapter read state — mark read if unread, unmark if read.
  ///
  /// Direct toggle without dialog or navigation. Updates persisted state
  /// immediately so the UI rebuilds.
  Future<void> toggleChapter({
    required String mangaId,
    required String chapterId,
    required int totalChaptersCount,
  }) async {
    final current = progressFor(mangaId);
    final Set<String> nextReadIds = current.readChapterIds.toSet();
    if (current.isChapterRead(chapterId)) {
      nextReadIds.remove(chapterId);
    } else {
      nextReadIds.add(chapterId);
    }
    final nextTotal = current.totalChaptersCount > totalChaptersCount
        ? current.totalChaptersCount
        : totalChaptersCount;
    final next = current.copyWith(
      readChapterIds: nextReadIds,
      totalChaptersCount: nextTotal,
    );

    // Optimistic update — set state immediately so rapid toggles don't
    // both snapshot the same readChapterIds set before the first persists.
    state = <String, MangaReadingProgress>{
      ...state,
      next.mangaId: next,
    };
    await _repository.save(next);
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
    debugPrint('[ProgressNotifier] _save: ${progress.mangaId} '
        'readChapterIds=${progress.readChapterIds.length} '
        'manual=${progress.manuallyMarkedCount} '
        'total=${progress.totalChaptersCount} '
        'effectiveRead=${progress.readChaptersCount}');
    await _repository.save(progress);
    state = <String, MangaReadingProgress>{
      ...state,
      progress.mangaId: progress,
    };
  }
}
