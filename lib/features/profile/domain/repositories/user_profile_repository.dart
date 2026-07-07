import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_profile.dart';

/// Domain contract for user profile operations.
// ignore: one_member_abstracts
abstract class UserProfileRepository {
  Future<Either<Failure, UserProfile>> getProfile();
}
