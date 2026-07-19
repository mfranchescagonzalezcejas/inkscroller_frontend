import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design_tokens.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_routes.dart';
import '../../../library/domain/entities/manga.dart';
import '../../../library/presentation/providers/library/library_provider.dart';
import '../constants/home_layout.dart';
import '../providers/home_provider.dart';
import 'home_shimmer.dart';

/// Featured manga carousel for the Home feed.
class HeroCarousel extends ConsumerStatefulWidget {
  /// Creates the featured carousel.
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
    final libraryState = ref.watch(libraryProvider);
    final mangas = ref.watch(homeProvider).featured;

    if (libraryState.isLoading && mangas.isEmpty) {
      return const HomeShimmer.carousel();
    }
    if (libraryState.failure != null && mangas.isEmpty) {
      return _HeroMessage(
        message: context.l10n.homeHeroError,
        action: TextButton(
          onPressed: () => ref.read(libraryProvider.notifier).refresh(),
          child: Text(context.l10n.retryAction),
        ),
      );
    }
    if (mangas.isEmpty) {
      return _HeroMessage(message: context.l10n.homeHeroEmpty);
    }

    return SizedBox(
      height: HomeLayout.heroCarouselHeight,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            physics: mangas.length == 1
                ? const NeverScrollableScrollPhysics()
                : null,
            itemCount: mangas.length,
            onPageChanged: (index) => setState(() => _activeIndex = index),
            itemBuilder: (context, index) => _HeroPage(manga: mangas[index]),
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(
                mangas.length,
                (index) => Container(
                  key: _activeIndex == index
                      ? ValueKey<String>('hero-dot-active-$index')
                      : ValueKey<String>('hero-dot-$index'),
                  width: _activeIndex == index ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _activeIndex == index
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMessage extends StatelessWidget {
  const _HeroMessage({required this.message, this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: HomeLayout.heroCarouselHeight,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: AppTypography.bodyStyle.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            if (action != null) action!,
          ],
        ),
      ),
    );
  }
}

class _HeroPage extends StatelessWidget {
  const _HeroPage({required this.manga});

  final Manga manga;

  @override
  Widget build(BuildContext context) {
    final meta = <String>[
      if (manga.typeDisplay != null) manga.typeDisplay!,
      if (manga.demographicDisplay != null) manga.demographicDisplay!,
    ].join(' · ');

    void openDetail() =>
        context.push(AppRoutes.mangaDetailPath(manga.id), extra: manga);

    return GestureDetector(
      onTap: openDetail,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _CoverImage(manga: manga),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.voidLowest.withValues(alpha: .94),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (manga.score != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.floating,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '★ ${manga.score!.toStringAsFixed(1)}',
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  manga.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                if (meta.isNotEmpty)
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                const SizedBox(height: 8),
                Semantics(
                  label: context.l10n.readNow,
                  button: true,
                  child: SizedBox(
                    key: const ValueKey<String>('hero-read-now'),
                    height: 48,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.brandGradient,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextButton(
                        onPressed: openDetail,
                        child: Text(
                          context.l10n.readNow,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.manga});

  final Manga manga;

  @override
  Widget build(BuildContext context) {
    final coverUrl = manga.coverUrl;
    if (coverUrl == null || coverUrl.isEmpty) {
      return const ColoredBox(
        color: AppColors.card,
        child: Center(
          child: Icon(Icons.image_not_supported, color: AppColors.outline),
        ),
      );
    }
    return Image.network(
      coverUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const ColoredBox(
        color: AppColors.card,
        child: Center(
          child: Icon(Icons.image_not_supported, color: AppColors.outline),
        ),
      ),
    );
  }
}
