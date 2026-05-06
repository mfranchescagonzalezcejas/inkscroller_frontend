import '../../../../../core/error/failures.dart';
import '../../../domain/entities/reader_mode.dart';

/// Immutable snapshot of the chapter reader state.
///
/// Holds the list of page URLs, image pre-cache progress ([loadedPages] / [totalPages]),
/// and loading/error flags. Consumed by [ReaderPage] via [readerProvider].
class ReaderState {
  final bool isLoading;
  final List<String> pages;
  final int loadedPages;
  final int totalPages;
  final Failure? failure;
  final ReaderMode readerMode;

  const ReaderState({
    this.isLoading = false,
    this.pages = const [],
    this.loadedPages = 0,
    this.totalPages = 0,
    this.failure,
    this.readerMode = ReaderMode.vertical,
  });

  double get progress => totalPages == 0 ? 0 : loadedPages / totalPages;

  ReaderState copyWith({
    bool? isLoading,
    List<String>? pages,
    int? loadedPages,
    int? totalPages,
    Failure? failure,
    ReaderMode? readerMode,
    bool clearFailure = false,
  }) {
    return ReaderState(
      isLoading: isLoading ?? this.isLoading,
      pages: pages ?? this.pages,
      loadedPages: loadedPages ?? this.loadedPages,
      totalPages: totalPages ?? this.totalPages,
      failure: clearFailure ? null : failure ?? this.failure,
      readerMode: readerMode ?? this.readerMode,
    );
  }
}
