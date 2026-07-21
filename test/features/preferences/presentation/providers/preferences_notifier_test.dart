import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/manga_tags.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/reader_mode.dart';
import 'package:inkscroller_flutter/features/preferences/domain/entities/content_rating.dart';
import 'package:inkscroller_flutter/features/preferences/domain/entities/user_reading_preferences.dart';
import 'package:inkscroller_flutter/features/preferences/domain/usecases/get_preferences.dart';
import 'package:inkscroller_flutter/features/preferences/domain/usecases/update_preferences.dart';
import 'package:inkscroller_flutter/features/preferences/presentation/providers/preferences_notifier.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetPreferences extends Mock implements GetPreferences {}

class _MockUpdatePreferences extends Mock implements UpdatePreferences {}

void main() {
  late GetPreferences getPreferences;
  late UpdatePreferences updatePreferences;
  late PreferencesNotifier notifier;

  setUp(() {
    getPreferences = _MockGetPreferences();
    updatePreferences = _MockUpdatePreferences();
    notifier = PreferencesNotifier(
      getPreferences: getPreferences,
      updatePreferences: updatePreferences,
    );
  });

  final samplePrefs = UserReadingPreferences(
    defaultReaderMode: ReaderMode.vertical,
    defaultLanguage: 'en',
    updatedAt: DateTime(2026),
  );

  // ── loadPreferences ───────────────────────────────────────────────────────

  test(
    'loadPreferences sets loading true then stores preferences on success',
    () async {
      when(() => getPreferences()).thenAnswer(
        (_) async => Right<Failure, UserReadingPreferences>(samplePrefs),
      );

      await notifier.loadPreferences();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.preferences, samplePrefs);
      expect(notifier.state.error, isNull);
    },
  );

  test('loadPreferences stores error message on failure', () async {
    when(
      () => getPreferences(),
    ).thenAnswer((_) async => const Left(NetworkFailure(message: 'offline')));

    await notifier.loadPreferences();

    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.preferences, isNull);
    expect(notifier.state.error, 'offline');
  });

  // ── savePreferences ───────────────────────────────────────────────────────

  test('savePreferences stores updated preferences on success', () async {
    when(
      () => updatePreferences(
        defaultReaderMode: any(named: 'defaultReaderMode'),
        defaultLanguage: any(named: 'defaultLanguage'),
        contentRatingFilter: any(named: 'contentRatingFilter'),
      ),
    ).thenAnswer(
      (_) async => Right<Failure, UserReadingPreferences>(samplePrefs),
    );

    await notifier.savePreferences(defaultReaderMode: 'paged');

    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.preferences, samplePrefs);
    expect(notifier.state.error, isNull);
  });

  test('savePreferences forwards concrete contentRatingFilter', () async {
    final prefsWithRating = UserReadingPreferences(
      defaultReaderMode: ReaderMode.vertical,
      defaultLanguage: 'en',
      contentRatingFilter: ContentRating.suggestive,
      updatedAt: DateTime(2026),
    );

    when(
      () => updatePreferences(
        defaultReaderMode: any(named: 'defaultReaderMode'),
        defaultLanguage: any(named: 'defaultLanguage'),
        contentRatingFilter: any(named: 'contentRatingFilter'),
      ),
    ).thenAnswer(
      (_) async => Right<Failure, UserReadingPreferences>(prefsWithRating),
    );

    await notifier.savePreferences(contentRatingFilter: 'suggestive');

    expect(notifier.state.isLoading, isFalse);
    expect(
      notifier.state.preferences?.contentRatingFilter,
      ContentRating.suggestive,
    );
    verify(
      () => updatePreferences(
        defaultReaderMode: any(named: 'defaultReaderMode'),
        defaultLanguage: any(named: 'defaultLanguage'),
        contentRatingFilter: 'suggestive',
      ),
    ).called(1);
  });

  test('savePreferences stores error message on failure', () async {
    when(
      () => updatePreferences(
        defaultReaderMode: any(named: 'defaultReaderMode'),
        defaultLanguage: any(named: 'defaultLanguage'),
        contentRatingFilter: any(named: 'contentRatingFilter'),
      ),
    ).thenAnswer(
      (_) async => const Left(ServerFailure(message: 'server error')),
    );

    await notifier.savePreferences(defaultReaderMode: 'vertical');

    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.preferences, isNull);
    expect(notifier.state.error, 'server error');
  });

  // ── clearError ────────────────────────────────────────────────────────────

  test(
    'clearError removes error from state without changing other fields',
    () async {
      when(
        () => getPreferences(),
      ).thenAnswer((_) async => const Left(NetworkFailure(message: 'offline')));

      await notifier.loadPreferences();
      expect(notifier.state.error, 'offline');

      notifier.clearError();

      expect(notifier.state.error, isNull);
      expect(notifier.state.preferences, isNull);
    },
  );

  // ── syncGuestPreferencesToRemote ──────────────────────────────────────────

  test(
    'syncGuestPreferencesToRemote calls updatePreferences with current state',
    () async {
      notifier = PreferencesNotifier(
        getPreferences: getPreferences,
        updatePreferences: updatePreferences,
        isServerBackedSession: () => false,
      );

      // Set up state with preferences.
      when(() => getPreferences()).thenAnswer(
        (_) async => Right<Failure, UserReadingPreferences>(samplePrefs),
      );
      await notifier.loadPreferences();

      when(
        () => updatePreferences(
          defaultReaderMode: any(named: 'defaultReaderMode'),
          defaultLanguage: any(named: 'defaultLanguage'),
          contentRatingFilter: any(named: 'contentRatingFilter'),
          demographicFilter: any(named: 'demographicFilter'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, UserReadingPreferences>(samplePrefs),
      );

      await notifier.syncGuestPreferencesToRemote();

      verify(
        () => updatePreferences(
          defaultReaderMode: 'vertical',
          defaultLanguage: 'en',
          contentRatingFilter: any(named: 'contentRatingFilter'),
          demographicFilter: any(named: 'demographicFilter'),
        ),
      ).called(1);
    },
  );

  test('syncGuestPreferencesToRemote skips after server-backed load', () async {
    when(() => getPreferences()).thenAnswer(
      (_) async => Right<Failure, UserReadingPreferences>(samplePrefs),
    );
    await notifier.loadPreferences();

    await notifier.syncGuestPreferencesToRemote();

    verifyNever(
      () => updatePreferences(
        defaultReaderMode: any(named: 'defaultReaderMode'),
        defaultLanguage: any(named: 'defaultLanguage'),
        contentRatingFilter: any(named: 'contentRatingFilter'),
        demographicFilter: any(named: 'demographicFilter'),
      ),
    );
  });

  test(
    'syncGuestPreferencesToRemote does nothing when preferences are null',
    () async {
      // State has no preferences — should not call updatePreferences.
      await notifier.syncGuestPreferencesToRemote();

      verifyNever(
        () => updatePreferences(
          defaultReaderMode: any(named: 'defaultReaderMode'),
          defaultLanguage: any(named: 'defaultLanguage'),
          contentRatingFilter: any(named: 'contentRatingFilter'),
          demographicFilter: any(named: 'demographicFilter'),
        ),
      );
    },
  );

  test(
    'syncGuestPreferencesToRemote preserves existing preferences fields',
    () async {
      notifier = PreferencesNotifier(
        getPreferences: getPreferences,
        updatePreferences: updatePreferences,
        isServerBackedSession: () => false,
      );

      final prefsWithAll = UserReadingPreferences(
        defaultReaderMode: ReaderMode.paged,
        defaultLanguage: 'es',
        contentRatingFilter: ContentRating.suggestive,
        demographicFilter: const [MangaDemographic.seinen],
        updatedAt: DateTime(2026, 7),
      );

      when(() => getPreferences()).thenAnswer(
        (_) async => Right<Failure, UserReadingPreferences>(prefsWithAll),
      );
      await notifier.loadPreferences();

      when(
        () => updatePreferences(
          defaultReaderMode: any(named: 'defaultReaderMode'),
          defaultLanguage: any(named: 'defaultLanguage'),
          contentRatingFilter: any(named: 'contentRatingFilter'),
          demographicFilter: any(named: 'demographicFilter'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, UserReadingPreferences>(prefsWithAll),
      );

      await notifier.syncGuestPreferencesToRemote();

      verify(
        () => updatePreferences(
          defaultReaderMode: 'paged',
          defaultLanguage: 'es',
          contentRatingFilter: 'suggestive',
          demographicFilter: ['seinen'],
        ),
      ).called(1);
    },
  );
}
