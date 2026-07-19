import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design_tokens.dart';
import '../../../../core/feedback/app_feedback.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../constants/home_layout.dart';
import '../providers/home_provider.dart';
import '../providers/home_latest_chapters_provider.dart';
import '../providers/home_state.dart';
import '../../domain/entities/home_chapter.dart';
import '../../../library/presentation/providers/library/library_provider.dart';
import '../../../library/presentation/providers/library/library_notifier.dart';
import '../../../library/presentation/widgets/manga_tile.dart';
import '../../../library/presentation/widgets/library_shimmer.dart';
import '../../../library/presentation/providers/user_library_provider.dart';
import '../../../library/domain/entities/manga.dart';

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
      ...state.latest.take(10),
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
    final homeState = ref.watch(homeProvider);
    final authState = ref.watch(authProvider);

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
      appBar: AppTopBar(authState: authState),
      body: libraryState.isLoading && libraryState.mangas.isEmpty
          ? const LibraryShimmer()
          : Stack(
              children: [
                RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.card,
                  onRefresh: () =>
                      ref.read(libraryProvider.notifier).refresh(),
                  child: _HomeBody(homeState: homeState),
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

class _HomeBody extends StatelessWidget {
  final HomeState homeState;

  const _HomeBody({required this.homeState});

  @override
  Widget build(BuildContext context) {
    // If there's no data, show empty state
    final hasContent =
        homeState.featured.isNotEmpty ||
        homeState.latest.isNotEmpty ||
        homeState.popular.isNotEmpty ||
        homeState.shounen.isNotEmpty ||
        homeState.shoujo.isNotEmpty ||
        homeState.seinen.isNotEmpty ||
        homeState.josei.isNotEmpty;

    if (!hasContent) {
      return Center(
        child: Text(
          context.l10n.homeNoMangas,
          style: AppTypography.bodyStyle.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 100), // Space for bottom nav bar
      children: [
        // Hero - Full bleed image per design
        if (homeState.featured.isNotEmpty)
          _HeroSection(mangas: homeState.featured),

        // Genre tabs + Trending section (filtered by selected tab)
        _GenreTabsSection(homeState: homeState),

        // New Chapters section - backed by homeLatestChaptersProvider
        const _NewChaptersSection(),
      ],
    );
  }
}

class _HeroSection extends ConsumerWidget {
  final List<Manga> mangas;

  const _HeroSection({required this.mangas});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (mangas.isEmpty) return const SizedBox.shrink();

    // Show first manga as hero
    final heroManga = mangas.first;
    final bool isInLibrary = ref.watch(
      userLibraryProvider.select(
        (value) => value[heroManga.id]?.isInLibrary ?? false,
      ),
    );
    final coverUrl = heroManga.coverUrl;

    // Don't show hero if no cover
    if (coverUrl == null || coverUrl.isEmpty) return const SizedBox.shrink();

    final double? safeScore = heroManga.score;

    // Build meta string: "Manga · Seinen" etc
    final metaParts = <String>[];
    if (heroManga.typeDisplay != null) metaParts.add(heroManga.typeDisplay!);
    if (heroManga.demographicDisplay != null) {
      metaParts.add(heroManga.demographicDisplay!);
    }
    final metaString = metaParts.isNotEmpty ? metaParts.join(' · ') : null;

    return SizedBox(
      height: 380,
      width: double.infinity,
      child: Stack(
        children: [
          // Hero image - full bleed (no margins)
          Positioned.fill(
            child: Image.network(
              coverUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: AppColors.card,
                child: Center(
                  child: Icon(
                    Icons.image_not_supported,
                    color: AppColors.outline,
                  ),
                ),
              ),
            ),
          ),
          // Gradient overlay - starts transparent at top, void at bottom
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.voidLowest.withValues(alpha: 0.93), // #080F10EE
                  ],
                ),
              ),
            ),
          ),
          // Content at bottom — .pen HeroOverlay padding=[0,20,28,20]
          // top=0, right=20, bottom=28, left=20
          Positioned(
            left: 20,
            right: 20,
            bottom: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Trending badge + Rating row
                Row(
                  children: [
                    // Trending badge
                    _buildTrendingBadge(),
                    const SizedBox(width: 12),
                    // Rating (if score available)
                    _buildRating(safeScore),
                  ],
                ),
                const SizedBox(height: 12),
                // Title - 28px, fontWeight 700 per design
                Text(
                  heroManga.title,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Meta: "Manga · Seinen"
                if (metaString != null)
                  Text(
                    metaString,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 16),
                // Action buttons — Expanded with asymmetric flex (5:7) gives
                // "Añadir a biblioteca" ~58 % of the available width so its
                // icon + longer label never truncate on 360 / 375 px viewports.
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildGradientButton(
                        context.l10n.readNow,
                        () => context.push(
                          AppRoutes.mangaDetailPath(heroManga.id),
                          extra: heroManga,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 7,
                      child: _buildLibraryButton(
                        isInLibrary
                            ? context.l10n.removeFromLibrary
                            : context.l10n.addToLibrary,
                        isInLibrary: isInLibrary,
                        onTap: () async {
                          final bool nowInLibrary = await ref
                              .read(userLibraryProvider.notifier)
                              .toggle(heroManga);
                          if (!context.mounted) {
                            return;
                          }

                          if (nowInLibrary) {
                            AppFeedback.showSuccess(
                              context,
                              title: context.l10n.libraryItemAdded(
                                heroManga.title,
                              ),
                            );
                          } else {
                            AppFeedback.showInfo(
                              context,
                              title: context.l10n.libraryItemRemoved(
                                heroManga.title,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingBadge() {
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
          const Text(
            'TRENDING',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRating(double? score) {
    final String scoreLabel = score?.toStringAsFixed(1) ?? 'N/A';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, color: AppColors.primary, size: 14),
        const SizedBox(width: 4),
        Text(
          scoreLabel,
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildGradientButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // width: double.infinity fills the Flexible cell, keeping button
        // widths balanced and avoiding intrinsic-size overflow.
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F766E), Color(0xFF1E40AF)],
            transform: GradientRotation(315 * 3.14159 / 180), // 315° in radians
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }

  Widget _buildLibraryButton(
    String text, {
    required bool isInLibrary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // width: double.infinity fills the Expanded cell. Horizontal padding
        // reduced to 12 (vs 16 on the gradient button) to give the longer
        // label + icon combo extra breathing room on 360 px viewports.
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isInLibrary ? Icons.check : Icons.add,
              color: AppColors.onSurface,
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSection extends StatelessWidget {
  final String title;
  final List<Manga> mangas;
  final bool isTrending; // true for trending section

  const _HomeSection({
    required this.title,
    required this.mangas,
    this.isTrending = false,
  });

  @override
  Widget build(BuildContext context) {
    if (mangas.isEmpty) return const SizedBox.shrink();

    // Per design: reduced padding for trending
    final double topPadding = isTrending ? 16.0 : AppSpacing.xl;
    final double rightPadding = isTrending ? 0.0 : AppSpacing.lg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            topPadding,
            rightPadding,
            AppSpacing.sm,
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ),
        SizedBox(
          height: isTrending ? 220 : HomeLayout.mangaCardRowHeight,
          child: ListView.separated(
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: mangas.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              // Use trending card style for trending section
              if (isTrending) {
                return _TrendingMangaCard(manga: mangas[index]);
              }
              return SizedBox(
                width: HomeLayout.mangaCardWidth,
                child: MangaTile(manga: mangas[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TrendingMangaCard extends StatelessWidget {
  final Manga manga;

  const _TrendingMangaCard({required this.manga});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.push(AppRoutes.mangaDetailPath(manga.id), extra: manga),
      child: Container(
        width: 160,
        height: 220,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          children: [
            // Cover image
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: manga.coverUrl != null
                    ? Image.network(
                        manga.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: AppColors.card,
                          child: Icon(Icons.image, color: AppColors.outline),
                        ),
                      )
                    : const ColoredBox(
                        color: AppColors.card,
                        child: Icon(Icons.image, color: AppColors.outline),
                      ),
              ),
            ),
            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.voidLowest.withValues(alpha: 0.87),
                    ],
                  ),
                ),
              ),
            ),
            // Rating badge (top-right)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cardHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      color: manga.score != null
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      manga.score?.toStringAsFixed(1) ?? '--',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: manga.score != null
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Title at bottom
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Text(
                manga.title,
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section with genre tabs that filter the trending content shown below.
/// Tabs: All, Popular, Romance, Action - each filters the displayed manga list.
///
/// Uses server-side filtering via [libraryProvider] - backend returns
/// filtered results via /manga?genre=romance, /manga?genre=action, etc.
class _GenreTabsSection extends ConsumerStatefulWidget {
  final HomeState homeState;

  const _GenreTabsSection({required this.homeState});

  @override
  ConsumerState<_GenreTabsSection> createState() => _GenreTabsSectionState();
}

class _GenreTabsSectionState extends ConsumerState<_GenreTabsSection>
    with AutomaticKeepAliveClientMixin {
  int _selectedTabIndex = 0; // 0=All, 1=Popular, 2=Romance, 3=Action

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Watch library provider for server-filtered manga list
    final libraryState = ref.watch(libraryProvider);
    final libraryMangas = libraryState.mangas;

    // Labels: All, Popular, Romance, Action
    final labels = <String>[
      context.l10n.genreAll,
      context.l10n.genrePopular,
      context.l10n.genreRomance,
      context.l10n.genreAction,
    ];

    // Get the manga list from library provider (server-filtered)
    final mangaList = libraryMangas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Genre tabs - reduced padding
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: List.generate(labels.length, (index) {
              final isSelected = _selectedTabIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedTabIndex = index);

                    // Map tab index to action
                    // 0=All (no filter), 1=Popular (order=popular), 2=Romance, 3=Action
                    if (index == 1) {
                      // Popular - use LibraryMode.popular
                      ref
                          .read(libraryProvider.notifier)
                          .loadInitial(mode: LibraryMode.popular);
                    } else {
                      // All, Romance, Action - use genre filter
                      const genres = [null, 'romance', 'action'];
                      // Adjust index: index 2->'romance', index 3->'action'
                      final genre = index > 1 ? genres[index - 1] : null;
                      ref.read(libraryProvider.notifier).setGenre(genre);
                    }
                  },
                  child: Container(
                    margin: EdgeInsets.only(
                      right: index < labels.length - 1 ? 4 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        labels[index],
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          fontSize: 11,
                          color: isSelected
                              ? AppColors.voidLowest
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 8),

        // Trending section with filtered content
        if (mangaList.isNotEmpty)
          _HomeSection(
            title: context.l10n.homePopular,
            mangas: mangaList,
            isTrending: true,
          ),
      ],
    );
  }
}

/// New Chapters section - displays latest chapter updates from the backend.
///
/// Connected to [homeLatestChaptersProvider] which calls the use case.
/// Displays: manga cover, title, chapter number, relative time.
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
