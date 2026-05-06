import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/error/failures.dart';
import 'package:inkscroller_flutter/features/profile/domain/entities/user_profile.dart';
import 'package:inkscroller_flutter/features/profile/domain/usecases/get_user_profile.dart';
import 'package:inkscroller_flutter/features/profile/presentation/providers/user_profile_notifier.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetUserProfile extends Mock implements GetUserProfile {}

void main() {
  late GetUserProfile getUserProfile;
  late UserProfileNotifier notifier;

  setUp(() {
    getUserProfile = _MockGetUserProfile();
    notifier = UserProfileNotifier(getUserProfile: getUserProfile);
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
}
