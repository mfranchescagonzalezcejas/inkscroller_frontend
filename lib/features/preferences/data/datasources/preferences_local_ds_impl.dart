import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../library/domain/entities/manga_tags.dart';
import '../../../library/domain/entities/reader_mode.dart';
import '../../domain/entities/content_rating.dart';
import '../../domain/entities/user_reading_preferences.dart';
import 'preferences_local_ds.dart';

/// SharedPreferences-backed implementation of local preferences cache.
///
/// Stores a JSON representation of [UserReadingPreferences] with a TTL-based
/// expiration so stale data is not served indefinitely.
class PreferencesLocalDataSourceImpl implements PreferencesLocalDataSource {
  final SharedPreferences prefs;

  PreferencesLocalDataSourceImpl(this.prefs);

  static const String _prefsKey = 'cached_user_reading_preferences';
  static const String _timestampKey = 'cached_preferences_timestamp';

  @override
  Future<UserReadingPreferences?> getCachedPreferences() async {
    final timestamp = prefs.getInt(_timestampKey);
    if (timestamp == null) return null;

    final now = DateTime.now().millisecondsSinceEpoch;
    final age = now - timestamp;
    if (age > AppConstants.mangaDetailCacheTtlMinutes * 60 * 1000) {
      await clearCache();
      return null;
    }

    final json = prefs.getString(_prefsKey);
    if (json == null) return null;

    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      final crf = data['contentRatingFilter'] as String?;
      final demographicFilter = (data['demographicFilter'] as List<dynamic>?)
          ?.whereType<String>()
          .map(MangaDemographic.fromJson)
          .toList();
      return UserReadingPreferences(
        defaultReaderMode: ReaderMode.values.byName(
          data['defaultReaderMode'] as String,
        ),
        defaultLanguage: data['defaultLanguage'] as String,
        contentRatingFilter: switch (crf) {
          'safe' => ContentRating.safe,
          'suggestive' => ContentRating.suggestive,
          'all' => ContentRating.all,
          _ => null,
        },
        demographicFilter: demographicFilter,
        updatedAt: DateTime.parse(data['updatedAt'] as String),
      );
    } on Object {
      await clearCache();
      return null;
    }
  }

  @override
  Future<void> savePreferences(UserReadingPreferences preferences) async {
    final json = jsonEncode({
      'defaultReaderMode': preferences.defaultReaderMode.name,
      'defaultLanguage': preferences.defaultLanguage,
      if (preferences.contentRatingFilter != null)
        'contentRatingFilter': preferences.contentRatingFilter!.wireValue,
      if (preferences.demographicFilter != null)
        'demographicFilter': preferences.demographicFilter!
            .map((demographic) => demographic.toJson())
            .toList(),
      'updatedAt': preferences.updatedAt.toIso8601String(),
    });

    await prefs.setString(_prefsKey, json);
    await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  @override
  Future<void> clearCache() async {
    await prefs.remove(_prefsKey);
    await prefs.remove(_timestampKey);
  }
}
