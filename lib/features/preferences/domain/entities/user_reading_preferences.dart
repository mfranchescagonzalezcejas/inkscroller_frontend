import '../../../library/domain/entities/reader_mode.dart';

/// Global reading preferences for the authenticated user.
class UserReadingPreferences {
  /// Effective default reader mode configured for the account.
  final ReaderMode defaultReaderMode;

  /// Preferred content language code.
  final String defaultLanguage;

  /// Last backend update timestamp.
  final DateTime updatedAt;

  const UserReadingPreferences({
    required this.defaultReaderMode,
    required this.defaultLanguage,
    required this.updatedAt,
  });
}
