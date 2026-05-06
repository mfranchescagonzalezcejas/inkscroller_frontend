import 'package:flutter/material.dart';

/// Paged chapter reader with page-by-page navigation and zoom support.
///
/// Shows one page at a time in a [PageView] with natural swipe gestures.
/// Tap toggles the page counter overlay. [InteractiveViewer] provides
/// pinch-to-zoom on each page.
class PagedReaderView extends StatefulWidget {
  /// Ordered chapter page image URLs.
  final List<String> pages;

  const PagedReaderView({super.key, required this.pages});

  @override
  State<PagedReaderView> createState() => _PagedReaderViewState();
}

class _PagedReaderViewState extends State<PagedReaderView> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: _toggleControls,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.pages.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              return _ReaderPageImage(
                url: widget.pages[index],
                pageNumber: index + 1,
              );
            },
          ),
        ),

        // Top bar with page counter
        AnimatedOpacity(
          opacity: _showControls ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: _TopBar(
            currentPage: _currentPage + 1,
            totalPages: widget.pages.length,
          ),
        ),
      ],
    );
  }
}

/// Top bar showing current page position.
class _TopBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const _TopBar({required this.currentPage, required this.totalPages});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
          ),
        ),
        child: Text(
          '$currentPage / $totalPages',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Single page image widget with loading and error states.
class _ReaderPageImage extends StatefulWidget {
  final String url;
  final int pageNumber;

  const _ReaderPageImage({required this.url, required this.pageNumber});

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
      setState(() => _isLoaded = true);
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

    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      child: Center(
        child: Image.network(
          widget.url,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) {
            return _ErrorPlaceholder(pageNumber: widget.pageNumber);
          },
        ),
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  final int pageNumber;

  const _LoadingPlaceholder({required this.pageNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            'Cargando página $pageNumber...',
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
