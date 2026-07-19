import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/design_tokens.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/router/app_routes.dart';
import '../../../library/domain/entities/manga.dart';
import '../providers/home_discover_provider.dart';
import 'home_section_header.dart';
import 'home_shimmer.dart';

/// Discover section with filter chips and manga row.
///
/// Uses its own filter state ([homeDiscoverFilterProvider]) so it never
/// contaminates [libraryProvider].
class DiscoverSection extends ConsumerWidget {
  const DiscoverSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(homeDiscoverFilterProvider);
    final mangas = ref.watch(homeDiscoverMangasProvider);
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(title: l10n.homeDiscover),
        const SizedBox(height: 4),

        // ── Filter chips ──────────────────────────────────────────────
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final f = _filters[i];
              final isSelected = filter == f.filter;
              return _DiscoverFilterChip(
                label: f.label(l10n),
                icon: f.icon,
                isSelected: isSelected,
                onTap: () =>
                    ref.read(homeDiscoverFilterProvider.notifier).state =
                        f.filter,
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // ── Manga row ─────────────────────────────────────────────────
        SizedBox(
          height: 220,
          child: mangas.isEmpty
              ? const HomeShimmer.cardRow()
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: mangas.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _CompactCard(manga: mangas[i]),
                ),
        ),
      ],
    );
  }
}

// ── Filter definition ─────────────────────────────────────────────────────

const _filters = <_FilterDef>[
  _FilterDef(HomeDiscoverFilter.all, Icons.grid_view, _allLabel),
  _FilterDef(
    HomeDiscoverFilter.popular,
    Icons.local_fire_department,
    _popularLabel,
  ),
  _FilterDef(HomeDiscoverFilter.romance, Icons.favorite_border, _romanceLabel),
  _FilterDef(HomeDiscoverFilter.action, Icons.sports_kabaddi, _actionLabel),
];

String _allLabel(AppLocalizations l10n) => l10n.genreAll;
String _popularLabel(AppLocalizations l10n) => l10n.genrePopular;
String _romanceLabel(AppLocalizations l10n) => l10n.genreRomance;
String _actionLabel(AppLocalizations l10n) => l10n.genreAction;

class _FilterDef {
  final HomeDiscoverFilter filter;
  final IconData icon;
  final String Function(AppLocalizations) label;

  const _FilterDef(this.filter, this.icon, this.label);
}

// ── Filter chip widget ───────────────────────────────────────────────────

class _DiscoverFilterChip extends StatelessWidget {
  const _DiscoverFilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Material(
        color: isSelected ? AppColors.primary : AppColors.card,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected
                      ? AppColors.voidLowest
                      : AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? AppColors.voidLowest
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Compact card ─────────────────────────────────────────────────────────

class _CompactCard extends StatelessWidget {
  const _CompactCard({required this.manga});

  final Manga manga;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.push(AppRoutes.mangaDetailPath(manga.id), extra: manga),
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _cardCover(manga.coverUrl),
              ),
            ),
            const SizedBox(height: 6),
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
            if (manga.score != null)
              Row(
                children: [
                  const Icon(Icons.star, size: 12, color: AppColors.scoreGold),
                  const SizedBox(width: 2),
                  Text(
                    manga.score!.toStringAsFixed(1),
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11,
                      color: AppColors.scoreGold,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _cardCover(String? url) {
    if (url == null || url.isEmpty) {
      return const ColoredBox(
        color: AppColors.cardHigh,
        child: Center(
          child: Icon(Icons.image, color: AppColors.outline, size: 24),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) => const ColoredBox(color: AppColors.cardHigh),
      errorWidget: (_, __, ___) => const ColoredBox(
        color: AppColors.cardHigh,
        child: Center(
          child: Icon(Icons.image, color: AppColors.outline, size: 24),
        ),
      ),
      memCacheWidth: 260,
      filterQuality: FilterQuality.medium,
    );
  }
}
