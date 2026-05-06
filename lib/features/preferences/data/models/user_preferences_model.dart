import '../../../library/domain/entities/reader_mode.dart';
import '../../domain/entities/user_reading_preferences.dart';

/// DTO for `/users/me/preferences`.
class UserPreferencesModel {
  final String firebaseUid;
  final String defaultReaderMode;
  final String defaultLanguage;
  final String updatedAt;

  const UserPreferencesModel({
    required this.firebaseUid,
    required this.defaultReaderMode,
    required this.defaultLanguage,
    required this.updatedAt,
  });

  factory UserPreferencesModel.fromJson(Map<String, dynamic> json) {
    return UserPreferencesModel(
      firebaseUid: json['firebase_uid'] as String,
      defaultReaderMode: json['default_reader_mode'] as String? ?? 'vertical',
      defaultLanguage: json['default_language'] as String? ?? 'en',
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toUpdateJson({
    String? defaultReaderMode,
    String? defaultLanguage,
  }) {
    return <String, dynamic>{
      if (defaultReaderMode != null) 'default_reader_mode': defaultReaderMode,
      if (defaultLanguage != null) 'default_language': defaultLanguage,
    };
  }

  UserReadingPreferences toEntity() {
    return UserReadingPreferences(
      defaultReaderMode: switch (defaultReaderMode) {
        'paged' => ReaderMode.paged,
        _ => ReaderMode.vertical,
      },
      defaultLanguage: defaultLanguage,
      updatedAt:
          DateTime.tryParse(updatedAt) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
