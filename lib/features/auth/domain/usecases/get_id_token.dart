import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

/// Use case that returns the current Firebase ID token for backend requests.
class GetIdToken {
  final AuthRepository repository;

  const GetIdToken(this.repository);

  /// Returns the ID token string, refreshing it if expired.
  Future<Either<Failure, String>> call() => repository.getIdToken();
}
