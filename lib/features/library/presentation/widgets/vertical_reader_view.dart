import 'dart:async';

import 'package:flutter/material.dart';

/// How many off-screen pages to build and pre-load in the vertical reader.
const int _preloadAheadCount = 8;

/// Extra scroll-buffer pixels to trigger off-screen page preloading.
const double _cacheExtent = 800;

/// Vertical-scroll chapter reader that stacks page images top-to-bottom.
///
/// Each page shows a loading placeholder while the image downloads,
/// handles individual image errors gracefully, and uses gapless playback
/// to avoid flickering when scrolling back.
class VerticalReaderView extends StatelessWidget {
  /// Ordered chapter page image URLs.
  final List<String> pages;

  const VerticalReaderView({super.key, required this.pages});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: pages.length,
      cacheExtent: _cacheExtent,
      itemBuilder: (context, index) {
        _preloadNext(context, index);
        return _ReaderPageImage(
          url: pages[index],
          pageNumber: index + 1,
          fit: BoxFit.fitWidth,
        );
      },
    );
  }

  /// Fires background decode for the next `_preloadAheadCount` pages.
  void _preloadNext(BuildContext context, int currentIndex) {
    for (int i = currentIndex + 1;
        i <= currentIndex + _preloadAheadCount && i < pages.length;
        i++) {
      unawaited(precacheImage(NetworkImage(pages[i]), context));
    }
  }
}

/// Single page image widget with loading and error states.
class _ReaderPageImage extends StatelessWidget {
  final String url;
  final int pageNumber;
  final BoxFit fit;

  const _ReaderPageImage({
    required this.url,
    required this.pageNumber,
    required this.fit,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      gaplessPlayback: true,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _LoadingPlaceholder(pageNumber: pageNumber);
      },
      errorBuilder: (context, error, stackTrace) {
        return _ErrorPlaceholder(pageNumber: pageNumber);
      },
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  final int pageNumber;

  const _LoadingPlaceholder({required this.pageNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 12),
          Text(
            'Página $pageNumber',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  final int pageNumber;

  const _ErrorPlaceholder({required this.pageNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      alignment: Alignment.center,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'No se pudo cargar la página $pageNumber',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
