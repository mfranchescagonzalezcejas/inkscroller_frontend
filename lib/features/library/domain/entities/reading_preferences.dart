import 'reader_mode.dart';

/// Global reading preferences for the current user.
///
/// This is a pure domain entity. Persistence details belong to later M3 work.
class ReadingPreferences {
  /// Explicit global reader mode selected by the user.
  final ReaderMode? preferredReaderMode;

  const ReadingPreferences({this.preferredReaderMode});
}

/// Optional override for a specific manga/title.
class PerTitleOverride {
  /// Manga identifier this override applies to.
  final String mangaId;

  /// Explicit mode for this title.
  final ReaderMode preferredReaderMode;

  const PerTitleOverride({
    required this.mangaId,
    required this.preferredReaderMode,
  });
}

/// Content metadata used only to resolve a fallback reader mode.
class ReaderContentMetadata {
  /// Optional manga identifier related to the currently opened chapter.
  final String? mangaId;

  /// Number of pages in the chapter.
  final int pageCount;

  /// Suggested mode derived from content-level heuristics, if available.
  final ReaderMode? suggestedMode;

  const ReaderContentMetadata({
    this.mangaId,
    required this.pageCount,
    this.suggestedMode,
  });
}
