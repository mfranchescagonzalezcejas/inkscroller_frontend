import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design_tokens.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_routes.dart';
import '../providers/continue_reading_provider.dart';
import 'home_section_header.dart';
import 'home_shimmer.dart';

/// Horizontal rail of manga with incomplete reading progress.
class ContinueReadingSection extends ConsumerWidget {
  const ContinueReadingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(continueReadingProvider);
    return progress.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 24),
        child: HomeShimmer.cardRow(),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeSectionHeader(title: context.l10n.homeContinueReading),
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _ContinueReadingCard(item: items[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({required this.item});

  final ContinueReadingItem item;

  @override
  Widget build(BuildContext context) {
    final read = item.progress.readChaptersCount;
    final total = item.progress.totalChaptersCount;
    final value = total > 0 ? (read / total).clamp(0.0, 1.0) : 0.0;
    final pct = total > 0 ? '${(value * 100).toInt()}%' : '--';

    return Semantics(
      label: context.l10n.libraryProgressValue(read, total),
      button: true,
      child: SizedBox(
        width: 280,
        child: Material(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => context.push(
              AppRoutes.mangaDetailPath(item.manga.id),
              extra: item.manga,
            ),
            borderRadius: BorderRadius.circular(14),
            child: Row(
              children: [
                // Cover thumbnail
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(14),
                  ),
                  child: SizedBox(
                    width: 100,
                    height: 150,
                    child: _CoverThumb(coverUrl: item.manga.coverUrl),
                  ),
                ),
                // Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.manga.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Capítulo ${item.progress.readChaptersCount}',
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 6,
                            backgroundColor: AppColors.cardHigh,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pct,
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CoverThumb extends StatelessWidget {
  const _CoverThumb({required this.coverUrl});

  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    if (coverUrl == null || coverUrl!.isEmpty) {
      return const ColoredBox(
        color: AppColors.cardHigh,
        child: Center(
          child: Icon(Icons.image, color: AppColors.outline, size: 28),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: coverUrl!,
      fit: BoxFit.cover,
      placeholder: (_, __) => const ColoredBox(color: AppColors.cardHigh),
      errorWidget: (_, __, ___) => const ColoredBox(
        color: AppColors.cardHigh,
        child: Center(
          child: Icon(Icons.image, color: AppColors.outline, size: 28),
        ),
      ),
      memCacheWidth: 200,
      filterQuality: FilterQuality.medium,
    );
  }
}
