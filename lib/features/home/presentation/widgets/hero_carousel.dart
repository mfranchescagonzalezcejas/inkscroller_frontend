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
      return const SizedBox(height: 400);
    }

    return SizedBox(
      height: 410,
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

          // Bottom gradient + solid buffer — blends hero into home background
          // The extended solid area prevents white lines during overscroll.
          Positioned(
            left: 0,
            right: 0,
            bottom: -40,
            height: 100,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.voidLowest.withValues(alpha: 0),
                    AppColors.voidLowest,
                    AppColors.voidLowest,
                  ],
                  stops: const [0.0, 0.5, 1.0],
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

class _HeroSlide extends ConsumerStatefulWidget {
  const _HeroSlide({required this.manga});

  final Manga manga;

  @override
  ConsumerState<_HeroSlide> createState() => _HeroSlideState();
}

class _HeroSlideState extends ConsumerState<_HeroSlide> {
  _CoverRatio _ratio = _CoverRatio.portrait;
  ImageStream? _imageStream;
  late final ImageStreamListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = ImageStreamListener(_onImage, onError: (_, __) {});
    _resolve();
  }

  @override
  void dispose() {
    _imageStream?.removeListener(_listener);
    super.dispose();
  }

  void _resolve() {
    final url = widget.manga.coverUrl;
    if (url == null || url.isEmpty) return;
    _imageStream?.removeListener(_listener);
    _imageStream = CachedNetworkImageProvider(url)
        .resolve(ImageConfiguration.empty);
    _imageStream!.addListener(_listener);
  }

  void _onImage(ImageInfo info, bool sync) {
    final size = Size(info.image.width.toDouble(), info.image.height.toDouble());
    final detected = _ratioFromSize(size);
    if (!mounted) return;
    if (detected != _ratio) {
      setState(() => _ratio = detected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inLibrary = ref.watch(
      userLibraryProvider.select((map) => map[widget.manga.id]?.isInLibrary ?? false),
    );
    final isLandscape = _ratio == _CoverRatio.landscape;
    final typeLabel = widget.manga.typeDisplay;
    final demoLabel = widget.manga.demographicDisplay;

    void openDetail() =>
        context.push(AppRoutes.mangaDetailPath(widget.manga.id), extra: widget.manga);

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Blurred cover background (like manga detail) ──────────
        if (widget.manga.coverUrl != null)
          Positioned.fill(
            child: ClipRRect(
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: CachedNetworkImage(
                  imageUrl: widget.manga.coverUrl!,
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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Badge row: trending + type + demographic
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    const _TrendingBadge(),
                    if (typeLabel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.cardHigh,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              typeLabel == 'Manhwa' ? Icons.auto_stories : Icons.menu_book,
                              size: 10, color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(typeLabel, style: const TextStyle(fontFamily: AppTypography.fontFamily, fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
                          ],
                        ),
                      ),
                    if (demoLabel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.cardHigh,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              demoLabel == 'Shounen' ? Icons.flash_on :
                              demoLabel == 'Shoujo' ? Icons.favorite :
                              demoLabel == 'Seinen' ? Icons.explore :
                              Icons.auto_awesome,
                              size: 10, color: AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(demoLabel, style: const TextStyle(fontFamily: AppTypography.fontFamily, fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Portrait: two-column layout (cover+buttons | title+desc)
                // Landscape: single-column layout (badges → cover → title → desc → buttons)
                Expanded(
                  child: isLandscape
                      ? _LandscapeContent(
                          manga: widget.manga,
                          inLibrary: inLibrary,
                          onDetail: openDetail,
                        )
                      : _PortraitContent(
                          manga: widget.manga,
                          inLibrary: inLibrary,
                          onDetail: openDetail,
                        ),
                ),
              ],
            ),
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
// PortraitContent — two-column: (cover+badge+buttons) | (title+desc)
// ─────────────────────────────────────────────────────────────────────────────

class _PortraitContent extends StatelessWidget {
  const _PortraitContent({
    required this.manga,
    required this.inLibrary,
    required this.onDetail,
  });

  final Manga manga;
  final bool inLibrary;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _AdaptiveHeroCover(coverUrl: manga.coverUrl),
                if (manga.score != null)
                  Positioned(
                    top: 4, right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.cardHigh, borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 10, color: AppColors.scoreGold),
                          const SizedBox(width: 2),
                          Text(manga.score!.toStringAsFixed(1), style: const TextStyle(fontFamily: AppTypography.fontFamily, fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.scoreGold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            _HeroActions(manga: manga, inLibrary: inLibrary, onDetail: onDetail),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(manga.title, maxLines: 3, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: AppTypography.fontFamily, fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
              if (manga.description != null && manga.description!.trim().isNotEmpty)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: SingleChildScrollView(
                      child: Text(manga.description!, style: const TextStyle(fontFamily: AppTypography.fontFamily, fontSize: 12, color: AppColors.onSurfaceVariant, height: 1.35)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LandscapeContent — single-column: cover → title → desc → buttons
// ─────────────────────────────────────────────────────────────────────────────

class _LandscapeContent extends StatelessWidget {
  const _LandscapeContent({
    required this.manga,
    required this.inLibrary,
    required this.onDetail,
  });

  final Manga manga;
  final bool inLibrary;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _AdaptiveHeroCover(coverUrl: manga.coverUrl),
              if (manga.score != null)
                Positioned(
                  top: 4, right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.cardHigh, borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 10, color: AppColors.scoreGold),
                        const SizedBox(width: 2),
                        Text(manga.score!.toStringAsFixed(1), style: const TextStyle(fontFamily: AppTypography.fontFamily, fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.scoreGold)),
                      ],
                    ),
                  ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Title
        Text(manga.title, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontFamily: AppTypography.fontFamily, fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
        // Description — fills remaining space
        if (manga.description != null && manga.description!.trim().isNotEmpty)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SingleChildScrollView(
                child: Text(manga.description!, style: const TextStyle(fontFamily: AppTypography.fontFamily, fontSize: 12, color: AppColors.onSurfaceVariant, height: 1.35)),
              ),
            ),
          ),
        const SizedBox(height: 8),
        _HeroActions(manga: manga, inLibrary: inLibrary, onDetail: onDetail),
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
// AdaptiveHeroCover — detects image aspect ratio and sizes like manga_detail
// ─────────────────────────────────────────────────────────────────────────────

// Copy of manga_detail's ratio detection (can't import private enum)
enum _CoverRatio { portrait, landscape, square }

_CoverRatio _ratioFromSize(Size size) {
  final ratio = size.width / size.height;
  if (ratio > 1.15) return _CoverRatio.landscape;
  if (ratio < 0.85) return _CoverRatio.portrait;
  return _CoverRatio.square;
}

class _AdaptiveHeroCover extends StatefulWidget {
  const _AdaptiveHeroCover({required this.coverUrl});

  final String? coverUrl;

  @override
  State<_AdaptiveHeroCover> createState() => _AdaptiveHeroCoverState();
}

class _AdaptiveHeroCoverState extends State<_AdaptiveHeroCover> {
  _CoverRatio _ratio = _CoverRatio.portrait;
  ImageStream? _imageStream;
  double _imageAspectRatio = 2 / 3; // default portrait
  late final ImageStreamListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = ImageStreamListener(_onImage, onError: (_, __) {});
    _resolve();
  }

  @override
  void didUpdateWidget(_AdaptiveHeroCover old) {
    super.didUpdateWidget(old);
    if (old.coverUrl != widget.coverUrl) {
      _imageStream?.removeListener(_listener);
      _resolve();
    }
  }

  @override
  void dispose() {
    _imageStream?.removeListener(_listener);
    super.dispose();
  }

  void _resolve() {
    final url = widget.coverUrl;
    if (url == null || url.isEmpty) return;
    _imageStream?.removeListener(_listener);
    final provider = CachedNetworkImageProvider(url);
    _imageStream = provider.resolve(ImageConfiguration.empty);
    _imageStream!.addListener(_listener);
  }

  void _onImage(ImageInfo info, bool sync) {
    final size = Size(info.image.width.toDouble(), info.image.height.toDouble());
    final detected = _ratioFromSize(size);
    final aspect = size.width / size.height;
    if (!mounted) return;
    if (detected != _ratio || aspect != _imageAspectRatio) {
      setState(() {
        _ratio = detected;
        _imageAspectRatio = aspect;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.coverUrl == null || widget.coverUrl!.isEmpty) {
      return const ColoredBox(
        color: AppColors.card,
        child: Center(
          child: Icon(Icons.image_not_supported, color: AppColors.outline),
        ),
      );
    }

    // Dimensions per ratio (same logic as manga_detail, scaled for hero)
    final double coverWidth = switch (_ratio) {
      _CoverRatio.portrait => 142.0,
      _CoverRatio.landscape => 200.0,
      _CoverRatio.square => 170.0,
    };
    final double coverHeight = coverWidth / _imageAspectRatio;

    return SizedBox(
      width: coverWidth,
      height: coverHeight.clamp(120, 280),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: widget.coverUrl!,
          fit: BoxFit.cover,
          placeholder: (_, __) => const ColoredBox(color: AppColors.card),
          errorWidget: (_, __, ___) => const ColoredBox(
            color: AppColors.card,
            child: Center(
              child: Icon(Icons.image_not_supported, color: AppColors.outline),
            ),
          ),
          fadeInDuration: const Duration(milliseconds: 300),
          memCacheWidth: 400,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
