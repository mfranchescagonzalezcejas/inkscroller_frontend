import 'package:flutter/material.dart';

import '../../../../core/design/design_tokens.dart';
import '../../../library/domain/entities/manga.dart';
import '../constants/home_layout.dart';
import '../../../library/presentation/widgets/manga_tile.dart';
import 'home_shimmer.dart';

/// Horizontal scrollable row of manga tiles with a section title.
///
/// Shows a shimmer placeholder while [isLoading], hides completely when
/// [mangas] is empty (no empty state — just invisible).
class DemographicMangaRow extends StatelessWidget {
  final List<Manga> mangas;
  final String title;
  final bool isLoading;

  const DemographicMangaRow({
    super.key,
    required this.mangas,
    required this.title,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title),
          const SizedBox(height: 8),
          const HomeShimmer.cardRow(),
        ],
      );
    }

    if (mangas.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title),
        const SizedBox(height: 8),
        SizedBox(
          height: HomeLayout.mangaCardRowHeight,
          child: ListView.separated(
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: mangas.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) => SizedBox(
              width: HomeLayout.mangaCardWidth,
              child: MangaTile(manga: mangas[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
      ),
    );
  }
}
