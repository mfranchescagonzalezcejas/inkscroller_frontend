import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../domain/usecases/get_user_profile.dart';
import 'user_profile_state.dart';

/// StateNotifier handling user profile UI flow.
class UserProfileNotifier extends StateNotifier<UserProfileState> {
  final GetUserProfile getUserProfile;

  UserProfileNotifier({required this.getUserProfile})
    : super(const UserProfileState());

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await getUserProfile();

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: _mapFailureToMessage(failure),
      ),
      (profile) => state = state.copyWith(
        isLoading: false,
        profile: profile,
        clearError: true,
      ),
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _mapFailureToMessage(Failure failure) {
    return switch (failure) {
      ServerFailure(message: final message) ||
      NetworkFailure(message: final message) ||
      CacheFailure(message: final message) ||
      UnexpectedFailure(message: final message) ||
      ExternalChapterFailure(message: final message) => message,
    };
  }
}
