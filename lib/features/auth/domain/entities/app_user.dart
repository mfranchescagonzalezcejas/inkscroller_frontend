/// Represents the currently authenticated user in the domain layer.
///
/// This is a pure Dart value object with no Firebase or infrastructure
/// dependencies. The data layer maps Firebase-specific user objects to this
/// entity.
class AppUser {
  /// Firebase UID — the stable, globally unique identity key.
  final String uid;

  /// Primary email address for the user.
  final String email;

  /// Optional display name. May be null when not set on the Firebase account.
  final String? displayName;

  /// Whether the user's email has been verified via Firebase.
  final bool isEmailVerified;

  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.isEmailVerified = false,
  });
}
