import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

/// Use case that sends a password reset email to the given address.
class SendPasswordReset {
  final AuthRepository repository;

  const SendPasswordReset(this.repository);

  /// Executes the password reset email flow.
  Future<Either<Failure, void>> call({required String email}) {
    return repository.sendPasswordReset(email: email);
  }
}
