import 'dart:convert';
import 'dart:io';

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
  static const String _guestPrefix = 'guest_';

  String _keyFor(String base, bool isGuest) =>
      isGuest ? '$_guestPrefix$base' : base;

  @override
  Future<UserReadingPreferences?> getCachedPreferences({
    bool isGuest = false,
  }) async {
    final timestamp = prefs.getInt(_keyFor(_timestampKey, isGuest));
    if (timestamp == null) {
      return isGuest ? _guestDefaults() : null;
    }

    // Guest preferences never expire — they persist until explicitly cleared.
    if (!isGuest) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final age = now - timestamp;
      if (age > AppConstants.mangaDetailCacheTtlMinutes * 60 * 1000) {
        await clearCache();
        return null;
      }
    }

    final json = prefs.getString(_keyFor(_prefsKey, isGuest));
    if (json == null) return isGuest ? _guestDefaults() : null;

    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      final crf = data['contentRatingFilter'] as String?;
      final demographicFilter = (data['demographicFilter'] as List<dynamic>?)
          ?.whereType<String>()
          .map(MangaDemographic.tryFromJson)
          .whereType<MangaDemographic>()
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
      await clearCache(isGuest: isGuest);
      return isGuest ? _guestDefaults() : null;
    }
  }

  @override
  Future<void> savePreferences(
    UserReadingPreferences preferences, {
    bool isGuest = false,
  }) async {
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

    await prefs.setString(_keyFor(_prefsKey, isGuest), json);
    await prefs.setInt(
      _keyFor(_timestampKey, isGuest),
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  Future<void> clearCache({bool isGuest = false}) async {
    final key = _keyFor(_prefsKey, isGuest);
    final tsKey = _keyFor(_timestampKey, isGuest);
    await prefs.remove(key);
    await prefs.remove(tsKey);
  }

  /// Maps a platform locale string to a supported reading language code.
  /// Defaults to 'en' when the locale is unrecognised.
  String _normalizeLanguage(String raw) {
    final code = raw.split('_').first.split('-').first.toLowerCase();
    const supported = {'en', 'es', 'pt', 'fr', 'de', 'it', 'ja', 'ko', 'zh'};
    return supported.contains(code) ? code : 'en';
  }

  /// Returns device-locale defaults for a first-time guest load.
  UserReadingPreferences _guestDefaults() {
    return UserReadingPreferences(
      defaultReaderMode: ReaderMode.vertical,
      defaultLanguage: _normalizeLanguage(Platform.localeName),
      contentRatingFilter: ContentRating.safe,
      demographicFilter: const [
        MangaDemographic.shounen,
        MangaDemographic.shoujo,
      ],
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
