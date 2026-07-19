import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design_tokens.dart';
import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_routes.dart';
import '../../../library/domain/entities/manga.dart';
import '../../../library/presentation/providers/user_library_provider.dart';
import '../providers/home_provider.dart';

/// Max slides in the hero carousel.
const int _heroMaxSlides = 5;

// ─────────────────────────────────────────────────────────────────────────────
// HeroCarousel
// ─────────────────────────────────────────────────────────────────────────────

/// Swipeable featured-manga carousel with blurred cover background,
/// page indicators, bookmark toggle, and detail navigation.
class HeroCarousel extends ConsumerStatefulWidget {
  const HeroCarousel({super.key});

  @override
  ConsumerState<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends ConsumerState<HeroCarousel> {
  final PageController _controller = PageController();
  int _activeIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mangas = ref.watch(homeProvider).featured;
    final slides = mangas.take(_heroMaxSlides).toList();

    if (slides.isEmpty) {
      return const SizedBox(height: 390);
    }

    return SizedBox(
      height: 400,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            physics: slides.length == 1
                ? const NeverScrollableScrollPhysics()
                : null,
            itemCount: slides.length,
            onPageChanged: (i) => setState(() => _activeIndex = i),
            itemBuilder: (_, i) => _HeroSlide(manga: slides[i]),
          ),

          // Bottom gradient — blends hero into home background
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.voidLowest.withValues(alpha: 0),
                    AppColors.voidLowest,
                  ],
                ),
              ),
            ),
          ),

          // Page indicators
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: _HeroPageIndicator(
              count: slides.length,
              activeIndex: _activeIndex,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HeroPageIndicator
// ─────────────────────────────────────────────────────────────────────────────

class _HeroPageIndicator extends StatelessWidget {
  const _HeroPageIndicator({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HeroSlide — blurred cover + overlay + content
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSlide extends ConsumerWidget {
  const _HeroSlide({required this.manga});

  final Manga manga;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inLibrary = ref.watch(
      userLibraryProvider.select((map) => map[manga.id]?.isInLibrary ?? false),
    );
    final meta = [
      if (manga.typeDisplay != null) manga.typeDisplay!,
      if (manga.demographicDisplay != null) manga.demographicDisplay!,
    ].join(' · ');

    void openDetail() =>
        context.push(AppRoutes.mangaDetailPath(manga.id), extra: manga);

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Blurred cover background (like manga detail) ──────────
        if (manga.coverUrl != null)
          Positioned.fill(
            child: ClipRRect(
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: CachedNetworkImage(
                  imageUrl: manga.coverUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),

        // ── Dark gradient overlay ─────────────────────────────────
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.5),
                  AppColors.voidLowest.withValues(alpha: 0.7),
                  AppColors.voidLowest.withValues(alpha: 0.85),
                ],
              ),
            ),
          ),
        ),

        // ── Foreground content ────────────────────────────────────
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Badge row: trending + demographic
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    const _TrendingBadge(),
                    if (meta.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.floating,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          meta,
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Cover + text row — expands to fill vertical space
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 150,
                          height: 250,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Positioned.fill(child: _HeroCover(coverUrl: manga.coverUrl)),
                              if (manga.score != null)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardHigh,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star, size: 10, color: AppColors.scoreGold),
                                        const SizedBox(width: 2),
                                        Text(
                                          manga.score!.toStringAsFixed(1),
                                          style: const TextStyle(fontFamily: AppTypography.fontFamily, fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.scoreGold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              manga.title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontFamily: AppTypography.fontFamily, fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                            ),
                            if (manga.description != null && manga.description!.trim().isNotEmpty)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    manga.description!,
                                    maxLines: 100,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontFamily: AppTypography.fontFamily, fontSize: 12, color: AppColors.onSurfaceVariant, height: 1.35),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Actions at bottom ─────────────────────────────────────
        Positioned(
          left: 20,
          right: 20,
          bottom: 48,
          child: _HeroActions(
            manga: manga,
            inLibrary: inLibrary,
            onDetail: openDetail,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TrendingBadge
// ─────────────────────────────────────────────────────────────────────────────

class _TrendingBadge extends StatelessWidget {
  const _TrendingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.floating,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            context.l10n.homeTrendingLabel,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: .8,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HeroMetadata
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// HeroActions — compact "Ver detalles" + bookmark
// ─────────────────────────────────────────────────────────────────────────────

class _HeroActions extends ConsumerWidget {
  const _HeroActions({
    required this.manga,
    required this.inLibrary,
    required this.onDetail,
  });

  final Manga manga;
  final bool inLibrary;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // Ver detalles — only as wide as the text
        IntrinsicWidth(
          child: SizedBox(
            height: 40,
            child: FilledButton(
              onPressed: onDetail,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.voidLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Ver detalles'),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Bookmark
        SizedBox(
          width: 40,
          height: 40,
          child: IconButton.filledTonal(
            style: IconButton.styleFrom(
              backgroundColor: AppColors.cardHigh,
              foregroundColor: AppColors.onSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _toggleBookmark(ref, context),
            icon: Icon(
              inLibrary ? Icons.bookmark : Icons.bookmark_border,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleBookmark(WidgetRef ref, BuildContext context) async {
    final nowIn = await ref.read(userLibraryProvider.notifier).toggle(manga);
    if (!context.mounted) return;
    if (nowIn) {
      AppFeedback.showSuccess(
        context,
        title: context.l10n.libraryItemAdded(manga.title),
      );
    } else {
      AppFeedback.showInfo(
        context,
        title: context.l10n.libraryItemRemoved(manga.title),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HeroCover
// ─────────────────────────────────────────────────────────────────────────────

class _HeroCover extends StatelessWidget {
  const _HeroCover({required this.coverUrl});

  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    if (coverUrl == null || coverUrl!.isEmpty) {
      return const ColoredBox(
        color: AppColors.card,
        child: Center(
          child: Icon(Icons.image_not_supported, color: AppColors.outline),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: coverUrl!,
      fit: BoxFit.cover,
      placeholder: (_, __) => const ColoredBox(color: AppColors.card),
      errorWidget: (_, __, ___) => const ColoredBox(
        color: AppColors.card,
        child: Center(
          child: Icon(Icons.image_not_supported, color: AppColors.outline),
        ),
      ),
      fadeInDuration: const Duration(milliseconds: 300),
      memCacheWidth: 200,
      filterQuality: FilterQuality.medium,
    );
  }
}
