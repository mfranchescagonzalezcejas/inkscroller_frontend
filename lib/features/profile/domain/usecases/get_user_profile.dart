import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_profile.dart';
import '../repositories/user_profile_repository.dart';

/// Use case that fetches the authenticated user's profile.
class GetUserProfile {
  final UserProfileRepository repository;

  const GetUserProfile(this.repository);

  /// Executes the fetch.
  Future<Either<Failure, UserProfile>> call() {
    return repository.getProfile();
  }
}
