import '../../../library/domain/entities/reader_mode.dart';
import 'content_rating.dart';

/// Global reading preferences for the authenticated user.
class UserReadingPreferences {
  /// Effective default reader mode configured for the account.
  final ReaderMode defaultReaderMode;

  /// Preferred content language code.
  final String defaultLanguage;

  /// Content rating filter for catalogue results.
  final ContentRating? contentRatingFilter;

  /// Last backend update timestamp.
  final DateTime updatedAt;

  const UserReadingPreferences({
    required this.defaultReaderMode,
    required this.defaultLanguage,
    this.contentRatingFilter,
    required this.updatedAt,
  });
}
