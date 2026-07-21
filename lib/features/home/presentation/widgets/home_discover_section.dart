import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/widgets/catalog_tab_bar.dart';
import '../../../library/presentation/constants/library_ui_constants.dart';
import '../../../library/presentation/widgets/manga_tile.dart';
import '../providers/home_provider.dart';
import 'home_section_header.dart';
import 'home_shimmer.dart';

/// Discover section with filter tabs and manga grid.
///
/// Comparte el mismo [homeDataProvider] que el Hero y Recommended, evitando
/// duplicar requests. Los cambios de filtro usan el tab cache compartido.
class DiscoverSection extends ConsumerWidget {
  const DiscoverSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(homeDiscoverFilterProvider);
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

        // ── Manga row con transición suave shimmer → contenido ──
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: mangas.isEmpty
              ? const HomeShimmer.cardRow()
              : LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxisCount = width >= 600 ? 3 : 2;
                      final tileWidth = (width -
                              LibraryUiConstants.horizontalPadding * 2 -
                              LibraryUiConstants.gridCrossSpacing * (crossAxisCount - 1)) /
                          crossAxisCount;
                      final rowHeight = tileWidth * 1.5 + 40;
                      return SizedBox(
                        height: rowHeight.clamp(200, 320),
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: mangas.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (_, i) => SizedBox(
                            width: tileWidth,
                            child: MangaTile(manga: mangas[i]),
                          ),
                        ),
                      );
                    },
                  ),
              ),
      ],
    );
  }
}
