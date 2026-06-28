import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_profile.dart';
import '../repositories/user_profile_repository.dart';

/// Use case that updates authenticated user profile metadata.
class UpdateUserProfile {
  final UserProfileRepository repository;

  const UpdateUserProfile(this.repository);

  /// Submits profile metadata to the backend.
  Future<Either<Failure, UserProfile>> call({
    required String username,
    required DateTime birthDate,
  }) {
    return repository.updateProfile(username: username, birthDate: birthDate);
  }
}
