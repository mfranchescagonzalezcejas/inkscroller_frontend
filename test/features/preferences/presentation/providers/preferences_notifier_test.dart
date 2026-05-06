import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/library/domain/entities/reader_mode.dart';
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

  test('loadPreferences sets loading true then stores preferences on success',
      () async {
    when(
      () => getPreferences(),
    ).thenAnswer((_) async => Right<Failure, UserReadingPreferences>(samplePrefs));

    await notifier.loadPreferences();

    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.preferences, samplePrefs);
    expect(notifier.state.error, isNull);
  });

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
      ),
    ).thenAnswer((_) async => Right<Failure, UserReadingPreferences>(samplePrefs));

    await notifier.savePreferences(defaultReaderMode: 'paged');

    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.preferences, samplePrefs);
    expect(notifier.state.error, isNull);
  });

  test('savePreferences stores error message on failure', () async {
    when(
      () => updatePreferences(
        defaultReaderMode: any(named: 'defaultReaderMode'),
        defaultLanguage: any(named: 'defaultLanguage'),
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

  test('clearError removes error from state without changing other fields',
      () async {
    when(
      () => getPreferences(),
    ).thenAnswer((_) async => const Left(NetworkFailure(message: 'offline')));

    await notifier.loadPreferences();
    expect(notifier.state.error, 'offline');

    notifier.clearError();

    expect(notifier.state.error, isNull);
    expect(notifier.state.preferences, isNull);
  });
}
