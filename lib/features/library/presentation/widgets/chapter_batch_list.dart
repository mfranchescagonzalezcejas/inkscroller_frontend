import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkscroller_flutter/core/design/design_tokens.dart'
    show AppColors, AppTypography;
import 'package:inkscroller_flutter/core/l10n/l10n.dart';

import '../../domain/chapter_progress_utils.dart';
import '../../domain/entities/chapter.dart';
import '../../domain/entities/chapter_batch.dart';
import '../../domain/entities/manga_reading_progress.dart';
import '../providers/reading_progress_provider.dart';
import '../widgets/chapter_tile.dart';

/// A batch-organized chapter list that groups chapters into expandable batches.
///
/// Each batch shows a header with its range (e.g. "Chapters 1–25") and can
/// be expanded to reveal the chapters inside.
class ChapterBatchList extends ConsumerWidget {
  const ChapterBatchList({
    super.key,
    required this.mangaId,
    required this.batches,
    required this.onChapterTap,
    this.allChapters,
    this.descending = false,
    this.scrollController,
    this.hiddenChapterIds,
  });

  final String mangaId;
  final List<ChapterBatch> batches;
  final void Function(Chapter chapter) onChapterTap;
  final bool descending;
  final ScrollController? scrollController;

  /// When set, readable items whose [Chapter.id] is in this set are omitted.
  /// Used to implement the "hide read chapters" filter in batch mode.
  final Set<String>? hiddenChapterIds;

  /// Full chapter list for cascading checkbox marks across all batches.
  /// When provided, toggling a chapter as read marks all chapters up to it.
  final List<Chapter>? allChapters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(
      readingProgressProvider.select(
        (value) => value[mangaId],
      ),
    );

    final displayBatches = descending ? batches.reversed.toList() : batches;
    final int manualThreshold = progress?.manuallyMarkedCount ?? 0;

    // Omit read items (hiddenChapterIds) and placeholders covered by
    // manuallyMarkedCount. Both filters only activate when the user has
    // toggled "hide read" (hiddenChapterIds is non-null), so manual marking
    // alone never hides placeholders from the full list.
    final bool hasFilter =
        hiddenChapterIds != null && hiddenChapterIds!.isNotEmpty;
    final Set<String> effectiveHidden = hiddenChapterIds ?? <String>{};
    final visibleBatches = hasFilter
        ? displayBatches
            .map((b) => b.copyWithFilteredItems(
                  effectiveHidden,
                  manualThreshold: manualThreshold,
                ))
            .where((b) => b.items.isNotEmpty)
            .toList()
        : displayBatches;

    if (visibleBatches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.l10n.chaptersFilteredOut,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visibleBatches.length,
      itemBuilder: (context, batchIndex) {
        final batch = visibleBatches[batchIndex];
        return _BatchExpansionTile(
          key: ValueKey('batch-${batch.start}-${batch.end}'),
          batch: batch,
          progress: progress,
          mangaId: mangaId,
          onChapterTap: onChapterTap,
          allChapters: allChapters,
        );
      },
    );
  }
}

class _BatchExpansionTile extends ConsumerStatefulWidget {
  const _BatchExpansionTile({
    super.key,
    required this.batch,
    required this.progress,
    required this.mangaId,
    required this.onChapterTap,
    this.allChapters,
  });

  final ChapterBatch batch;
  final MangaReadingProgress? progress;
  final String mangaId;
  final void Function(Chapter chapter) onChapterTap;
  final List<Chapter>? allChapters;

  @override
  ConsumerState<_BatchExpansionTile> createState() =>
      _BatchExpansionTileState();
}

class _BatchExpansionTileState extends ConsumerState<_BatchExpansionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final batch = widget.batch;
    final manualCount = widget.progress?.manuallyMarkedCount ?? 0;
    final readCount = batch.items.where((item) {
      if (item is ReadableChapterBatchItem) {
        return widget.progress?.isChapterRead(item.chapter.id) ?? false;
      }
      if (item is PlaceholderChapterBatchItem) {
        return manualCount >= item.chapterNumber;
      }
      return false;
    }).length;

    return Column(
      children: <Widget>[
        ListTile(
          title: Text(
            '${context.l10n.chaptersTitle} '
            '${formatChapterNumber(batch.start.toDouble())}–${formatChapterNumber(batch.end.toDouble())}',
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          subtitle: Text(
            '$readCount / ${batch.items.length}',
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          trailing: Icon(
            _expanded ? Icons.expand_less : Icons.expand_more,
            color: AppColors.onSurfaceVariant,
          ),
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        if (_expanded)
          ...batch.items.map((item) {
            return switch (item) {
              ReadableChapterBatchItem() => ChapterTile(
                  chapter: item.chapter,
                  isRead:
                      widget.progress?.isChapterRead(item.chapter.id) ?? false,
                  onTap: () => widget.onChapterTap(item.chapter),
                  onToggleRead: () {
                    final chapters = widget.allChapters ??
                        batch.items
                            .whereType<ReadableChapterBatchItem>()
                            .map((i) => i.chapter)
                            .toList();
                    ref
                        .read(readingProgressProvider.notifier)
                        .toggleChapter(
                          mangaId: widget.mangaId,
                          chapterId: item.chapter.id,
                          totalChaptersCount: batch.end,
                          chapters: chapters,
                        );
                  },
                ),
              PlaceholderChapterBatchItem() => _PlaceholderTile(
                  chapterNumber: item.chapterNumber,
                  mangaId: widget.mangaId,
                ),
            };
          }),
      ],
    );
  }
}

class _PlaceholderTile extends ConsumerWidget {
  const _PlaceholderTile({
    required this.chapterNumber,
    required this.mangaId,
  });

  final int chapterNumber;
  final String mangaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(
      readingProgressProvider.select(
        (value) => value[mangaId],
      ),
    );
    final int manualCount = progress?.manuallyMarkedCount ?? 0;
    final bool isChecked = manualCount >= chapterNumber;

    return ListTile(
      leading: IconButton(
        icon: Icon(
          isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 22,
          color: isChecked
              ? AppColors.primary
              : AppColors.onSurfaceVariant,
        ),
        onPressed: () {
          if (isChecked) {
            // Unmark: set count just below this chapter number
            ref
                .read(readingProgressProvider.notifier)
                .setManuallyMarkedCountTo(mangaId, chapterNumber - 1);
          } else {
            // Mark: ensure count reaches this chapter number
            final delta = chapterNumber - manualCount;
            if (delta > 0) {
              ref
                  .read(readingProgressProvider.notifier)
                  .updateManuallyMarkedCount(mangaId, delta);
            }
          }
        },
        tooltip: context.l10n.placeholderMarkRead,
        visualDensity: VisualDensity.compact,
      ),
      title: Text(
        context.l10n.chapterLabel(formatChapterNumber(chapterNumber.toDouble())),
        style: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 14,
          color: AppColors.onSurfaceVariant,
        ),
      ),
      subtitle: const Text(
        '—', // Placeholder indicator
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 11,
          color: AppColors.outline,
        ),
      ),
      enabled: false,
    );
  }
}
