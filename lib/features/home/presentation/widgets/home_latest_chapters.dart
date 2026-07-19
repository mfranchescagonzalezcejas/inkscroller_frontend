import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design_tokens.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_routes.dart';
import '../../domain/entities/home_chapter.dart';
import '../../../library/domain/entities/manga.dart';
import '../providers/home_latest_chapters_provider.dart';
import 'home_section_header.dart';
import 'home_shimmer.dart';

/// Max chapters to show on the Home feed.
const int _maxChapters = 10;

/// Latest chapters section with redesigned tiles.
class LatestChaptersSection extends ConsumerWidget {
  const LatestChaptersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(homeLatestChaptersProvider);
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: l10n.homeLatest,
          actionLabel: l10n.homeViewAll,
          onActionTap: () => context.go(AppRoutes.explore),
        ),
        async.when(
          data: (chapters) {
            final items = chapters.take(_maxChapters).toList();
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  l10n.homeNoMangas,
                  style: AppTypography.bodyStyle.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _LatestChapterTile(chapter: items[i]),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: HomeShimmer.chapterRow(),
          ),
          error: (e, _) => _ErrorState(
            message: l10n.homeChapterError,
            onRetry: () =>
                ref.invalidate(homeLatestChaptersProvider),
          ),
        ),
      ],
    );
  }
}

class _LatestChapterTile extends StatelessWidget {
  const _LatestChapterTile({required this.chapter});

  final HomeChapter chapter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final chapterLabel = l10n.chapterLabel(chapter.chapterNumber ?? '--');
    final subtitle = chapter.chapterTitle != null &&
            chapter.chapterTitle!.trim().isNotEmpty
        ? '$chapterLabel · ${chapter.chapterTitle}'
        : chapterLabel;

    final routeManga = Manga(
      id: chapter.mangaId,
      title: chapter.mangaTitle,
      coverUrl: chapter.mangaCoverUrl,
    );

    // TODO: Open reader directly when chapter.id routing lands.
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => context.push(
          AppRoutes.mangaDetailPath(chapter.mangaId),
          extra: routeManga,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Cover
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 48,
                  height: 64,
                  child: _cover(chapter.mangaCoverUrl),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      chapter.mangaTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Time + chevron
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 64),
                child: _timeAgo(chapter.publishAt),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cover(String? url) {
    if (url == null || url.isEmpty) {
      return const ColoredBox(
        color: AppColors.cardHigh,
        child: Center(
          child: Icon(Icons.image, color: AppColors.outline, size: 20),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => const ColoredBox(color: AppColors.cardHigh),
      errorWidget: (_, __, ___) => const ColoredBox(
        color: AppColors.cardHigh,
        child: Center(
          child: Icon(Icons.image, color: AppColors.outline, size: 20),
        ),
      ),
      memCacheWidth: 96,
      filterQuality: FilterQuality.medium,
    );
  }

  Widget _timeAgo(DateTime? date) {
    if (date == null) return const SizedBox.shrink();
    final now = DateTime.now().toUtc();
    final diff = now.difference(date.toUtc());
    String label;
    if (diff.inMinutes < 60) {
      label = '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      label = '${diff.inHours}h';
    } else {
      label = '${diff.inDays}d';
    }
    return Text(
      label,
      style: const TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 11,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyStyle.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(context.l10n.retryAction),
          ),
        ],
      ),
    );
  }
}
