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
      return const SizedBox(height: 440);
    }

    return SizedBox(
      height: 440,
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
            bottom: -1,
            height: 60,
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
            bottom: 48,
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
          width: isActive ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
            borderRadius: BorderRadius.circular(4),
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
      userLibraryProvider.select(
        (map) => map[manga.id]?.isInLibrary ?? false,
      ),
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
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Trending badge
                const _TrendingBadge(),
                const SizedBox(height: 12),

                // Cover + text row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cover thumbnail (similar to manga detail)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 100,
                        height: 150,
                        child: _HeroCover(coverUrl: manga.coverUrl),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Text info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            manga.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _HeroMetadata(manga: manga, meta: meta),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Actions at bottom (inside hero, above gradient) ───────
        Positioned(
          left: 20,
          right: 20,
          bottom: 56,
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

class _HeroMetadata extends StatelessWidget {
  const _HeroMetadata({required this.manga, required this.meta});

  final Manga manga;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (meta.isNotEmpty)
          Text(
            meta,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        if (manga.score != null) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 14, color: AppColors.scoreGold),
              const SizedBox(width: 2),
              Text(
                manga.score!.toStringAsFixed(1),
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.scoreGold,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

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
        // Ver detalles — compact
        SizedBox(
          height: 40,
          child: Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onDetail,
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: Text(
                    'Ver detalles',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.voidLowest,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Bookmark
        SizedBox(
          width: 40,
          height: 40,
          child: Material(
            color: AppColors.cardHigh,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _toggleBookmark(ref, context),
              child: Center(
                child: Icon(
                  inLibrary ? Icons.bookmark : Icons.bookmark_border,
                  color: AppColors.onSurface,
                  size: 18,
                ),
              ),
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
