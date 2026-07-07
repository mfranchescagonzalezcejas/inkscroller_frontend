/// Represents the authenticated user's profile.
class UserProfile {
  final String firebaseUid;
  final String email;
  final String? displayName;
  final DateTime createdAt;

  const UserProfile({
    required this.firebaseUid,
    required this.email,
    this.displayName,
    required this.createdAt,
  });
}
