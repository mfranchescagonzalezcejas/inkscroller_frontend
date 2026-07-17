import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

/// Use case that sends an email verification link to the current user.
class SendEmailVerification {
  final AuthRepository repository;

  const SendEmailVerification(this.repository);

  /// Executes sending the verification email.
  Future<Either<Failure, void>> call() {
    return repository.sendEmailVerification();
  }
}
