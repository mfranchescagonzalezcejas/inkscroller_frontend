import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

/// Use case that signs out the currently authenticated user.
class SignOut {
  final AuthRepository repository;

  const SignOut(this.repository);

  /// Executes the sign-out flow.
  Future<Either<Failure, void>> call() {
    return repository.signOut();
  }
}
