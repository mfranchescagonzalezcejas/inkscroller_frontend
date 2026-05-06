import 'package:flutter/material.dart';

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
      itemBuilder: (context, index) {
        return _ReaderPageImage(
          url: pages[index],
          pageNumber: index + 1,
          fit: BoxFit.fitWidth,
        );
      },
    );
  }
}

/// Single page image widget with loading and error states.
class _ReaderPageImage extends StatefulWidget {
  final String url;
  final int pageNumber;
  final BoxFit fit;

  const _ReaderPageImage({
    required this.url,
    required this.pageNumber,
    required this.fit,
  });

  @override
  State<_ReaderPageImage> createState() => _ReaderPageImageState();
}

class _ReaderPageImageState extends State<_ReaderPageImage> {
  ImageStream? _imageStream;
  bool _isLoaded = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(_ReaderPageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _imageStream?.removeListener(ImageStreamListener(_onImageLoaded));
      _loadImage();
    }
  }

  void _loadImage() {
    setState(() {
      _isLoaded = false;
      _hasError = false;
    });

    final image = NetworkImage(widget.url);
    _imageStream = image.resolve(ImageConfiguration.empty);
    _imageStream!.addListener(
      ImageStreamListener(_onImageLoaded, onError: _onImageError),
    );
  }

  void _onImageLoaded(ImageInfo imageInfo, bool synchronousCall) {
    if (mounted) {
      setState(() {
        _isLoaded = true;
      });
    }
  }

  void _onImageError(dynamic exception, StackTrace? stackTrace) {
    if (mounted) {
      setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _imageStream?.removeListener(ImageStreamListener(_onImageLoaded));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _ErrorPlaceholder(pageNumber: widget.pageNumber);
    }

    if (!_isLoaded) {
      return _LoadingPlaceholder(pageNumber: widget.pageNumber);
    }

    return Image.network(
      widget.url,
      fit: widget.fit,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        return _ErrorPlaceholder(pageNumber: widget.pageNumber);
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
