import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inkscroller_flutter/core/l10n/l10n.dart';
import 'package:inkscroller_flutter/core/router/app_routes.dart';
import 'package:inkscroller_flutter/features/library/presentation/constants/library_ui_constants.dart';

import '../../../../core/design/design_tokens.dart';
import '../../domain/entities/manga.dart';
import 'cover_image.dart';

/// Presentational card widget that displays a manga cover and title.
///
/// Tapping the tile navigates to [MangaDetailPage] via go_router.
/// Uses [CoverImage] for cached network image rendering.
class MangaTile extends StatelessWidget {
  final Manga manga;
  final int? readChaptersCount;
  final int? totalChaptersCount;

  const MangaTile({
    super.key,
    required this.manga,
    this.readChaptersCount,
    this.totalChaptersCount,
  });

  @override
  Widget build(BuildContext context) {
    final double? safeScore = manga.score;
    final String badgeLabel = safeScore?.toStringAsFixed(1) ?? '--';
    final String secondaryMeta =
        manga.status ??
        (manga.year != null
            ? '${manga.year}'
            : context.l10n.libraryUnknownMeta);
    final int? effectiveReadCount =
        readChaptersCount ?? manga.readChaptersCount;
    final int? effectiveTotalCount =
        totalChaptersCount ?? manga.totalChaptersCount;
    final bool showProgress =
        effectiveReadCount != null &&
        effectiveTotalCount != null &&
        effectiveTotalCount > 0;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: () {
          context.push(AppRoutes.mangaDetailPath(manga.id), extra: manga);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: AspectRatio(
            aspectRatio: 2 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 🖼 Imagen de portada
                CoverImage(url: manga.coverUrl),

                // 🌑 Degradado inferior
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: LibraryUiConstants.cardOverlayHeight,
                    padding: const EdgeInsets.fromLTRB(
                      LibraryUiConstants.cardOverlayHorizontalPadding,
                      0,
                      LibraryUiConstants.cardOverlayHorizontalPadding,
                      LibraryUiConstants.cardOverlayBottomPadding,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.voidLowest.withValues(alpha: 0.93),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          manga.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.onSurface,
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          secondaryMeta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            height: 1.2,
                          ),
                        ),
                        if (showProgress) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.libraryProgressValue(
                              effectiveReadCount,
                              effectiveTotalCount,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ⭐ Rating badge (top-left)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.star,
                          size: 12,
                          color: safeScore != null
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          badgeLabel,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: safeScore != null
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
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
