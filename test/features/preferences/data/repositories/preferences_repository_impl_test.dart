import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/exceptions.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/reader_mode.dart';
import 'package:inkscroller_flutter/features/preferences/data/datasources/preferences_local_ds.dart';
import 'package:inkscroller_flutter/features/preferences/data/datasources/preferences_remote_ds.dart';
import 'package:inkscroller_flutter/features/preferences/data/models/user_preferences_model.dart';
import 'package:inkscroller_flutter/features/preferences/data/repositories/preferences_repository_impl.dart';
import 'package:inkscroller_flutter/features/preferences/domain/entities/user_reading_preferences.dart';
import 'package:inkscroller_flutter/features/preferences/domain/repositories/preferences_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemoteDataSource extends Mock implements PreferencesRemoteDataSource {}

class _MockLocalDataSource extends Mock implements PreferencesLocalDataSource {}

void main() {
  late PreferencesRemoteDataSource remoteDataSource;
  late PreferencesLocalDataSource localDataSource;
  late PreferencesRepository repository;

  setUpAll(() {
    registerFallbackValue(UserReadingPreferences(
      defaultReaderMode: ReaderMode.vertical,
      defaultLanguage: 'en',
      updatedAt: DateTime.now(),
    ));
  });

  setUp(() {
    remoteDataSource = _MockRemoteDataSource();
    localDataSource = _MockLocalDataSource();
    repository = PreferencesRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
    );
  });

  final localPrefs = UserReadingPreferences(
    defaultReaderMode: ReaderMode.paged,
    defaultLanguage: 'es',
    updatedAt: DateTime(2026, 4, 5, 12), // newer
  );

  const remoteModel = UserPreferencesModel(
    firebaseUid: 'uid-123',
    defaultReaderMode: 'vertical',
    defaultLanguage: 'en',
    updatedAt: '2026-01-01T00:00:00.000',
  );

  // ── getPreferences ────────────────────────────────────────────────────────

  test('returns remote data and updates local cache when remote succeeds',
      () async {
    when(
      () => remoteDataSource.getPreferences(),
    ).thenAnswer((_) async => remoteModel);
    when(
      () => localDataSource.getCachedPreferences(),
    ).thenAnswer((_) async => null);
    when(
      () => localDataSource.savePreferences(any()),
    ).thenAnswer((_) async {});

    final result = await repository.getPreferences();

    expect(result, isA<Right<Failure, UserReadingPreferences>>());
    final prefs = (result as Right<Failure, UserReadingPreferences>).value;
    expect(prefs.defaultReaderMode, ReaderMode.vertical);
    verify(() => localDataSource.savePreferences(prefs)).called(1);
  });

  test('falls back to local cache when remote fails and cache exists', () async {
    when(
      () => remoteDataSource.getPreferences(),
    ).thenThrow(const NetworkException(message: 'offline'));
    when(
      () => localDataSource.getCachedPreferences(),
    ).thenAnswer((_) async => localPrefs);

    final result = await repository.getPreferences();

    expect(result, isA<Right<Failure, UserReadingPreferences>>());
    final prefs = (result as Right<Failure, UserReadingPreferences>).value;
    expect(prefs.defaultReaderMode, ReaderMode.paged);
    expect(prefs.defaultLanguage, 'es');
  });

  test('returns failure when remote fails and no cache exists', () async {
    when(
      () => remoteDataSource.getPreferences(),
    ).thenThrow(const NetworkException(message: 'offline'));
    when(
      () => localDataSource.getCachedPreferences(),
    ).thenAnswer((_) async => null);

    final result = await repository.getPreferences();

    expect(result, isA<Left<Failure, UserReadingPreferences>>());
    final failure = (result as Left<Failure, UserReadingPreferences>).value;
    expect(failure, isA<NetworkFailure>());
  });

  test('keeps local data when local timestamp is newer than remote', () async {
    const olderRemoteModel = UserPreferencesModel(
      firebaseUid: 'uid-123',
      defaultReaderMode: 'vertical',
      defaultLanguage: 'en',
      updatedAt: '2026-01-01T00:00:00.000',
    );

    when(
      () => remoteDataSource.getPreferences(),
    ).thenAnswer((_) async => olderRemoteModel);
    when(
      () => localDataSource.getCachedPreferences(),
    ).thenAnswer((_) async => localPrefs);
    when(
      () => remoteDataSource.updatePreferences(
        defaultReaderMode: any(named: 'defaultReaderMode'),
        defaultLanguage: any(named: 'defaultLanguage'),
      ),
    ).thenAnswer((_) async => remoteModel);

    final result = await repository.getPreferences();

    expect(result, isA<Right<Failure, UserReadingPreferences>>());
    final prefs = (result as Right<Failure, UserReadingPreferences>).value;
    // Local is newer, so it should be kept.
    expect(prefs.defaultReaderMode, ReaderMode.paged);
    expect(prefs.defaultLanguage, 'es');
    // Verify push-to-remote was attempted.
    verify(
      () => remoteDataSource.updatePreferences(
        defaultReaderMode: 'paged',
        defaultLanguage: 'es',
      ),
    ).called(1);
  });

  // ── updatePreferences ─────────────────────────────────────────────────────

  test('writes to local first then syncs remote on success', () async {
    when(
      () => localDataSource.getCachedPreferences(),
    ).thenAnswer((_) async => null);
    when(
      () => localDataSource.savePreferences(any()),
    ).thenAnswer((_) async {});
    when(
      () => remoteDataSource.updatePreferences(
        defaultReaderMode: any(named: 'defaultReaderMode'),
        defaultLanguage: any(named: 'defaultLanguage'),
      ),
    ).thenAnswer((_) async => remoteModel);

    final result = await repository.updatePreferences(
      defaultReaderMode: 'paged',
    );

    expect(result, isA<Right<Failure, UserReadingPreferences>>());
    // Local should be written at least once (optimistic + remote response).
    verify(() => localDataSource.savePreferences(any())).called(2);
  });

  test('returns optimistic data when remote fails during update', () async {
    when(
      () => localDataSource.getCachedPreferences(),
    ).thenAnswer((_) async => null);
    when(
      () => localDataSource.savePreferences(any()),
    ).thenAnswer((_) async {});
    when(
      () => remoteDataSource.updatePreferences(
        defaultReaderMode: any(named: 'defaultReaderMode'),
        defaultLanguage: any(named: 'defaultLanguage'),
      ),
    ).thenThrow(const NetworkException(message: 'offline'));

    final result = await repository.updatePreferences(
      defaultReaderMode: 'paged',
      defaultLanguage: 'es',
    );

    // Should still return Right with optimistic data.
    expect(result, isA<Right<Failure, UserReadingPreferences>>());
    final prefs =
        (result as Right<Failure, UserReadingPreferences>).value;
    expect(prefs.defaultReaderMode, ReaderMode.paged);
    expect(prefs.defaultLanguage, 'es');
    // Local was written optimistically.
    verify(() => localDataSource.savePreferences(any())).called(1);
  });

  test('preserves cached fields not being updated', () async {
    when(
      () => localDataSource.getCachedPreferences(),
    ).thenAnswer((_) async => localPrefs);
    when(
      () => localDataSource.savePreferences(any()),
    ).thenAnswer((_) async {});
    when(
      () => remoteDataSource.updatePreferences(
        defaultReaderMode: any(named: 'defaultReaderMode'),
        defaultLanguage: any(named: 'defaultLanguage'),
      ),
    ).thenThrow(const NetworkException(message: 'offline'));

    final result = await repository.updatePreferences(
      defaultReaderMode: 'vertical', // only changing reader mode
    );

    expect(result, isA<Right<Failure, UserReadingPreferences>>());
    final prefs =
        (result as Right<Failure, UserReadingPreferences>).value;
    expect(prefs.defaultReaderMode, ReaderMode.vertical);
    // Language should be preserved from cache.
    expect(prefs.defaultLanguage, 'es');
  });
}
