/// Contract for the remote settings data source.
// ignore: one_member_abstracts
abstract class SettingsRemoteDataSource {
  /// Deletes the authenticated user's account via `DELETE /users/me`.
  Future<void> deleteAccount();
}
