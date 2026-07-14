import '../../../library/domain/entities/manga_tags.dart';
import '../../../library/domain/entities/reader_mode.dart';
import '../../domain/entities/content_rating.dart';
import '../../domain/entities/user_reading_preferences.dart';

/// DTO for `/users/me/preferences`.
class UserPreferencesModel {
  final String firebaseUid;
  final String defaultReaderMode;
  final String defaultLanguage;
  final String? contentRatingFilter;
  final List<MangaDemographic>? demographicFilter;
  final String updatedAt;

  const UserPreferencesModel({
    required this.firebaseUid,
    required this.defaultReaderMode,
    required this.defaultLanguage,
    this.contentRatingFilter,
    this.demographicFilter,
    required this.updatedAt,
  });

  factory UserPreferencesModel.fromJson(Map<String, dynamic> json) {
    final rawDemographics = json['demographic_filter'] as List<dynamic>?;
    return UserPreferencesModel(
      firebaseUid: json['firebase_uid'] as String,
      defaultReaderMode: json['default_reader_mode'] as String? ?? 'vertical',
      defaultLanguage: json['default_language'] as String? ?? 'en',
      contentRatingFilter: json['content_rating_filter'] as String?,
      demographicFilter: _canonicalDemographics(rawDemographics?.whereType<String>()),
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toUpdateJson({
    String? defaultReaderMode,
    String? defaultLanguage,
    String? contentRatingFilter,
    List<MangaDemographic>? demographicFilter,
  }) {
    // Use the explicit parameter, or fall back to the model's stored field.
    final effectiveDemographics = _canonicalDemographics(
      (demographicFilter ?? this.demographicFilter)?.map((item) => item.name),
    );

    return <String, dynamic>{
      if (defaultReaderMode != null) 'default_reader_mode': defaultReaderMode,
      if (defaultLanguage != null) 'default_language': defaultLanguage,
      if (contentRatingFilter != null)
        'content_rating_filter': contentRatingFilter,
      if (effectiveDemographics != null)
        'demographic_filter': effectiveDemographics.isEmpty
            ? null
            : effectiveDemographics.map((e) => e.toJson()).toList(),
    };
  }

  static List<MangaDemographic>? _canonicalDemographics(Iterable<String>? raw) {
    if (raw == null) return null;
    final values = raw
        .map(MangaDemographic.tryFromJson)
        .whereType<MangaDemographic>()
        .toSet()
        .toList()
      ..sort((left, right) => left.index.compareTo(right.index));
    return values;
  }

  UserReadingPreferences toEntity() {
    return UserReadingPreferences(
      defaultReaderMode: switch (defaultReaderMode) {
        'paged' => ReaderMode.paged,
        _ => ReaderMode.vertical,
      },
      defaultLanguage: defaultLanguage,
      contentRatingFilter: switch (contentRatingFilter) {
        'safe' => ContentRating.safe,
        'suggestive' => ContentRating.suggestive,
        'all' => ContentRating.all,
        _ => null,
      },
      demographicFilter: demographicFilter,
      updatedAt:
          DateTime.tryParse(updatedAt) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
