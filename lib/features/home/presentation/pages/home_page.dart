import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design_tokens.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_routes.dart';
import '../providers/home_provider.dart';
import '../providers/home_latest_chapters_provider.dart';
import '../providers/home_state.dart';
import '../../domain/entities/home_chapter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../library/domain/entities/manga.dart';
import '../../../library/presentation/providers/library/library_provider.dart';
import '../widgets/continue_reading_section.dart';
import '../widgets/demographic_manga_row.dart';
import '../widgets/hero_carousel.dart';

/// Landing page with curated manga sections: Featured, Latest, Popular, and Demographics.
///
/// Composes horizontal scrollable lists and a segmented demographic tab bar.
/// Watches [libraryProvider] for loading state and [homeProvider] for section data.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  // Warms up Image.network images (hero + trending cards) and
  // CachedNetworkImage images (demographic carousels) as soon as data arrives,
  // so the user never sees a blank frame when they scroll.
  static void _precacheMangaCovers(BuildContext context, HomeState state) {
    if (!context.mounted) return;

    // Hero and trending cards use Image.network → NetworkImage provider.
    final networkUrls = [
      ...state.featured,
      ...state.popular.take(10),
    ].map((m) => m.coverUrl).whereType<String>().where((u) => u.isNotEmpty);

    for (final url in networkUrls) {
      precacheImage(NetworkImage(url), context);
    }

    // Demographic carousels use CoverImage → CachedNetworkImage.
    final cachedUrls = [
      ...state.shounen.take(8),
      ...state.shoujo.take(8),
      ...state.seinen.take(8),
      ...state.josei.take(8),
    ].map((m) => m.coverUrl).whereType<String>().where((u) => u.isNotEmpty);

    for (final url in cachedUrls) {
      precacheImage(CachedNetworkImageProvider(url), context);
    }
  }

  static void _precacheChapterCovers(
    BuildContext context,
    List<HomeChapter> chapters,
  ) {
    if (!context.mounted) return;
    for (final chapter in chapters) {
      final url = chapter.mangaCoverUrl;
      if (url != null && url.isNotEmpty) {
        precacheImage(NetworkImage(url), context);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(libraryProvider);
    ref.listen<HomeState>(homeProvider, (_, next) {
      if (next.featured.isNotEmpty) _precacheMangaCovers(context, next);
    });

    ref.listen<AsyncValue<List<HomeChapter>>>(
      homeLatestChaptersProvider,
      (_, next) => next.whenData(
        (chapters) => _precacheChapterCovers(context, chapters),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.voidLowest,
      body: Stack(
        children: [
          RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.card,
            onRefresh: () =>
                ref.read(libraryProvider.notifier).refresh(),
            child: const _HomeBody(),
                ),
                if (libraryState.isLoading && libraryState.mangas.isNotEmpty)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      color: AppColors.primary.withValues(alpha: 0.5),
                      minHeight: 2,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);
    final libraryState = ref.watch(libraryProvider);
    final isLoading = libraryState.isLoading && libraryState.mangas.isEmpty;
    final isAuth = ref.watch(authProvider).user != null;
    final l10n = context.l10n;

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        const HeroCarousel(),
        const SizedBox(height: 24),
        const ContinueReadingSection(),
        DemographicMangaRow(
          mangas: homeState.popular,
          title: l10n.homePopular,
          isLoading: isLoading,
        ),
        DemographicMangaRow(
          mangas: homeState.shounen,
          title: l10n.demographicShounen,
          isLoading: isLoading,
        ),
        DemographicMangaRow(
          mangas: homeState.shoujo,
          title: l10n.demographicShoujo,
          isLoading: isLoading,
        ),
        if (isAuth)
          DemographicMangaRow(
            mangas: homeState.seinen,
            title: l10n.demographicSeinen,
            isLoading: isLoading,
          ),
        if (isAuth)
          DemographicMangaRow(
            mangas: homeState.josei,
            title: l10n.demographicJosei,
            isLoading: isLoading,
          ),
        const _NewChaptersSection(),
        const _ExploreCta(),
      ],
    );
  }
}

class _NewChaptersSection extends ConsumerWidget {
  const _NewChaptersSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestChaptersAsync = ref.watch(homeLatestChaptersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            context.l10n.homeLatest,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ),

        latestChaptersAsync.when(
          data: (chapters) {
            if (chapters.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Text(
                  context.l10n.homeNoMangas,
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
              itemCount: chapters.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final chapter = chapters[index];
                return _HomeChapterTile(chapter: chapter);
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: LinearProgressIndicator(minHeight: 2),
          ),
          error: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              context.l10n.homeNoMangas,
              style: AppTypography.bodyStyle.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeChapterTile extends StatelessWidget {
  final HomeChapter chapter;

  const _HomeChapterTile({required this.chapter});

  @override
  Widget build(BuildContext context) {
    final chapterLabel = context.l10n.chapterLabel(
      chapter.chapterNumber ?? '--',
    );
    final subtitle = chapter.chapterTitle?.trim().isNotEmpty ?? false
        ? chapter.chapterTitle!
        : chapterLabel;

    final routeManga = Manga(
      id: chapter.mangaId,
      title: chapter.mangaTitle,
      coverUrl: chapter.mangaCoverUrl,
    );

    return GestureDetector(
      onTap: () => context.push(
        AppRoutes.mangaDetailPath(chapter.mangaId),
        extra: routeManga,
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 48,
                height: 64,
                child: chapter.mangaCoverUrl == null
                    ? const ColoredBox(
                        color: AppColors.cardHigh,
                        child: Icon(
                          Icons.image,
                          color: AppColors.outline,
                          size: 24,
                        ),
                      )
                    : Image.network(
                        chapter.mangaCoverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: AppColors.cardHigh,
                          child: Icon(
                            Icons.image,
                            color: AppColors.outline,
                            size: 24,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // Chapter info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter.mangaTitle,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Time ago
            Text(
              _formatRelativeTime(chapter.publishAt),
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _ExploreCta extends StatelessWidget {
  const _ExploreCta();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: SizedBox(
        height: 48,
        width: double.infinity,
        child: TextButton(
          onPressed: () => context.go(AppRoutes.explore),
          child: Text(context.l10n.homeExploreCta),
        ),
      ),
    );
  }
}

String _formatRelativeTime(DateTime? date) {
  if (date == null) return '--';
  final now = DateTime.now().toUtc();
  final diff = now.difference(date.toUtc());

  if (diff.inMinutes < 60) {
    return '${diff.inMinutes}m';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours}h';
  }
  return '${diff.inDays}d';
}
