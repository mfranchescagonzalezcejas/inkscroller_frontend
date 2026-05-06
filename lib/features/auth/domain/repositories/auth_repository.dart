import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_user.dart';

/// Domain contract for all authentication operations.
///
/// Implementations live in the data layer and are injected by the DI
/// container. Use cases depend only on this interface, keeping domain logic
/// free of Firebase or infrastructure concerns.
abstract class AuthRepository {
  /// A broadcast stream that emits the authenticated [AppUser] when signed in,
  /// or `null` when signed out.
  Stream<AppUser?> get authStateChanges;

  /// Returns the currently signed-in [AppUser], or `null` if not authenticated.
  AppUser? get currentUser;

  /// Signs in the user with [email] and [password].
  ///
  /// Returns [Right(AppUser)] on success or [Left(Failure)] on failure.
  Future<Either<Failure, AppUser>> signIn({
    required String email,
    required String password,
  });

  /// Creates a new account with [email] and [password].
  ///
  /// Returns [Right(AppUser)] on success or [Left(Failure)] on failure.
  Future<Either<Failure, AppUser>> signUp({
    required String email,
    required String password,
  });

  /// Signs out the current user.
  ///
  /// Returns [Right(null)] on success or [Left(Failure)] on failure.
  Future<Either<Failure, void>> signOut();

  /// Returns the current Firebase ID token for backend requests.
  ///
  /// Refreshes the token if it has expired. Returns [Right(token)] on success.
  Future<Either<Failure, String>> getIdToken();
}
