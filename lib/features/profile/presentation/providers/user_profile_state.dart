import '../../domain/entities/user_profile.dart';

/// Immutable UI state for user profile.
class UserProfileState {
  final bool isLoading;
  final UserProfile? profile;
  final String? error;

  const UserProfileState({this.isLoading = false, this.profile, this.error});

  UserProfileState copyWith({
    bool? isLoading,
    UserProfile? profile,
    String? error,
    bool clearProfile = false,
    bool clearError = false,
  }) {
    return UserProfileState(
      isLoading: isLoading ?? this.isLoading,
      profile: clearProfile ? null : profile ?? this.profile,
      error: clearError ? null : error ?? this.error,
    );
  }
}
