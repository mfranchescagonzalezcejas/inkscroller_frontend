import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkscroller_flutter/core/design/design_tokens.dart'
    show AppColors, AppSpacing, AppTypography;
import 'package:inkscroller_flutter/core/l10n/l10n.dart';

import '../providers/reading_progress_provider.dart';
import 'progress_jump_dialog.dart';

/// Displays the current reading progress with +/- manual-mark controls,
/// a batch-size selector, and a jump-to-chapter button.
///
/// Intended to sit above the chapter list on [MangaDetailPage].
class ReadingProgressSection extends ConsumerWidget {
  const ReadingProgressSection({
    super.key,
    required this.mangaId,
    required this.readCount,
    required this.totalCount,
    this.onJumpToChapter,
  });

  final String mangaId;
  final int readCount;
  final int totalCount;

  /// Called after a successful jump so the parent can scroll to the target
  /// batch. `null` means the jump dialog still updates progress but no
  /// scrolling happens.
  final ValueChanged<int>? onJumpToChapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(
      readingProgressProvider.select(
        (value) => value[mangaId],
      ),
    );
    final int effectiveTotal =
        totalCount > 0 ? totalCount : progress?.totalChaptersCount ?? 0;
    final double fraction =
        effectiveTotal > 0 ? readCount / effectiveTotal : 0.0;
    final int batchSize = progress?.batchSize ?? 25;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.card,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Controls row: read count, +/-, batch size, jump
          Row(
            children: <Widget>[
              // Read count label
              Text(
                context.l10n.libraryProgressValue(readCount, effectiveTotal),
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),

              // Decrease button
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                color: AppColors.onSurfaceVariant,
                onPressed: () {
                  ref
                      .read(readingProgressProvider.notifier)
                      .updateManuallyMarkedCount(mangaId, -1);
                },
                tooltip: context.l10n.manualMarkDecrease,
                visualDensity: VisualDensity.compact,
              ),

              // Increase button
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                color: AppColors.onSurfaceVariant,
                onPressed: () {
                  ref
                      .read(readingProgressProvider.notifier)
                      .updateManuallyMarkedCount(mangaId, 1);
                },
                tooltip: context.l10n.manualMarkIncrease,
                visualDensity: VisualDensity.compact,
              ),

              // Batch size selector
              _BatchSizeSelector(
                mangaId: mangaId,
                currentSize: batchSize,
              ),

              // Jump button
              IconButton(
                icon: const Icon(Icons.fast_forward, size: 20),
                color: AppColors.onSurfaceVariant,
                onPressed: () async {
                  final chapter = await showProgressJumpDialog(
                    context,
                    totalChaptersCount: effectiveTotal,
                  );
                  if (chapter != null) {
                    onJumpToChapter?.call(chapter);
                  }
                },
                tooltip: context.l10n.jumpToChapter,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BatchSizeSelector extends ConsumerWidget {
  const _BatchSizeSelector({
    required this.mangaId,
    required this.currentSize,
  });

  final String mangaId;
  final int currentSize;

  static const List<int> _sizes = <int>[10, 25, 50, 100];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<int>(
      initialValue: currentSize,
      onSelected: (value) {
        ref
            .read(readingProgressProvider.notifier)
            .setBatchSize(mangaId, value);
      },
      itemBuilder: (context) => _sizes
          .map(
            (size) => PopupMenuItem<int>(
              value: size,
              child: Text(
                '$size',
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '$currentSize',
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
