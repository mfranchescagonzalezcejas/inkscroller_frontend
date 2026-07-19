import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/design_tokens.dart';
import '../../../library/presentation/providers/library/library_provider.dart';
import '../../domain/entities/home_chapter.dart';
import '../providers/home_latest_chapters_provider.dart';
import '../providers/home_provider.dart';
import '../providers/home_state.dart';
import '../widgets/continue_reading_section.dart';
import '../widgets/hero_carousel.dart';
import '../widgets/home_discover_section.dart';
import '../widgets/home_latest_chapters.dart';
import '../widgets/home_recommended_section.dart';
import '../widgets/home_shimmer.dart';

/// Home feed — trending carousel, continue reading, discover, recommendations,
/// and latest chapters.
///
/// Does NOT render an AppTopBar or genre tabs. Bottom navigation is external.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for precache opportunities
    ref.listen<HomeState>(homeProvider, (_, next) {
      if (next.featured.isNotEmpty) _precacheHome(context, next);
    });
    ref.listen<AsyncValue<List<HomeChapter>>>(
      homeLatestChaptersProvider,
      (_, next) => next.whenData(
        (chapters) => _precacheChapters(context, chapters),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.voidLowest,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.card,
        onRefresh: () => _refreshHome(ref),
        child: const _HomeBody(),
      ),
    );
  }

  /// Pull-to-refresh: invalidate all home providers so they re-fetch.
  Future<void> _refreshHome(WidgetRef ref) async {
    ref.invalidate(homeProvider);
    ref.invalidate(homeLatestChaptersProvider);

    try {
      await ref.read(homeLatestChaptersProvider.future);
    } catch (_) {
      // Refresh is best-effort; errors are handled per-section already.
    }
  }

  /// Bounded precache — hero covers only, capped at 3.
  static void _precacheHome(BuildContext context, HomeState state) {
    if (!context.mounted) return;
    for (final manga in state.featured.take(3)) {
      final url = manga.coverUrl;
      if (url != null && url.isNotEmpty) {
        try {
          unawaited(
            precacheImage(CachedNetworkImageProvider(url), context),
          );
        } catch (_) {}
      }
    }
  }

  static void _precacheChapters(
    BuildContext context,
    List<HomeChapter> chapters,
  ) {
    if (!context.mounted) return;
    for (final ch in chapters.take(5)) {
      final url = ch.mangaCoverUrl;
      if (url != null && url.isNotEmpty) {
        try {
          unawaited(precacheImage(NetworkImage(url), context));
        } catch (_) {}
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────
// HomeBody — composes all sections
// ─────────────────────────────────────────────────────────────────────────

class _HomeBody extends ConsumerWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Full-page loading skeleton while the library first hydrates.
    final libraryState = ref.watch(libraryProvider);
    if (libraryState.isLoading && libraryState.mangas.isEmpty) {
      return const HomeShimmer();
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.md,
      ),
      children: const [
        // 1. Hero swipeable de tendencias
        HeroCarousel(),

        // 2. Continue reading
        ContinueReadingSection(),

        // 3. Discover filter + manga row
        DiscoverSection(),

        // 4. Recommendations
        RecommendedSection(),

        // 5. Latest chapters
        LatestChaptersSection(),
      ],
    );
  }
}
