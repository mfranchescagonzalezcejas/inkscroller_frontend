import '../models/user_profile_model.dart';

/// Contract for the remote user profile data source.
// ignore: one_member_abstracts
abstract class UserProfileRemoteDataSource {
  /// Reads `/users/me`.
  Future<UserProfileModel> getProfile();

  /// Updates authenticated profile metadata via `/users/me`.
  Future<UserProfileModel> updateProfile({
    required String username,
    required DateTime birthDate,
  });
}
