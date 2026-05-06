import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Use case that exposes the authentication state stream.
///
/// Consumers watch this stream to react to sign-in/sign-out events.
class GetAuthState {
  final AuthRepository repository;

  const GetAuthState(this.repository);

  /// Returns a broadcast stream of [AppUser?].
  ///
  /// Emits an [AppUser] when signed in and `null` when signed out.
  Stream<AppUser?> call() => repository.authStateChanges;
}
