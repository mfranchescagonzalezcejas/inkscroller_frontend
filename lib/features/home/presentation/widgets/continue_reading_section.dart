import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design_tokens.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_routes.dart';
import '../constants/home_layout.dart';
import '../providers/continue_reading_provider.dart';
import 'home_shimmer.dart';

/// Horizontal rail of manga with incomplete reading progress.
class ContinueReadingSection extends ConsumerWidget {
  /// Creates the continue-reading rail.
  const ContinueReadingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(continueReadingProvider);
    return progress.when(
      loading: () => const HomeShimmer.cardRow(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: HomeLayout.continueReadingCardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _ProgressCard(item: items[index]),
          ),
        );
      },
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.item});

  final ContinueReadingItem item;

  @override
  Widget build(BuildContext context) {
    final read = item.progress.readChaptersCount;
    final total = item.progress.totalChaptersCount;
    final value = total > 0 ? (read / total).clamp(0.0, 1.0) : null;
    final progressLabel = context.l10n.libraryProgressValue(read, total);

    return Semantics(
      label: progressLabel,
      button: true,
      child: SizedBox(
        width: HomeLayout.continueReadingCardWidth,
        child: InkWell(
          onTap: () => context.push(
            AppRoutes.mangaDetailPath(item.manga.id),
            extra: item.manga,
          ),
          borderRadius: BorderRadius.circular(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _CoverImage(coverUrl: item.manga.coverUrl),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.voidLowest.withValues(alpha: .92),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.manga.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(value: value),
                    ],
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

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.coverUrl});

  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    if (coverUrl == null || coverUrl!.isEmpty) {
      return const ColoredBox(
        color: AppColors.card,
        child: Icon(Icons.image_not_supported, color: AppColors.outline),
      );
    }
    return Image.network(
      coverUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const ColoredBox(
        color: AppColors.card,
        child: Icon(Icons.image_not_supported, color: AppColors.outline),
      ),
    );
  }
}
