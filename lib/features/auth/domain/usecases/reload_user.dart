import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Use case that reloads the current Firebase user and returns the updated
/// [AppUser] with the latest `isEmailVerified` status.
class ReloadUser {
  final AuthRepository repository;

  const ReloadUser(this.repository);

  /// Executes the user reload.
  Future<Either<Failure, AppUser>> call() {
    return repository.reloadUser();
  }
}
