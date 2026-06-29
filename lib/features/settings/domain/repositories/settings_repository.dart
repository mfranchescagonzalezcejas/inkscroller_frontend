import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';

/// Domain contract for account-level settings operations.
// ignore: one_member_abstracts
abstract class SettingsRepository {
  /// Permanently deletes the authenticated user's account on the backend.
  ///
  /// Returns [Right(null)] on success or [Left(Failure)] on failure.
  Future<Either<Failure, void>> deleteAccount();
}
