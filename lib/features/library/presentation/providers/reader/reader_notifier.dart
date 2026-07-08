import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/error/failures.dart';
import '../../../domain/entities/reader_mode.dart';
import '../../../domain/entities/reading_preferences.dart';
import '../../../domain/usecases/resolve_reader_mode.dart';
import '../../../domain/usecases/get_chapter_pages.dart';
import 'reader_state.dart';

/// Loads chapter page URLs and pre-caches images concurrently in the background.
///
/// Fetches page data via [GetChapterPages], then immediately shows the reader
/// with all page URLs while pre-warming images in parallel using a worker pool.
/// Each reader view widget handles its own per-image loading placeholder, so
/// the reader is usable from the first frame after URLs are available.
class ReaderNotifier extends StateNotifier<ReaderState> {
  final GetChapterPages getChapterPages;
  final ResolveReaderMode resolveReaderMode;

  ReaderNotifier({
    required this.getChapterPages,
    required this.resolveReaderMode,
  }) : super(const ReaderState());

  bool _isDisposed = false;

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
    result.fold(
      (failure) {
        hasFailed = true;
        if (_isDisposed) return;
        state = state.copyWith(isLoading: false, failure: failure);
      },
      (p) => pages = p,
    );
    if (hasFailed || _isDisposed) return;
    if (pages.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        failure: const UnexpectedFailure(message: 'Capítulo sin páginas'),
      );
      return;
    }

    final readerMode = resolveReaderMode(
      globalReaderMode: globalReaderMode,
      titleOverride: titleOverride,
      contentMetadata: ReaderContentMetadata(pageCount: pages.length),
    );

    // Precache the first 3 pages while the loading screen is still visible.
    // This way the reader opens with images already in cache — no spinners.
    state = state.copyWith(
      pages: pages,
      isLoading: true,
      readerMode: readerMode,
      totalPages: pages.length,
      loadedPages: 0,
      clearFailure: true,
    );

    final firstPages = pages.take(3).toList();
    // Gracefully handle precache failures — images still load on demand.
    try {
      await _precacheImages(firstPages);
    } on Object catch (_) {
      // Precache is a perf optimisation, not a requirement.
    }

    // Now show the reader — first 3 pages are cache-ready.
    state = state.copyWith(
      isLoading: false,
      loadedPages: firstPages.length,
    );

    // Pre-warm the remaining pages in the background.
    if (pages.length > 3) {
      unawaited(_precacheAllConcurrent(pages.sublist(3)));
    }
  }

  /// Downloads and caches [urls] using a worker-pool with [concurrency] slots.
  ///
  /// Workers compete for the next URL via a shared index so all slots stay busy
  /// until the queue is exhausted. Updates [ReaderState.loadedPages] after each
  /// image completes so the progress indicator (if visible) stays accurate.
  Future<void> _precacheAllConcurrent(
    List<String> urls, {
    int concurrency = 4,
  }) async {
    var index = 0;
    var loaded = 0;

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
        state = state.copyWith(loadedPages: loaded);
      }
    }

    await Future.wait(
      List.generate(math.min(concurrency, urls.length), (_) => worker()),
    );
  }

  /// Pre-caches [urls] in parallel. Used for the initial batch so the reader
  /// opens with the first pages already in the image cache.
  Future<void> _precacheImages(List<String> urls) async {
    await Future.wait(urls.map(_precacheNetworkImage));
  }

  Future<void> _precacheNetworkImage(String url) async {
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
