import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:inkscroller_flutter/core/l10n/l10n.dart';
import 'package:inkscroller_flutter/core/network/connectivity_status_provider.dart';
import 'package:inkscroller_flutter/l10n/app_localizations.dart';
import 'package:inkscroller_flutter/core/router/app_routes.dart';
import 'package:inkscroller_flutter/core/widgets/offline_banner.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/design/design_tokens.dart'
    show AppColors, AppTypography;
import '../../../../core/error/failures.dart';
import '../../../../core/feedback/app_feedback.dart';
import '../../../preferences/presentation/providers/preferences_provider.dart';
import '../../domain/chapter_progress_utils.dart';
import '../../domain/entities/chapter.dart';
import '../../domain/entities/chapter_batch.dart';
import '../../domain/entities/manga.dart';
import '../../domain/entities/manga_reading_progress.dart';
import '../../domain/entities/reader_mode.dart';
import '../providers/chapters/manga_chapter_provider.dart';
import '../providers/chapters/manga_chapter_state.dart';
import '../providers/per_title_override_provider.dart';
import '../providers/reading_progress_provider.dart';
import '../providers/user_library_provider.dart';
import '../widgets/chapter_batch_list.dart';
import '../widgets/chapter_tile.dart';
import '../widgets/language_selector.dart';
import '../widgets/manga_detail_shimmer.dart';
import '../widgets/reading_progress_section.dart';

/// Resolves a library [Failure] to a localized error message.
///
/// Maps stable failure codes to the corresponding [AppLocalizations] string.
/// Falls back to [AppLocalizations.libraryErrorNetworkUnknown] for unknown
/// or unexpected failure types.
String _libraryErrorText(Failure? failure, AppLocalizations l10n) {
  if (failure == null) return '';
  final message = failure.message;
  return switch (message) {
    'network/no-connection' => l10n.libraryErrorNetworkNoConnection,
    'server/bad-response' => l10n.libraryErrorServerBadResponse,
    'client/cancelled' => l10n.libraryErrorRequestCancelled,
    'server/invalid-certificate' => l10n.libraryErrorInvalidCertificate,
    'network/unknown' => l10n.libraryErrorNetworkUnknown,
    'server/empty-response' => l10n.libraryErrorEmptyResponse,
    'chapter/external-only' => l10n.libraryErrorExternalChapter,
    _ =>
      failure is NetworkFailure
          ? l10n.libraryErrorNetworkNoConnection
          : failure is ServerFailure
          ? l10n.libraryErrorServerBadResponse
          : l10n.libraryErrorNetworkUnknown,
  };
}

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
    Future.microtask(() async {
      final notifier = ref.read(mangaChaptersProvider.notifier);
      final prefsState = ref.read(preferencesProvider);

      // Show shimmer immediately so the user doesn't see a false empty state
      // while preferences load (P2 Codex finding).
      notifier.setLoading(widget.manga.id);

      // Await preferences if not yet loaded so the correct default language
      // is used for the initial chapters request (P2 Codex finding #4).
      if (!_preferencesRequested && prefsState.preferences == null) {
        _preferencesRequested = true;
        await ref.read(preferencesProvider.notifier).loadPreferences();
      }

      // Guard: if the user left this page while preferences were loading,
      // don't continue with a disposed widget (P2 Codex finding).
      if (!context.mounted) return;

      final updatedPrefs = ref.read(preferencesProvider);
      final defaultLang = updatedPrefs.preferences?.defaultLanguage ?? 'en';

      // Single call: gets available languages, matched language, and chapters.
      await notifier.loadLanguages(widget.manga.id, preferredLang: defaultLang);
    });
    // Sync reading progress when chapters change — lives here, not in build().
    _mangaChaptersSub = ref.listenManual<MangaChaptersState>(
      mangaChaptersProvider,
      (prev, next) {
        if (next.chapters.isEmpty) return;
        // Dedup: skip if the set of chapters hasn't actually changed.
        final prevIds = prev?.chapters.map((c) => c.id).toSet() ?? <String>{};
        final nextIds = next.chapters.map((c) => c.id).toSet();
        if (prevIds.length == nextIds.length && prevIds.containsAll(nextIds)) {
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
    final List<Chapter> displayChapters = organizeChapters(
      state.chapters,
      descending: state.sortDescending,
      readChapterIds: state.filterUnreadOnly ? progress.readChapterIds : null,
    );

    // ── 4-state determination ──────────────────────────────────────
    debugPrint(
      '[DetailPage] build $hashCode '
      'mangaId=${widget.manga.id} '
      'malId=${widget.manga.malId} '
      'totalChaptersCount=${progress.totalChaptersCount} '
      'readChapterIds.len=${progress.readChapterIds.length} '
      'manuallyMarkedCount=${progress.manuallyMarkedCount} '
      'readChaptersCount=${progress.readChaptersCount} '
      'state.chapters=${state.chapters.length} '
      'totalChaptersCount=${progress.totalChaptersCount}',
    );
    // Tracking shows progress readChapters / totalChapters even without
    // Jikan data — totalChaptersCount is derived from max chapter number
    // in the MangaDex list or Jikan total.
    final bool hasTotal = progress.totalChaptersCount > 0;
    final bool hasMdChapters = state.chapters.isNotEmpty;
    final bool showTracking = hasTotal;
    final bool showBatches = showTracking && hasMdChapters;
    final bool showNothing = !showTracking && !hasMdChapters;
    // Batch mode uses the full chapter list (state.chapters) for correct
    // positioning. The read/unread filter is visual only — ChapterTile
    // already shows isRead state via its checkbox. In flat list mode
    // (when batches are off), displayChapters filters read chapters out.
    final bool useBatchList =
        showBatches && progress.totalChaptersCount > progress.batchSize;

    // Cover section height (estimated from content). Used both for the blur
    // background and as the top padding so the scrollable chapters start below
    // the fixed cover content (yellow lines are impossible because there's no
    // SliverToBoxAdapter constraint).
    final double maxCvrHeight = MediaQuery.of(context).size.height * 0.60;
    final double hasDesc = (widget.manga.description?.isNotEmpty ?? false) ? 200.0 : 0.0;
    final double coverSectionHeight = maxCvrHeight + 200.0 + hasDesc;

    return Scaffold(
      backgroundColor: AppColors.voidLowest,
      body: Stack(
        children: <Widget>[
          // ── Blur + gradient fill behind the cover content ──────
          Positioned(
            top: 0, left: 0, right: 0,
            height: coverSectionHeight,
            child: Stack(
              children: <Widget>[
                if (widget.manga.coverUrl != null)
                  Positioned.fill(
                    child: ClipRRect(
                      child: ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: CachedNetworkImage(
                          imageUrl: widget.manga.coverUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.black.withValues(alpha: 0.6),
                          AppColors.voidLowest.withValues(alpha: 0.85),
                          AppColors.voidLowest,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Everything scrolls in one column ──────────────────
          Column(
            children: <Widget>[
              if (isOffline) const OfflineBanner(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      // ── Cover + tags + title + score + desc ──
                      _CoverSection(manga: widget.manga),

                      // ── Reading progress ──────────────────────
                      if (showTracking)
                        ReadingProgressSection(
                          mangaId: widget.manga.id,
                          readCount: progress.readChaptersCount,
                          totalCount: progress.totalChaptersCount,
                          onJumpToChapter: (chapterNumber) {
                            ref
                                .read(readingProgressProvider.notifier)
                                .setManuallyMarkedCountTo(
                                  widget.manga.id,
                                  chapterNumber,
                                  chapters: state.chapters,
                                );
                          },
                        ),

                      // ── Chapters header ───────────────────────
                      if (hasMdChapters || hasTotal)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: _ChaptersHeader(
                            progress: progress,
                            mangaId: widget.manga.id,
                            showLanguageSelector: hasMdChapters,
                          ),
                        ),

                      // ── Chapter states ────────────────────────
                      if (state.isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: MangaDetailShimmer()),
                        )
                      else if (state.failure != null)
                        Padding(
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
                                  _libraryErrorText(state.failure, context.l10n),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FilledButton(
                                  onPressed: () {
                                    final lang = state.selectedLanguage != 'en'
                                        ? state.selectedLanguage
                                        : (ref
                                                  .read(preferencesProvider)
                                                  .preferences
                                                  ?.defaultLanguage ??
                                              'en');
                                    ref
                                        .read(mangaChaptersProvider.notifier)
                                        .loadLanguages(
                                          widget.manga.id,
                                          preferredLang: lang,
                                        );
                                  },
                                  child: Text(context.l10n.retryAction),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (showNothing)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              'No chapters available',
                              style: TextStyle(color: AppColors.onSurfaceVariant),
                            ),
                          ),
                        )
                      else if (useBatchList) ...[
                        ChapterBatchList(
                          mangaId: widget.manga.id,
                          descending: state.sortDescending,
                          hiddenChapterIds: state.filterUnreadOnly
                              ? progress.readChapterIds
                              : null,
                          batches: computeChapterBatches(
                            chapters: state.chapters,
                            totalChaptersCount: progress.totalChaptersCount,
                            batchSize: progress.batchSize,
                          ),
                          onChapterTap: (chapter) async {
                            await _handleChapterTap(
                              context,
                              chapter,
                              state.chapters,
                            );
                          },
                        ),
                        // ── Extra chapters ──────────────────────
                        if (state.chapters.any((ch) => ch.number == null)) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                            child: Text(
                              context.l10n.extrasTitle,
                              style: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          ...state.chapters
                              .where((ch) => ch.number == null)
                              .map((chapter) => ChapterTile(
                                chapter: chapter,
                                isRead: progress.isChapterRead(chapter.id),
                                onTap: () async {
                                  await _handleChapterTap(
                                    context,
                                    chapter,
                                    state.chapters,
                                  );
                                },
                                onToggleRead: () {
                                  ref
                                      .read(readingProgressProvider.notifier)
                                      .toggleChapter(
                                        mangaId: widget.manga.id,
                                        chapterId: chapter.id,
                                        totalChaptersCount:
                                            state.chapters.length,
                                      );
                                },
                              )),
                        ]
                      ] else if (displayChapters.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              'Chapters filtered out',
                              style: TextStyle(
                                  color: AppColors.onSurfaceVariant),
                            ),
                          ),
                        )
                      else
                        ...displayChapters.map((chapter) => ChapterTile(
                          chapter: chapter,
                          isRead: progress.isChapterRead(chapter.id),
                          onTap: () async {
                            await _handleChapterTap(
                              context,
                              chapter,
                              state.chapters,
                            );
                          },
                          onToggleRead: () {
                            ref
                                .read(readingProgressProvider.notifier)
                                .toggleChapter(
                                  mangaId: widget.manga.id,
                                  chapterId: chapter.id,
                                  totalChaptersCount: state.chapters.length,
                                );
                          },
                        )),

                    // Bottom padding
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
            ],
          ),

          // ── Floating top buttons ──────────────────────────────
          _FloatingTopButtons(manga: widget.manga),
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
        AppRoutes.readerPath(mangaId: widget.manga.id, chapterId: chapter.id),
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
        AppRoutes.readerPath(mangaId: widget.manga.id, chapterId: chapter.id),
        extra: chapter,
      );
      return;
    }

    try {
      final uri = Uri.parse(externalUrl);
      if (uri.scheme != 'http' && uri.scheme != 'https') {
        AppFeedback.showWarning(
          context,
          title: context.l10n.externalChapterTitle,
        );
        return;
      }

      // ponytail: skip canLaunchUrl — on modern Android it often returns false
      // even when a browser can handle the URL. Just launch directly.
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        AppFeedback.showWarning(
          context,
          title: context.l10n.externalChapterTitle,
        );
      }
    } on Exception catch (e, st) {
      debugPrint('[ExternalLink] Failed to launch URL: $e\n$st');
      if (!context.mounted) return;
      AppFeedback.showWarning(
        context,
        title: context.l10n.externalChapterTitle,
      );
    }
  }
}

// ── Floating Top Buttons ─────────────────────────────────────────────────────

class _FloatingTopButtons extends ConsumerWidget {
  final Manga manga;

  const _FloatingTopButtons({required this.manga});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isInLibrary = ref.watch(
      userLibraryProvider.select(
        (value) => value[manga.id]?.isInLibrary ?? false,
      ),
    );

    return Positioned(
      top: MediaQuery.of(context).padding.top + 4,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            // Back button
            SizedBox(
              width: 40,
              height: 40,
              child: Material(
                color: AppColors.voidLowest.withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.pop(),
                  child: const Icon(
                    Icons.arrow_back,
                    color: AppColors.onSurface,
                    size: 24,
                  ),
                ),
              ),
            ),
            // Bookmark toggle
            SizedBox(
              width: 40,
              height: 40,
              child: Material(
                color: AppColors.voidLowest.withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final bool nowInLibrary = await ref
                        .read(userLibraryProvider.notifier)
                        .toggle(manga);
                    if (!context.mounted) return;

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
                  child: Icon(
                    isInLibrary ? Icons.bookmark : Icons.bookmark_border,
                    color: AppColors.onSurface,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cover Aspect Ratio Classification ─────────────────────────────────────────

/// Classifies an image by its width/height ratio.
enum _CoverRatio {
  portrait,
  landscape,
  square;

  static _CoverRatio fromSize(Size size) {
    final ratio = size.width / size.height;
    if (ratio > 1.15) return landscape;
    if (ratio < 0.85) return portrait;
    return square;
  }
}

// ── Cover Section ─────────────────────────────────────────────────────────────

class _CoverSection extends StatefulWidget {
  final Manga manga;

  const _CoverSection({required this.manga});

  @override
  State<_CoverSection> createState() => _CoverSectionState();
}

class _CoverSectionState extends State<_CoverSection> {
  _CoverRatio _ratio = _CoverRatio.square;
  ImageStream? _imageStream;

  @override
  void initState() {
    super.initState();
    _imageListener = ImageStreamListener(_onImageInfo, onError: _onImageError);
    // Resuelve la imagen ANTES del primer frame. Si está en cache,
    // _onImageInfo se llama síncrono y _ratio queda seteado para el build.
    _resolveImage();
  }

  @override
  void dispose() {
    _imageStream?.removeListener(_imageListener);
    super.dispose();
  }

  late final ImageStreamListener _imageListener;

  void _onImageInfo(ImageInfo info, bool sync) {
    final size = Size(
      info.image.width.toDouble(),
      info.image.height.toDouble(),
    );
    final detected = _CoverRatio.fromSize(size);
    if (detected != _ratio && mounted) {
      setState(() => _ratio = detected);
    }
  }

  void _onImageError(Object error, StackTrace? stack) {
    // Silently keep the neutral default on error.
  }

  void _resolveImage() {
    final url = widget.manga.coverUrl;
    if (url == null) return;

    _imageStream?.removeListener(_imageListener);
    final provider = CachedNetworkImageProvider(url);
    _imageStream = provider.resolve(ImageConfiguration.empty);
    _imageStream!.addListener(_imageListener);
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // Pick width based on aspect ratio so each format shines.
    final double coverWidth = switch (_ratio) {
      _CoverRatio.portrait => (screenWidth * 0.55).clamp(220, 320),
      _CoverRatio.landscape => (screenWidth * 0.90).clamp(300, 420),
      _CoverRatio.square => (screenWidth * 0.70).clamp(260, 360),
    };

    // Max height so tall portrait covers don't tower.
    final double maxHeight = switch (_ratio) {
      _CoverRatio.portrait => (screenHeight * 0.60),
      _CoverRatio.landscape => (screenHeight * 0.45),
      _CoverRatio.square => (screenHeight * 0.60),
    };

    // Max top so tall portrait covers don't tower.
    final double topPadding = switch (_ratio) {
      _CoverRatio.portrait => (maxHeight * 0.2),
      _CoverRatio.landscape => (maxHeight * 0.25),
      _CoverRatio.square => (maxHeight * 0.2),
    };

    // Content below the cover: tags (~60px) + title (~80px) + score (~20px)

    // ConstrainedBox outside ClipRRect: the cap limits the box, but
    // ClipRRect wraps the image at its RENDERED size, so corner-radius
    // clips actual image pixels — not letterbox.
    final Widget coverImage = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: widget.manga.coverUrl ?? '',
          fit: BoxFit.contain,
          placeholder: (_, __) => const ColoredBox(
            color: AppColors.card,
            child: Center(child: Icon(Icons.image, color: AppColors.outline)),
          ),
          errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
        ),
      ),
    );

    // ── Tags ─────────────────────────────────────────────────
    final List<String> tags = <String>[
      if (widget.manga.status != null) widget.manga.status!.toUpperCase(),
      ...widget.manga.genres.take(3).map((g) => g.toUpperCase()),
      if (widget.manga.demographic != null)
        widget.manga.demographic!.toUpperCase(),
    ];

    // ── Score badge row ──────────────────────────────────────
    final String? scoreStr = widget.manga.score?.toStringAsFixed(1);

    return Column(
        mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: EdgeInsetsGeometry.only(
                  top: topPadding,
                  bottom: 16,
                ),
                child: SizedBox(
                  width: coverWidth,
                  child: Stack(
                    children: <Widget>[
                      coverImage,
                      // Score badge (same style as MangaTile)
                      // For landscape the image doesn't reach the top, so
                      // we place the badge at the bottom instead.
                      if (scoreStr != null)
                        Positioned(
                          top: _ratio == _CoverRatio.landscape ? null : 8,
                          bottom: _ratio == _CoverRatio.landscape ? 8 : null,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.cardHigh,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Icon(Icons.star,
                                    size: 12, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  scoreStr,
                                  style: const TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
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

              // Tags row
              if (tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: tags.asMap().entries.map((entry) {
                      final bool isFirst = entry.key == 0;
                      return _Tag(label: entry.value, isStatus: isFirst);
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 16),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  widget.manga.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ),

              // Description — unlimited, adapts to text length
              if (widget.manga.description != null &&
                  widget.manga.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Text(
                    widget.manga.description!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),

              // Bottom breathing room before the next sliver
              const SizedBox(height: 24),
            ],
    );
  }
}

// ── Tag Chip ──────────────────────────────────────────────────────────────────

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

// ── Chapters Header ──────────────────────────────────────────────────────────

class _ChaptersHeader extends ConsumerWidget {
  final MangaReadingProgress progress;
  final String mangaId;
  final bool showLanguageSelector;

  const _ChaptersHeader({
    required this.progress,
    required this.mangaId,
    this.showLanguageSelector = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mangaChaptersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
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
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  icon: Icon(
                    state.sortDescending
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: const Color(0xFF889391),
                    size: 20,
                  ),
                  onPressed: () => ref
                      .read(mangaChaptersProvider.notifier)
                      .setSortDescending(value: !state.sortDescending),
                  tooltip: state.sortDescending
                      ? context.l10n.chaptersSortDesc
                      : context.l10n.chaptersSortAsc,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: Icon(
                    state.filterUnreadOnly
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: const Color(0xFF889391),
                    size: 20,
                  ),
                  onPressed: () => ref
                      .read(mangaChaptersProvider.notifier)
                      .setFilterUnreadOnly(value: !state.filterUnreadOnly),
                  tooltip: state.filterUnreadOnly
                      ? context.l10n.chaptersFilterUnread
                      : context.l10n.chaptersFilterAll,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Language + Reader mode inline
        Row(
          children: <Widget>[
            if (showLanguageSelector)
              Expanded(
                child: LanguageSelector(
                  availableLanguages: state.availableLanguages,
                  selectedLanguage: state.selectedLanguage,
                  isLoading: state.isLanguageLoading,
                  onLanguageChanged: (lang) {
                    ref
                        .read(mangaChaptersProvider.notifier)
                        .loadChapters(mangaId, language: lang);
                  },
                ),
              ),
            const SizedBox(width: 8),
            const _CompactReaderModeToggle(),
          ],
        ),
      ],
    );
  }
}

/// Compact reader mode toggle — chip-style PopupMenuButton instead of a full
/// DropdownButtonFormField, placed inline next to the language selector.
class _CompactReaderModeToggle extends ConsumerWidget {
  const _CompactReaderModeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mangaId = GoRouterState.of(context).pathParameters['mangaId'];
    if (mangaId == null) return const SizedBox.shrink();

    final overrideState = ref.watch(perTitleOverrideProvider(mangaId));
    final notifier = ref.read(perTitleOverrideProvider(mangaId).notifier);
    final prefsState = ref.watch(preferencesProvider);
    final globalMode = prefsState.preferences?.defaultReaderMode;
    final rawOverride = overrideState?.preferredReaderMode;

    final ReaderMode currentMode =
        rawOverride ?? globalMode ?? ReaderMode.vertical;
    final String currentLabel = currentMode == ReaderMode.vertical
        ? 'Vertical'
        : 'Paginado';

    return PopupMenuButton<ReaderMode>(
      initialValue: currentMode,
      onSelected: (mode) {
        if (mode == globalMode) {
          notifier.clearOverride();
        } else {
          notifier.setMode(mode);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.menu_book_outlined,
              size: 16,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              currentLabel,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
      itemBuilder: (context) {
        final items = <PopupMenuItem<ReaderMode>>[
          const PopupMenuItem(
            value: ReaderMode.vertical,
            child: Text('Vertical', style: TextStyle(fontSize: 13)),
          ),
          const PopupMenuItem(
            value: ReaderMode.paged,
            child: Text('Paginado', style: TextStyle(fontSize: 13)),
          ),
        ];
        if (globalMode != null && rawOverride != null) {
          items.insert(
            0,
            PopupMenuItem(
              value: globalMode,
              child: Text(
                'Usar global (${globalMode == ReaderMode.vertical ? "Vertical" : "Paginado"})',
                style: const TextStyle(fontSize: 13, color: AppColors.primary),
              ),
            ),
          );
        }
        return items;
      },
    );
  }
}

// ── Chapter Tile (pen design) ────────────────────────────────────────────────
// (see chapter_tile.dart — updated separately)
