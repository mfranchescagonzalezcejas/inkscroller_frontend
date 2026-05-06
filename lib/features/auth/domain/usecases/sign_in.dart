import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Use case that signs in an existing user with email and password.
class SignIn {
  final AuthRepository repository;

  const SignIn(this.repository);

  /// Executes the sign-in flow.
  Future<Either<Failure, AppUser>> call({
    required String email,
    required String password,
  }) {
    return repository.signIn(email: email, password: password);
  }
}
