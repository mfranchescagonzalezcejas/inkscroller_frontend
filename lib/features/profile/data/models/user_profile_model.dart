import '../../domain/entities/user_profile.dart';

/// DTO for `/users/me` response.
class UserProfileModel {
  final String firebaseUid;
  final String email;
  final String? displayName;
  final String? username;
  final String? birthDate;
  final String createdAt;

  const UserProfileModel({
    required this.firebaseUid,
    required this.email,
    this.displayName,
    this.username,
    this.birthDate,
    required this.createdAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      firebaseUid: json['firebase_uid'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      username: json['username'] as String?,
      birthDate: json['birth_date'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  UserProfile toEntity() {
    return UserProfile(
      firebaseUid: firebaseUid,
      email: email,
      displayName: displayName,
      username: username,
      birthDate: birthDate == null ? null : DateTime.tryParse(birthDate!),
      createdAt:
          DateTime.tryParse(createdAt) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
