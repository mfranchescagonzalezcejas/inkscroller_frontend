import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/widgets/catalog_tab_bar.dart';
import '../../../library/presentation/widgets/manga_tile.dart';
import '../providers/home_discover_provider.dart';
import '../constants/home_layout.dart';
import 'home_section_header.dart';
import 'home_shimmer.dart';

/// Discover section with filter tabs and manga grid.
///
/// Uses its own [homeDiscoverProvider] (isolated [LibraryNotifier]) so it
/// never contaminates [libraryProvider] or [exploreProvider].
class DiscoverSection extends ConsumerWidget {
  const DiscoverSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(homeDiscoverFilterProvider);
    final libraryState = ref.watch(homeDiscoverProvider);
    final mangas = ref.watch(homeDiscoverMangasProvider);
    final l10n = context.l10n;

    final labels = <String>[
      l10n.genreAll,
      l10n.genrePopular,
      l10n.genreRomance,
      l10n.genreAction,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(title: l10n.homeDiscover),

        // ── Filter tabs (same as Explore / Library) ─────────────────
        CatalogTabBar(
          labels: labels,
          selectedIndex: filter.index,
          onSelected: (i) => triggerDiscoverFilter(
            ref,
            HomeDiscoverFilter.values[i],
          ),
        ),

        const SizedBox(height: 12),

        // ── Manga row — same MangaTile sizing as Explore ──────────────
        SizedBox(
          height: HomeLayout.discoverRowHeight,


          child: libraryState.isLoading && mangas.isEmpty
              ? const HomeShimmer.cardRow()
              : mangas.isEmpty
                  ? const SizedBox.shrink()
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: mangas.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => SizedBox(
                        width: HomeLayout.mangaCardWidth,
                        child: MangaTile(manga: mangas[i]),
                      ),
                    ),
        ),
      ],
    );
  }
}
