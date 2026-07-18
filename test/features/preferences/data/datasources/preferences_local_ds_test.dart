import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/constants/app_constants.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_tags.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/reader_mode.dart';
import 'package:inkscroller_flutter/features/preferences/data/datasources/preferences_local_ds_impl.dart';
import 'package:inkscroller_flutter/features/preferences/domain/entities/content_rating.dart';
import 'package:inkscroller_flutter/features/preferences/domain/entities/user_reading_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late PreferencesLocalDataSourceImpl dataSource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    dataSource = PreferencesLocalDataSourceImpl(prefs);
  });

  final samplePrefs = UserReadingPreferences(
    defaultReaderMode: ReaderMode.paged,
    defaultLanguage: 'es',
    updatedAt: DateTime(2026, 4, 5, 12),
  );

  // ── savePreferences / getCachedPreferences ────────────────────────────────

  test('returns null when no cache exists', () async {
    final result = await dataSource.getCachedPreferences();
    expect(result, isNull);
  });

  test('saves and retrieves preferences correctly', () async {
    await dataSource.savePreferences(samplePrefs);

    final result = await dataSource.getCachedPreferences();

    expect(result, isNotNull);
    expect(result!.defaultReaderMode, ReaderMode.paged);
    expect(result.defaultLanguage, 'es');
    expect(result.contentRatingFilter, isNull);
    expect(result.updatedAt, DateTime(2026, 4, 5, 12));
  });

  test('round-trips non-null contentRatingFilter', () async {
    final prefsWithRating = UserReadingPreferences(
      defaultReaderMode: ReaderMode.vertical,
      defaultLanguage: 'en',
      contentRatingFilter: ContentRating.suggestive,
      updatedAt: DateTime(2026, 6),
    );

    await dataSource.savePreferences(prefsWithRating);
    final result = await dataSource.getCachedPreferences();

    expect(result, isNotNull);
    expect(result!.contentRatingFilter, ContentRating.suggestive);
    expect(result.defaultReaderMode, ReaderMode.vertical);
  });

  test('drops unknown demographic values from cache', () async {
    // Pre-seed cache with a known good value + an unknown `kodomo` token.
    await prefs.setString('cached_user_reading_preferences', '''
{
  "defaultReaderMode": "vertical",
  "defaultLanguage": "en",
  "demographicFilter": ["seinen", "kodomo", "josei"],
  "updatedAt": "${DateTime(2026, 6).toIso8601String()}"
}''');
    await prefs.setInt(
      'cached_preferences_timestamp',
      DateTime.now().millisecondsSinceEpoch,
    );

    final result = await dataSource.getCachedPreferences();

    expect(result, isNotNull);
    expect(
      result!.demographicFilter,
      const <MangaDemographic>[MangaDemographic.seinen, MangaDemographic.josei],
    );
  });

  test('round-trips demographicFilter', () async {
    final prefsWithDemographics = UserReadingPreferences(
      defaultReaderMode: ReaderMode.vertical,
      defaultLanguage: 'en',
      demographicFilter: const <MangaDemographic>[MangaDemographic.seinen, MangaDemographic.josei],
      updatedAt: DateTime(2026, 6),
    );

    await dataSource.savePreferences(prefsWithDemographics);
    final result = await dataSource.getCachedPreferences();

    expect(result!.demographicFilter, const <MangaDemographic>[MangaDemographic.seinen, MangaDemographic.josei]);
  });

  test('returns null when cache is expired', () async {
    await dataSource.savePreferences(samplePrefs);

    // Manually set timestamp to beyond TTL.
    final expiredTimestamp = DateTime.now().millisecondsSinceEpoch -
        (AppConstants.mangaDetailCacheTtlMinutes + 1) * 60 * 1000;
    await prefs.setInt('cached_preferences_timestamp', expiredTimestamp);

    final result = await dataSource.getCachedPreferences();

    expect(result, isNull);
  });

  test('returns preferences when cache is within TTL', () async {
    await dataSource.savePreferences(samplePrefs);

    final result = await dataSource.getCachedPreferences();

    expect(result, isNotNull);
    expect(result!.defaultReaderMode, ReaderMode.paged);
  });

  test('returns null and clears cache when JSON is corrupted', () async {
    await prefs.setString('cached_user_reading_preferences', '{bad json');
    await prefs.setInt(
      'cached_preferences_timestamp',
      DateTime.now().millisecondsSinceEpoch,
    );

    final result = await dataSource.getCachedPreferences();

    expect(result, isNull);
    // Verify cache was cleared.
    expect(prefs.getString('cached_user_reading_preferences'), isNull);
  });

  // ── guest-scoped keys ─────────────────────────────────────────────────────

  test('guest savePreferences writes to guest_-prefixed keys', () async {
    await dataSource.savePreferences(samplePrefs, isGuest: true);

    // Guest data lives under guest_-prefixed keys, not the normal keys.
    expect(prefs.getString('cached_user_reading_preferences'), isNull);
    expect(prefs.getInt('cached_preferences_timestamp'), isNull);
    expect(prefs.getString('guest_cached_user_reading_preferences'), isNotNull);
    expect(prefs.getInt('guest_cached_preferences_timestamp'), isNotNull);
  });

  test('guest getCachedPreferences reads from guest_-prefixed keys', () async {
    // Seed guest key with data.
    await dataSource.savePreferences(samplePrefs, isGuest: true);

    final result = await dataSource.getCachedPreferences(isGuest: true);

    expect(result, isNotNull);
    expect(result!.defaultReaderMode, ReaderMode.paged);
    expect(result.defaultLanguage, 'es');
  });

  test('guest and authenticated keys are independent', () async {
    final guestPrefs = UserReadingPreferences(
      defaultReaderMode: ReaderMode.vertical,
      defaultLanguage: 'ja',
      updatedAt: DateTime(2026, 7),
    );

    await dataSource.savePreferences(guestPrefs, isGuest: true);
    await dataSource.savePreferences(samplePrefs);

    final guestResult = await dataSource.getCachedPreferences(isGuest: true);
    final authResult = await dataSource.getCachedPreferences();

    expect(guestResult!.defaultReaderMode, ReaderMode.vertical);
    expect(authResult!.defaultReaderMode, ReaderMode.paged);
  });

  test('guest getCachedPreferences returns defaults on cache miss', () async {
    final result = await dataSource.getCachedPreferences(isGuest: true);

    expect(result, isNotNull);
    expect(result!.defaultReaderMode, ReaderMode.vertical);
    expect(result.defaultLanguage, isNotEmpty);
    expect(result.contentRatingFilter, ContentRating.safe);
    expect(
      result.demographicFilter,
      const <MangaDemographic>[MangaDemographic.shounen, MangaDemographic.shoujo],
    );
  });

  test('clearCache removes guest_-prefixed keys too', () async {
    await dataSource.savePreferences(samplePrefs, isGuest: true);
    expect(
      prefs.getString('guest_cached_user_reading_preferences'),
      isNotNull,
    );

    await dataSource.clearCache();

    expect(
      prefs.getString('guest_cached_user_reading_preferences'),
      isNull,
    );
    expect(
      prefs.getInt('guest_cached_preferences_timestamp'),
      isNull,
    );
  });

  // ── clearCache ────────────────────────────────────────────────────────────

  test('clearCache removes both preferences and timestamp', () async {
    await dataSource.savePreferences(samplePrefs);

    // Verify data exists.
    expect(prefs.getString('cached_user_reading_preferences'), isNotNull);
    expect(prefs.getInt('cached_preferences_timestamp'), isNotNull);

    await dataSource.clearCache();

    expect(prefs.getString('cached_user_reading_preferences'), isNull);
    expect(prefs.getInt('cached_preferences_timestamp'), isNull);
  });
}
