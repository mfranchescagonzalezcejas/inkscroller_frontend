import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/design/design_tokens.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../preferences/presentation/providers/preferences_provider.dart';
import '../../domain/entities/chapter.dart';
import '../../domain/entities/reader_mode.dart';
import '../providers/per_title_override_provider.dart';
import '../providers/reader/reader_provider.dart';
import '../providers/reader/reader_ui_provider.dart';
import '../widgets/paged_reader_view.dart';
import '../widgets/reader_settings_sheet.dart';
import '../widgets/vertical_reader_view.dart';

/// Vertical-scroll chapter reader that displays page images with pre-cache progress.
///
/// Receives a [chapterId], resolves page URLs via [readerProvider], and shows
/// a linear progress bar while images are being pre-cached by [ReaderNotifier].
/// The effective reader mode is resolved through [ResolveReaderMode] using the
/// preference chain: per-title override → global preference → content heuristic
/// → app default (`vertical`).
///
/// ## P0-F2 — External chapter guard
///
/// When [chapter] is provided and [Chapter.external] is `true`, the page renders
/// a warning screen instead of the internal reader. The guard is a second line of
/// defense: [MangaDetailPage] already prevents navigation for external chapters,
/// but deep-links and direct route constructions bypass that layer.
class ReaderPage extends ConsumerStatefulWidget {
  final String chapterId;
  final String? mangaId;

  /// Optional chapter entity passed from the navigation layer.
  ///
  /// When provided and [Chapter.external] is `true`, the internal reader is
  /// skipped entirely and an external-link warning screen is shown instead.
  final Chapter? chapter;

  const ReaderPage({
    super.key,
    required this.chapterId,
    this.mangaId,
    this.chapter,
  });

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage> {
  @override
  void initState() {
    super.initState();

    // P0-F2 guard: skip loading entirely when the chapter is external-only.
    // The external warning screen is built synchronously in [build]; no
    // provider load is needed.
    if (widget.chapter?.external ?? false) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final preferences = ref.read(preferencesProvider);
      final globalReaderMode = preferences.preferences?.defaultReaderMode;

      final titleOverride = widget.mangaId != null
          ? ref.read(perTitleOverrideProvider(widget.mangaId!))
          : null;

      ref.read(readerProvider(widget.chapterId).notifier).loadChapter(
            chapterId: widget.chapterId,
            globalReaderMode: globalReaderMode,
            titleOverride: titleOverride,
          );
    });
  }

  @override
  void dispose() {
    // Restore system UI directly — ref is not usable inside dispose() in
    // Riverpod's ConsumerStatefulWidget lifecycle.
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── P0-F2: External chapter guard ────────────────────────────────────
    // When the chapter entity is known and flagged as external, render a
    // redirect/warning screen. This prevents any in-app rendering of content
    // that is hosted exclusively on third-party sites.
    if (widget.chapter?.external ?? false) {
      return _ExternalChapterScreen(
        externalUrl: widget.chapter?.externalUrl,
      );
    }

    final state = ref.watch(readerProvider(widget.chapterId));

    if (state.isLoading) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.loadingChapter,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: state.progress),
                const SizedBox(height: 12),
                Text(
                  context.l10n.chapterPagesProgress(
                    state.loadedPages,
                    state.totalPages,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.failure != null) {
      return Scaffold(body: Center(child: Text(state.failure!.message)));
    }

    final uiState = ref.watch(readerUiProvider(widget.chapterId));
    final background =
        uiState.amoledBlack ? Colors.black : AppColors.voidLowest;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(context.l10n.readingChapter),
        backgroundColor: background,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            tooltip: context.l10n.readerSettingsConfirm,
            onPressed: () => showReaderSettings(
              context,
              chapterId: widget.chapterId,
              mangaId: widget.mangaId,
            ),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          switch (state.readerMode) {
            ReaderMode.vertical => VerticalReaderView(pages: state.pages),
            ReaderMode.paged => PagedReaderView(pages: state.pages),
          },
          // Brightness overlay — black with opacity inversely proportional to
          // the brightness level. At full brightness (1.0) the overlay is
          // invisible; at minimum (0.1) it dims the content significantly.
          if (uiState.brightness < 1.0)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: Colors.black
                      .withValues(alpha: 1.0 - uiState.brightness),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Warning screen shown when a chapter is marked as [Chapter.external].
///
/// Offers the user the option to open the chapter on the original site (via
/// [url_launcher]) or to go back. This screen is shown instead of the in-app
/// reader to comply with P0-F2 compliance requirements: external chapters must
/// NOT be rendered internally.
class _ExternalChapterScreen extends StatelessWidget {
  final String? externalUrl;

  const _ExternalChapterScreen({this.externalUrl});

  @override
  Widget build(BuildContext context) {
    final hasUrl = externalUrl != null && externalUrl!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.externalChapterTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.open_in_new, size: 48),
              const SizedBox(height: 16),
              Text(
                context.l10n.externalChapterTitle,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.externalChapterMessage,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (hasUrl)
                FilledButton.icon(
                  icon: const Icon(Icons.open_in_browser),
                  label: Text(context.l10n.externalChapterOpenAction),
                  onPressed: () async {
                    final uri = Uri.parse(externalUrl!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  }
                },
                child: Text(context.l10n.externalChapterGoBackAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
