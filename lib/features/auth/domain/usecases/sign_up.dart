import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Use case that creates a new account with email and password.
class SignUp {
  final AuthRepository repository;

  const SignUp(this.repository);

  /// Executes the registration flow.
  Future<Either<Failure, AppUser>> call({
    required String email,
    required String password,
  }) {
    return repository.signUp(email: email, password: password);
  }
}
