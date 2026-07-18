import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/profile/domain/entities/user_profile.dart';
import 'package:inkscroller_flutter/features/profile/domain/usecases/get_user_profile.dart';
import 'package:inkscroller_flutter/features/profile/domain/usecases/update_user_profile.dart';
import 'package:inkscroller_flutter/features/profile/presentation/providers/user_profile_notifier.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetUserProfile extends Mock implements GetUserProfile {}

class _MockUpdateUserProfile extends Mock implements UpdateUserProfile {}

/// Shared test birth date used across profile-update scenarios.
final _kTestBirthDate = DateTime(2000);

/// Unit tests for [UserProfileNotifier].
void main() {
  late GetUserProfile getUserProfile;
  late UpdateUserProfile mockUpdateUserProfile;
  late UserProfileNotifier notifier;

  setUp(() {
    getUserProfile = _MockGetUserProfile();
    mockUpdateUserProfile = _MockUpdateUserProfile();
    notifier = UserProfileNotifier(
      getUserProfile: getUserProfile,
      updateUserProfile: mockUpdateUserProfile,
    );
  });

  final sampleProfile = UserProfile(
    firebaseUid: 'uid-123',
    email: 'test@example.com',
    displayName: 'Test User',
    createdAt: DateTime(2026),
  );

  // ── loadProfile ───────────────────────────────────────────────────────────

  test('loadProfile sets loading true then stores profile on success', () async {
    when(
      () => getUserProfile(),
    ).thenAnswer((_) async => Right<Failure, UserProfile>(sampleProfile));

    await notifier.loadProfile();

    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.profile, sampleProfile);
    expect(notifier.state.error, isNull);
  });

  test('loadProfile stores error message on failure', () async {
    when(
      () => getUserProfile(),
    ).thenAnswer((_) async => const Left(NetworkFailure(message: 'offline')));

    await notifier.loadProfile();

    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.profile, isNull);
    expect(notifier.state.error, 'offline');
  });

  test('loadProfile stores server error message on server failure', () async {
    when(
      () => getUserProfile(),
    ).thenAnswer(
      (_) async => const Left(ServerFailure(message: 'server error')),
    );

    await notifier.loadProfile();

    expect(notifier.state.isLoading, isFalse);
    expect(notifier.state.profile, isNull);
    expect(notifier.state.error, 'server error');
  });

  // ── clearError ────────────────────────────────────────────────────────────

  test('clearError removes error from state without changing other fields',
      () async {
    when(
      () => getUserProfile(),
    ).thenAnswer((_) async => const Left(NetworkFailure(message: 'offline')));

    await notifier.loadProfile();
    expect(notifier.state.error, 'offline');

    notifier.clearError();

    expect(notifier.state.error, isNull);
    expect(notifier.state.profile, isNull);
  });

  // ── updateProfile ───────────────────────────────────────────────────────

  group('updateProfile', () {
    test('stores updated profile on success', () async {
      when(
        () => mockUpdateUserProfile(
          username: any(named: 'username'),
          birthDate: any(named: 'birthDate'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, UserProfile>(
          UserProfile(
            firebaseUid: 'uid-123',
            email: 'test@example.com',
            username: 'newname',
            createdAt: DateTime(2026),
          ),
        ),
      );

      await notifier.updateProfile(
        username: 'newname',
        birthDate: _kTestBirthDate,
      );

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.profile?.username, 'newname');
      expect(notifier.state.error, isNull);
    });

    test('stores error message on failure', () async {
      when(
        () => mockUpdateUserProfile(
          username: any(named: 'username'),
          birthDate: any(named: 'birthDate'),
        ),
      ).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'username taken')),
      );

      await notifier.updateProfile(
        username: 'taken',
        birthDate: _kTestBirthDate,
      );

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, 'username taken');
    });

    test('stores network error on failure', () async {
      when(
        () => mockUpdateUserProfile(
          username: any(named: 'username'),
          birthDate: any(named: 'birthDate'),
        ),
      ).thenAnswer(
        (_) async => const Left(NetworkFailure(message: 'offline')),
      );

      await notifier.updateProfile(
        username: 'newname',
        birthDate: _kTestBirthDate,
      );

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, 'offline');
    });
  });
}
