import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/error/failures.dart';
import '../../../domain/entities/reader_mode.dart';
import '../../../domain/entities/reading_preferences.dart';
import '../../../domain/usecases/resolve_reader_mode.dart';
import '../../../domain/usecases/get_chapter_pages.dart';
import 'reader_state.dart';

/// How many pages to pre-cache before showing the reader.
const int _initialPrecacheCount = 5;

/// Loads chapter page URLs and pre-caches images concurrently in the background.
///
/// Fetches page data via [GetChapterPages], then immediately shows the reader
/// with all page URLs while pre-warming images in parallel using a worker pool.
/// Each reader view widget handles its own per-image loading placeholder, so
/// the reader is usable from the first frame after URLs are available.
class ReaderNotifier extends StateNotifier<ReaderState> {
  final GetChapterPages getChapterPages;
  final ResolveReaderMode resolveReaderMode;
  final Future<void> Function(String url) _precacheNetworkImage;
  final Duration _initialPrecacheTimeout;

  ReaderNotifier({
    required this.getChapterPages,
    required this.resolveReaderMode,
    Future<void> Function(String url)? precacheNetworkImage,
    Duration initialPrecacheTimeout = const Duration(
      seconds: AppConstants.readerPrecacheTimeoutSeconds,
    ),
  }) : _precacheNetworkImage =
           precacheNetworkImage ?? _defaultPrecacheNetworkImage,
       _initialPrecacheTimeout = initialPrecacheTimeout,
       super(const ReaderState());

  bool _isDisposed = false;
  int _loadGeneration = 0;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> loadChapter({
    required String chapterId,
    ReaderMode? globalReaderMode,
    PerTitleOverride? titleOverride,
  }) async {
    if (_isDisposed) return;

    state = state.copyWith(
      isLoading: true,
      loadedPages: 0,
      totalPages: 0,
      clearFailure: true,
    );

    final result = await getChapterPages(chapterId);
    if (_isDisposed) return;

    var pages = <String>[];
    var hasFailed = false;
    result.fold((failure) {
      hasFailed = true;
      if (_isDisposed) return;
      state = state.copyWith(isLoading: false, failure: failure);
    }, (p) => pages = p);
    if (hasFailed || _isDisposed) return;
    if (pages.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        failure: const EmptyChapterFailure(),
      );
      return;
    }

    final readerMode = resolveReaderMode(
      globalReaderMode: globalReaderMode,
      titleOverride: titleOverride,
      contentMetadata: ReaderContentMetadata(pageCount: pages.length),
    );

    // Precache initial pages while the loading screen is still visible.
    // This way the reader opens with images already in cache — no spinners.
    state = state.copyWith(
      pages: pages,
      isLoading: true,
      readerMode: readerMode,
      totalPages: pages.length,
      loadedPages: 0,
      clearFailure: true,
    );

    final firstPages = pages.take(_initialPrecacheCount).toList();
    _loadGeneration++;
    try {
      await _precacheAllConcurrent(
        firstPages,
        generation: _loadGeneration,
      ).timeout(
        _initialPrecacheTimeout,
        onTimeout: () {},
      );
    } on Object catch (_) {
      // Precache is a perf optimisation, not a requirement.
    }
    if (_isDisposed) return;

    // Bump generation so any residual first-batch workers from a timed-out
    // precache don't overwrite loadedPages with stale values.
    _loadGeneration++;

    // Show the reader with the first 5 pages already cached.
    state = state.copyWith(isLoading: false, loadedPages: firstPages.length);

    // Pre-warm the remaining pages in the background.
    if (pages.length > _initialPrecacheCount) {
      unawaited(_precacheAllConcurrent(
        pages.sublist(_initialPrecacheCount),
        generation: _loadGeneration,
        initialLoaded: _initialPrecacheCount,
      ));
    }
  }

  /// Re-resolves and applies the reader mode after a settings change.
  ///
  /// Does NOT reload pages — only updates [ReaderState.readerMode] so the
  /// reader switches between [VerticalReaderView] and [PagedReaderView]
  /// without re-fetching the chapter.
  void reapplyReaderMode({
    ReaderMode? globalReaderMode,
    PerTitleOverride? titleOverride,
  }) {
    final currentPages = state.pages;
    if (currentPages.isEmpty) return;

    final readerMode = resolveReaderMode(
      globalReaderMode: globalReaderMode,
      titleOverride: titleOverride,
      contentMetadata: ReaderContentMetadata(pageCount: currentPages.length),
    );

    state = state.copyWith(readerMode: readerMode);
  }

  /// Downloads and caches [urls] using a worker-pool with [concurrency] slots.
  ///
  /// Workers compete for the next URL via a shared index so all slots stay busy
  /// until the queue is exhausted. Updates [ReaderState.loadedPages] after each
  /// image completes so the progress indicator (if visible) stays accurate.
  Future<void> _precacheAllConcurrent(
    List<String> urls, {
    int concurrency = 4,
    required int generation,
    int initialLoaded = 0,
  }) async {
    var index = 0;
    var loaded = initialLoaded;

    Future<void> worker() async {
      while (!_isDisposed) {
        final i = index++;
        if (i >= urls.length) return;

        try {
          await _precacheNetworkImage(urls[i]);
        } on Object catch (_) {
          // Skip pages that fail to pre-cache so the rest still load.
        }

        if (_isDisposed) return;
        loaded++;
        // Only update state if this load generation is still active,
        // so timed-out workers cannot write stale progress values.
        if (generation == _loadGeneration) {
          state = state.copyWith(loadedPages: loaded);
        }
      }
    }

    await Future.wait(
      List.generate(math.min(concurrency, urls.length), (_) => worker()),
    );
  }

  static Future<void> _defaultPrecacheNetworkImage(String url) async {
    final provider = NetworkImage(url);
    final stream = provider.resolve(ImageConfiguration.empty);

    final completer = Completer<void>();

    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (image, synchronousCall) {
        stream.removeListener(listener);
        completer.complete();
      },
      onError: (error, stackTrace) {
        stream.removeListener(listener);
        completer.completeError(error, stackTrace);
      },
    );

    stream.addListener(listener);
    return completer.future;
  }
}
