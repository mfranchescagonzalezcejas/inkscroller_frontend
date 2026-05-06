import '../entities/reader_mode.dart';
import '../entities/reading_preferences.dart';

/// Resolves the effective reader mode using the Phase 5 preference chain.
///
/// Priority:
/// 1. per-title override
/// 2. global user preference
/// 3. content suggestion / heuristic
/// 4. app default (`vertical`)
class ResolveReaderMode {
  const ResolveReaderMode();

  /// Returns the effective [ReaderMode] for the current chapter session.
  ReaderMode call({
    ReaderMode? globalReaderMode,
    PerTitleOverride? titleOverride,
    required ReaderContentMetadata contentMetadata,
  }) {
    return titleOverride?.preferredReaderMode ??
        globalReaderMode ??
        contentMetadata.suggestedMode ??
        ReaderMode.vertical;
  }
}
