import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkscroller_flutter/core/l10n/l10n.dart';
import 'package:inkscroller_flutter/core/network/connectivity_status_provider.dart';
import 'package:inkscroller_flutter/core/router/app_routes.dart';
import 'package:inkscroller_flutter/core/widgets/offline_banner.dart';
import 'package:inkscroller_flutter/features/library/presentation/widgets/cover_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/design/design_tokens.dart'
    show AppColors, AppSpacing, AppTypography;
import '../../../../core/feedback/app_feedback.dart';
import '../../../preferences/presentation/providers/preferences_provider.dart';
import '../../domain/chapter_progress_utils.dart';
import '../../domain/entities/chapter.dart';
import '../../domain/entities/manga.dart';
import '../../domain/entities/manga_reading_progress.dart';
import '../../domain/entities/reader_mode.dart';
import '../providers/chapters/manga_chapter_provider.dart';
import '../providers/chapters/manga_chapter_state.dart';
import '../providers/per_title_override_provider.dart';
import '../providers/reading_progress_provider.dart';
import '../providers/user_library_provider.dart';
import '../widgets/chapter_tile.dart';
import '../widgets/manga_detail_shimmer.dart';

/// Manga detail page matching inkscroller.pen design (node paPg4).
///
/// Structure: TopBar (overlay) · Cover · Tags · Title+Meta · CTA · Chapters
class MangaDetailPage extends ConsumerStatefulWidget {
  final Manga manga;

  const MangaDetailPage({super.key, required this.manga});

  @override
  ConsumerState<MangaDetailPage> createState() => _MangaDetailPageState();
}

class _MangaDetailPageState extends ConsumerState<MangaDetailPage> {
  bool _preferencesRequested = false;
  late final ProviderSubscription _mangaChaptersSub;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(mangaChaptersProvider.notifier).loadChapters(widget.manga.id);
      final prefsState = ref.read(preferencesProvider);
      if (!_preferencesRequested && prefsState.preferences == null) {
        _preferencesRequested = true;
        ref.read(preferencesProvider.notifier).loadPreferences();
      }
    });
    // Sync reading progress when chapters change — lives here, not in build().
    _mangaChaptersSub = ref.listenManual<MangaChaptersState>(
      mangaChaptersProvider,
      (prev, next) {
        if (next.chapters.isEmpty) return;
        // Dedup: skip if the set of chapters hasn't actually changed.
        final prevIds =
            prev?.chapters.map((c) => c.id).toSet() ?? <String>{};
        final nextIds = next.chapters.map((c) => c.id).toSet();
        if (prevIds.length == nextIds.length &&
            prevIds.containsAll(nextIds)) {
          return;
        }
        ref
            .read(readingProgressProvider.notifier)
            .syncChapters(widget.manga.id, next.chapters);
      },
    );
  }

  @override
  void dispose() {
    _mangaChaptersSub.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mangaChaptersProvider);
    final progress = ref.watch(
      readingProgressProvider.select(
        (value) =>
            value[widget.manga.id] ??
            MangaReadingProgress(mangaId: widget.manga.id),
      ),
    );
    final bool isOffline = ref
        .watch(connectivityStatusProvider)
        .maybeWhen(data: (isOnline) => !isOnline, orElse: () => false);

    return Scaffold(
      backgroundColor: AppColors.voidLowest,
      appBar: _DetailTopBar(manga: widget.manga),
      body: Column(
        children: <Widget>[
          if (isOffline) const OfflineBanner(),
          Expanded(
            child: CustomScrollView(
              slivers: <Widget>[
                // ── Cover section ─────────────────────────────────
                SliverToBoxAdapter(child: _CoverSection(manga: widget.manga)),

                // ── Tags row ─────────────────────────────────────
                SliverToBoxAdapter(child: _TagsRow(manga: widget.manga)),

                // ── Title + Meta ──────────────────────────────────
                SliverToBoxAdapter(child: _TitleArea(manga: widget.manga)),

                // ── CTA button ────────────────────────────────────
                SliverToBoxAdapter(
                  child: _CtaButton(
                    label: context.l10n.readNow.toUpperCase(),
                    onTap: () {
                      final chapters = ref.read(mangaChaptersProvider).chapters;
                      if (chapters.isNotEmpty) {
                        final first = chapters.first;
                        context.push(
                          AppRoutes.readerPath(
                            mangaId: widget.manga.id,
                            chapterId: first.id,
                          ),
                          extra: first,
                        );
                      }
                    },
                  ),
                ),

                // ── Per-title reader mode override ────────────────
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: _ReaderModeOverride(),
                  ),
                ),

                // ── Chapters section ──────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _ChaptersHeader(
                      count: state.chapters.length,
                      progress: progress,
                    ),
                  ),
                ),

                if (state.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: MangaDetailShimmer()),
                  )
                else if (state.failure != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              context.l10n.failedToLoadChapters,
                              style: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.failure!.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => ref
                                  .read(mangaChaptersProvider.notifier)
                                  .loadChapters(widget.manga.id),
                              child: Text(context.l10n.retryAction),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (state.chapters.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        context.l10n.noChaptersAvailable,
                        style: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final chapter = state.chapters[index];
                      return ChapterTile(
                        chapter: chapter,
                        isRead: progress.isChapterRead(chapter.id),
                        onTap: () async {
                          await _handleChapterTap(
                            context,
                            chapter,
                            state.chapters,
                          );
                        },
                      );
                    }, childCount: state.chapters.length),
                  ),

                // safe bottom padding for floating nav
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleChapterTap(
    BuildContext context,
    Chapter chapter,
    List<Chapter> chapters,
  ) async {
    final int unreadCount = ref
        .read(readingProgressProvider.notifier)
        .unreadCountThrough(
          mangaId: widget.manga.id,
          chapters: chapters.cast(),
          targetChapterId: chapter.id,
        );

    if (unreadCount > 1 || (chapter.external && unreadCount > 0)) {
      final bool shouldMark =
          await _showMarkProgressDialog(context, chapter, unreadCount) ?? false;
      if (!context.mounted) {
        return;
      }

      if (shouldMark) {
        await _markThroughAndOfferUndo(context, chapter.id, chapters);
      } else if (chapter.external) {
        await _openExternalChapter(context, chapter);
        return;
      }
    } else if (unreadCount == 1) {
      await _markThroughAndOfferUndo(context, chapter.id, chapters);
    }

    if (!context.mounted) {
      return;
    }

    if (chapter.external) {
      await _openExternalChapter(context, chapter);
      return;
    }

    if (chapter.readable) {
      await context.push(
        AppRoutes.readerPath(
          mangaId: widget.manga.id,
          chapterId: chapter.id,
        ),
        extra: chapter,
      );
    }
  }

  Future<bool?> _showMarkProgressDialog(
    BuildContext context,
    Chapter chapter,
    int unreadCount,
  ) {
    final String chapterLabel = chapter.number == null
        ? context.l10n.extraLabel
        : context.l10n.chapterLabel(formatChapterNumber(chapter.number!));

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.readingProgressDialogTitle),
        content: Text(
          chapter.external
              ? context.l10n.readingProgressDialogExternalMessage(
                  unreadCount,
                  chapterLabel,
                )
              : context.l10n.readingProgressDialogMessage(
                  unreadCount,
                  chapterLabel,
                ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              chapter.external
                  ? context.l10n.readingProgressOpenOnlyAction
                  : context.l10n.externalChapterGoBackAction,
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.readingProgressConfirmAction),
          ),
        ],
      ),
    );
  }

  Future<void> _markThroughAndOfferUndo(
    BuildContext context,
    String targetChapterId,
    List<Chapter> chapters,
  ) async {
    final previous = await ref
        .read(readingProgressProvider.notifier)
        .markThrough(
          mangaId: widget.manga.id,
          chapters: chapters,
          targetChapterId: targetChapterId,
        );
    if (previous == null || !context.mounted) {
      return;
    }

    AppFeedback.showUndo(
      context,
      title: context.l10n.readingProgressUpdatedMessage,
      onUndo: () {
        ref.read(readingProgressProvider.notifier).restore(previous);
      },
    );
  }

  Future<void> _openExternalChapter(
    BuildContext context,
    Chapter chapter,
  ) async {
    final String? externalUrl = chapter.externalUrl;
    if (externalUrl == null || externalUrl.isEmpty) {
      await context.push(
        AppRoutes.readerPath(
          mangaId: widget.manga.id,
          chapterId: chapter.id,
        ),
        extra: chapter,
      );
      return;
    }

    final uri = Uri.parse(externalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ── TopBar ────────────────────────────────────────────────────────────────────

class _DetailTopBar extends ConsumerWidget implements PreferredSizeWidget {
  final Manga manga;

  const _DetailTopBar({required this.manga});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isInLibrary = ref.watch(
      userLibraryProvider.select(
        (value) => value[manga.id]?.isInLibrary ?? false,
      ),
    );

    return AppBar(
      backgroundColor: AppColors.stage,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(
          Icons.arrow_back,
          color: AppColors.onSurface,
          size: 24,
        ),
      ),
      title: Text(
        manga.title,
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: <Widget>[
        IconButton(
          onPressed: () async {
            final bool nowInLibrary = await ref
                .read(userLibraryProvider.notifier)
                .toggle(manga);
            if (!context.mounted) {
              return;
            }

            if (nowInLibrary) {
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
          },
          icon: Icon(
            isInLibrary ? Icons.bookmark : Icons.bookmark_border,
            color: AppColors.onSurface,
            size: 24,
          ),
        ),
      ],
    );
  }
}

// ── Cover Section ─────────────────────────────────────────────────────────────

class _CoverSection extends StatelessWidget {
  final Manga manga;

  const _CoverSection({required this.manga});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Radial gradient background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: <Color>[
                    Color(0x330F766E), // teal tint centre
                    Color(0xFF080F10), // void edge
                  ],
                ),
              ),
            ),
          ),
          // Cover image with glow shadow
          Container(
            width: 140,
            height: 195,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x660F766E),
                  blurRadius: 40,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CoverImage(url: manga.coverUrl),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tags Row ─────────────────────────────────────────────────────────────────

class _TagsRow extends StatelessWidget {
  final Manga manga;

  const _TagsRow({required this.manga});

  @override
  Widget build(BuildContext context) {
    final List<String> tags = <String>[
      if (manga.status != null) manga.status!.toUpperCase(),
      ...manga.genres.take(3).map((g) => g.toUpperCase()),
      if (manga.demographic != null) manga.demographic!.toUpperCase(),
    ];

    if (tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: tags.asMap().entries.map((entry) {
          final bool isFirst = entry.key == 0;
          return _Tag(label: entry.value, isStatus: isFirst);
        }).toList(),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final bool isStatus;

  const _Tag({required this.label, this.isStatus = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2122),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (isStatus) ...<Widget>[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              fontWeight: isStatus ? FontWeight.w600 : FontWeight.w400,
              color: isStatus
                  ? AppColors.onSurface
                  : AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Title + Meta ──────────────────────────────────────────────────────────────

class _TitleArea extends StatelessWidget {
  final Manga manga;

  const _TitleArea({required this.manga});

  @override
  Widget build(BuildContext context) {
    final String? scoreStr = manga.score?.toStringAsFixed(1);
    final String meta = <String>[
      if (scoreStr != null) '★ $scoreStr',
      if (manga.rank != null) '${manga.rank} readers',
    ].join('  ·  ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        children: <Widget>[
          Text(
            manga.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          if (meta.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              meta,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── CTA Button ───────────────────────────────────────────────────────────────

class _CtaButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _CtaButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFF0F766E), Color(0xFF1E40AF)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.play_arrow, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Chapters Header ──────────────────────────────────────────────────────────

class _ChaptersHeader extends StatelessWidget {
  final int count;
  final MangaReadingProgress progress;

  const _ChaptersHeader({required this.count, required this.progress});

  @override
  Widget build(BuildContext context) {
    final int total = progress.hasKnownTotal
        ? progress.totalChaptersCount
        : count;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              context.l10n.chaptersTitle,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.libraryProgressValue(
                progress.readChaptersCount,
                total,
              ),
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const Icon(Icons.tune, color: Color(0xFF889391), size: 22),
      ],
    );
  }
}

// ── Chapter Tile (pen design) ────────────────────────────────────────────────
// (see chapter_tile.dart — updated separately)

// ── Reader Mode Override ──────────────────────────────────────────────────────

class _ReaderModeOverride extends ConsumerWidget {
  const _ReaderModeOverride();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mangaId = GoRouterState.of(context).pathParameters['mangaId'];
    if (mangaId == null) return const SizedBox.shrink();

    final overrideState = ref.watch(perTitleOverrideProvider(mangaId));
    final notifier = ref.read(perTitleOverrideProvider(mangaId).notifier);
    final prefsState = ref.watch(preferencesProvider);
    final globalMode = prefsState.preferences?.defaultReaderMode;
    final rawOverride = overrideState?.preferredReaderMode;

    if (globalMode != null) {
      final hasOverride = rawOverride != null && rawOverride != globalMode;
      final otherMode = globalMode == ReaderMode.vertical
          ? ReaderMode.paged
          : ReaderMode.vertical;
      final otherLabel = globalMode == ReaderMode.vertical
          ? 'Paginado'
          : 'Vertical';
      final globalLabel =
          'Tu preferencia: ${globalMode == ReaderMode.vertical ? "Vertical" : "Paginado"}';

      final items = <DropdownMenuItem<ReaderMode?>>[
        DropdownMenuItem<ReaderMode?>(child: Text(globalLabel)),
        DropdownMenuItem<ReaderMode>(value: otherMode, child: Text(otherLabel)),
      ];

      return _buildDropdown(
        items: items,
        value: hasOverride ? rawOverride : null,
        notifier: notifier,
      );
    }

    const items = <DropdownMenuItem<ReaderMode?>>[
      DropdownMenuItem<ReaderMode?>(child: Text('Predeterminado (Vertical)')),
      DropdownMenuItem<ReaderMode>(
        value: ReaderMode.vertical,
        child: Text('Vertical'),
      ),
      DropdownMenuItem<ReaderMode>(
        value: ReaderMode.paged,
        child: Text('Paginado'),
      ),
    ];

    return _buildDropdown(items: items, value: rawOverride, notifier: notifier);
  }

  Widget _buildDropdown({
    required List<DropdownMenuItem<ReaderMode?>> items,
    required ReaderMode? value,
    required PerTitleOverrideNotifier notifier,
  }) {
    return Row(
      children: <Widget>[
        const Icon(
          Icons.bookmark_border,
          size: 20,
          color: AppColors.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: DropdownButtonFormField<ReaderMode?>(
            initialValue: value,
            decoration: const InputDecoration(
              labelText: 'Modo de lectura para este título',
              helperText: 'Anula tu preferencia global solo para este manga',
            ),
            items: items,
            onChanged: (newValue) {
              if (newValue == null) {
                notifier.clearOverride();
              } else {
                notifier.setMode(newValue);
              }
            },
          ),
        ),
      ],
    );
  }
}
