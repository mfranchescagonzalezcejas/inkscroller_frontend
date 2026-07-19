import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design_tokens.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_routes.dart';
import '../../../library/domain/entities/manga.dart';
import '../providers/home_provider.dart';
import 'home_section_header.dart';

/// Horizontal row of recommended manga, deduplicated against featured.
class RecommendedSection extends ConsumerWidget {
  const RecommendedSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);

    final heroIds = homeState.featured.map((m) => m.id).toSet();
    final source = <Manga>[
      ...homeState.popular,
      ...homeState.shounen,
      ...homeState.shoujo,
    ];
    final seen = <String>{};
    final deduped = <Manga>[];
    for (final m in source) {
      if (heroIds.contains(m.id)) continue;
      if (!seen.add(m.id)) continue;
      deduped.add(m);
      if (deduped.length >= 10) break;
    }

    if (deduped.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(title: context.l10n.homeRecommended),
        const SizedBox(height: 4),
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: deduped.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _RecommendedCard(manga: deduped[i]),
          ),
        ),
      ],
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({required this.manga});

  final Manga manga;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: () =>
            context.push(AppRoutes.mangaDetailPath(manga.id), extra: manga),
        child: SizedBox(
          width: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 150,
                  height: 220,
                  child: Stack(
                    children: [
                      _cover(manga.coverUrl),
                      // Score badge
                      if (manga.score != null)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cardHigh,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 10,
                                  color: AppColors.scoreGold,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  manga.score!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.scoreGold,
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
              const SizedBox(height: 8),
              // Title
              Text(
                manga.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              if (manga.demographicDisplay != null)
                Text(
                  manga.demographicDisplay!,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 10,
                    color: AppColors.onSurfaceVariant,
                  ),
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
        color: AppColors.card,
        child: Center(
          child: Icon(Icons.image, color: AppColors.outline, size: 32),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => const ColoredBox(color: AppColors.card),
      errorWidget: (_, __, ___) => const ColoredBox(
        color: AppColors.card,
        child: Center(
          child: Icon(Icons.image, color: AppColors.outline, size: 32),
        ),
      ),
      memCacheWidth: 300,
      filterQuality: FilterQuality.medium,
    );
  }
}
