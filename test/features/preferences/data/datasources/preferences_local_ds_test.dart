import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/constants/app_constants.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/reader_mode.dart';
import 'package:inkscroller_flutter/features/preferences/data/datasources/preferences_local_ds_impl.dart';
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
    expect(result.updatedAt, DateTime(2026, 4, 5, 12));
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
