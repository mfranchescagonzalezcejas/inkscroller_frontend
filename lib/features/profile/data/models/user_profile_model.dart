import '../../domain/entities/user_profile.dart';

/// DTO for `/users/me` response.
class UserProfileModel {
  final String firebaseUid;
  final String email;
  final String? displayName;
  final String createdAt;

  const UserProfileModel({
    required this.firebaseUid,
    required this.email,
    this.displayName,
    required this.createdAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      firebaseUid: json['firebase_uid'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  UserProfile toEntity() {
    return UserProfile(
      firebaseUid: firebaseUid,
      email: email,
      displayName: displayName,
      createdAt:
          DateTime.tryParse(createdAt) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
